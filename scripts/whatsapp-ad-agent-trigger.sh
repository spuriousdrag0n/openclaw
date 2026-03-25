#!/bin/bash
# Trigger WhatsApp ad send via agent (bypasses broken CLI)

TRIGGER_FILE="/root/.openclaw/workspace/data/whatsapp_ad_trigger.json"
LOG_FILE="/var/log/whatsapp-ad-agent.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Triggering agent to send WhatsApp ad" >> "$LOG_FILE"

# Create trigger file that agent will detect
cat > "$TRIGGER_FILE" << 'JSON'
{
  "action": "send_whatsapp_ad",
  "timestamp": "$(date -Iseconds)",
  "source": "cron"
}
JSON

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Trigger file created. Agent will process." >> "$LOG_FILE"
