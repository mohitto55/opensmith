#!/bin/bash
# Memory Bank 쿼리 헬퍼
# SQLite + sqlite-vec 기반 시맨틱 검색 인터페이스

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
MEMORY_DB="$PROJECT_ROOT/.claude/memory-bank/memory.db"

# Memory Bank가 존재하는지 확인
memory_bank_exists() {
  [ -f "$MEMORY_DB" ]
}

# top 프로젝트 팩트 조회
get_top_facts() {
  local limit=${1:-5}

  if ! memory_bank_exists; then
    echo "(Memory Bank 미초기화)"
    return 0
  fi

  sqlite3 "$MEMORY_DB" "
    SELECT type, fact FROM facts
    WHERE status = 'active'
    ORDER BY confidence DESC, updated_at DESC
    LIMIT $limit;
  " 2>/dev/null || echo "(조회 실패)"
}

# 타입별 팩트 조회
get_facts_by_type() {
  local fact_type="$1"
  local limit=${2:-5}

  if ! memory_bank_exists; then
    return 0
  fi

  sqlite3 "$MEMORY_DB" "
    SELECT fact FROM facts
    WHERE type = '$fact_type' AND status = 'active'
    ORDER BY confidence DESC
    LIMIT $limit;
  " 2>/dev/null
}

# pending self-improve 태스크 조회
get_pending_improvements() {
  local limit=${1:-3}

  if ! memory_bank_exists; then
    return 0
  fi

  sqlite3 "$MEMORY_DB" "
    SELECT fact FROM facts
    WHERE type = 'self-improve' AND status = 'pending'
    ORDER BY created_at DESC
    LIMIT $limit;
  " 2>/dev/null
}

# 키워드로 팩트 검색 (FTS)
search_facts() {
  local query="$1"
  local limit=${2:-5}

  if ! memory_bank_exists; then
    return 0
  fi

  sqlite3 "$MEMORY_DB" "
    SELECT f.type, f.fact FROM fts_facts ft
    JOIN facts f ON ft.docid = f.rowid
    WHERE fts_facts MATCH '$query'
    LIMIT $limit;
  " 2>/dev/null
}
