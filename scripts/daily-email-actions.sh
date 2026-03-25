#!/bin/bash
export PATH="/root/.nvm/versions/node/v22.22.0/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
source /root/.openclaw/workspace/scripts/env-setup.sh
LOG_FILE="/var/log/email-action-items.log"
DATE=$(date +%Y-%m-%d-%H:%M)
SUMMARY_DIR="/root/.openclaw/workspace/data/email-actions"
SUMMARY_FILE="$SUMMARY_DIR/$(date +%Y-%m-%d).txt"

# Email configuration
FROM_EMAIL="simon@merkler00t.com"
TO_EMAIL="simon@merkler00t.com"
SMTP_SERVER="smtp.forwardemail.net"
SMTP_PORT="587"
SMTP_USER="simon@merkler00t.com"
SMTP_PASS="Avadakadavra##33"

mkdir -p "$SUMMARY_DIR"

echo "[$DATE] Starting email analysis..." >> "$LOG_FILE"

cat > "$SUMMARY_FILE" << INNEREOF
📧 DAILY EMAIL ACTION ITEMS
$(date +"%A, %B %d")

INNEREOF

# Check simon@merkler00t.com via IMAP
python3 << PYEOF >> "$SUMMARY_FILE"
import imaplib
import email
from datetime import datetime, timedelta

try:
    mail = imaplib.IMAP4_SSL('imap.forwardemail.net', 993)
    mail.login('simon@merkler00t.com', 'Avadakadavra##33')
    mail.select('inbox')
    
    date = (datetime.now() - timedelta(days=1)).strftime("%d-%b-%Y")
    _, search_data = mail.search(None, f'(SINCE "{date}")')
    
    email_ids = search_data[0].split()
    
    urgent = []
    opportunities = []
    
    for e_id in email_ids[-15:]:
        _, data = mail.fetch(e_id, '(RFC822)')
        raw_email = data[0][1]
        msg = email.message_from_bytes(raw_email)
        subject = msg['subject'] or ''
        
        if '=?UTF-8?' in subject:
            try:
                subject = email.header.decode_header(subject)[0][0].decode('utf-8')
            except:
                pass
        
        if any(word in subject.lower() for word in ['urgent', 'asap', 'deadline', 'payment', 'invoice', 'suspension', 'legal', 'court', 'police']):
            urgent.append(subject)
        elif any(word in subject.lower() for word in ['opportunity', 'partnership', 'investment', 'funding', 'pitch', 'grant', 'speaking', 'event']):
            opportunities.append(subject)
    
    mail.logout()
    
    print(f"📧 simon@merkler00t.com:")
    if urgent:
        print("🚨 URGENT:")
        for s in urgent[:3]:
            print(f"• {s}")
        print("")
    if opportunities:
        print("💰 OPPORTUNITIES:")
        for s in opportunities[:3]:
            print(f"• {s}")
        print("")
    if not urgent and not opportunities:
        print("✅ No action items")
        print("")
            
except Exception as e:
    print(f"📧 simon@merkler00t.com: Error fetching emails ({str(e)})")
    print("")
PYEOF

echo "" >> "$SUMMARY_FILE"
echo "RedQueen Systems | Email Intelligence" >> "$SUMMARY_FILE"

# Send email via SMTP
SEND_RESULT=$(python3 << PYEOF
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

try:
    with open('$SUMMARY_FILE', 'r') as f:
        body = f.read()
    
    msg = MIMEMultipart()
    msg['From'] = '$FROM_EMAIL'
    msg['To'] = '$TO_EMAIL'
    msg['Subject'] = 'Daily Email Action Items - $(date +"%A, %B %d")'
    
    msg.attach(MIMEText(body, 'plain', 'utf-8'))
    
    server = smtplib.SMTP('$SMTP_SERVER', $SMTP_PORT)
    server.starttls()
    server.login('$SMTP_USER', '$SMTP_PASS')
    server.send_message(msg)
    server.quit()
    
    print("SUCCESS")
except Exception as e:
    print(f"FAILED: {str(e)}")
PYEOF
)

if [ "$SEND_RESULT" = "SUCCESS" ]; then
    echo "[$DATE] Email sent to $TO_EMAIL" >> "$LOG_FILE"
else
    echo "[$DATE] ERROR: $SEND_RESULT" >> "$LOG_FILE"
fi

echo "[$DATE] Analysis complete" >> "$LOG_FILE"
