#!/bin/bash
# A1: 빌드 실패 자동 수정 에이전트
# BuildFail 이벤트에서 실행
# 독립 Opus 에이전트를 스폰하여 빌드 에러 자동 수정

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/escalation.sh"

ERROR_LOG="$1"  # 빌드 에러 로그 (stdin 또는 인수)

if [ -z "$ERROR_LOG" ]; then
  ERROR_LOG=$(cat 2>/dev/null || echo "")
fi

if [ -z "$ERROR_LOG" ]; then
  exit 0
fi

# 에스컬레이션 레벨 확인
LEVEL=$(escalate_level "build-fix" "build")

case "$LEVEL" in
  1)
    # 1단계: 소프트 알림 — 에러 정보만 주입
    echo "## Build Error (Auto-detected)"
    echo ""
    echo "빌드 에러가 감지되었습니다. 아래 에러를 확인하고 수정하세요:"
    echo '```'
    echo "$ERROR_LOG" | head -20
    echo '```'
    escalate_increment "build-fix" "build" "$(echo "$ERROR_LOG" | head -5)"
    ;;
  2)
    # 2단계: 에이전트 수정 프롬프트 생성
    echo "## Build Fix Agent Required"
    echo ""
    echo "빌드 에러가 반복되고 있습니다. 독립 에이전트로 수정을 시도합니다."
    echo ""
    echo "에이전트 프롬프트:"
    echo "---"
    echo "빌드 에러를 수정하세요:"
    echo "$ERROR_LOG" | head -20
    echo "---"
    echo ""
    echo "scaffold 규칙: .claude/skills/backend-patterns.md, .claude/skills/frontend-patterns.md"
    escalate_increment "build-fix" "build" "$(echo "$ERROR_LOG" | head -5)"
    ;;
  3)
    # 3단계: 강제 차단
    echo "BLOCK"
    echo "빌드 에러가 6회 이상 반복되었습니다. 접근 방식을 변경하세요."
    # 알림
    bash "$SCRIPT_DIR/../soft/telegram-notify.sh" "build-fix" "build" "$(echo "$ERROR_LOG" | head -10)"
    escalate_reset "build-fix" "build"
    escalate_log "build-fix" "build" 3 "$(echo "$ERROR_LOG" | head -5)"
    ;;
esac
