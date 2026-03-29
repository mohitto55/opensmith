#!/bin/bash
# H1: 타입 체크 게이트
# TypeScript/C# 파일 수정 시 타입 에러 검사
# PreToolUse(Write/Edit) 이벤트에서 실행

FILE="$1"
if [ -z "$FILE" ]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

case "$FILE" in
  *.tsx|*.ts)
    # TypeScript 타입 체크
    cd "$PROJECT_ROOT/frontend" 2>/dev/null || exit 0
    ERRORS=$({{FRONTEND_TYPECHECK_CMD}} 2>&1 | grep -c "error TS" 2>/dev/null)
    if [ "$ERRORS" -gt 0 ]; then
      echo "BLOCK"
      echo "TypeScript 타입 에러 ${ERRORS}개 발견"
      {{FRONTEND_TYPECHECK_CMD}} 2>&1 | grep "error TS" | head -5
      exit 0
    fi
    ;;
  *.cs)
    # C# 빌드 체크
    cd "$PROJECT_ROOT/backend/{{BACKEND_PROJECT_PATH}}" 2>/dev/null || exit 0
    if ! {{BACKEND_BUILD_CMD}} --nologo -v q 2>&1 | tail -3 | grep -q "succeeded"; then
      echo "BLOCK"
      echo "C# 빌드 에러 발견"
      {{BACKEND_BUILD_CMD}} --nologo -v q 2>&1 | grep -i "error" | head -5
      exit 0
    fi
    ;;
esac

exit 0
