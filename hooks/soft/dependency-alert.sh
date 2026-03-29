#!/bin/bash
# S11: 의존성 경고
# PostToolUse(Bash:npm install) 이벤트에서 실행

# stdin에서 npm install 결과 읽기
OUTPUT=$(cat 2>/dev/null || echo "")

if echo "$OUTPUT" | grep -q "added"; then
  ADDED=$(echo "$OUTPUT" | grep -oP '\d+ packages? added' | head -1)
  echo "## Dependency Alert"
  echo "$ADDED"
  echo ""
  echo "새 패키지 추가 시 확인사항:"
  echo "- 번들 크기 영향 (npx bundlephobia-cli <pkg>)"
  echo "- 라이선스 호환성"
  echo "- 프로젝트 컨벤션과 충돌 여부"
fi
