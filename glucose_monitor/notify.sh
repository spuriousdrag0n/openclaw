#!/bin/bash
# Send glucose alerts via WhatsApp (CLI method)

WORK_DIR="/root/.openclaw/workspace/glucose_monitor"
LATEST="$WORK_DIR/latest_reading.json"
ALERT_LOG="$WORK_DIR/alerts.log"

if [ ! -f "$LATEST" ]; then
    exit 1
fi

VALUE=$(cat "$LATEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('value', 0))")
STATUS=$(cat "$LATEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status', 'UNKNOWN'))")
TREND=$(cat "$LATEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('trend', ''))")

# Format base message
MESSAGE="🩸 GLUCOSE ALERT - Simon

Value: ${VALUE} mg/dL
Trend: ${TREND}
Status: ${STATUS}
Time: $(date '+%Y-%m-%d %H:%M')"

# Add recommendations based on status
if [ "$STATUS" = "URGENT LOW" ]; then
    MESSAGE="$MESSAGE

🚨 URGENT - LOW BLOOD SUGAR

Actions needed:
• Give Simon 15g fast carbs immediately (juice, candy, glucose tablets)
• Recheck in 15 minutes
• Call emergency if he becomes unresponsive"
    URGENT=true
elif [ "$STATUS" = "LOW" ]; then
    MESSAGE="$MESSAGE

⚠️ LOW BLOOD SUGAR

Actions:
• Simon should have a small snack
• Monitor closely"
    URGENT=true
elif [ "$STATUS" = "URGENT HIGH" ]; then
    MESSAGE="$MESSAGE

🚨 URGENT - HIGH BLOOD SUGAR

Actions needed:
• Check ketones if possible
• Hydrate with water
• Contact healthcare provider if persists"
    URGENT=true
elif [ "$STATUS" = "HIGH" ]; then
    MESSAGE="$MESSAGE

⚠️ HIGH BLOOD SUGAR

Actions:
• Take walk if safe
• Hydrate
• Review meal timing"
    URGENT=true
else
    URGENT=false
fi

# Log all readings
echo "$(date -Iseconds) - $STATUS - $VALUE mg/dL" >> "$ALERT_LOG"

# Send WhatsApp for out-of-range values
if [ "$URGENT" = true ]; then
    # Send to Chantal
    openclaw message send --channel whatsapp --target "+9613961764" --message "$MESSAGE" 2>/dev/null || \
        echo "$(date -Iseconds) - Failed to send WhatsApp to Chantal" >> "$ALERT_LOG"
    
    # Also send to Simon
    openclaw message send --channel whatsapp --target "+96170224984" --message "$MESSAGE" 2>/dev/null || \
        echo "$(date -Iseconds) - Failed to send WhatsApp to Simon" >> "$ALERT_LOG"
    
    echo "$(date -Iseconds) - ALERT SENT: $STATUS - $VALUE mg/dL" >> "$ALERT_LOG"
fi
