#!/bin/bash
# execute 파이프라인 체이닝 훅
# TaskCompleted 이벤트에서 실행 — Python 스크립트로 위임
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
python "$PLUGIN_ROOT/scripts/chain_next_step.py"
