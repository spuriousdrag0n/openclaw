#!/bin/bash
# BTC Price Alert Script - Runs every 6 hours
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
# Fetches BTC price and sends WhatsApp alert

WORKSPACE_DIR="/root/.openclaw/workspace"
LOG_FILE="/var/log/btc-price-alert.log"
DATA_FILE="$WORKSPACE_DIR/data/btc-last-price.json"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TARGET_GROUP="120363027105322990@g.us"

# Ensure data directory exists
mkdir -p "$WORKSPACE_DIR/data"

# Fetch BTC price from CryptoCompare API
BTC_DATA=$(curl -s "https://min-api.cryptocompare.com/data/price?fsym=BTC&tsyms=USD,EUR" 2>/dev/null)

if [[ -z "$BTC_DATA" ]]; then
    echo "[$TIMESTAMP] ERROR: Failed to fetch BTC price" >> "$LOG_FILE"
    exit 1
fi

BTC_USD=$(echo "$BTC_DATA" | jq -r '.USD // empty')
BTC_EUR=$(echo "$BTC_DATA" | jq -r '.EUR // empty')

if [[ -z "$BTC_USD" || -z "$BTC_EUR" ]]; then
    echo "[$TIMESTAMP] ERROR: Invalid price data received" >> "$LOG_FILE"
    exit 1
fi

# Format price with commas
BTC_USD_FMT=$(echo "$BTC_USD" | awk '{printf "%.0f", $0}' | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
BTC_EUR_FMT=$(echo "$BTC_EUR" | awk '{printf "%.0f", $0}' | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')

# Calculate change if previous price exists
CHANGE_MSG=""
if [[ -f "$DATA_FILE" ]]; then
    LAST_USD=$(jq -r '.usd // empty' "$DATA_FILE")
    if [[ -n "$LAST_USD" && "$LAST_USD" != "0" ]]; then
        CHANGE=$(echo "scale=2; (($BTC_USD - $LAST_USD) / $LAST_USD) * 100" | bc -l 2>/dev/null)
        if [[ -n "$CHANGE" ]]; then
            if (( $(echo "$CHANGE >= 0" | bc -l) )); then
                CHANGE_MSG="📈 +${CHANGE}%"
            else
                CHANGE_MSG="📉 ${CHANGE}%"
            fi
        fi
    fi
fi

# Save current price for next comparison
echo "{\"usd\": $BTC_USD, \"eur\": $BTC_EUR, \"timestamp\": \"$TIMESTAMP\"}" > "$DATA_FILE"
# Fetch crypto news from CoinDesk RSS
NEWS=$(curl -s "https://www.coindesk.com/arc/outboundfeeds/rss/" 2>/dev/null | \
    grep -oP '(?<=<title>)<!\[CDATA\[.*?\]\]>|[^<]+' | \
    grep -v "CoinDesk" | \
    head -4 | \
    sed 's/<!\[CDATA\[//;s/\]\]>//' | \
    sed 's/^/• /')

if [[ -z "$NEWS" ]]; then
    NEWS="• No major headlines"
fi

# Build alert message
MESSAGE="*🟠 BTC Price Alert*

💰 *\$${BTC_USD_FMT}* USD
💶 *€${BTC_EUR_FMT}* EUR

${CHANGE_MSG}

*📰 Headlines:*
${NEWS}

_Updated: $TIMESTAMP_"

# Send via WhatsApp using message tool
# Note: This requires the message tool to be available
if command -v openclaw &> /dev/null; then
    # Try to send via openclaw message command
    openclaw message send \
        --channel whatsapp \
        --target "$TARGET_GROUP" \
        --message "$MESSAGE" 2>> "$LOG_FILE"
    
    if [[ $? -eq 0 ]]; then
        echo "[$TIMESTAMP] Alert sent: BTC \$${BTC_USD_FMT} (USD) / €${BTC_EUR_FMT} (EUR) $CHANGE_MSG" >> "$LOG_FILE"
    else
        echo "[$TIMESTAMP] ERROR: Failed to send WhatsApp message" >> "$LOG_FILE"
    fi
else
    echo "[$TIMESTAMP] ERROR: openclaw CLI not available" >> "$LOG_FILE"
    exit 1
fi
