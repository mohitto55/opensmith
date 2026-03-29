#!/bin/bash
# S16: 알림 전송 (Webhook)
# Notification(escalation=3) 이벤트에서 실행
# 3단계 에스컬레이션 시 알림 전송

HOOK_NAME="$1"
FILE_PATH="$2"
ERROR_MSG="$3"

# 알림 설정 (환경변수에서 읽기)
# {{NOTIFICATION_WEBHOOK}} - Configure your notification webhook
WEBHOOK_URL="${NOTIFICATION_WEBHOOK_URL:-}"

# Telegram 예시 (기본 구현)
BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
  echo "알림 봇 미설정. TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID 환경변수를 확인하세요."
  exit 0
fi

MESSAGE="🚨 *에스컬레이션 3단계*

📄 파일: \`${FILE_PATH}\`
🔧 훅: \`${HOOK_NAME}\`
⏰ 시간: $(date '+%Y-%m-%d %H:%M')

에러:
\`\`\`
${ERROR_MSG}
\`\`\`

사람의 지시가 필요합니다."

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$MESSAGE" \
  -d parse_mode="Markdown" \
  > /dev/null 2>&1

echo "알림 전송 완료"
