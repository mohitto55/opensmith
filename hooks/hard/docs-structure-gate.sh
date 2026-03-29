#!/bin/bash
# H8: 문서 구조 검증 게이트
# 기존 validate-docs.sh를 래핑
# PreCommit 이벤트에서 실행

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# 기존 validate-docs.sh 실행
if [ -f "$PROJECT_ROOT/.claude/hooks/validate-docs.sh" ]; then
  cd "$PROJECT_ROOT"
  bash .claude/hooks/validate-docs.sh
  exit $?
fi

exit 0
