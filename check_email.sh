#!/bin/bash
# Check email via IMAP

EMAIL="simon@merkler00t.com"
PASSWORD="Avadakadavra##33"
IMAP_SERVER="imap.forwardemail.net"
IMAP_PORT="993"

echo "Checking email for $EMAIL..."
echo "Server: $IMAP_SERVER:$IMAP_PORT"
echo ""

# Use openssl to connect and check inbox
openssl s_client -connect $IMAP_SERVER:$IMAP_PORT -crlf 2>/dev/null << EOF | grep -E "^\* |OK|NO|BAD" | head -30
A1 LOGIN $EMAIL $PASSWORD
A2 SELECT INBOX
A3 STATUS INBOX (MESSAGES UNSEEN)
A4 LOGOUT
EOF

