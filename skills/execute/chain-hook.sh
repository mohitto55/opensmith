#!/bin/bash
# execute 파이프라인 체이닝 훅
# 각 스텝 완료 시 다음 스텝을 트리거합니다.

STATE_FILE=".execute/state.json"

if [ ! -f "$STATE_FILE" ]; then
  echo "(execute 파이프라인 비활성)"
  exit 0
fi

CURRENT_STEP=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['current_step'])" 2>/dev/null)

if [ -z "$CURRENT_STEP" ] || [ "$CURRENT_STEP" = "done" ]; then
  exit 0
fi

SKILL_DIR=".claude/skills/execute/steps"

case $CURRENT_STEP in
  0) NEXT="$SKILL_DIR/step0-read-prd.md" ;;
  1) NEXT="$SKILL_DIR/step1-feature-prd.md" ;;
  2) NEXT="$SKILL_DIR/step2-collect.md" ;;
  3) NEXT="$SKILL_DIR/step3-design.md" ;;
  4) NEXT="$SKILL_DIR/step4-approve.md" ;;
  5) NEXT="$SKILL_DIR/step5-implement.md" ;;
  6) NEXT="$SKILL_DIR/step6-build.md" ;;
  7) NEXT="$SKILL_DIR/step7-qa.md" ;;
  8) NEXT="$SKILL_DIR/step8-deploy.md" ;;
  9) NEXT="$SKILL_DIR/step9-report.md" ;;
  *) exit 0 ;;
esac

cat <<EOF
{
  "additionalContext": "execute 파이프라인 Step $CURRENT_STEP 실행 필요. 다음 파일을 Read하고 지시를 따르세요: $NEXT"
}
EOF
