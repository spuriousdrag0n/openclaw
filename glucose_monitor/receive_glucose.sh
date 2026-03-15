#!/bin/bash
# Receive glucose data from iPhone shortcut/automation

WORK_DIR="/root/.openclaw/workspace/glucose_monitor"
LOG_FILE="$WORK_DIR/glucose_history.jsonl"
ALERT_LOG="$WORK_DIR/alerts.log"

# Read JSON from stdin (sent by iPhone)
read -r JSON_DATA

# Validate JSON
echo "$JSON_DATA" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null || {
    echo "$(date -Iseconds) - Invalid JSON received" >> "$ALERT_LOG"
    echo '{"status": "error", "message": "Invalid JSON"}'
    exit 1
}

# Save to history
echo "{\"timestamp\": \"$(date -Iseconds)\", \"data\": $JSON_DATA}" >> "$LOG_FILE"

# Extract values
VALUE=$(echo "$JSON_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('value', 0))")
TREND=$(echo "$JSON_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('trend', 'Unknown'))")

# Analyze and alert if needed
if [ "$VALUE" -lt 70 ] 2>/dev/null; then
    STATUS="URGENT LOW"
    MESSAGE="🚨 URGENT GLUCOSE ALERT - Simon

Value: ${VALUE} mg/dL
Trend: ${TREND}
Status: ${STATUS}
Time: $(date '+%Y-%m-%d %H:%M')

⚠️ ACTIONS NEEDED:
• Consume 15g fast carbs immediately
• Recheck in 15 minutes
• Call emergency if unresponsive"
    
    # Send WhatsApp alerts
    openclaw message send --channel whatsapp --target "+9613961764" --message "$MESSAGE" 2>/dev/null
    openclaw message send --channel whatsapp --target "+96170224984" --message "$MESSAGE" 2>/dev/null
    
    echo "$(date -Iseconds) - URGENT LOW ALERT: $VALUE mg/dL" >> "$ALERT_LOG"
    
elif [ "$VALUE" -gt 250 ] 2>/dev/null; then
    STATUS="URGENT HIGH"
    MESSAGE="🚨 URGENT GLUCOSE ALERT - Simon

Value: ${VALUE} mg/dL
Trend: ${TREND}
Status: ${STATUS}
Time: $(date '+%Y-%m-%d %H:%M')

⚠️ ACTIONS NEEDED:
• Check ketones
• Hydrate with water
• Contact healthcare provider if persists"
    
    # Send WhatsApp alerts
    openclaw message send --channel whatsapp --target "+9613961764" --message "$MESSAGE" 2>/dev/null
    openclaw message send --channel whatsapp --target "+96170224984" --message "$MESSAGE" 2>/dev/null
    
    echo "$(date -Iseconds) - URGENT HIGH ALERT: $VALUE mg/dL" >> "$ALERT_LOG"
fi

# Return success
echo '{"status": "success", "message": "Glucose data received"}'
