#!/bin/bash
# 팩트 추출 훅
# Stop 이벤트에서 실행
# 세션 종료 시 대화에서 팩트 자동 추출

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(pwd)"
MEMORY_DB="$PROJECT_ROOT/.opensmith/memory-bank/memory.db"

# Memory Bank가 없으면 스킵
if [ ! -f "$MEMORY_DB" ]; then
  exit 0
fi

# ANTHROPIC_API_KEY가 없으면 스킵
if [ -z "$ANTHROPIC_API_KEY" ]; then
  exit 0
fi

# extract-facts.py 실행 (백그라운드)
python3 "$PLUGIN_ROOT/scripts/extract-facts.py" &>/dev/null &

# 새 팩트가 있으면 임베딩 생성 (백그라운드)
python3 "$PLUGIN_ROOT/scripts/embed.py" &>/dev/null &

exit 0
