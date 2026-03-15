#!/bin/bash
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
LOG_FILE="/var/log/daily-executive-summary.log"
DATE=$(date +%Y-%m-%d-%H:%M)
TARGET="120363027105322990@g.us"
echo "[$DATE] Starting..." >> $LOG_FILE
WEATHER=$(curl -s "https://wttr.in/34.1208,35.6500?format=%C|%t" 2>/dev/null || echo "N/A|N/A")
MSG="Daily Summary - $(date +%A)"
openclaw message send --channel whatsapp --target "$TARGET" --message "$MSG" 2>&1 >> $LOG_FILE
