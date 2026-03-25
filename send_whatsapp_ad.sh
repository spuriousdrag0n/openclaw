#!/bin/bash
# WhatsApp Ad Sender - Simple working version
# Sends one ad per execution to rotating contacts

set -euo pipefail

OPENCLAW="/root/.nvm/versions/node/v22.22.0/bin/openclaw"
STATE_DIR="/root/.openclaw/workspace/data"
STATE_FILE="$STATE_DIR/whatsapp_ad_state.json"
LOG="/var/log/whatsapp_ad.log"
IMAGE="/root/.openclaw/media/inbound/file_0---f34d7c03-e4a1-46d0-8f11-724dce29292c.jpg"

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

MESSAGE='DEPLOYMENTS START FROM $5,000 — SCALING TO $100,000+

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

You don'"'"'t buy tools.
You deploy power.

Let'"'"'s discuss:
https://wa.me/96181381671'

mkdir -p "$STATE_DIR"

if [[ -f "$STATE_FILE" ]]; then
    INDEX=$(jq -r '.index // 0' "$STATE_FILE" 2>/dev/null || echo 0)
else
    INDEX=0
fi

TOTAL=${#CONTACTS[@]}
TARGET="${CONTACTS[$INDEX]}"

echo "[$(date -Iseconds)] Sending to contact $((INDEX+1))/$TOTAL: $TARGET" | tee -a "$LOG"

if $OPENCLAW message send \
    --channel whatsapp \
    --target "$TARGET" \
    --message "$MESSAGE" \
    --media "$IMAGE" >> "$LOG" 2>&1; then
    
    echo "[$(date -Iseconds)] ✓ Sent to $TARGET" | tee -a "$LOG"
    NEXT=$(( (INDEX + 1) % TOTAL ))
    echo "{\"index\": $NEXT, \"last_sent\": \"$(date -Iseconds)\", \"last_target\": \"$TARGET\"}" > "$STATE_FILE"
    exit 0
else
    echo "[$(date -Iseconds)] ✗ Failed to send to $TARGET" | tee -a "$LOG"
    exit 1
fi
