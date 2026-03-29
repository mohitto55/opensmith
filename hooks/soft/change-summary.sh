#!/bin/bash
# S4: 변경 사항 자동 요약
# PreCommit 이벤트에서 실행

STAGED=$(git diff --cached --stat 2>/dev/null)
if [ -n "$STAGED" ]; then
  echo "## Staged Changes Summary"
  echo "$STAGED"
  echo ""

  FILES_CHANGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
  INSERTIONS=$(git diff --cached --shortstat 2>/dev/null | grep -oP '\d+ insertion' | grep -oP '\d+')
  DELETIONS=$(git diff --cached --shortstat 2>/dev/null | grep -oP '\d+ deletion' | grep -oP '\d+')

  echo "파일: ${FILES_CHANGED}개, 추가: ${INSERTIONS:-0}줄, 삭제: ${DELETIONS:-0}줄"
fi
