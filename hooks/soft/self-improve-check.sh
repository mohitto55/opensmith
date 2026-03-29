#!/bin/bash
# S2: self-improve 태스크 체크
# SessionStart 이벤트에서 실행

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/memory-query.sh"

PENDING=$(get_pending_improvements 3)
if [ -n "$PENDING" ]; then
  echo "## Pending Self-Improve Tasks"
  echo "다음 개선 태스크가 대기 중입니다:"
  echo "$PENDING"
  echo ""
  echo "/self-improve 를 실행하여 적용할 수 있습니다."
fi
