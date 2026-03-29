#!/bin/bash
# Memory Bank 쿼리 헬퍼
# 시맨틱 검색 (sqlite-vec) + FTS 하이브리드 검색
# RRF (Reciprocal Rank Fusion)로 결과 결합

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(pwd)"
MEMORY_DB="$PROJECT_ROOT/.opensmith/memory-bank/memory.db"
META_FILE="$PROJECT_ROOT/.opensmith/memory-bank/meta.json"

memory_bank_exists() {
  [ -f "$MEMORY_DB" ]
}

vec_enabled() {
  if [ -f "$META_FILE" ]; then
    python3 -c "import json; print(json.load(open('$META_FILE')).get('vec_enabled', False))" 2>/dev/null
  else
    echo "False"
  fi
}

get_top_facts() {
  local limit=${1:-5}
  if ! memory_bank_exists; then
    echo "(Memory Bank 미초기화. /opensmith:init-memory 를 실행하세요)"
    return 0
  fi
  sqlite3 "$MEMORY_DB" "
    SELECT type, fact FROM facts
    WHERE status = 'active'
    ORDER BY confidence DESC, updated_at DESC
    LIMIT $limit;
  " 2>/dev/null || echo "(조회 실패)"
}

get_facts_by_type() {
  local fact_type="$1"
  local limit=${2:-5}
  if ! memory_bank_exists; then return 0; fi
  sqlite3 "$MEMORY_DB" "
    SELECT fact FROM facts
    WHERE type = '$fact_type' AND status = 'active'
    ORDER BY confidence DESC
    LIMIT $limit;
  " 2>/dev/null
}

get_pending_improvements() {
  local limit=${1:-3}
  if ! memory_bank_exists; then return 0; fi
  sqlite3 "$MEMORY_DB" "
    SELECT fact FROM facts
    WHERE type = 'self-improve' AND status = 'pending'
    ORDER BY created_at DESC
    LIMIT $limit;
  " 2>/dev/null
}

# 시맨틱 + FTS 하이브리드 검색
search_hybrid() {
  local query="$1"
  local limit=${2:-5}
  local fact_type="$3"
  if ! memory_bank_exists; then return 0; fi

  local type_filter=""
  if [ -n "$fact_type" ]; then
    type_filter="AND f.type = '$fact_type'"
  fi

  local safe_query
  safe_query=$(echo "$query" | sed "s/'/''/g")

  # FTS 검색
  local fts_results
  fts_results=$(sqlite3 "$MEMORY_DB" "
    SELECT f.id, f.type, f.fact, f.confidence
    FROM fts_facts ft
    JOIN facts f ON ft.rowid = f.rowid
    WHERE fts_facts MATCH '$safe_query'
      AND f.status = 'active'
      $type_filter
    ORDER BY rank
    LIMIT 20;
  " 2>/dev/null)

  # vec 검색 시도
  local vec_results=""
  if [ "$(vec_enabled)" = "True" ]; then
    local query_hex
    query_hex=$(python3 "$PLUGIN_ROOT/scripts/embed.py" --query "$query" 2>/dev/null)

    if [ -n "$query_hex" ]; then
      vec_results=$(sqlite3 "$MEMORY_DB" "
        SELECT f.id, f.type, f.fact, f.confidence
        FROM vec_facts v
        JOIN facts f ON v.id = f.id
        WHERE f.status = 'active'
          $type_filter
        ORDER BY vec_distance_cosine(v.embedding, X'$query_hex') ASC
        LIMIT 20;
      " 2>/dev/null)
    fi
  fi

  # RRF 결합 또는 단일 소스 출력
  if [ -n "$vec_results" ] && [ -n "$fts_results" ]; then
    python3 -c "
K = 60
scores = {}
facts = {}
for rank, line in enumerate('''$vec_results'''.strip().split('\n')):
    if not line: continue
    parts = line.split('|')
    if len(parts) >= 3:
        fid = parts[0]
        scores[fid] = scores.get(fid, 0) + 1.0 / (K + rank + 1)
        facts[fid] = {'type': parts[1], 'fact': parts[2], 'conf': parts[3] if len(parts)>3 else '0.5'}
for rank, line in enumerate('''$fts_results'''.strip().split('\n')):
    if not line: continue
    parts = line.split('|')
    if len(parts) >= 3:
        fid = parts[0]
        scores[fid] = scores.get(fid, 0) + 1.0 / (K + rank + 1)
        facts[fid] = {'type': parts[1], 'fact': parts[2], 'conf': parts[3] if len(parts)>3 else '0.5'}
ranked = sorted(scores.items(), key=lambda x: -x[1])[:$limit]
for fid, score in ranked:
    f = facts[fid]
    print(f\"{f['type']}|{f['fact']}|{f['conf']}\")
" 2>/dev/null
  elif [ -n "$fts_results" ]; then
    echo "$fts_results" | head -n "$limit" | awk -F'|' '{print $2"|"$3"|"$4}'
  elif [ -n "$vec_results" ]; then
    echo "$vec_results" | head -n "$limit" | awk -F'|' '{print $2"|"$3"|"$4}'
  fi
}

# FTS only 검색 (하위호환)
search_facts() {
  local query="$1"
  local limit=${2:-5}
  if ! memory_bank_exists; then return 0; fi
  local safe_query
  safe_query=$(echo "$query" | sed "s/'/''/g")
  sqlite3 "$MEMORY_DB" "
    SELECT f.type, f.fact FROM fts_facts ft
    JOIN facts f ON ft.rowid = f.rowid
    WHERE fts_facts MATCH '$safe_query'
      AND f.status = 'active'
    LIMIT $limit;
  " 2>/dev/null
}

# CLI 직접 호출
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  QUERY=""
  TOP_K=5
  TYPE=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      --top-k) TOP_K="$2"; shift 2 ;;
      --type) TYPE="$2"; shift 2 ;;
      --top-project-facts) get_top_facts "$2"; exit 0 ;;
      --pending) get_pending_improvements "$2"; exit 0 ;;
      *) QUERY="$QUERY $1"; shift ;;
    esac
  done

  QUERY=$(echo "$QUERY" | xargs)

  if [ -z "$QUERY" ]; then
    get_top_facts "$TOP_K"
  else
    search_hybrid "$QUERY" "$TOP_K" "$TYPE"
  fi
fi
