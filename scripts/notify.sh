#!/bin/bash
# OpenSmith 범용 알림 시스템
# Slack, Discord, Telegram 지원
#
# 사용법:
#   bash notify.sh --channel slack --event deploy_success --message "배포 완료"
#   bash notify.sh --channel discord --event build_fail --message "빌드 실패: 에러 내용"
#   bash notify.sh --channel all --event qa_fail --message "QA 실패"
#
# 환경변수:
#   OPENSMITH_SLACK_WEBHOOK    - Slack Incoming Webhook URL
#   OPENSMITH_DISCORD_WEBHOOK  - Discord Webhook URL
#   OPENSMITH_TELEGRAM_TOKEN   - Telegram Bot Token
#   OPENSMITH_TELEGRAM_CHAT_ID - Telegram Chat ID

CHANNEL=""
EVENT=""
MESSAGE=""
PROJECT_NAME="${OPENSMITH_PROJECT_NAME:-$(basename $(pwd))}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --channel) CHANNEL="$2"; shift 2 ;;
    --event) EVENT="$2"; shift 2 ;;
    --message) MESSAGE="$2"; shift 2 ;;
    --project) PROJECT_NAME="$2"; shift 2 ;;
    *) MESSAGE="$MESSAGE $1"; shift ;;
  esac
done

MESSAGE=$(echo "$MESSAGE" | xargs)

if [ -z "$MESSAGE" ]; then
  echo "[notify] 메시지가 비어있습니다."
  exit 0
fi

# 이벤트별 이모지/색상 매핑
case $EVENT in
  deploy_success)  EMOJI="🚀"; COLOR="#36a64f"; TITLE="배포 성공" ;;
  deploy_fail)     EMOJI="💥"; COLOR="#ff0000"; TITLE="배포 실패" ;;
  build_success)   EMOJI="✅"; COLOR="#36a64f"; TITLE="빌드 성공" ;;
  build_fail)      EMOJI="❌"; COLOR="#ff0000"; TITLE="빌드 실패" ;;
  qa_pass)         EMOJI="🧪"; COLOR="#36a64f"; TITLE="QA 통과" ;;
  qa_fail)         EMOJI="🐛"; COLOR="#ff9900"; TITLE="QA 실패" ;;
  escalation)      EMOJI="🚨"; COLOR="#ff0000"; TITLE="에스컬레이션" ;;
  feature_done)    EMOJI="🎉"; COLOR="#36a64f"; TITLE="기능 구현 완료" ;;
  pipeline_done)   EMOJI="🏁"; COLOR="#36a64f"; TITLE="전체 파이프라인 완료" ;;
  bug_found)       EMOJI="🐞"; COLOR="#ff6600"; TITLE="버그 발견" ;;
  bug_fixed)       EMOJI="🔧"; COLOR="#36a64f"; TITLE="버그 해결" ;;
  bug_report)      EMOJI="📋"; COLOR="#439FE0"; TITLE="버그 리포트" ;;
  *)               EMOJI="📢"; COLOR="#439FE0"; TITLE="알림" ;;
esac

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ========== Slack ==========
send_slack() {
  local webhook="${OPENSMITH_SLACK_WEBHOOK:-}"
  if [ -z "$webhook" ]; then return 1; fi

  local payload=$(cat <<SLACKEOF
{
  "blocks": [
    {
      "type": "header",
      "text": {"type": "plain_text", "text": "$EMOJI $TITLE"}
    },
    {
      "type": "section",
      "fields": [
        {"type": "mrkdwn", "text": "*Project:*\n$PROJECT_NAME"},
        {"type": "mrkdwn", "text": "*Time:*\n$TIMESTAMP"}
      ]
    },
    {
      "type": "section",
      "text": {"type": "mrkdwn", "text": "$MESSAGE"}
    }
  ]
}
SLACKEOF
)

  curl -s -X POST "$webhook" \
    -H "Content-Type: application/json" \
    -d "$payload" > /dev/null 2>&1

  echo "[notify] Slack 전송 완료"
}

# ========== Discord ==========
send_discord() {
  local webhook="${OPENSMITH_DISCORD_WEBHOOK:-}"
  if [ -z "$webhook" ]; then return 1; fi

  local payload=$(cat <<DISCORDEOF
{
  "embeds": [{
    "title": "$EMOJI $TITLE",
    "description": "$MESSAGE",
    "color": $(printf '%d' "0x${COLOR:1}"),
    "fields": [
      {"name": "Project", "value": "$PROJECT_NAME", "inline": true},
      {"name": "Time", "value": "$TIMESTAMP", "inline": true}
    ]
  }]
}
DISCORDEOF
)

  curl -s -X POST "$webhook" \
    -H "Content-Type: application/json" \
    -d "$payload" > /dev/null 2>&1

  echo "[notify] Discord 전송 완료"
}

# ========== Telegram ==========
send_telegram() {
  local token="${OPENSMITH_TELEGRAM_TOKEN:-}"
  local chat_id="${OPENSMITH_TELEGRAM_CHAT_ID:-}"
  if [ -z "$token" ] || [ -z "$chat_id" ]; then return 1; fi

  local text="$EMOJI *$TITLE*

📁 Project: \`$PROJECT_NAME\`
⏰ Time: $TIMESTAMP

$MESSAGE"

  curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
    -d chat_id="$chat_id" \
    -d text="$text" \
    -d parse_mode="Markdown" > /dev/null 2>&1

  echo "[notify] Telegram 전송 완료"
}

# ========== 발송 ==========
case $CHANNEL in
  slack)    send_slack ;;
  discord)  send_discord ;;
  telegram) send_telegram ;;
  all)
    send_slack
    send_discord
    send_telegram
    ;;
  *)
    # 채널 미지정 시 설정된 모든 채널로 발송
    [ -n "$OPENSMITH_SLACK_WEBHOOK" ] && send_slack
    [ -n "$OPENSMITH_DISCORD_WEBHOOK" ] && send_discord
    [ -n "$OPENSMITH_TELEGRAM_TOKEN" ] && send_telegram
    ;;
esac
