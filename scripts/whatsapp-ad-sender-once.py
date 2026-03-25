#!/usr/bin/env python3
"""
MerkleRoot WhatsApp Ad Sender - One-time per contact
Sends to each contact once using trigger file method.
"""
import json
import subprocess
import os
import sys
import re
from datetime import datetime

STATE_DIR = "/root/.openclaw/workspace/data"
STATE_FILE = f"{STATE_DIR}/merkleroot_ad_state_once.json"
LOG_FILE = "/var/log/merkleroot-ad-once.log"
TRIGGER_FILE = f"{STATE_DIR}/whatsapp_ad_trigger.json"

def log(msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{timestamp}] {msg}\n")
    print(msg)

def extract_phone(line):
    """Extract phone number from gog output line"""
    if not line.strip() or line.startswith('#') or line.startswith('RESOURCE'):
        return None
    if not line.startswith('people/'):
        return None
    
    parts = line.strip().split()
    
    # Look for phone pattern at the end of the line
    # Collect trailing digit sequences
    phone_parts = []
    for part in reversed(parts):
        clean = part.replace('-', '')
        if clean.isdigit() or (clean.startswith('+') and clean[1:].isdigit()):
            phone_parts.insert(0, clean)
        else:
            break
    
    if phone_parts:
        raw_phone = ''.join(phone_parts)
        # Format the phone number
        if raw_phone.startswith('+'):
            return raw_phone
        elif raw_phone.startswith('00'):
            return '+' + raw_phone[2:]
        elif raw_phone.startswith('0'):
            # Lebanese local format 0X XXX XXX -> +961 X XXX XXX
            return '+961' + raw_phone[1:]
        else:
            # Assume Lebanese without leading 0
            return '+961' + raw_phone
    return None

def get_contacts():
    """Fetch all contacts with phone numbers from gog"""
    try:
        # Use full environment to ensure gog can find its credentials
        env = os.environ.copy()
        env['HOME'] = '/root'
        env['GOG_ACCOUNT'] = 'spuriousdragon@gmail.com'
        
        result = subprocess.run(
            ["/usr/local/bin/gog", "contacts", "list", "--limit", "2000"],
            capture_output=True, text=True, timeout=300,
            env=env
        )
        
        if result.returncode != 0:
            log(f"gog command failed with code {result.returncode}")
            log(f"stderr: {result.stderr[:200]}")
            return []
        
        contacts = []
        for line in result.stdout.strip().split("\n"):
            phone = extract_phone(line)
            if phone and len(phone) >= 10:
                contacts.append(phone)
        
        unique = list(set(contacts))
        log(f"Found {len(unique)} unique contacts")
        return unique
    except Exception as e:
        log(f"ERROR fetching contacts: {e}")
        import traceback
        log(traceback.format_exc())
        return []

def load_state():
    default = {"sent": [], "completed": False}
    try:
        if os.path.exists(STATE_FILE):
            with open(STATE_FILE, "r") as f:
                return {**default, **json.load(f)}
    except Exception as e:
        log(f"ERROR loading state: {e}")
    return default

def save_state(state):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    except Exception as e:
        log(f"ERROR saving state: {e}")

def send_whatsapp_ad(phone):
    """Create trigger file for HEARTBEAT.md to process"""
    try:
        trigger = {
            "action": "send_whatsapp_ad",
            "campaign": "merkleroot",
            "target": phone,
            "timestamp": datetime.now().isoformat()
        }
        
        with open(TRIGGER_FILE, "w") as f:
            json.dump(trigger, f, indent=2)
        
        log(f"Trigger created for {phone}")
        return True
    except Exception as e:
        log(f"ERROR creating trigger: {e}")
        return False

def main():
    log("=== MerkleRoot Ad Sender (Once-Per-Contact) Starting ===")
    
    # Check if there's already a pending trigger
    if os.path.exists(TRIGGER_FILE):
        log("Trigger file already exists. Waiting for HEARTBEAT to process.")
        sys.exit(0)
    
    state = load_state()
    
    # Check if already completed
    if state.get("completed"):
        log("All contacts already processed. Nothing to do.")
        sys.exit(0)
    
    contacts = get_contacts()
    if not contacts:
        log("ERROR: No contacts found")
        sys.exit(1)
    
    sent_list = state.get("sent", [])
    remaining = [c for c in contacts if c not in sent_list]
    
    log(f"Total contacts: {len(contacts)}")
    log(f"Already sent: {len(sent_list)}")
    log(f"Remaining: {len(remaining)}")
    
    if not remaining:
        log("All contacts processed. Marking complete.")
        state["completed"] = True
        save_state(state)
        sys.exit(0)
    
    # Send to next contact
    target = remaining[0]
    log(f"Creating trigger for: {target}")
    
    if send_whatsapp_ad(target):
        sent_list.append(target)
        state["sent"] = sent_list
        state["last_run"] = datetime.now().isoformat()
        
        # Check if complete after this send
        if len(sent_list) >= len(contacts):
            state["completed"] = True
            log("All contacts processed. Campaign complete.")
        
        save_state(state)
        log(f"Progress: {len(sent_list)}/{len(contacts)}")
        log("Trigger created. HEARTBEAT will process the send.")
    else:
        log("Trigger creation failed, will retry next run")
        sys.exit(1)

if __name__ == "__main__":
    main()
