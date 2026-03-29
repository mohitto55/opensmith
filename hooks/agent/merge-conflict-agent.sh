#!/bin/bash
# A6: 머지 충돌 자동 해결 에이전트
# PostToolUse(Bash:git merge) 이벤트에서 실행

OUTPUT=$(cat 2>/dev/null || echo "")

# 충돌 감지
if echo "$OUTPUT" | grep -qi "CONFLICT\|merge conflict\|Automatic merge failed"; then
  CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)

  echo "## Merge Conflict Detected"
  echo ""
  echo "충돌 파일:"
  echo "$CONFLICT_FILES"
  echo ""

  # WIP 커밋에서 의사결정 히스토리 수집
  BRANCH=$(git branch --show-current 2>/dev/null)
  WIP_HISTORY=$(git log --oneline -10 --format="%h %s" "$BRANCH" 2>/dev/null | grep -i "WIP:" | head -5)

  if [ -n "$WIP_HISTORY" ]; then
    echo "### WIP 커밋 히스토리 (충돌 해결 컨텍스트)"
    echo "$WIP_HISTORY"
    echo ""
    echo "위 WIP 히스토리를 참고하여 충돌을 해결하세요."
    echo "각 WIP 커밋의 상세 메시지: git log -1 --format='%B' <hash>"
  else
    echo "WIP 커밋 히스토리가 없습니다. 수동 충돌 해결이 필요합니다."
  fi
fi
