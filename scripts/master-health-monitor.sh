#!/bin/bash
# Master health monitor - checks all systems and auto-fixes

source /root/.openclaw/workspace/scripts/env-setup.sh

LOG_FILE="$LOG_DIR/master-health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting master health check..." >> "$LOG_FILE"

# Function to check and restart cron job if needed
check_cron_job() {
    local job_name=$1
    local script_path=$2
    local schedule=$3
    
    if ! crontab -l | grep -q "$script_path"; then
        echo "[$DATE] WARNING: $job_name missing from crontab, re-adding..." >> "$LOG_FILE"
        (crontab -l 2>/dev/null; echo "$schedule $script_path >> $LOG_DIR/$(basename $script_path .sh).log 2>&1") | crontab -
        echo "[$DATE] FIXED: $job_name re-added to crontab" >> "$LOG_FILE"
    fi
}

# Check all critical cron jobs
check_cron_job "hourly-whatsapp-ad" "$SCRIPTS_DIR/hourly-whatsapp-ad.sh" "0 * * * *"
check_cron_job "btc-price-alert" "$SCRIPTS_DIR/btc-price-alert.sh" "0 */6 * * *"
check_cron_job "daily-email-actions" "$SCRIPTS_DIR/daily-email-actions.sh" "0 10 * * *"
check_cron_job "moltbook-engagement" "$SCRIPTS_DIR/moltbook-engagement.sh" "0 */4 * * *"
check_cron_job "daily-x-molt" "$SCRIPTS_DIR/daily-x-molt.sh" "0 12 * * *"

# Check if scripts have env-setup
for script in $SCRIPTS_DIR/*.sh; do
    if [ "$script" != "$SCRIPTS_DIR/env-setup.sh" ] && ! grep -q "env-setup.sh" "$script"; then
        echo "[$DATE] WARNING: $script missing env-setup, fixing..." >> "$LOG_FILE"
        sed -i '2a source /root/.openclaw/workspace/scripts/env-setup.sh' "$script"
        echo "[$DATE] FIXED: Added env-setup to $script" >> "$LOG_FILE"
    fi
done

# Check gateway status
if ! pgrep -f openclaw-gateway > /dev/null; then
    echo "[$DATE] CRITICAL: Gateway not running, attempting restart..." >> "$LOG_FILE"
    $OPENCLAW_BIN gateway restart 2>/dev/null || echo "[$DATE] ERROR: Failed to restart gateway" >> "$LOG_FILE"
else
    echo "[$DATE] OK: Gateway running" >> "$LOG_FILE"
fi

# Check recent WhatsApp ad activity
if [ -f "$LOG_DIR/hourly-whatsapp-ad.log" ]; then
    LAST_SUCCESS=$(grep "✓ Ad with image sent successfully" "$LOG_DIR/hourly-whatsapp-ad.log" | tail -1)
    if [ -n "$LAST_SUCCESS" ]; then
        SUCCESS_TIME=$(echo "$LAST_SUCCESS" | grep -oP '\[\K[^\]]+')
        SUCCESS_EPOCH=$(date -d "$SUCCESS_TIME" +%s 2>/dev/null || echo 0)
        CURRENT_EPOCH=$(date +%s)
        TIME_DIFF=$((CURRENT_EPOCH - SUCCESS_EPOCH))
        
        if [ $TIME_DIFF -gt 7200 ]; then
            echo "[$DATE] WARNING: No ad sent in $TIME_DIFF seconds, triggering manual send..." >> "$LOG_FILE"
            $SCRIPTS_DIR/hourly-whatsapp-ad.sh >> "$LOG_FILE" 2>&1
        else
            echo "[$DATE] OK: Last ad sent $TIME_DIFF seconds ago" >> "$LOG_FILE"
        fi
    fi
fi

echo "[$DATE] Master health check complete" >> "$LOG_FILE"
