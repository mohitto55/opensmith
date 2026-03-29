#!/bin/bash
# execute 파이프라인 체이닝 훅
# TaskCompleted / PostToolUse(Write) 이벤트에서 실행
# state.json의 current_step을 읽고 다음 스텝을 강제 트리거

STATE_FILE=".execute/state.json"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

CURRENT_STEP=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['current_step'])" 2>/dev/null)

if [ -z "$CURRENT_STEP" ] || [ "$CURRENT_STEP" = "done" ]; then
  exit 0
fi

# 플러그인 루트에서 스텝 파일 경로 결정
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
SKILL_DIR="$PLUGIN_ROOT/skills/execute/steps"

case $CURRENT_STEP in
  0) NEXT="$SKILL_DIR/step0-read-prd.md"; DESC="시스템 PRD 읽기" ;;
  1) NEXT="$SKILL_DIR/step1-feature-prd.md"; DESC="세분화 PRD 생성" ;;
  2) NEXT="$SKILL_DIR/step2-collect.md"; DESC="자료 수집 (Memory Bank + 코드 + 문서 + GitHub)" ;;
  3) NEXT="$SKILL_DIR/step3-design.md"; DESC="기술 설계" ;;
  4) NEXT="$SKILL_DIR/step4-approve.md"; DESC="사용자 승인" ;;
  5) NEXT="$SKILL_DIR/step5-implement.md"; DESC="구현 (agent-teams)" ;;
  6) NEXT="$SKILL_DIR/step6-build.md"; DESC="빌드 검증" ;;
  7) NEXT="$SKILL_DIR/step7-qa.md"; DESC="QA 테스트" ;;
  8) NEXT="$SKILL_DIR/step8-deploy.md"; DESC="배포" ;;
  9) NEXT="$SKILL_DIR/step9-report.md"; DESC="완료 보고" ;;
  *) exit 0 ;;
esac

cat <<EOF
{
  "additionalContext": "[OPENSMITH PIPELINE] Step $CURRENT_STEP: $DESC 실행 필요.\n\n중요: 반드시 다음 파일을 Read하고 그 안의 지시사항을 모두 따르세요.\n파일: $NEXT\n\nstate.json의 current_step을 업데이트한 후 이 스텝이 완전히 끝나야 다음 스텝으로 넘어갑니다.\n절대 스텝을 건너뛰지 마세요."
}
EOF
