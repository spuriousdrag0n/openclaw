#!/usr/bin/env python3
"""
MerkleRoot WhatsApp Ad Blaster
Sends ads directly via openclaw message send command.
"""
import json
import subprocess
import os
import sys
import re
import time
from datetime import datetime

STATE_DIR = "/root/.openclaw/workspace/data"
STATE_FILE = f"{STATE_DIR}/whatsapp_blast_state.json"
LOG_FILE = "/var/log/merkleroot-blast.log"
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
    if not line.strip() or line.startswith('#') or line.startswith('RESOURCE'):
        return None
    if not line.startswith('people/'):
        return None
    
    if len(line) <= 62:
        return None
    
    phone_col = line[62:].strip()
    if not phone_col:
        return None
    
    phone = normalize_phone(phone_col)
    if phone and phone.startswith('+') and len(re.sub(r'\D', '', phone)) >= 8:
        return phone
    return None

def get_contacts():
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
            log(f"gog failed: {result.stderr[:200]}")
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
        log(f"ERROR: {e}")
        return []

def load_state():
    default = {"sent": [], "completed": False}
    try:
        if os.path.exists(STATE_FILE):
            with open(STATE_FILE, "r") as f:
                return {**default, **json.load(f)}
    except:
        pass
    return default

def save_state(state):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    except Exception as e:
        log(f"ERROR saving state: {e}")

def send_ad(phone):
    try:
        result = subprocess.run(
            [
                "/usr/local/bin/openclaw", "message", "send",
                "--channel", "whatsapp",
                "--target", phone,
                "--media", AD_IMAGE,
                "--message", AD_CAPTION
            ],
            capture_output=True, text=True, timeout=60
        )
        
        if result.returncode == 0:
            log(f"✓ {phone}")
            return True
        else:
            log(f"✗ {phone}: {result.stderr[:100]}")
            return False
    except Exception as e:
        log(f"✗ {phone}: {e}")
        return False

def main():
    delay_seconds = int(sys.argv[1]) if len(sys.argv) > 1 else 60
    
    log(f"=== MerkleRoot Ad Blast Starting (delay={delay_seconds}s) ===")
    
    state = load_state()
    contacts = get_contacts()
    
    if not contacts:
        log("No contacts found")
        sys.exit(1)
    
    sent_list = set(state.get("sent", []))
    remaining = [c for c in contacts if c not in sent_list]
    
    log(f"Total: {len(contacts)} | Sent: {len(sent_list)} | Remaining: {len(remaining)}")
    
    if not remaining:
        log("All contacts processed")
        sys.exit(0)
    
    for i, phone in enumerate(remaining, 1):
        log(f"[{i}/{len(remaining)}] Sending to {phone}...")
        
        if send_ad(phone):
            sent_list.add(phone)
            state["sent"] = list(sent_list)
            state["last_run"] = datetime.now().isoformat()
            save_state(state)
        
        if i < len(remaining):
            time.sleep(delay_seconds)
    
    log(f"=== Blast Complete: {len(sent_list)}/{len(contacts)} sent ===")

if __name__ == "__main__":
    main()
