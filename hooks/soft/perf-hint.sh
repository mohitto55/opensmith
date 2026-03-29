#!/bin/bash
# S10: 성능 안티패턴 감지
# PostToolUse(Write/Edit) 이벤트에서 실행

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

WARNINGS=""

case "$FILE" in
  *.tsx|*.ts)
    # useEffect 내에서 setState 후 바로 참조
    if grep -qP 'set\w+\(.*\).*\n.*\w+' "$FILE" 2>/dev/null; then
      # 간단한 패턴만 검사
      :
    fi

    # 불필요한 리렌더: 객체/배열 리터럴을 props로 전달
    if grep -qP 'style=\{\{' "$FILE" 2>/dev/null; then
      COUNT=$(grep -cP 'style=\{\{' "$FILE" 2>/dev/null)
      if [ "$COUNT" -gt 5 ]; then
        WARNINGS="$WARNINGS\n- 인라인 style 객체가 ${COUNT}개 — useMemo 또는 CSS 클래스 권장"
      fi
    fi
    ;;
  *.cs)
    # 동기 {{DATABASE}} 호출
    if grep -qP '\.Find\(.*\)\.(First|Single|ToList)\(\)' "$FILE" 2>/dev/null; then
      MATCH=$(grep -nP '\.Find\(.*\)\.(First|Single|ToList)\(\)' "$FILE" 2>/dev/null | head -2)
      WARNINGS="$WARNINGS\n- 동기 {{DATABASE}} 호출 감지. Async 버전 사용 권장:\n  $MATCH"
    fi
    ;;
esac

if [ -n "$WARNINGS" ]; then
  echo "## Performance Hints"
  echo -e "$WARNINGS"
fi
