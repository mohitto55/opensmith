#!/bin/bash
# S1: 세션 컨텍스트 주입
# SessionStart 이벤트에서 실행
# 세션 연속성 + pending self-improve + top 팩트를 additionalContext로 주입

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/memory-query.sh"

echo "## Session Context (Auto-injected)"
echo ""

# 1. 세션 연속성: 마지막 WIP 커밋
LAST_WIP=$(git log --oneline -5 --format="%h %s" 2>/dev/null | grep -i "WIP:" | head -1)
if [ -n "$LAST_WIP" ]; then
  echo "### Last WIP Session"
  echo "$LAST_WIP"
  echo ""
fi

# 2. pending self-improve 태스크
PENDING=$(get_pending_improvements 3)
if [ -n "$PENDING" ]; then
  echo "### Pending Improvements"
  echo "$PENDING"
  echo ""
fi

# 3. top 프로젝트 팩트
TOP=$(get_top_facts 5)
if [ -n "$TOP" ] && [ "$TOP" != "(Memory Bank 미초기화)" ]; then
  echo "### Key Project Facts"
  echo "$TOP"
  echo ""
fi

# 4. scaffold 요약
echo "### Scaffold 규칙"
echo "- 프론트엔드: .claude/skills/frontend-patterns.md"
echo "- 백엔드: .claude/skills/backend-patterns.md"
echo "- NEVER DO: .claude/skills/never-do.md"
