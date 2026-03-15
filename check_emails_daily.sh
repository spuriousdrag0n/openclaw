#!/bin/bash
# Daily email check for Simon Tadros
# Checks: simon@merkler00t.com (IMAP) and spuriousdragon@gmail.com (gog)

LOG_FILE="/root/.openclaw/workspace/email_checks.log"
DATE=$(date '+%Y-%m-%d %H:%M')

echo "========================================" >> "$LOG_FILE"
echo "Email Check: $DATE" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Check 1: simon@merkler00t.com (forwardemail.net via IMAP)
echo "" >> "$LOG_FILE"
echo "--- simon@merkler00t.com ---" >> "$LOG_FILE"

python3 << 'PYEOF' >> "$LOG_FILE" 2>&1
import imaplib
import ssl
import email

EMAIL = "simon@merkler00t.com"
PASSWORD = "Avadakadavra##33"
IMAP_SERVER = "imap.forwardemail.net"

try:
    context = ssl.create_default_context()
    mail = imaplib.IMAP4_SSL(IMAP_SERVER, 993, ssl_context=context)
    mail.login(EMAIL, PASSWORD)
    mail.select("INBOX")
    
    status, messages = mail.search(None, 'ALL')
    total = len(messages[0].split())
    
    status, unseen = mail.search(None, 'UNSEEN')
    unread = len(unseen[0].split()) if unseen[0] else 0
    
    today = datetime.now().strftime("%d-%b-%Y")
    status, today_msgs = mail.search(None, f'ON {today}')
    today_count = len(today_msgs[0].split()) if today_msgs[0] else 0
    
    print(f"Total: {total} | Unread: {unread} | Today: {today_count}")
    
    if messages[0]:
        last_3 = messages[0].split()[-3:]
        print("Last 3:")
        for msg_id in reversed(last_3):
            status, msg_data = mail.fetch(msg_id, '(RFC822)')
            raw_email = msg_data[0][1]
            email_message = email.message_from_bytes(raw_email)
            subject = email_message['Subject'][:40]
            from_addr = email_message['From'][:30]
            print(f"  - {from_addr}: {subject}")
    
    mail.logout()
    print("✓ OK")
    
except Exception as e:
    print(f"✗ Error: {e}")
PYEOF

# Check 2: spuriousdragon@gmail.com (via gog)
echo "" >> "$LOG_FILE"
echo "--- spuriousdragon@gmail.com (Gmail) ---" >> "$LOG_FILE"

gog gmail search 'newer_than:1d' --max 5 --account spuriousdragon@gmail.com --json 2>/dev/null | python3 << 'PYEOF' >> "$LOG_FILE" 2>&1
import json
import sys

try:
    data = json.load(sys.stdin)
    emails = data.get('messages', [])
    
    print(f"Recent emails: {len(emails)}")
    
    for msg in emails[:3]:
        subject = msg.get('subject', 'No subject')[:40]
        from_addr = msg.get('from', 'Unknown')[:30]
        print(f"  - {from_addr}: {subject}")
    
    print("✓ OK")
except Exception as e:
    print(f"✗ Error: {e}")
PYEOF

echo "" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "Completed at $(date '+%H:%M')" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
