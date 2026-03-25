#!/bin/bash
export PATH="/root/.nvm/versions/node/v22.22.0/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
source /root/.openclaw/workspace/scripts/env-setup.sh
LOG_FILE="/var/log/gmail-auth-reminder.log"
DATE=$(date +%Y-%m-%d-%H:%M)
TARGET="120363027105322990@g.us"

# Test Gmail auth
gog gmail search "newer_than:1d" --max 1 --json > /dev/null 2>&1

if [ $? -ne 0 ]; then
    MSG="🔴 *GMAIL AUTH EXPIRED*

Gmail OAuth token needs renewal.

*Action required:*
Run: gog auth login --account spuriousdragon@gmail.com

_Expiry detected: $DATE_"
    openclaw message send --channel whatsapp --target "$TARGET" --message "$MSG" 2>&1 >> "$LOG_FILE"
    echo "[$DATE] Auth expired - alert sent" >> "$LOG_FILE"
else
    echo "[$DATE] Auth valid" >> "$LOG_FILE"
fi
