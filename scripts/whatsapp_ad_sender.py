#!/usr/bin/env python3
"""WhatsApp Ad Sender - Uses agent trigger file"""
import json
import os
from datetime import datetime

TRIGGER_FILE = "/root/.openclaw/workspace/data/whatsapp_ad_trigger.json"
LOG_FILE = "/var/log/whatsapp-ad-agent.log"

def log(msg):
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.now().isoformat()}] {msg}\n")

def main():
    log("Python ad sender started")
    
    # Create trigger file for agent
    trigger = {
        "action": "send_whatsapp_ad",
        "timestamp": datetime.now().isoformat(),
        "source": "python_cron"
    }
    
    os.makedirs(os.path.dirname(TRIGGER_FILE), exist_ok=True)
    with open(TRIGGER_FILE, "w") as f:
        json.dump(trigger, f)
    
    log(f"Trigger file created at {TRIGGER_FILE}")
    print("WhatsApp ad trigger created. Agent will process.")

if __name__ == "__main__":
    main()
