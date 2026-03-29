#!/bin/bash
# S8: DB 스키마 변경 경고
# PostToolUse(Write/Edit) 이벤트에서 실행

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

# {{DATABASE}} 모델 파일만 검사
case "$FILE" in
  *Models/*.cs|*Models/**/*.cs) ;;
  *) exit 0 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# BsonElement 속성 변경 감지
if git diff "$FILE" 2>/dev/null | grep -qP '^\+.*\[BsonElement|^\-.*\[BsonElement'; then
  MODEL_NAME=$(basename "$FILE" .cs)

  # 이 모델을 사용하는 서비스 찾기
  SERVICES=$(grep -rl "$MODEL_NAME" "$PROJECT_ROOT/backend/{{BACKEND_PROJECT_PATH}}/Services/" 2>/dev/null | xargs -I{} basename {} .cs 2>/dev/null)
  ENDPOINTS=$(grep -rl "$MODEL_NAME" "$PROJECT_ROOT/backend/{{BACKEND_PROJECT_PATH}}/Endpoints/" 2>/dev/null | xargs -I{} basename {} .cs 2>/dev/null)

  echo "## DB Schema Change Warning"
  echo ""
  echo "모델 ${MODEL_NAME}의 스키마가 변경되었습니다."
  if [ -n "$SERVICES" ]; then
    echo "영향 받는 서비스: $SERVICES"
  fi
  if [ -n "$ENDPOINTS" ]; then
    echo "영향 받는 엔드포인트: $ENDPOINTS"
  fi
  echo ""
  echo "기존 도큐먼트와의 호환성을 확인하세요."
  echo "새 필드에 기본값이 설정되어 있는지 확인하세요."
fi
