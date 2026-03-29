#!/bin/bash
# S15: 세션 메트릭 기록
# Stop 이벤트에서 실행

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
MEMORY_DIR="$PROJECT_ROOT/.claude/memory-bank"

mkdir -p "$MEMORY_DIR" 2>/dev/null

# 간단한 메트릭 CSV 기록
TIMESTAMP=$(date -Iseconds)
COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo 0)
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

echo "$TIMESTAMP,$BRANCH,$COMMITS" >> "$MEMORY_DIR/metrics.csv" 2>/dev/null
