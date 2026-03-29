#!/bin/bash
# A3: scaffold 위반 자동 수정 에이전트
# PostToolUse(Write/Edit) 이벤트에서 실행
# scaffold 위반 감지 시 패턴에 맞게 코드 재작성 제안

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/patterns.sh"
source "$SCRIPT_DIR/../lib/escalation.sh"

FILE_TYPE=$(get_file_type "$FILE")
VIOLATIONS=""

case "$FILE_TYPE" in
  frontend)
    for pattern in "${FRONTEND_NEVER_PATTERNS[@]}"; do
      MATCH=$(grep -nP "$pattern" "$FILE" 2>/dev/null | head -1)
      if [ -n "$MATCH" ]; then
        VIOLATIONS="$VIOLATIONS\n  $MATCH"
      fi
    done
    ;;
  backend)
    for pattern in "${BACKEND_NEVER_PATTERNS[@]}"; do
      MATCH=$(grep -nP "$pattern" "$FILE" 2>/dev/null | head -1)
      if [ -n "$MATCH" ]; then
        VIOLATIONS="$VIOLATIONS\n  $MATCH"
      fi
    done
    ;;
esac

if [ -n "$VIOLATIONS" ]; then
  LEVEL=$(escalate_level "scaffold-fix" "$FILE")

  case "$LEVEL" in
    1)
      echo "## Scaffold Violation Detected"
      echo ""
      echo "파일: $FILE"
      echo -e "위반 사항:$VIOLATIONS"
      echo ""
      echo "scaffold 규칙에 맞게 수정하세요."
      echo "참조: .claude/skills/${FILE_TYPE}-patterns.md"
      escalate_increment "scaffold-fix" "$FILE" "scaffold violation"
      ;;
    2|3)
      echo "## Scaffold Fix Agent"
      echo ""
      echo "scaffold 위반이 반복됩니다."
      echo -e "$VIOLATIONS"
      echo ""
      echo "패턴 파일을 읽고 올바른 패턴으로 재작성하세요."
      escalate_increment "scaffold-fix" "$FILE" "scaffold violation"
      ;;
  esac
fi
