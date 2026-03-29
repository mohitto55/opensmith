#!/bin/bash
# S12: 워크트리 상태
# SessionStart 이벤트에서 실행

WORKTREES=$(git worktree list 2>/dev/null)
WORKTREE_COUNT=$(echo "$WORKTREES" | wc -l)

if [ "$WORKTREE_COUNT" -gt 1 ]; then
  echo "## Active Worktrees"
  echo ""
  echo "| 경로 | 브랜치 | 커밋 |"
  echo "|------|--------|------|"
  while IFS= read -r line; do
    PATH_COL=$(echo "$line" | awk '{print $1}')
    HASH_COL=$(echo "$line" | awk '{print $2}')
    BRANCH_COL=$(echo "$line" | grep -oP '\[.*\]')
    echo "| $(basename "$PATH_COL") | $BRANCH_COL | $HASH_COL |"
  done <<< "$WORKTREES"
  echo ""
fi
