#!/bin/bash
# S6: API 일관성 경고
# PostToolUse(Write/Edit) 이벤트에서 실행
# API 엔드포인트 변경 시 기존 패턴과의 일관성 체크

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

# 백엔드 엔드포인트 파일만 검사
case "$FILE" in
  *Endpoints.cs) ;;
  *) exit 0 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# 기존 API 라우트 패턴 수집
EXISTING_ROUTES=$(grep -rh 'MapGroup\|MapGet\|MapPost\|MapPut\|MapDelete' "$PROJECT_ROOT/backend/{{BACKEND_PROJECT_PATH}}/Endpoints/" 2>/dev/null | head -20)

# 새 파일의 라우트 패턴
NEW_ROUTES=$(grep -h 'MapGroup\|MapGet\|MapPost\|MapPut\|MapDelete' "$FILE" 2>/dev/null)

if [ -n "$NEW_ROUTES" ]; then
  # /api/v1 접두어 확인
  if ! echo "$NEW_ROUTES" | grep -q "/api/v1\|group\.Map"; then
    echo "## API Consistency Warning"
    echo "새 엔드포인트가 /api/v1 그룹 하에 있는지 확인하세요."
    echo "기존 패턴: api.MapGroup(\"/api/v1\")"
  fi

  # int 제약조건 확인
  if echo "$NEW_ROUTES" | grep -qP '/{id}' && ! echo "$NEW_ROUTES" | grep -qP '/{id:int}'; then
    echo "## API Consistency Warning"
    echo "정수 경로 파라미터에 {id:int} 제약조건을 사용하세요."
  fi
fi
