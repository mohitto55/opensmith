#!/bin/bash
# H6: 파일 크기 제한
# 500줄 경고, 800줄 차단
# PreToolUse(Write) 이벤트에서 실행

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then exit 0; fi

# 코드 파일만 검사
case "$FILE" in
  *.tsx|*.ts|*.jsx|*.js|*.cs) ;;
  *) exit 0 ;;
esac

LINE_COUNT=$(wc -l < "$FILE" 2>/dev/null)
LINE_COUNT=${LINE_COUNT:-0}

if [ "$LINE_COUNT" -gt 800 ]; then
  echo "BLOCK"
  echo "파일이 ${LINE_COUNT}줄로 800줄 제한을 초과합니다."
  echo "커스텀 훅이나 서브 컴포넌트로 분리하세요."
  exit 0
fi

if [ "$LINE_COUNT" -gt 500 ]; then
  echo "WARNING"
  echo "파일이 ${LINE_COUNT}줄입니다. 500줄 초과 시 분리를 권장합니다."
fi

exit 0
