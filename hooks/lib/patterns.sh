#!/bin/bash
# NEVER DO 패턴 로더 + 보안 패턴
# scaffold 파일에서 금지 패턴을 추출하여 검사에 사용

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

# 프론트엔드 금지 패턴 (grep -P 호환 정규식)
# Customize: Add project-specific frontend forbidden patterns
FRONTEND_NEVER_PATTERNS=(
  'type="color"'
  "React\.FC<"
  "React\.FC "
)

# 백엔드 금지 패턴
# Customize: Add project-specific backend forbidden patterns
BACKEND_NEVER_PATTERNS=(
  '\[ApiController\]'
  '\[HttpGet\]'
  '\[HttpPost\]'
  'AllowAnyOrigin'
)

# 보안 금지 패턴 (secure-web-saas 15항목 기반)
SECURITY_NEVER_PATTERNS=(
  # 11. Secret 하드코딩
  'password\s*[:=]\s*"[^"]{8,}"'
  'secret\s*[:=]\s*"[^"]{8,}"'
  'apikey\s*[:=]\s*"[^"]{8,}"'
  'api_key\s*[:=]\s*"[^"]{8,}"'
  'token\s*[:=]\s*"[^"]{8,}"'
  'private_key\s*[:=]\s*"[^"]{8,}"'
  # 클라우드 키
  'AKIA[0-9A-Z]{16}'
  'AIza[0-9A-Za-z_-]{35}'
  '-----BEGIN (RSA |EC )?PRIVATE KEY'
  # 1. CORS 와일드카드
  'AllowAnyOrigin'
  'Access-Control-Allow-Origin.*\*'
  # 3. XSS
  'dangerouslySetInnerHTML'
  'innerHTML\s*='
  'document\.write\('
  'eval\('
  # 8. SQLi
  '"SELECT.*\+.*\$'
  'f"SELECT'
  'f"INSERT'
  'f"UPDATE'
  'f"DELETE'
  # 14. 에러 노출
  'DeveloperExceptionPage'
  'DJANGO_DEBUG\s*=\s*True'
)

# 파일 확장자로 프론트/백엔드 판별
get_file_type() {
  local file="$1"
  case "$file" in
    *.tsx|*.ts|*.jsx|*.js|*.css|*.vue)
      echo "frontend"
      ;;
    *.cs|*.csproj|*.py|*.go|*.java|*.rb)
      echo "backend"
      ;;
    *)
      echo "other"
      ;;
  esac
}

# 패턴 매칭 검사
check_patterns() {
  local file="$1"
  shift
  local patterns=("$@")
  local violations=()

  for pattern in "${patterns[@]}"; do
    if grep -qP "$pattern" "$file" 2>/dev/null; then
      local line=$(grep -nP "$pattern" "$file" 2>/dev/null | head -1)
      violations+=("$line")
    fi
  done

  if [ ${#violations[@]} -gt 0 ]; then
    echo "${violations[@]}"
    return 1
  fi
  return 0
}
