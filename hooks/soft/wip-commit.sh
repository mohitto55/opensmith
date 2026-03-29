#!/bin/bash
# S14: WIP 커밋 자동 생성
# Stop 이벤트에서 실행
# 미커밋 변경 사항이 있으면 WIP 커밋 생성

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$PROJECT_ROOT" || exit 0

# 변경 사항 확인
CHANGES=$(git status --porcelain 2>/dev/null | grep -v "^??" | head -1)
if [ -z "$CHANGES" ]; then
  exit 0  # 변경 없음
fi

# 변경 파일 목록
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null)
DIFF_SUMMARY=$(git diff --stat HEAD 2>/dev/null | tail -5)

# WIP 커밋 메시지
WIP_MSG="WIP: $(date +%Y-%m-%d-%H%M) session work

## Changed Files
$CHANGED_FILES

## Diff Summary
$DIFF_SUMMARY

## Context
Auto-generated WIP commit on session end.
"

# 추적 중인 변경 사항만 스테이징 + 커밋
git add -u 2>/dev/null
git commit -m "$WIP_MSG" --no-verify 2>/dev/null

echo "WIP commit created."
