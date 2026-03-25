#!/usr/bin/env python3
"""
MerkleRoot WhatsApp Ad Sender
Pulls contacts from gog, sends to next contact every run.
"""
import json
import subprocess
import os
import sys
import re
from datetime import datetime

STATE_DIR = "/root/.openclaw/workspace/data"
STATE_FILE = f"{STATE_DIR}/whatsapp_ad_state.json"
SENT_FILE = f"{STATE_DIR}/whatsapp_ad_sent_numbers.json"
LOG_FILE = "/var/log/merkleroot-ad.log"

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

def normalize_phone(phone_str):
    """Normalize phone number to standard format for deduplication"""
    if not phone_str:
        return None
    cleaned = re.sub(r'[^\d+]', '', phone_str)
    if not cleaned:
        return None
    if not cleaned.startswith('+'):
        return None
    if len(cleaned) < 10:
        return None
    return cleaned

def clean_phone(phone_str):
    """Clean and format phone number from various formats"""
    if not phone_str:
        return None
    cleaned = re.sub(r'[^\d+]', '', phone_str)
    if not cleaned:
        return None
    if cleaned.startswith('+'):
        return cleaned if len(cleaned) >= 10 else None
    if cleaned.startswith('0'):
        return '+961' + cleaned[1:]
    if len(cleaned) == 8:
        return '+961' + cleaned
    if len(cleaned) >= 7:
        return '+' + cleaned
    return None

def extract_phone_from_line(line):
    """Extract phone from gog contacts output"""
    line_without_resource = re.sub(r'^people/c\d+\s+', '', line)
    
    plus_match = re.search(r'\+\d[\d\s]*$', line_without_resource.strip())
    if plus_match:
        phone = clean_phone(plus_match.group(0))
        if phone and len(phone) >= 10:
            return phone
    
    digit_match = re.search(r'\d[\d\s]*\d$', line_without_resource.strip())
    if digit_match:
        phone = clean_phone(digit_match.group(0))
        if phone and len(phone) >= 10:
            return phone
    
    return None

def get_contacts():
    """Fetch all contacts with phone numbers from gog"""
    try:
        result = subprocess.run(
            ["gog", "contacts", "list", "--limit", "2000"],
            capture_output=True, text=True, timeout=300
        )
        
        if result.returncode != 0:
            log(f"ERROR: gog failed: {result.stderr}")
            return []
        
        contacts = []
        lines = result.stdout.strip().split("\n")
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('RESOURCE'):
                continue
            if not line.startswith('people/'):
                continue
            
            phone = extract_phone_from_line(line)
            if phone and len(phone) >= 10:
                contacts.append(phone)
        
        log(f"Found {len(contacts)} contacts from gog")
        return contacts
    except Exception as e:
        log(f"ERROR fetching contacts: {e}")
        import traceback
        log(traceback.format_exc())
        return []

def load_state():
    default = {"index": 0, "total_contacts": 0, "last_run": None}
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

def load_sent_numbers():
    """Load set of already sent numbers"""
    try:
        if os.path.exists(SENT_FILE):
            with open(SENT_FILE, "r") as f:
                data = json.load(f)
                return set(data.get("sent", []))
    except Exception as e:
        log(f"ERROR loading sent numbers: {e}")
    return set()

def save_sent_numbers(sent_set):
    """Save set of sent numbers"""
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(SENT_FILE, "w") as f:
            json.dump({"sent": list(sent_set)}, f, indent=2)
    except Exception as e:
        log(f"ERROR saving sent numbers: {e}")

def send_whatsapp_ad(phone):
    try:
        trigger = {
            "action": "send_whatsapp_ad",
            "campaign": "merkleroot",
            "target": phone,
            "timestamp": datetime.now().isoformat(),
            "image": AD_IMAGE,
            "caption": AD_CAPTION
        }
        trigger_file = f"{STATE_DIR}/whatsapp_ad_trigger.json"
        with open(trigger_file, "w") as f:
            json.dump(trigger, f, indent=2)
        log(f"Trigger created for {phone}")
        return True
    except Exception as e:
        log(f"ERROR creating trigger: {e}")
        return False

def main():
    log("=== MerkleRoot Ad Sender Starting ===")
    
    state = load_state()
    sent_numbers = load_sent_numbers()
    current_index = state.get("index", 0)
    
    log(f"Current index: {current_index}")
    log(f"Already sent to {len(sent_numbers)} unique numbers")
    
    # Get contacts
    contacts = get_contacts()
    if not contacts:
        log("ERROR: No contacts found")
        sys.exit(1)
    
    # Deduplicate contacts by normalized phone number
    unique_contacts = []
    seen_normalized = set()
    for phone in contacts:
        normalized = normalize_phone(phone)
        if normalized and normalized not in seen_normalized:
            seen_normalized.add(normalized)
            unique_contacts.append(phone)
    
    total = len(unique_contacts)
    log(f"Total unique contacts: {total}")
    
    # Find next unsent contact starting from current index
    target = None
    attempts = 0
    start_index = current_index % total
    
    while attempts < total:
        idx = (start_index + attempts) % total
        candidate = unique_contacts[idx]
        normalized = normalize_phone(candidate)
        
        if normalized and normalized not in sent_numbers:
            target = candidate
            current_index = idx
            break
        
        attempts += 1
    
    if not target:
        log("All contacts have been sent to. Resetting sent list.")
        sent_numbers.clear()
        target = unique_contacts[0]
        current_index = 0
    
    log(f"Target: {current_index + 1}/{total} -> {target}")
    
    if send_whatsapp_ad(target):
        # Mark as sent
        normalized = normalize_phone(target)
        if normalized:
            sent_numbers.add(normalized)
            save_sent_numbers(sent_numbers)
        
        # Update index to next position
        state["index"] = (current_index + 1) % total
        state["total_contacts"] = total
        state["last_run"] = datetime.now().isoformat()
        save_state(state)
        log(f"SUCCESS: Next index = {state['index']}, Total sent = {len(sent_numbers)}")
    else:
        log("FAILED")
        sys.exit(1)

if __name__ == "__main__":
    main()
