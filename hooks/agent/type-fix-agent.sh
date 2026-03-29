#!/bin/bash
# A4: 타입 에러 자동 수정 에이전트
# PostToolUse(Write/Edit) 이벤트에서 실행

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/../lib/escalation.sh"

case "$FILE" in
  *.tsx|*.ts)
    cd "$PROJECT_ROOT/frontend" 2>/dev/null || exit 0
    ERRORS=$({{FRONTEND_TYPECHECK_CMD}} 2>&1 | grep "error TS")
    if [ -n "$ERRORS" ]; then
      LEVEL=$(escalate_level "type-fix" "$FILE")
      ERROR_COUNT=$(echo "$ERRORS" | wc -l)

      echo "## Type Error Detected ($ERROR_COUNT errors)"
      echo ""
      echo '```'
      echo "$ERRORS" | head -10
      echo '```'

      if [ "$LEVEL" -ge 2 ]; then
        echo ""
        echo "타입 에러가 반복됩니다. 타입 정의를 확인하고 수정하세요."
      fi

      escalate_increment "type-fix" "$FILE" "$(echo "$ERRORS" | head -3)"
    fi
    ;;
esac
