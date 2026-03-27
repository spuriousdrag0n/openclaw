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
LOG_FILE = "/var/log/merkleroot-cron.log"
TRIGGER_FILE = f"{STATE_DIR}/whatsapp_ad_trigger.json"
AD_IMAGE = "/root/.openclaw/workspace/data/merkleroot_ad.jpg"

AD_CAPTION = '''DEPLOYMENTS START FROM $5,000 — SCALING TO $100,000+

MERKLERR00T × OPENCLAW
Code is Law.

This is not software.
This is your AI command infrastructure.

▪ Command your entire digital universe
▪ Deploy autonomous agents across all communications
▪ Execute real-world actions — instantly
▪ Trade, monitor & dominate financial markets
▪ Run prediction intelligence systems
▪ Deploy autonomous AI engineering teams
▪ Control servers, systems & physical infrastructure
▪ Generate revenue pipelines automatically
▪ Gather intelligence at global scale
▪ Execute any workflow, any logic, anywhere
▪ Operate 24/7 — without limits

Built for billionaires, operators & elite corporations.

You don't buy tools.
You deploy power.

Let's discuss:
https://wa.me/+96181381671'''

def log(msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{timestamp}] {msg}\n")
    print(msg)

def normalize_phone(phone):
    """Normalize phone to standard format"""
    if not phone:
        return None
    cleaned = re.sub(r'[^\d+]', '', phone)
    if not cleaned:
        return None
    if cleaned.startswith('+'):
        return cleaned
    elif cleaned.startswith('00'):
        return '+' + cleaned[2:]
    elif cleaned.startswith('0'):
        return '+961' + cleaned[1:]
    else:
        return '+961' + cleaned

def extract_phone_from_line(line):
    """Extract phone from gog contacts output - PHONE column starts at position 62"""
    if not line.strip() or line.startswith('#') or line.startswith('RESOURCE'):
        return None
    if not line.startswith('people/'):
        return None
    
    # PHONE column starts at position 62 in the fixed-width format
    if len(line) <= 62:
        return None
    
    phone_col = line[62:].strip()
    if not phone_col:
        return None
    
    # Normalize and validate
    phone = normalize_phone(phone_col)
    if phone and phone.startswith('+') and len(re.sub(r'\D', '', phone)) >= 8:
        return phone
    return None

def get_contacts():
    """Fetch all contacts with phone numbers from gog"""
    try:
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
        seen = set()
        for line in result.stdout.strip().split("\n"):
            phone = extract_phone_from_line(line)
            if phone and phone not in seen:
                seen.add(phone)
                contacts.append(phone)
        
        log(f"Found {len(contacts)} unique contacts")
        return contacts
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
            "timestamp": datetime.now().isoformat(),
            "image": AD_IMAGE,
            "caption": AD_CAPTION
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
    
    if state.get("completed"):
        log("All contacts already processed. Nothing to do.")
        sys.exit(0)
    
    contacts = get_contacts()
    if not contacts:
        log("ERROR: No contacts found")
        sys.exit(1)
    
    sent_list = state.get("sent", [])
    
    # Clean up any malformed entries from sent list
    cleaned_sent = []
    for s in sent_list:
        normalized = normalize_phone(s)
        if normalized and normalized not in cleaned_sent:
            cleaned_sent.append(normalized)
    sent_list = cleaned_sent
    
    remaining = [c for c in contacts if c not in sent_list]
    
    log(f"Total contacts: {len(contacts)}")
    log(f"Already sent: {len(sent_list)}")
    log(f"Remaining: {len(remaining)}")
    
    if not remaining:
        log("All contacts processed. Marking complete.")
        state["completed"] = True
        save_state(state)
        sys.exit(0)
    
    target = remaining[0]
    log(f"Creating trigger for: {target}")
    
    if send_whatsapp_ad(target):
        sent_list.append(target)
        state["sent"] = sent_list
        state["last_run"] = datetime.now().isoformat()
        
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
