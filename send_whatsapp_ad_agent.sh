#!/bin/bash
# WhatsApp Ad Sender - Uses agent session instead of broken CLI

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

STATE_FILE="/root/.openclaw/workspace/data/whatsapp_ad_state.json"
mkdir -p "$(dirname "$STATE_FILE")"

if [[ -f "$STATE_FILE" ]]; then
    INDEX=$(jq -r '.index // 0' "$STATE_FILE" 2>/dev/null || echo 0)
else
    INDEX=0
fi

TARGET="${CONTACTS[$INDEX]}"
NEXT=$(( (INDEX + 1) % ${#CONTACTS[@]} ))

# Use openclaw sessions send to route through agent
/root/.nvm/versions/node/v22.22.0/bin/openclaw sessions send \
    --label main \
    --message "Send WhatsApp ad to $TARGET with image /root/.openclaw/media/inbound/file_0---f34d7c03-e4a1-46d0-8f11-724dce29292c.jpg

Message:
DEPLOYMENTS START FROM \$5,000 — SCALING TO \$100,000+

MERKLERR00T × OPENCLAW
Code is Law.

This is not software.
This is your AI command infrastructure.

▪ Command your entire digital universe
▪ Deploy autonomous agents across all communications
▪ Execute real-world actions — instantly
▪ Trade, monitor & dominate financial markets
▪ Run prediction intelligence systems
▪ Deploy autonomous AI engineering teams
▪ Control servers, systems & physical infrastructure
▪ Generate revenue pipelines automatically
▪ Gather intelligence at global scale
▪ Execute any workflow, any logic, anywhere
▪ Operate 24/7 — without limits

Built for billionaires, operators & elite corporations.

You don't buy tools.
You deploy power.

Let's discuss:
https://wa.me/96181381671"

echo "{\"index\": $NEXT}" > "$STATE_FILE"
