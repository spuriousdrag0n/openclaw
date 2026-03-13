#!/bin/bash
# Main glucose check script with notifications

WORK_DIR="/root/.openclaw/workspace/glucose_monitor"
LOG_FILE="$WORK_DIR/glucose_history.jsonl"
ALERT_LOG="$WORK_DIR/alerts.log"

# Run the monitor and capture response
RESPONSE=$(bash "$WORK_DIR/libre_monitor.sh" 2>/dev/null)

# Check if response contains error
if echo "$RESPONSE" | grep -q "error\|status.*[24]"; then
    echo "$(date -Iseconds) - API Error: $RESPONSE" >> "$ALERT_LOG"
    exit 1
fi

# Parse and analyze
echo "$RESPONSE" | python3 "$WORK_DIR/analyze_glucose.py" > "$WORK_DIR/latest_reading.json"

# Log to history
echo "{\"timestamp\": \"$(date -Iseconds)\", \"response\": $RESPONSE}" >> "$LOG_FILE"

# Send notifications if needed
bash "$WORK_DIR/notify.sh"

# Display result
cat "$WORK_DIR/latest_reading.json"
