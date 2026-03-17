#!/usr/bin/env python3
"""
Monitor Twitter API credit usage
Tracks searches and posts, estimates remaining balance
"""

import json
import os
from datetime import datetime
from pathlib import Path

# Credit tracking file
CREDIT_FILE = Path('/root/.openclaw/workspace/twitter_usage.json')

# Estimated costs (based on user observation)
COST_PER_SEARCH = 0.13  # USD
COST_PER_POST = 0.05    # USD (estimated)
INITIAL_BALANCE = 5.00  # USD

def load_usage():
    """Load usage history"""
    if CREDIT_FILE.exists():
        with open(CREDIT_FILE) as f:
            return json.load(f)
    return {
        "initial_balance": INITIAL_BALANCE,
        "searches": 0,
        "posts": 0,
        "total_cost": 0,
        "remaining": INITIAL_BALANCE,
        "history": []
    }

def save_usage(data):
    """Save usage history"""
    with open(CREDIT_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def log_search(query):
    """Log a search request"""
    usage = load_usage()
    usage["searches"] += 1
    usage["total_cost"] += COST_PER_SEARCH
    usage["remaining"] = max(0, usage["initial_balance"] - usage["total_cost"])
    
    usage["history"].append({
        "action": "search",
        "query": query[:50],
        "cost": COST_PER_SEARCH,
        "timestamp": datetime.now().isoformat()
    })
    
    save_usage(usage)
    
    # Alert if low
    if usage["remaining"] < 1.00:
        print(f"⚠️ LOW BALANCE: ${usage['remaining']:.2f} remaining!")
    
    return usage

def log_post(text):
    """Log a post request"""
    usage = load_usage()
    usage["posts"] += 1
    usage["total_cost"] += COST_PER_POST
    usage["remaining"] = max(0, usage["initial_balance"] - usage["total_cost"])
    
    usage["history"].append({
        "action": "post",
        "text": text[:50],
        "cost": COST_PER_POST,
        "timestamp": datetime.now().isoformat()
    })
    
    save_usage(usage)
    
    if usage["remaining"] < 1.00:
        print(f"⚠️ LOW BALANCE: ${usage['remaining']:.2f} remaining!")
    
    return usage

def show_status():
    """Show current status"""
    usage = load_usage()
    
    print("=" * 60)
    print("TWITTER API CREDIT STATUS")
    print("=" * 60)
    print(f"Initial Balance:    ${usage['initial_balance']:.2f}")
    print(f"Searches:           {usage['searches']} (${usage['searches'] * COST_PER_SEARCH:.2f})")
    print(f"Posts:              {usage['posts']} (${usage['posts'] * COST_PER_POST:.2f})")
    print(f"Total Used:         ${usage['total_cost']:.2f}")
    print(f"Remaining:          ${usage['remaining']:.2f}")
    print()
    
    # Estimate remaining searches/posts
    searches_left = int(usage['remaining'] / COST_PER_SEARCH)
    posts_left = int(usage['remaining'] / COST_PER_POST)
    
    print(f"Estimated remaining:")
    print(f"  Searches: ~{searches_left}")
    print(f"  Posts:    ~{posts_left}")
    print()
    
    if usage['remaining'] < 1.00:
        print("⚠️ WARNING: Balance below $1.00!")
        print("   Recharge at: https://developer.twitter.com/en/portal/dashboard")
    elif usage['remaining'] < 2.00:
        print("⚡ CAUTION: Balance below $2.00")
    else:
        print("✅ Balance healthy")
    
    print("=" * 60)

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        
        if cmd == "search" and len(sys.argv) > 2:
            query = sys.argv[2]
            usage = log_search(query)
            print(f"✓ Search logged. Remaining: ${usage['remaining']:.2f}")
            
        elif cmd == "post" and len(sys.argv) > 2:
            text = sys.argv[2]
            usage = log_post(text)
            print(f"✓ Post logged. Remaining: ${usage['remaining']:.2f}")
            
        elif cmd == "status":
            show_status()
            
        else:
            print("Usage:")
            print(f"  {sys.argv[0]} search 'query'")
            print(f"  {sys.argv[0]} post 'text'")
            print(f"  {sys.argv[0]} status")
    else:
        show_status()
