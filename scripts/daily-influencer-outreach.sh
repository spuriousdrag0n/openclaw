#!/bin/bash
# Daily Influencer Outreach Script
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
# Sends AI influencer solution pitches to crypto/human rights contacts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/var/log/influencer-outreach.log"
TRACKING_FILE="$WORKSPACE_DIR/data/outreach-tracking.json"
ACCOUNT="spuriousdragon@gmail.com"

# Ensure tracking directory exists
mkdir -p "$WORKSPACE_DIR/data"

# Define contacts array (name|email|organization|type)
declare -a CONTACTS=(
    "Neeraj Agrawal|neeraj@coincenter.org|Coin Center|policy"
    "Peter Van Valkenburgh|peter@coincenter.org|Coin Center|policy"
    "Coin Center General|info@coincenter.org|Coin Center|policy"
    "Jillian York|jilliancyork@gmail.com|Author/Activist|rights"
    "Alex Gladstein|alex@gladstein.org|HRF|bitcoin"
    "HRF General|info@hrf.org|Human Rights Foundation|rights"
    "Mart Belcher|mart@martbelcher.com|Bitcoin Legal|bitcoin"
    "Anita Posch|hello@anitaposch.com|Bitcoin Educator|bitcoin"
    "Roya Mahboob|roya@womensannex.org|Digital Citizen Fund|rights"
    "Farida Nabourema|farida@faridanabourema.com|Activist|rights"
    "Filecoin Foundation|hello@fil.org|Filecoin|web3"
    "Protocol Labs|contact@protocol.ai|Protocol Labs|web3"
    "Access Now|hello@accessnow.org|Digital Rights|rights"
    "EFF|info@eff.org|Electronic Frontier Foundation|rights"
    "Open Money Initiative|hello@openmoneyinitiative.org|Bitcoin|bitcoin"
    "Bitcoin Policy Institute|info@policy.institute|BPI|policy"
    "C4|info@cryptoconsortium.org|Crypto Consortium|education"
    "Digital Currency Initiative|dci@media.mit.edu|MIT DCI|research"
    "Blockchain Association|info@theblockchainassociation.org|Industry|policy"
)

# Email template
SUBJECT="AI Influencer Solutions for Brand Growth - Partnership Opportunity"

send_email() {
    local name="$1"
    local email="$2"
    local org="$3"
    local type="$4"
    
    local BODY="Hi $name,

I'm Simon Tadros, founder of Merkle Root — we build AI-driven influencer systems for brands and agencies.

We're working with companies like Tesliya (entertainment streaming) to create AI brand ambassadors that:

• Generate 10x more content at 1% of traditional influencer costs
• Speak 50+ languages with perfect localization
• Are 100% brand-safe (no scandals, no drama)
• Own your audience data (no platform dependency)

Given your work at $org in the $type space, I thought there might be a fit — either for your organization directly or for brands in your network.

**Quick value props:**
- $500/month operational cost vs $50K-500K for human macro-influencers
- 200-300 content pieces per month vs 20-30
- Same persona, infinite markets

We've put together a case study and technical framework. Happy to share if there's interest.

Worth a 15-min call?

Best,
Simon Tadros
Merkle Root | https://merkleroot.io
+961 70 224 984 (WhatsApp)"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sending to: $name <$email> ($org)" >> "$LOG_FILE"
    
    if gog gmail send \
        --account "$ACCOUNT" \
        --to "$email" \
        --subject "$SUBJECT" \
        --body "$BODY" 2>> "$LOG_FILE"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $email" >> "$LOG_FILE"
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAILED: $email" >> "$LOG_FILE"
        return 1
    fi
}

# Initialize tracking file if doesn't exist
if [[ ! -f "$TRACKING_FILE" ]]; then
    echo '{"contacts": {},"last_run": null,"total_sent": 0}' > "$TRACKING_FILE"
fi

# Get contacts to email today (max 3 per day to avoid spam)
TODAY=$(date '+%Y-%m-%d')
SENT_TODAY=0
MAX_DAILY=3

# Read tracking data
if command -v jq &> /dev/null; then
    LAST_RUN=$(jq -r '.last_run // empty' "$TRACKING_FILE" 2>/dev/null)
    TOTAL_SENT=$(jq -r '.total_sent // 0' "$TRACKING_FILE" 2>/dev/null)
else
    LAST_RUN=""
    TOTAL_SENT=0
fi

# If already ran today, exit
if [[ "$LAST_RUN" == "$TODAY" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Already ran today. Exiting." >> "$LOG_FILE"
    exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting daily outreach..." >> "$LOG_FILE"

# Loop through contacts and send to those not yet contacted
for contact in "${CONTACTS[@]}"; do
    IFS='|' read -r name email org type <<< "$contact"
    
    # Check if already contacted (using email as key)
    EMAIL_KEY=$(echo "$email" | tr '.' '_')
    if command -v jq &> /dev/null; then
        CONTACTED=$(jq -r ".contacts[\"$EMAIL_KEY\"].contacted // false" "$TRACKING_FILE" 2>/dev/null)
    else
        CONTACTED="false"
    fi
    
    if [[ "$CONTACTED" == "true" ]]; then
        continue
    fi
    
    # Send email
    if send_email "$name" "$email" "$org" "$type"; then
        ((SENT_TODAY++))
        TOTAL_SENT=$((TOTAL_SENT + 1))
        
        # Update tracking
        if command -v jq &> /dev/null; then
            jq --arg key "$EMAIL_KEY" \
               --arg date "$TODAY" \
               '.contacts[$key] = {"contacted": true, "date": $date}' \
               "$TRACKING_FILE" > "$TRACKING_FILE.tmp" && mv "$TRACKING_FILE.tmp" "$TRACKING_FILE"
        fi
    fi
    
    # Stop if max reached
    if [[ $SENT_TODAY -ge $MAX_DAILY ]]; then
        break
    fi
    
    # Sleep to avoid rate limits
    sleep 5
done

# Update tracking file
if command -v jq &> /dev/null; then
    jq --arg date "$TODAY" \
       --argjson total "$TOTAL_SENT" \
       '.last_run = $date | .total_sent = $total' \
       "$TRACKING_FILE" > "$TRACKING_FILE.tmp" && mv "$TRACKING_FILE.tmp" "$TRACKING_FILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed. Sent: $SENT_TODAY, Total: $TOTAL_SENT" >> "$LOG_FILE"
