#!/bin/bash
# S7: 컴포넌트 패턴 가이드
# PostToolUse(Write/Edit) 이벤트에서 실행
# React 컴포넌트 작성 시 기존 패턴 가이드 주입

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

case "$FILE" in
  *.tsx) ;;
  *) exit 0 ;;
esac

WARNINGS=""

# 1. 'use client' 누락 체크 (useState/useEffect 사용하는데 'use client' 없는 경우)
if grep -qP "useState|useEffect|useCallback|useRef" "$FILE" 2>/dev/null; then
  if ! head -3 "$FILE" | grep -q "'use client'"; then
    WARNINGS="$WARNINGS\n- 'use client' 선언이 필요합니다 (React 훅 사용 감지)"
  fi
fi

# 2. export default function 패턴 체크
if grep -qP "export const \w+ = \(" "$FILE" 2>/dev/null; then
  WARNINGS="$WARNINGS\n- export const 대신 export default function 패턴을 사용하세요"
fi

# 3. React.FC 사용 체크
if grep -q "React\.FC" "$FILE" 2>/dev/null; then
  WARNINGS="$WARNINGS\n- React.FC 대신 function ComponentName(props: Props) 패턴을 사용하세요"
fi

if [ -n "$WARNINGS" ]; then
  echo "## Component Pattern Guide"
  echo -e "$WARNINGS"
  echo ""
  echo "참조: .claude/skills/frontend-patterns.md"
fi
