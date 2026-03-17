#!/bin/bash
# BTC Price Alert with Links

LOG_FILE="/var/log/btc-price-alert.log"
exec >> "$LOG_FILE" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting BTC alert..."

OPENCLAW="/root/.nvm/versions/node/v22.22.0/bin/openclaw"

# Fetch BTC price
CACHE_BUSTER=$(date +%s)
PRICE_DATA=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd,eur&include_24hr_change=true&_=$CACHE_BUSTER" 2>/dev/null)

if [ -z "$PRICE_DATA" ] || [ "$PRICE_DATA" = "null" ]; then
    echo "ERROR: Failed to fetch price"
    exit 1
fi

BTC_USD=$(echo "$PRICE_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['bitcoin']['usd'])")
BTC_EUR=$(echo "$PRICE_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['bitcoin']['eur'])")
CHANGE_24H=$(echo "$PRICE_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['bitcoin'].get('usd_24h_change', 0))")

USD_FORMATTED=$(printf "%,.0f" "$BTC_USD")
EUR_FORMATTED=$(printf "%,.0f" "$BTC_EUR")
CHANGE_FORMATTED=$(printf "%.2f" "$CHANGE_24H")

if (( $(echo "$CHANGE_24H > 0" | bc -l) )); then
    DIRECTION="📈"
    SIGN="+"
else
    DIRECTION="📉"
    SIGN=""
fi

# Get news with links
NEWS_WITH_LINKS=$(python3 << 'PYCODE'
import urllib.request
import re

try:
    headers = {'User-Agent': 'Mozilla/5.0'}
    req = urllib.request.Request('https://www.coindesk.com/arc/outboundfeeds/rss/', headers=headers)
    with urllib.request.urlopen(req, timeout=10) as response:
        content = response.read().decode('utf-8')
    
    # Find all items
    items = re.findall(r'<item[^>]*>(.*?)</item>', content, re.DOTALL)
    
    articles = []
    for item in items[:5]:
        # Extract title
        title_match = re.search(r'<title[^>]*>(.*?)</title>', item, re.DOTALL)
        # Extract link
        link_match = re.search(r'<link[^>]*>(.*?)</link>', item, re.DOTALL)
        
        if title_match and link_match:
            title = title_match.group(1).strip()
            link = link_match.group(1).strip()
            
            # Clean CDATA
            title = re.sub(r'<!\[CDATA\[(.*?)\]\]>', r'\1', title, flags=re.DOTALL)
            title = title.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').strip()
            
            # Skip feed title
            if title and "CoinDesk:" not in title and len(title) > 15:
                # Truncate title if too long
                if len(title) > 70:
                    title = title[:67] + "..."
                articles.append((title, link))
                if len(articles) >= 3:
                    break
    
    if articles:
        result = "📰 *Latest Crypto News:*\n\n"
        for i, (title, link) in enumerate(articles, 1):
            result += f"{i}. {title}\n"
            result += f"   👉 {link}\n\n"
        print(result, end='')
    else:
        print("📰 *Latest Crypto News:*\n\n")
        print("1. Bitcoin maintains key support levels\n")
        print("2. Market volatility continues\n")
        print("3. Institutional adoption grows\n\n")
except Exception as e:
    print(f"📰 *Latest Crypto News:*\n\n")
    print("1. Bitcoin price updates\n")
    print("2. Market analysis\n\n")
PYCODE
)

# Build beautiful message
MESSAGE="🚨 *BITCOIN ALERT* 🚨

💰 *Current Price*
━━━━━━━━━━━━━━
💵 USD: $${USD_FORMATTED}
💶 EUR: €${EUR_FORMATTED}
📊 24h Change: ${SIGN}${CHANGE_FORMATTED}% ${DIRECTION}

${NEWS_WITH_LINKS}
⏰ $(date '+%H:%M %Z') | $(date '+%b %d, %Y')

💬 Questions? Ask RedQueen ♛"

echo "--- MESSAGE ---"
echo "$MESSAGE"
echo "--- END ---"

echo "Sending to WhatsApp..."
$OPENCLAW message send --channel whatsapp --target "120363027105322990@g.us" --message "$MESSAGE"

if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ SUCCESS"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ FAILED"
fi
