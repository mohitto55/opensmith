#!/bin/bash
# H5: 금지 라이브러리 import 감지
# PreToolUse(Write/Edit) 이벤트에서 실행

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

# 프론트엔드 파일만 검사
case "$FILE" in
  *.tsx|*.ts|*.jsx|*.js) ;;
  *) exit 0 ;;
esac

VIOLATIONS=""

# 금지 라이브러리 목록
# Add project-specific forbidden imports here
BANNED_IMPORTS=(
  # "from 'forbidden-package'"
  # 'from "forbidden-package"'
)

for pattern in "${BANNED_IMPORTS[@]}"; do
  if grep -q "$pattern" "$FILE" 2>/dev/null; then
    MATCH=$(grep -n "$pattern" "$FILE" 2>/dev/null | head -1)
    VIOLATIONS="$VIOLATIONS\n  금지 import: $MATCH"
  fi
done

if [ -n "$VIOLATIONS" ]; then
  echo "BLOCK"
  echo "금지된 라이브러리 import 감지:"
  echo -e "$VIOLATIONS"
  echo ""
  echo "참조: .claude/skills/never-do.md"
  exit 0
fi

exit 0
