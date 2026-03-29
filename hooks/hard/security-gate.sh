#!/bin/bash
# H4: 보안 위반 검사
# 하드코딩 비밀번호, wildcard CORS, 취약한 해싱 감지
# PreToolUse(Write/Edit) 이벤트에서 실행

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/patterns.sh"

VIOLATIONS=""

for pattern in "${SECURITY_NEVER_PATTERNS[@]}"; do
  MATCH=$(grep -nPi "$pattern" "$FILE" 2>/dev/null | head -1)
  if [ -n "$MATCH" ]; then
    VIOLATIONS="$VIOLATIONS\n  보안 위반: $MATCH"
  fi
done

# 추가: .env 파일에 있어야 할 값이 코드에 하드코딩되었는지 체크
if grep -qP '(CONNECTION_STRING|JWT_SECRET|CLIENT_ID|API_KEY)\s*=\s*"[^"]{10,}"' "$FILE" 2>/dev/null; then
  MATCH=$(grep -nP '(CONNECTION_STRING|JWT_SECRET|CLIENT_ID|API_KEY)\s*=\s*"[^"]{10,}"' "$FILE" 2>/dev/null | head -1)
  VIOLATIONS="$VIOLATIONS\n  보안 위반 (하드코딩 시크릿): $MATCH"
fi

if [ -n "$VIOLATIONS" ]; then
  echo "BLOCK"
  echo "보안 규칙 위반 감지:"
  echo -e "$VIOLATIONS"
  echo ""
  echo "시크릿은 환경변수 또는 K8s Secret으로 관리하세요."
  exit 0
fi

exit 0
