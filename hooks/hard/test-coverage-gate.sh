#!/bin/bash
# H7: 테스트 커버리지 게이트
# 새 기능 코드에 대응하는 테스트 파일 존재 확인
# PreCommit 이벤트에서 실행

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# 스테이징된 새 파일 중 테스트가 필요한 것 확인
STAGED_FILES=$(git diff --cached --name-only --diff-filter=A 2>/dev/null)
MISSING_TESTS=""

for file in $STAGED_FILES; do
  case "$file" in
    # 프론트엔드 컴포넌트/페이지
    frontend/app/components/*|frontend/app/*/page.tsx)
      # TODO: test framework 설정 후 활성화
      ;;
    # 백엔드 서비스
    backend/{{BACKEND_PROJECT_PATH}}/Services/*.cs)
      # TODO: test project 설정 후 활성화
      ;;
  esac
done

if [ -n "$MISSING_TESTS" ]; then
  echo "WARNING"
  echo "테스트 파일이 없는 새 코드:"
  echo "$MISSING_TESTS"
fi

exit 0
