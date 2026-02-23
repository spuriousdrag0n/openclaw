#!/bin/bash
# Daily Executive Summary for Simon Tadros
# Runs at 8:00 AM daily

export GOG_ACCOUNT=spuriousdragon@gmail.com
LOG_FILE="/var/log/daily-executive-summary.log"
DATE=$(date '+%Y-%m-%d %H:%M')

echo "[$DATE] Starting daily executive summary..." >> $LOG_FILE

# Get unread emails from last 24h
EMAILS=$(gog gmail search 'newer_than:1d is:unread' --max 30 --json 2>/dev/null)

# Get today's calendar events
CAL_EVENTS=$(gog calendar events primary --from $(date -I)T00:00:00Z --to $(date -d '+1 day' -I)T00:00:00Z --json 2>/dev/null)

# Check for critical alerts
CONTABO_ALERT=$(echo "$EMAILS" | grep -i "contabo.*payment.*due" | head -1)
OPENAI_ALERT=$(echo "$EMAILS" | grep -i "openai.*payment" | head -1)
GCLOUD_ALERT=$(echo "$EMAILS" | grep -i "google cloud.*billing\|project.*suspension" | head -1)
ETHIQ_DOWN=$(echo "$EMAILS" | grep -i "ethiq.*down\|monitor is down" | head -1)
ABUSE_ALERT=$(echo "$EMAILS" | grep -i "abuse.*complaint" | head -1)

# Check for opportunities
CRYPTO_REWARDS=$(echo "$EMAILS" | grep -iE "(usdt|claim.*reward|airdrop)" | head -3)
EVENT_OPPS=$(echo "$EMAILS" | grep -iE "(event|conference|speaking|pitch)" | head -3)

# Get weather for user's location (Byblos/Jbeil)
WEATHER=$(curl -s 'https://wttr.in/34.1208,35.6500?format=%C|%t|%w|%h' 2>/dev/null || echo "Weather unavailable|N/A|N/A|N/A")
WEATHER_COND=$(echo "$WEATHER" | cut -d'|' -f1)
WEATHER_TEMP=$(echo "$WEATHER" | cut -d'|' -f2)
WEATHER_WIND=$(echo "$WEATHER" | cut -d'|' -f3)

# Build summary message
SUMMARY="📊 DAILY EXECUTIVE SUMMARY - $(date '+%A, %B %d')

🌤️ WEATHER: Byblos (Jbeil), Lebanon
Condition: $WEATHER_COND
Temp: $WEATHER_TEMP | Wind: $WEATHER_WIND"

📅 CALENDAR: Today
"

if [ "$CAL_EVENTS" == "{\"events\":[],\"nextPageToken\":\"\"}" ] || [ -z "$CAL_EVENTS" ]; then
    SUMMARY+="No meetings scheduled. Free day for execution.
"
else
    SUMMARY+="$(echo "$CAL_EVENTS" | jq -r '.events[] | "• \" + .summary + " at " + (.start.dateTime // .start.date)' 2>/dev/null)
"
fi

SUMMARY+="
🚨 CRITICAL ALERTS:
"

ALERT_COUNT=0

if [ -n "$ETHIQ_DOWN" ]; then
    SUMMARY+="❌ ETHIQ.us IS DOWN - Check immediately
"
    ((ALERT_COUNT++))
fi

if [ -n "$CONTABO_ALERT" ]; then
    SUMMARY+="⚠️ Contabo payment due within 48h - Risk: Service suspension
"
    ((ALERT_COUNT++))
fi

if [ -n "$OPENAI_ALERT" ]; then
    SUMMARY+="⚠️ OpenAI Plus payment failed - Update billing method
"
    ((ALERT_COUNT++))
fi

if [ -n "$GCLOUD_ALERT" ]; then
    SUMMARY+="⚠️ Google Cloud billing past due - Project suspension risk
"
    ((ALERT_COUNT++))
fi

if [ -n "$ABUSE_ALERT" ]; then
    SUMMARY+="⚠️ VPS abuse complaint received - Review and respond
"
    ((ALERT_COUNT++))
fi

if [ $ALERT_COUNT -eq 0 ]; then
    SUMMARY+="✅ No critical infrastructure alerts
"
fi

SUMMARY+="
💰 MONEY OPPORTUNITIES:
"

if [ -n "$CRYPTO_REWARDS" ]; then
    SUMMARY+"$CRYPTO_REWARDS
"
else
    SUMMARY+"No crypto rewards detected in email
"
fi

SUMMARY+="
🎯 RECOMMENDED ACTIONS:
"

if [ -n "$ETHIQ_DOWN" ]; then
    SUMMARY+="1. [URGENT] Fix ETHIQ.us downtime
"
fi
if [ -n "$CONTABO_ALERT" ]; then
    SUMMARY+="2. Pay Contabo invoice
"
fi
if [ -n "$OPENAI_ALERT" ]; then
    SUMMARY+="3. Update OpenAI payment method
"
fi
if [ -n "$GCLOUD_ALERT" ]; then
    SUMMARY+="4. Resolve Google Cloud billing
"
fi

SUMMARY+="
📈 TRANSCENDENCE PROGRESS:
• Early crypto alpha: Monitor launchpads
• Trading bots: Review positions
• Upfront.gg: Track funding opportunities
• ETHIQ: Fix infrastructure
• Merkle Root: Client acquisition active

---
RedQueen Systems | Daily Brief"

# Send via WhatsApp
openclaw message send --to +96170224984 --message "$SUMMARY" 2>&1 >> $LOG_FILE

echo "[$DATE] Summary sent." >> $LOG_FILE
