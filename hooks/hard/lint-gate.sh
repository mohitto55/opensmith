#!/bin/bash
# H2: 린트 체크 게이트
# ESLint (프론트엔드) 실행
# PreToolUse(Write/Edit) 이벤트에서 실행

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

case "$FILE" in
  *.tsx|*.ts|*.jsx|*.js)
    cd "$PROJECT_ROOT/frontend" 2>/dev/null || exit 0
    # ESLint 설정이 있는 경우에만 실행
    if [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ] || [ -f "eslint.config.js" ]; then
      ERRORS=$({{FRONTEND_LINT_CMD}} "$FILE" --no-warn 2>&1 | grep -c "error" 2>/dev/null)
      if [ "$ERRORS" -gt 0 ]; then
        echo "BLOCK"
        echo "ESLint 에러 ${ERRORS}개 발견"
        {{FRONTEND_LINT_CMD}} "$FILE" --no-warn 2>&1 | head -10
        exit 0
      fi
    fi
    ;;
esac

exit 0
