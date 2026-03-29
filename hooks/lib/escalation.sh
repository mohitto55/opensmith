#!/bin/bash
# 에스컬레이션 카운터 관리
# 훅 실패 횟수를 추적하고 에스컬레이션 레벨을 결정

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ESCALATION_DB="$PROJECT_ROOT/.claude/escalation.db"

# DB 초기화
init_escalation_db() {
  if [ ! -f "$ESCALATION_DB" ]; then
    sqlite3 "$ESCALATION_DB" "
      CREATE TABLE IF NOT EXISTS escalation_counter (
        hook TEXT NOT NULL,
        file TEXT NOT NULL,
        error TEXT,
        count INTEGER DEFAULT 0,
        updated_at TEXT,
        PRIMARY KEY (hook, file)
      );
      CREATE TABLE IF NOT EXISTS escalation_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hook TEXT NOT NULL,
        file TEXT NOT NULL,
        level INTEGER NOT NULL,
        error TEXT,
        resolution TEXT,
        created_at TEXT NOT NULL
      );
    "
  fi
}

# 카운터 증가
escalate_increment() {
  local hook_name="$1"
  local file_path="$2"
  local error_msg="$3"

  init_escalation_db

  sqlite3 "$ESCALATION_DB" "
    INSERT INTO escalation_counter (hook, file, error, count, updated_at)
    VALUES ('$hook_name', '$file_path', '$(echo "$error_msg" | sed "s/'/''/g")', 1, datetime('now'))
    ON CONFLICT(hook, file) DO UPDATE SET
      count = count + 1,
      error = '$(echo "$error_msg" | sed "s/'/''/g")',
      updated_at = datetime('now');
  "
}

# 현재 레벨 확인 (1=소프트, 2=에이전트, 3=강제차단)
escalate_level() {
  local hook_name="$1"
  local file_path="$2"

  init_escalation_db

  local count=$(sqlite3 "$ESCALATION_DB" "
    SELECT COALESCE(count, 0) FROM escalation_counter
    WHERE hook='$hook_name' AND file='$file_path';
  " 2>/dev/null)

  count=${count:-0}

  if [ "$count" -le 2 ]; then
    echo "1"
  elif [ "$count" -le 5 ]; then
    echo "2"
  else
    echo "3"
  fi
}

# 카운터 리셋
escalate_reset() {
  local hook_name="$1"
  local file_path="$2"

  init_escalation_db

  sqlite3 "$ESCALATION_DB" "
    DELETE FROM escalation_counter
    WHERE hook='$hook_name' AND file='$file_path';
  "
}

# 히스토리 기록
escalate_log() {
  local hook_name="$1"
  local file_path="$2"
  local level="$3"
  local error_msg="$4"

  init_escalation_db

  sqlite3 "$ESCALATION_DB" "
    INSERT INTO escalation_history (hook, file, level, error, created_at)
    VALUES ('$hook_name', '$file_path', $level, '$(echo "$error_msg" | sed "s/'/''/g")', datetime('now'));
  "
}
