#!/bin/bash
# S5: 에러 패턴 경고
# PostToolUse(Bash) 이벤트에서 실행
# 에러 메시지가 Memory Bank의 기존 패턴과 매치되면 해결책 주입

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/memory-query.sh"

# stdin에서 도구 실행 결과 읽기 (있으면)
OUTPUT=$(cat 2>/dev/null || echo "")

# 에러 키워드 감지
if echo "$OUTPUT" | grep -qiP "error|exception|failed|ENOENT|EACCES|TypeError|Cannot find"; then
  ERROR_LINE=$(echo "$OUTPUT" | grep -iP "error|exception|failed" | head -3)

  # Memory Bank에서 유사 에러 검색
  SIMILAR=$(search_facts "$(echo "$ERROR_LINE" | head -1)" 2)

  if [ -n "$SIMILAR" ]; then
    echo "## Known Error Pattern Detected"
    echo ""
    echo "유사한 에러가 이전에 해결된 적이 있습니다:"
    echo "$SIMILAR"
  fi
fi
