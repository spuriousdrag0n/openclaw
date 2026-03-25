#!/bin/bash
export PATH="/root/.nvm/versions/node/v22.22.0/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
source /root/.openclaw/workspace/scripts/env-setup.sh
# BTC Price Alert with WhatsApp delivery

LOG_FILE="/var/log/btc-price-alert.log"
exec >> "$LOG_FILE" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting BTC alert..."

SUMMARY_DIR="/root/.openclaw/workspace/data/btc-alerts"
mkdir -p "$SUMMARY_DIR"
SUMMARY_FILE="$SUMMARY_DIR/$(date '+%Y-%m-%d-%H%M').txt"

# WhatsApp group for BTC alerts
WHATSAPP_GROUP="120363027105322990@g.us"

# Fetch BTC price
CACHE_BUSTER=$(date +%s)
PRICE_DATA=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd,eur&include_24hr_change=true&_=$CACHE_BUSTER" 2>/dev/null)

if [ -z "$PRICE_DATA" ] || [ "$PRICE_DATA" = "null" ]; then
    echo "ERROR: Failed to fetch price" | tee "$SUMMARY_FILE"
    exit 1
fi

BTC_USD=$(echo "$PRICE_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['bitcoin']['usd'])")
BTC_EUR=$(echo "$PRICE_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['bitcoin']['eur'])")
CHANGE_24H=$(echo "$PRICE_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['bitcoin'].get('usd_24h_change', 0))")

USD_FORMATTED=$(printf "%'.0f" "$BTC_USD")
EUR_FORMATTED=$(printf "%'.0f" "$BTC_EUR")
CHANGE_FORMATTED=$(printf "%.2f" "$CHANGE_24H")

if (( $(echo "$CHANGE_24H > 0" | bc -l) )); then
    DIRECTION="📈"
    SIGN="+"
else
    DIRECTION="📉"
    SIGN=""
fi

NEWS_WITH_LINKS=$(python3 << 'PYCODE'
import urllib.request
import re

def clean(text):
    text = re.sub(r'<!\[CDATA\[(.*?)\]\]>', r'\1', text, flags=re.DOTALL)
    return text.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').strip()

try:
    headers = {'User-Agent': 'Mozilla/5.0'}
    req = urllib.request.Request('https://www.coindesk.com/arc/outboundfeeds/rss/', headers=headers)
    with urllib.request.urlopen(req, timeout=10) as response:
        content = response.read().decode('utf-8')

    items = re.findall(r'<item[^>]*>(.*?)</item>', content, re.DOTALL)
    articles = []
    for item in items:
        title_match = re.search(r'<title[^>]*>(.*?)</title>', item, re.DOTALL)
        link_match = re.search(r'<link[^>]*>(.*?)</link>', item, re.DOTALL)
        if title_match and link_match:
            title = clean(title_match.group(1))
            link = clean(link_match.group(1))
            if not title or "CoinDesk:" in title or len(title) <= 15:
                continue
            if len(title) > 70:
                title = title[:67] + "..."
            articles.append((title, link))
        if len(articles) >= 3:
            break
except Exception:
    articles = []

if not articles:
    print("📰 Latest Crypto News:\n1. Bitcoin price updates\n2. Market analysis\n3. Institutional flows")
else:
    print("📰 Latest Crypto News:")
    for idx, (title, link) in enumerate(articles, 1):
        print(f"{idx}. {title}\n   👉 {link}")
PYCODE
)

MESSAGE=$(cat <<MSG
🚨 BITCOIN ALERT 🚨

💰 Current Price
━━━━━━━━━━━━━━
💵 USD: \$${USD_FORMATTED}
💶 EUR: €${EUR_FORMATTED}
📊 24h Change: ${SIGN}${CHANGE_FORMATTED}% ${DIRECTION}

${NEWS_WITH_LINKS}

⏰ $(date '+%H:%M %Z') | $(date '+%b %d, %Y')
MSG
)

# Save to file
printf '%s\n' "$MESSAGE" | tee "$SUMMARY_FILE"

# Send to WhatsApp group
/root/.nvm/versions/node/v22.22.0/bin/openclaw message send --channel whatsapp --target "$WHATSAPP_GROUP" --message "$MESSAGE"

if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BTC alert sent to WhatsApp group and saved to $SUMMARY_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to send WhatsApp message, but saved to $SUMMARY_FILE"
fi
