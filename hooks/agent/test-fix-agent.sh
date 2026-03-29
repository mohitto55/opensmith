#!/bin/bash
# A2: 테스트 실패 자동 수정 에이전트
# TestFail 이벤트에서 실행

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/escalation.sh"

ERROR_LOG=$(cat 2>/dev/null || echo "")
if [ -z "$ERROR_LOG" ]; then exit 0; fi

LEVEL=$(escalate_level "test-fix" "test")

case "$LEVEL" in
  1)
    echo "## Test Failure (Auto-detected)"
    echo ""
    echo '```'
    echo "$ERROR_LOG" | head -20
    echo '```'
    echo ""
    echo "테스트 코드 또는 구현 코드를 확인하세요."
    escalate_increment "test-fix" "test" "$(echo "$ERROR_LOG" | head -5)"
    ;;
  2)
    echo "## Test Fix Agent Required"
    echo ""
    echo "테스트 실패가 반복됩니다. 독립 에이전트 수정 권장."
    echo "$ERROR_LOG" | head -20
    escalate_increment "test-fix" "test" "$(echo "$ERROR_LOG" | head -5)"
    ;;
  3)
    echo "BLOCK"
    echo "테스트 실패 6회 이상 반복. 접근 방식 변경 필요."
    bash "$SCRIPT_DIR/../soft/telegram-notify.sh" "test-fix" "test" "$(echo "$ERROR_LOG" | head -10)"
    escalate_reset "test-fix" "test"
    ;;
esac
