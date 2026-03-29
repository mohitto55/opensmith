#!/bin/bash
# NEVER DO 패턴 로더
# scaffold 파일에서 금지 패턴을 추출하여 검사에 사용

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
NEVER_DO_FILE="$PROJECT_ROOT/.claude/skills/never-do.md"

# 프론트엔드 금지 패턴 (grep -P 호환 정규식)
# Add project-specific frontend forbidden patterns here
FRONTEND_NEVER_PATTERNS=(
  'type="color"'
  # Add project-specific import rules here
  "React\.FC<"
  "React\.FC "
  "export const .* = \(\) =>"
  "export const .* = \(props"
)

# 백엔드 금지 패턴
# Add project-specific backend forbidden patterns here
BACKEND_NEVER_PATTERNS=(
  '\[ApiController\]'
  '\[HttpGet\]'
  '\[HttpPost\]'
  # Add project-specific DB access patterns here (e.g. direct collection access)
  'wildcard.*\*'
  'AllowAnyOrigin'
  'password.*=.*"'
  'secret.*=.*"'
  'MD5\.Create'
  'SHA256\.Create.*password'
)

# 보안 금지 패턴 (전체)
SECURITY_NEVER_PATTERNS=(
  'password.*=.*"[^"]{3,}"'
  'secret.*=.*"[^"]{3,}"'
  'apikey.*=.*"[^"]{3,}"'
  'token.*=.*"[^"]{3,}"'
  'AllowAnyOrigin'
  'Access-Control-Allow-Origin.*\*'
)

# 파일 확장자로 프론트/백엔드 판별
get_file_type() {
  local file="$1"
  case "$file" in
    *.tsx|*.ts|*.jsx|*.js|*.css)
      echo "frontend"
      ;;
    *.cs|*.csproj)
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
