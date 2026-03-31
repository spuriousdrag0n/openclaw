#!/usr/bin/env python3
"""
MerkleRoot WhatsApp Ad Sender (Cached Fallback Version)
Pulls contacts from gog, falls back to cache if gog fails.
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
CACHE_FILE = f"{STATE_DIR}/whatsapp_contacts_cache.json"
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

def load_state():
    try:
        with open(STATE_FILE, "r") as f:
            return json.load(f)
    except:
        return {"index": 0}

def save_state(state):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    except Exception as e:
        log(f"ERROR saving state: {e}")

def load_sent_numbers():
    try:
        with open(SENT_FILE, "r") as f:
            data = json.load(f)
            return set(data.get("sent", []))
    except:
        return set()

def save_sent_numbers(sent_set):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(SENT_FILE, "w") as f:
            json.dump({"sent": list(sent_set)}, f, indent=2)
    except Exception as e:
        log(f"ERROR saving sent numbers: {e}")

def get_contacts_from_gog():
    try:
        result = subprocess.run(
            ["gog", "contacts", "list", "--limit", "2000"],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            log(f"gog error: {result.stderr}")
            return None
        
        contacts = []
        for line in result.stdout.strip().split('\n'):
            line = line.strip()
            if not line or line.startswith('NAME'):
                continue
            parts = line.split()
            for part in parts:
                if '+' in part and len(part) > 8:
                    cleaned = normalize_phone(part)
                    if cleaned:
                        contacts.append(cleaned)
        return contacts if contacts else None
    except Exception as e:
        log(f"ERROR fetching from gog: {e}")
        return None

def get_contacts_from_cache():
    try:
        with open(CACHE_FILE, "r") as f:
            data = json.load(f)
            contacts = [c["phone"] for c in data.get("contacts", [])]
            log(f"Loaded {len(contacts)} contacts from cache")
            return contacts
    except Exception as e:
        log(f"ERROR loading cache: {e}")
        return None

def get_contacts():
    contacts = get_contacts_from_gog()
    if contacts:
        log(f"Fetched {len(contacts)} contacts from gog")
        return contacts
    log("Falling back to cached contacts")
    return get_contacts_from_cache()

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
    log("=== MerkleRoot Ad Sender (Cached) Starting ===")
    
    state = load_state()
    sent_numbers = load_sent_numbers()
    current_index = state.get("index", 0)
    
    log(f"Current index: {current_index}")
    log(f"Already sent to {len(sent_numbers)} unique numbers")
    
    contacts = get_contacts()
    if not contacts:
        log("ERROR: No contacts found from any source")
        sys.exit(1)
    
    unique_contacts = []
    seen = set()
    for phone in contacts:
        normalized = normalize_phone(phone)
        if normalized and normalized not in seen:
            seen.add(normalized)
            unique_contacts.append(phone)
    
    total = len(unique_contacts)
    log(f"Total unique contacts: {total}")
    
    target = None
    attempts = 0
    start_index = current_index % total if total > 0 else 0
    
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
        log("All contacts processed. Resetting.")
        sent_numbers.clear()
        target = unique_contacts[0] if unique_contacts else None
        current_index = 0
    
    if not target:
        log("ERROR: No valid target")
        sys.exit(1)
    
    log(f"Target: {current_index + 1}/{total} -> {target}")
    
    if send_whatsapp_ad(target):
        normalized = normalize_phone(target)
        if normalized:
            sent_numbers.add(normalized)
            save_sent_numbers(sent_numbers)
        
        state["index"] = (current_index + 1) % total
        state["last_run"] = datetime.now().isoformat()
        save_state(state)
        log(f"SUCCESS: Next index = {state['index']}, Total sent = {len(sent_numbers)}")
    else:
        log("FAILED")
        sys.exit(1)

if __name__ == "__main__":
    main()
