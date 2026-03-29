#!/bin/bash
# HARD 훅: 보안 리포트 없으면 배포 차단
# PreToolUse(Bash) 이벤트에서 실행
# kubectl, docker push, deploy 명령 실행 전에 보안 15항목 통과 여부 확인

TOOL_INPUT="$1"

# 배포 관련 명령인지 확인
if ! echo "$TOOL_INPUT" | grep -qiP "kubectl.*rollout|kubectl.*apply|kubectl.*set.*image|docker.*push|deploy|rollout.*restart"; then
  exit 0
fi

REPORT_FILE=".execute/security-report.json"
STATE_FILE=".execute/state.json"

# execute 파이프라인 밖에서 직접 배포하는 경우는 허용
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# 보안 리포트 파일 존재 확인
if [ ! -f "$REPORT_FILE" ]; then
  echo "BLOCK"
  echo ""
  echo "보안 15항목 검사가 완료되지 않았습니다."
  echo "배포 전에 step7(QA)에서 secure-web-saas 15항목을 실행하세요."
  echo ""
  echo "필요한 파일: .execute/security-report.json"
  echo "이 파일은 step7에서 15/15 PASS 시 자동 생성됩니다."
  exit 2
fi

# 리포트 내용 확인 — 전부 PASS인지
FAIL_COUNT=$(python3 -c "
import json
try:
    report = json.load(open('$REPORT_FILE'))
    fails = [item for item in report.get('items', []) if item.get('result') != 'PASS']
    print(len(fails))
except:
    print(-1)
" 2>/dev/null)

if [ "$FAIL_COUNT" = "-1" ]; then
  echo "BLOCK"
  echo "보안 리포트 파일이 손상되었습니다. step7을 다시 실행하세요."
  exit 2
fi

if [ "$FAIL_COUNT" != "0" ]; then
  echo "BLOCK"
  echo ""
  echo "보안 검사 미통과 항목이 ${FAIL_COUNT}개 있습니다."
  echo "15/15 PASS 후에만 배포할 수 있습니다."
  echo ""
  # 실패 항목 표시
  python3 -c "
import json
report = json.load(open('$REPORT_FILE'))
for item in report.get('items', []):
    if item.get('result') != 'PASS':
        print(f\"  FAIL: {item.get('name', '?')} — {item.get('detail', '')}\")
" 2>/dev/null
  exit 2
fi

# 15/15 PASS — 배포 허용
exit 0
