#!/bin/bash
# Creates trigger file for agent to process

STATE_FILE="/root/.openclaw/workspace/data/whatsapp_ad_state.json"
TRIGGER_FILE="/root/.openclaw/workspace/data/whatsapp_ad_trigger.json"

mkdir -p "$(dirname "$STATE_FILE")"

if [[ -f "$STATE_FILE" ]]; then
    INDEX=$(jq -r '.index // 0' "$STATE_FILE" 2>/dev/null || echo 0)
else
    INDEX=0
fi

CONTACTS=(
    "+96170866366"
    "+96171629366"
    "+96171352464"
    "+96178880334"
    "+96103105434"
    "+96170271690"
    "+96170489784"
    "+96181737912"
    "+96103907296"
    "+96170224984"
)

TARGET="${CONTACTS[$INDEX]}"
NEXT=$(( (INDEX + 1) % ${#CONTACTS[@]} ))

cat > "$TRIGGER_FILE" << TRIGGER
{
  "action": "send_whatsapp_ad",
  "target": "$TARGET",
  "index": $INDEX,
  "next_index": $NEXT,
  "timestamp": "$(date -Iseconds)",
  "image": "/root/.openclaw/media/inbound/file_0---f34d7c03-e4a1-46d0-8f11-724dce29292c.jpg",
  "message": "DEPLOYMENTS START FROM \$5,000 — SCALING TO \$100,000+\n\nMERKLERR00T × OPENCLAW\nCode is Law.\n\nThis is not software.\nThis is your AI command infrastructure.\n\n▪ Command your entire digital universe\n▪ Deploy autonomous agents across all communications\n▪ Execute real-world actions — instantly\n▪ Trade, monitor & dominate financial markets\n▪ Run prediction intelligence systems\n▪ Deploy autonomous AI engineering teams\n▪ Control servers, systems & physical infrastructure\n▪ Generate revenue pipelines automatically\n▪ Gather intelligence at global scale\n▪ Execute any workflow, any logic, anywhere\n▪ Operate 24/7 — without limits\n\nBuilt for billionaires, operators & elite corporations.\n\nYou don't buy tools.\nYou deploy power.\n\nLet's discuss:\nhttps://wa.me/96181381671"
}
TRIGGER

echo "Trigger created: $TRIGGER_FILE"
echo "Agent should process this on next heartbeat"
