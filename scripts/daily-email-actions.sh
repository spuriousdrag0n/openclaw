#!/bin/bash
export PATH="/root/.nvm/versions/node/v22.22.0/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export GOG_ACCOUNT=spuriousdragon@gmail.com
LOG_FILE="/var/log/email-action-items.log"
DATE=$(date +%Y-%m-%d-%H:%M)
SUMMARY_DIR="/root/.openclaw/workspace/data/email-actions"
SUMMARY_FILE="$SUMMARY_DIR/$(date +%Y-%m-%d).txt"

mkdir -p "$SUMMARY_DIR"

echo "[$DATE] Starting email analysis..." >> "$LOG_FILE"

EMAILS_JSON=$(gog gmail search "newer_than:1d" --max 20 --json 2>/dev/null)

if [ -z "$EMAILS_JSON" ] || [ "$EMAILS_JSON" = "{\"threads\":[]}" ]; then
    {
        echo "*📧 Daily Email Check*"
        echo
        echo "No new emails requiring action."
        echo
        date +"_%A-%B-%d_"
        echo "_RedQueen Systems | Email Intelligence_"
    } > "$SUMMARY_FILE"
    echo "[$DATE] No emails found" >> "$LOG_FILE"
    exit 0
fi

URGENT=$(echo "$EMAILS_JSON" | grep -iE "(urgent|asap|deadline|payment due|invoice|suspension|abuse|complaint|legal|court|police)" | head -5)
OPPORTUNITIES=$(echo "$EMAILS_JSON" | grep -iE "(opportunity|partnership|investment|funding|grant|pitch|speaking|event|conference|reward|airdrop|claim)" | head -5)
REPLIES_NEEDED=$(echo "$EMAILS_JSON" | grep -iE "(re:|fw:|question|can you|could you|please respond|waiting for your|let me know)" | head -5)

{
    echo "*📧 DAILY EMAIL ACTION ITEMS*"
    date +"_%A-%B-%d_"
    echo

    if [ -n "$URGENT" ]; then
        echo "🚨 *URGENT - Reply Today:*"
        echo "$URGENT" | sed "s/^/• /"
        echo
    fi

    if [ -n "$OPPORTUNITIES" ]; then
        echo "💰 *OPPORTUNITIES - Reply Soon:*"
        echo "$OPPORTUNITIES" | sed "s/^/• /"
        echo
    fi

    if [ -n "$REPLIES_NEEDED" ]; then
        echo "📩 *REPLIES NEEDED:*"
        echo "$REPLIES_NEEDED" | sed "s/^/• /"
        echo
    fi

    if [ -z "$URGENT" ] && [ -z "$OPPORTUNITIES" ] && [ -z "$REPLIES_NEEDED" ]; then
        echo "✅ No urgent action items today."
        echo
        echo "*Tip:* Archive or delete emails to maintain inbox zero."
        echo
    fi

    echo "_RedQueen Systems | Email Intelligence_"
} > "$SUMMARY_FILE"

echo "[$DATE] Analysis written to $SUMMARY_FILE" >> "$LOG_FILE"
