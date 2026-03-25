#!/bin/bash
STATE_DIR="/root/.openclaw/workspace/data"
STATE_FILE="$STATE_DIR/whatsapp_ad_state.json"
LOG_FILE="/var/log/whatsapp-ad-cron.log"
CONTACTS=("+96170866366" "+96171629366" "+96171352464" "+96178880334" "+96103105434" "+96170271690" "+96170489784" "+96181737912" "+96103907296" "+96170224984")
INDEX=$(jq -r ".index // 0" "$STATE_FILE" 2>/dev/null || echo 0)
TOTAL=${#CONTACTS[@]}
TARGET="${CONTACTS[$INDEX]}"
echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Contact $((INDEX+1))/$TOTAL: $TARGET" >> "$LOG_FILE"
mkdir -p "$STATE_DIR"
printf "{\"action\":\"send_whatsapp_ad\",\"campaign\":\"merkleroot\",\"timestamp\":\"%s\",\"source\":\"cron\",\"target\":\"%s\",\"index\":%d,\"next_index\":%d}\n" "$(date -Iseconds)" "$TARGET" "$INDEX" "$(((INDEX+1)%TOTAL))" > "$STATE_DIR/whatsapp_ad_trigger.json"
printf "{\"index\":%d,\"last_run\":\"%s\"}\n" "$(((INDEX+1)%TOTAL))" "$(date -Iseconds)" > "$STATE_FILE"
