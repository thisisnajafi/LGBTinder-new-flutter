#!/usr/bin/env bash
# Send CI build report to Telegram (reuses existing LGBTFinder bot configuration).
# Called from GitHub Actions with environment variables set.
set -euo pipefail

# Reuse existing project Telegram config; allow GitHub secrets override.
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-7488407974:AAFl4Ek9IanbvlkKlRoikQAqdkDtFYbD0Gc}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:--1002275828844}"

if [[ -z "${TELEGRAM_BOT_TOKEN}" || -z "${TELEGRAM_CHAT_ID}" ]]; then
  echo "Telegram credentials not configured, skipping notification."
  exit 0
fi

STATUS_EMOJI="✅"
if [[ "${BUILD_STATUS:-failure}" != "success" ]]; then
  STATUS_EMOJI="❌"
fi

# Escape HTML special chars for Telegram parse_mode=HTML
escape_html() {
  sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$1"
}

PROJECT_NAME="$(escape_html "${PROJECT_NAME:-LGBTFinder Flutter}")"
BRANCH="$(escape_html "${BRANCH_NAME:-unknown}")"
COMMIT_SHA="$(escape_html "${COMMIT_SHA:-unknown}")"
COMMIT_AUTHOR="$(escape_html "${COMMIT_AUTHOR:-unknown}")"
BUILD_TIME="$(escape_html "${BUILD_TIMESTAMP:-$(date -u '+%Y-%m-%d %H:%M:%S UTC')}")"
FLUTTER_VER="$(escape_html "${FLUTTER_VERSION:-unknown}")"
SDK_CONFIG="$(escape_html "${ANDROID_SDK_CONFIG:-compileSdk=36, targetSdk=36, minSdk=24}")"
DURATION="$(escape_html "${BUILD_DURATION:-unknown}")"
TEST_RESULTS="$(escape_html "${TEST_RESULTS:-not run}")"
APK_STATUS="$(escape_html "${APK_STATUS:-unknown}")"
AAB_STATUS="$(escape_html "${AAB_STATUS:-unknown}")"
COMPAT_STATUS="$(escape_html "${COMPAT_STATUS:-not run}")"
ARTIFACT_LINKS="$(escape_html "${ARTIFACT_LINKS:-See GitHub Actions artifacts}")"
ERROR_SUMMARY="$(escape_html "${ERROR_SUMMARY:-none}")"
BUILD_STATUS_ESC="$(escape_html "${BUILD_STATUS:-failure}")"

MESSAGE=$(cat <<EOF
${STATUS_EMOJI} <b>${PROJECT_NAME}</b> — Android CI

<b>Status:</b> ${BUILD_STATUS_ESC}

<b>Branch:</b> ${BRANCH}
<b>Commit:</b> <code>${COMMIT_SHA}</code>
<b>Author:</b> ${COMMIT_AUTHOR}
<b>Time:</b> ${BUILD_TIME}
<b>Duration:</b> ${DURATION}

<b>Flutter:</b> ${FLUTTER_VER}
<b>Android SDK:</b> ${SDK_CONFIG}

<b>Tests:</b> ${TEST_RESULTS}
<b>APK:</b> ${APK_STATUS}
<b>App Bundle:</b> ${AAB_STATUS}
<b>Compatibility:</b> ${COMPAT_STATUS}

<b>Artifacts:</b>
${ARTIFACT_LINKS}

<b>Errors:</b>
${ERROR_SUMMARY}
EOF
)

curl -sS --connect-timeout 15 --max-time 30 \
  -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${MESSAGE}" \
  -d "parse_mode=HTML" \
  -d "disable_web_page_preview=true"

echo "Telegram notification sent."
