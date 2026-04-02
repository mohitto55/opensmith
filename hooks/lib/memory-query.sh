#!/bin/bash
# Memory Bank 쿼리 헬퍼
# Python 기반 하이브리드 검색 (FTS + sqlite-vec + RRF)
# Windows sqlite3 CLI에 FTS5 미지원 이슈로 Python으로 위임

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 라이브러리로 source 되었을 때를 위한 함수들
memory_bank_exists() {
  [ -f "$(pwd)/.opensmith/memory-bank/memory.db" ]
}

get_top_facts() {
  python "$PLUGIN_ROOT/scripts/memory_query.py" --top-project-facts "${1:-5}"
}

get_facts_by_type() {
  python "$PLUGIN_ROOT/scripts/memory_query.py" "$1" --type "$1" --top-k "${2:-5}"
}

get_pending_improvements() {
  python "$PLUGIN_ROOT/scripts/memory_query.py" --pending "${1:-3}"
}

search_hybrid() {
  local query="$1"
  local limit=${2:-5}
  local fact_type="$3"
  local args=("$query" --top-k "$limit")
  if [ -n "$fact_type" ]; then
    args+=(--type "$fact_type")
  fi
  python "$PLUGIN_ROOT/scripts/memory_query.py" "${args[@]}"
}

search_facts() {
  search_hybrid "$1" "${2:-5}"
}

search_exchanges() {
  python "$PLUGIN_ROOT/scripts/memory_query.py" --exchanges "$1" --top-k "${2:-5}"
}

# CLI 직접 호출
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  python "$PLUGIN_ROOT/scripts/memory_query.py" "$@"
fi
