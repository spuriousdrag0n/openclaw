#!/bin/bash
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export GOG_ACCOUNT=spuriousdragon@gmail.com
LOG_FILE="/var/log/email-action-items.log"
DATE=$(date +%Y-%m-%d-%H:%M)
TARGET="120363027105322990@g.us"

echo "[$DATE] Starting email analysis..." >> $LOG_FILE

# Get unread emails from last 24h
EMAILS_JSON=$(gog gmail search "newer_than:1d" --max 20 --json 2>/dev/null)

if [ -z "$EMAILS_JSON" ] || [ "$EMAILS_JSON" = "{\"threads\":[]}" ]; then
    MSG="*📧 Daily Email Check*

No new emails requiring action.

_$(date +%A-%B-%d)_"
    openclaw message send --channel whatsapp --target "$TARGET" --message "$MSG" 2>&1 >> $LOG_FILE
    echo "[$DATE] No emails found" >> $LOG_FILE
    exit 0
fi

# Extract actionable items
URGENT=$(echo "$EMAILS_JSON" | grep -iE "(urgent|asap|deadline|payment due|invoice|suspension|abuse|complaint|legal|court|police)" | head -5)
OPPORTUNITIES=$(echo "$EMAILS_JSON" | grep -iE "(opportunity|partnership|investment|funding|grant|pitch|speaking|event|conference|reward|airdrop|claim)" | head -5)
REPLIES_NEEDED=$(echo "$EMAILS_JSON" | grep -iE "(re:|fw:|question|can you|could you|please respond|waiting for your|let me know)" | head -5)

# Build action items message
MSG="*📧 DAILY EMAIL ACTION ITEMS*
_$(date +%A-%B-%d)_

"

# Urgent section
if [ -n "$URGENT" ]; then
    MSG+="🚨 *URGENT - Reply Today:*
"
    MSG+=$(echo "$URGENT" | sed "s/^/• /")
    MSG+="

"
fi

# Opportunities section
if [ -n "$OPPORTUNITIES" ]; then
    MSG+="💰 *OPPORTUNITIES - Reply Soon:*
"
    MSG+=$(echo "$OPPORTUNITIES" | sed "s/^/• /")
    MSG+="

"
fi

# Replies needed section
if [ -n "$REPLIES_NEEDED" ]; then
    MSG+="📩 *REPLIES NEEDED:*
"
    MSG+=$(echo "$REPLIES_NEEDED" | sed "s/^/• /")
    MSG+="

"
fi

# If nothing actionable found
if [ -z "$URGENT" ] && [ -z "$OPPORTUNITIES" ] && [ -z "$REPLIES_NEEDED" ]; then
    MSG+="✅ No urgent action items today.

*Tip:* Archive or delete emails to maintain inbox zero."
fi

MSG+="
_RedQueen Systems | Email Intelligence_"

# Send message
openclaw message send --channel whatsapp --target "$TARGET" --message "$MSG" 2>&1 >> $LOG_FILE
echo "[$DATE] Analysis sent" >> $LOG_FILE
