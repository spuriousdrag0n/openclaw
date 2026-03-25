#!/bin/bash
# Aggressive health check for hourly WhatsApp ad cron job
source /root/.openclaw/workspace/scripts/env-setup.sh

LOG_FILE="/var/log/hourly-whatsapp-ad.log"
STATE_FILE="/root/.openclaw/workspace/data/ad-contacts-state.json"
HEALTH_LOG="/var/log/hourly-ad-health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Check if last success was within 2 hours
if [ -f "$LOG_FILE" ]; then
    LAST_SUCCESS_LINE=$(grep "✓ Ad with image sent successfully" "$LOG_FILE" | tail -1)
    if [ -n "$LAST_SUCCESS_LINE" ]; then
        LAST_SUCCESS_TIME=$(echo "$LAST_SUCCESS_LINE" | grep -oP '\[\K[^\]]+')
        LAST_SUCCESS_EPOCH=$(date -d "$LAST_SUCCESS_TIME" +%s 2>/dev/null || echo 0)
        CURRENT_EPOCH=$(date +%s)
        TIME_DIFF=$((CURRENT_EPOCH - LAST_SUCCESS_EPOCH))
        
        if [ $TIME_DIFF -gt 7200 ]; then  # 2 hours = 7200 seconds
            echo "[$DATE] CRITICAL: No successful send in $TIME_DIFF seconds. Triggering backup send..." >> "$HEALTH_LOG"
            # Trigger immediate send
            /root/.openclaw/workspace/scripts/hourly-whatsapp-ad.sh >> "$HEALTH_LOG" 2>&1
        else
            echo "[$DATE] OK: Last success was $TIME_DIFF seconds ago" >> "$HEALTH_LOG"
        fi
    else
        echo "[$DATE] WARNING: No success records found. Triggering backup send..." >> "$HEALTH_LOG"
        /root/.openclaw/workspace/scripts/hourly-whatsapp-ad.sh >> "$HEALTH_LOG" 2>&1
    fi
else
    echo "[$DATE] CRITICAL: Log file missing. Recreating and triggering send..." >> "$HEALTH_LOG"
    touch "$LOG_FILE"
    /root/.openclaw/workspace/scripts/hourly-whatsapp-ad.sh >> "$HEALTH_LOG" 2>&1
fi

# Check current contact index
if [ -f "$STATE_FILE" ]; then
    CURRENT_INDEX=$(cat "$STATE_FILE")
    CONTACT_NUM=$(grep -oP '"current_index":\s*\K[0-9]+' "$STATE_FILE" | awk '{print $1+1}')
    echo "[$DATE] INFO: Next contact will be $CONTACT_NUM/10" >> "$HEALTH_LOG"
else
    echo "[$DATE] WARNING: State file missing, resetting to 0" >> "$HEALTH_LOG"
    echo "0" > "$STATE_FILE"
fi

# Verify cron job exists
CRON_CHECK=$(/root/.nvm/versions/node/v22.22.0/bin/openclaw cron list 2>/dev/null | grep hourly-whatsapp-ad)
if [ -z "$CRON_CHECK" ]; then
    echo "[$DATE] CRITICAL: Cron job missing! Re-registering..." >> "$HEALTH_LOG"
    /root/.nvm/versions/node/v22.22.0/bin/openclaw cron add --name hourly-whatsapp-ad --description "Send MerkleRoot ad to 10 contacts rotating hourly" --cron "0 * * * *" --system-event "shell:hourly-whatsapp-ad" --exact 2>/dev/null
    echo "[$DATE] INFO: Cron job re-registered" >> "$HEALTH_LOG"
else
    echo "[$DATE] OK: Cron job registered" >> "$HEALTH_LOG"
fi
