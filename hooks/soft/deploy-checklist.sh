#!/bin/bash
# S9: 배포 전 체크리스트
# PreToolUse(Bash:kubectl) 이벤트에서 실행

echo "## Deploy Checklist"
echo ""
echo "- [ ] 로컬 빌드 성공 확인 ({{BACKEND_BUILD_CMD}} + {{FRONTEND_BUILD_CMD}})"
echo "- [ ] 배포 아티팩트에 올바른 디렉토리 구조 포함"
echo "- [ ]  백엔드: {{BACKEND_PROJECT_PATH}}/ 최상위"
echo "- [ ]  프론트: package.json 최상위, node_modules/.next 제외"
echo "- [ ] 아티팩트 스토리지 업로드 완료"
echo "- [ ] Pod 재시작 후 rollout status 확인"
echo "- [ ] 헬스체크 HTTP 200 확인"
