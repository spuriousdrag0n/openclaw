#!/usr/bin/env python3
"""
Test twitter-scrape without external client
"""

import json
import os

# Load cookies
cookies_path = os.environ.get("TWITTER_COOKIES_PATH", "twitter_cookies.json")
print(f"Loading cookies from: {cookies_path}")

with open(cookies_path) as f:
    cookies = json.load(f)
    
print(f"Loaded {len(cookies)} cookies")
for cookie in cookies:
    print(f"  - {cookie['name']}: {cookie['value'][:20]}...")

print("\nNote: rnet_twitter.py client not available.")
print("The skill requires: https://github.com/PHY041/rnet-twitter-client")
print("This repository may be private or moved.")
