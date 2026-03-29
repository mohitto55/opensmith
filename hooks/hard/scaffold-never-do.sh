#!/bin/bash
# H3: NEVER DO 규칙 위반 검사
# 변경 내용이 scaffold 금지 패턴에 해당하는지 체크
# PreToolUse(Write/Edit) 이벤트에서 실행

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/patterns.sh"

FILE_TYPE=$(get_file_type "$FILE")
VIOLATIONS=""

case "$FILE_TYPE" in
  frontend)
    for pattern in "${FRONTEND_NEVER_PATTERNS[@]}"; do
      MATCH=$(grep -nP "$pattern" "$FILE" 2>/dev/null | head -1)
      if [ -n "$MATCH" ]; then
        VIOLATIONS="$VIOLATIONS\n  NEVER DO 위반: $MATCH"
      fi
    done
    ;;
  backend)
    for pattern in "${BACKEND_NEVER_PATTERNS[@]}"; do
      MATCH=$(grep -nP "$pattern" "$FILE" 2>/dev/null | head -1)
      if [ -n "$MATCH" ]; then
        VIOLATIONS="$VIOLATIONS\n  NEVER DO 위반: $MATCH"
      fi
    done
    ;;
esac

if [ -n "$VIOLATIONS" ]; then
  echo "BLOCK"
  echo "scaffold NEVER DO 규칙 위반 감지:"
  echo -e "$VIOLATIONS"
  echo ""
  echo "참조: .claude/skills/never-do.md"
  exit 0
fi

exit 0
