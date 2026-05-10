#!/bin/bash
# PostToolUse 카운터 훅: N회 ToolUse마다 자동 팩트 추출 트리거
#
# 동작:
#   1. 매 호출마다 .opensmith/memory-bank/.tool_counter +1
#   2. 임계값(THRESHOLD) 도달 시: stdin JSON의 transcript_path를 읽어
#      마지막 TAIL_LINES 줄을 extract-facts.py에 파이프 → 백그라운드 실행
#   3. 카운터 리셋
#
# 안전장치:
#   - Memory Bank DB 없으면 즉시 exit 0
#   - transcript_path 없거나 파일 없으면 카운터만 증가시키고 exit 0
#   - 추출은 항상 백그라운드 (사용자 작업 블로킹 금지)
#   - ANTHROPIC_API_KEY 없으면 extract-facts.py가 알아서 스킵

THRESHOLD=50
TAIL_LINES=400

PROJECT_ROOT="$(pwd)"
MEMORY_DIR="$PROJECT_ROOT/.opensmith/memory-bank"
DB_PATH="$MEMORY_DIR/memory.db"
COUNTER_FILE="$MEMORY_DIR/.tool_counter"

[ -f "$DB_PATH" ] || exit 0

PAYLOAD=""
if [ ! -t 0 ]; then
  PAYLOAD="$(cat)"
fi

mkdir -p "$MEMORY_DIR"
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE" 2>/dev/null | tr -dc '0-9')
[ -z "$COUNT" ] && COUNT=0
COUNT=$((COUNT + 1))

if [ "$COUNT" -lt "$THRESHOLD" ]; then
  echo "$COUNT" > "$COUNTER_FILE"
  exit 0
fi

# 임계값 도달: 추출 시도
TRANSCRIPT=""
if [ -n "$PAYLOAD" ]; then
  if command -v jq >/dev/null 2>&1; then
    TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null)
  else
    TRANSCRIPT=$(echo "$PAYLOAD" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null)
  fi
fi

# transcript 못 찾으면 카운터만 리셋하고 종료 (다음 사이클에 다시 시도)
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  echo "0" > "$COUNTER_FILE"
  exit 0
fi

# 카운터 즉시 리셋 (extract 실패해도 다음 사이클 정상 진입)
echo "0" > "$COUNTER_FILE"

# 백그라운드 추출: 마지막 TAIL_LINES 줄 → extract-facts.py
EXTRACT_PY="${CLAUDE_PLUGIN_ROOT:-$PROJECT_ROOT}/scripts/extract-facts.py"
[ -f "$EXTRACT_PY" ] || exit 0

LOG_FILE="$MEMORY_DIR/fact-extract.log"
(
  cd "$PROJECT_ROOT" && \
  tail -n "$TAIL_LINES" "$TRANSCRIPT" | python "$EXTRACT_PY" >> "$LOG_FILE" 2>&1
) &
disown 2>/dev/null || true

exit 0
