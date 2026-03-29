#!/bin/bash
# A5: 배포 실패 자동 수정 에이전트
# PostToolUse(Bash:kubectl) 이벤트에서 실행

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/escalation.sh"

OUTPUT=$(cat 2>/dev/null || echo "")

# 배포 실패 감지
if echo "$OUTPUT" | grep -qiP "error|failed|CrashLoopBackOff|ImagePullBackOff|ErrImagePull|OOMKilled"; then
  LEVEL=$(escalate_level "deploy-fix" "deployment")

  echo "## Deployment Issue Detected"
  echo ""

  # Pod 상태 정보 수집
  if echo "$OUTPUT" | grep -qi "CrashLoopBackOff"; then
    echo "Pod가 CrashLoopBackOff 상태입니다."
    echo "Pod 로그를 확인하세요: kubectl logs -n {{K8S_NAMESPACE}} deployment/<name> --tail=50"
  elif echo "$OUTPUT" | grep -qi "ImagePull"; then
    echo "이미지 풀 실패. 이미지 레지스트리 경로와 시크릿을 확인하세요."
  elif echo "$OUTPUT" | grep -qi "OOMKilled"; then
    echo "OOM 발생. 메모리 limit을 확인하세요."
    echo "현재 설정: kubectl get deployment -n {{K8S_NAMESPACE}} -o yaml | grep -A2 limits"
  fi

  echo ""
  echo '```'
  echo "$OUTPUT" | tail -15
  echo '```'

  escalate_increment "deploy-fix" "deployment" "$(echo "$OUTPUT" | head -5)"

  if [ "$LEVEL" -ge 3 ]; then
    bash "$SCRIPT_DIR/../soft/telegram-notify.sh" "deploy-fix" "deployment" "$(echo "$OUTPUT" | head -10)"
  fi
fi
