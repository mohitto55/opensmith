#!/bin/bash
# S13: 팩트 추출
# Stop 이벤트에서 실행
# 세션 종료 시 대화에서 팩트 자동 추출 트리거

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
MEMORY_DIR="$PROJECT_ROOT/.claude/memory-bank"

# Memory Bank 디렉토리 확인
if [ ! -d "$MEMORY_DIR" ]; then
  mkdir -p "$MEMORY_DIR"
fi

# 세션 메타데이터 기록
echo "$(date -Iseconds) session_end" >> "$MEMORY_DIR/session-log.txt" 2>/dev/null

echo "Session ended. Fact extraction queued."
