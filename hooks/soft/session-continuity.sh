#!/bin/bash
# S3: 세션 연속성 복원
# SessionStart 이벤트에서 실행
# 마지막 WIP 커밋의 상세 메시지로 이전 작업 컨텍스트 복원

LAST_WIP_HASH=$(git log --oneline -20 --format="%h %s" 2>/dev/null | grep -i "WIP:" | head -1 | awk '{print $1}')

if [ -n "$LAST_WIP_HASH" ]; then
  echo "## Previous Session Context"
  echo ""
  git log -1 --format="%B" "$LAST_WIP_HASH" 2>/dev/null
fi
