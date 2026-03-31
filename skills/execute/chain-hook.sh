#!/bin/bash
# execute 파이프라인 체이닝 훅
# TaskCompleted 이벤트에서 실행
# state.json 없이 동작 — Task 이름에서 현재 스텝을 파악

# 플러그인 루트에서 스텝 파일 경로 결정
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
SKILL_DIR="$PLUGIN_ROOT/skills/execute/steps"

# 이 훅은 더 이상 state.json을 읽지 않습니다.
# 파이프라인 진행은 SKILL.md의 지시에 따라 각 스텝 파일이
# "다음 스텝: execute/steps/stepN.md를 Read하고 따르세요" 형태로 체이닝합니다.
# 별도 외부 상태 파일 불필요.

exit 0
