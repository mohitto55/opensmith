#!/bin/bash
# HARD 훅: 보안 위반 실시간 차단
# PreToolUse(Write/Edit) 이벤트에서 실행
# secure-web-saas 15항목 중 즉시 차단 가능한 항목을 실시간 검사

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

VIOLATIONS=""

# === 1. CORS 와일드카드 ===
if grep -qPi "AllowAnyOrigin|Access-Control-Allow-Origin.*\*" "$FILE" 2>/dev/null; then
  MATCH=$(grep -nPi "AllowAnyOrigin|Access-Control-Allow-Origin.*\*" "$FILE" | head -1)
  VIOLATIONS="$VIOLATIONS\n  [CORS] 와일드카드 오리진 금지: $MATCH"
fi

# === 3. XSS 위험 패턴 ===
if grep -qP "dangerouslySetInnerHTML|innerHTML\s*=|document\.write\(|eval\(" "$FILE" 2>/dev/null; then
  MATCH=$(grep -nP "dangerouslySetInnerHTML|innerHTML\s*=|document\.write\(|eval\(" "$FILE" | head -1)
  VIOLATIONS="$VIOLATIONS\n  [XSS] 위험 패턴: $MATCH"
fi

# === 8. SQL Injection ===
if grep -qP '"\s*SELECT.*\+.*\$|"\s*INSERT.*\+.*\$|"\s*UPDATE.*\+.*\$|"\s*DELETE.*\+.*\$|f"SELECT|f"INSERT|f"UPDATE|f"DELETE' "$FILE" 2>/dev/null; then
  MATCH=$(grep -nP '"\s*SELECT.*\+|"\s*INSERT.*\+|f"SELECT|f"INSERT' "$FILE" | head -1)
  VIOLATIONS="$VIOLATIONS\n  [SQLi] 문자열 연결 SQL 금지 — 파라미터 바인딩 사용: $MATCH"
fi

# === 11. 하드코딩 시크릿 ===
if grep -qPi '(password|secret|apikey|api_key|token|private_key)\s*[:=]\s*["\x27][^\s"'\'']{8,}' "$FILE" 2>/dev/null; then
  MATCH=$(grep -nPi '(password|secret|apikey|api_key|token|private_key)\s*[:=]\s*["\x27][^\s"'\'']{8,}' "$FILE" | head -1)
  VIOLATIONS="$VIOLATIONS\n  [Secret] 하드코딩 시크릿 금지 — 환경변수 사용: $MATCH"
fi

# === AWS/GCP/Azure 키 패턴 ===
if grep -qP 'AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|-----BEGIN (RSA |EC )?PRIVATE KEY' "$FILE" 2>/dev/null; then
  MATCH=$(grep -nP 'AKIA|AIza|BEGIN.*PRIVATE KEY' "$FILE" | head -1)
  VIOLATIONS="$VIOLATIONS\n  [Secret] 클라우드 키/프라이빗 키 감지: $MATCH"
fi

# === 14. 프로덕션 에러 노출 ===
if grep -qP "DeveloperExceptionPage|DJANGO_DEBUG\s*=\s*True|DEBUG\s*=\s*True" "$FILE" 2>/dev/null; then
  MATCH=$(grep -nP "DeveloperExceptionPage|DEBUG.*True" "$FILE" | head -1)
  VIOLATIONS="$VIOLATIONS\n  [에러노출] 프로덕션에서 디버그 모드/스택트레이스 노출 금지: $MATCH"
fi

# === .env/.pem/.key 파일 생성 차단 ===
case "$FILE" in
  *.env|*.pem|*.key|*credentials*|*secret*)
    VIOLATIONS="$VIOLATIONS\n  [Secret] 민감 파일($FILE) 생성 금지 — .gitignore에 추가하고 환경변수로 관리"
    ;;
esac

if [ -n "$VIOLATIONS" ]; then
  echo "BLOCK"
  echo "보안 규칙 위반 감지 (secure-web-saas 15항목 기준):"
  echo -e "$VIOLATIONS"
  echo ""
  echo "수정 후 다시 시도하세요."
  exit 2
fi

exit 0
