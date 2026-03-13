#!/bin/bash
# Standalone WhatsApp notification script
# This runs outside the Telegram session context

WORK_DIR="/root/.openclaw/workspace/glucose_monitor"
LATEST="$WORK_DIR/latest_reading.json"

if [ ! -f "$LATEST" ]; then
    exit 1
fi

VALUE=$(cat "$LATEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('value', 0))")
STATUS=$(cat "$LATEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status', 'UNKNOWN'))")
TREND=$(cat "$LATEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('trend', ''))")

# Only send for urgent alerts
if [ "$STATUS" = "URGENT LOW" ] || [ "$STATUS" = "URGENT HIGH" ]; then
    MESSAGE="🚨 URGENT GLUCOSE ALERT - Simon

Value: ${VALUE} mg/dL
Trend: ${TREND}
Status: ${STATUS}
Time: $(date '+%Y-%m-%d %H:%M')

Please check on Simon immediately."
    
    # Use openclaw CLI to send WhatsApp message
    # This runs as a separate command, not bound to Telegram session
    openclaw message send --channel whatsapp --target "+9613961764" --message "$MESSAGE" 2>/dev/null || \
    echo "Failed to send WhatsApp - manual intervention needed" >> "$WORK_DIR/alert_failures.log
fi
