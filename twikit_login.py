#!/usr/bin/env python3
"""
Twikit initial login - saves cookies for future use
"""

import asyncio
import json
from pathlib import Path
from twikit import Client

# Twitter credentials
USERNAME = "spuriousdragon"
PASSWORD = "Avadakadavra##33"
EMAIL = "spuriousdragon@gmail.com"  # For verification if needed

# Cookie storage
COOKIE_PATH = Path('/root/.config/twitter/twikit_cookies.json')
COOKIE_PATH.parent.mkdir(parents=True, exist_ok=True)

async def login():
    client = Client(language='en-US')
    
    try:
        print("Logging into Twitter via twikit...")
        await client.login(
            auth_info_1=USERNAME,
            auth_info_2=EMAIL,  # Backup for verification
            password=PASSWORD
        )
        
        # Save cookies
        client.save_cookies(str(COOKIE_PATH))
        print(f"✓ Login successful!")
        print(f"✓ Cookies saved to: {COOKIE_PATH}")
        
        # Test search
        print("\nTesting search...")
        tweets = await client.search_tweet("crypto", count=5)
        print(f"✓ Found {len(tweets)} tweets")
        
        for tweet in tweets[:3]:
            print(f"  - @{tweet.user.screen_name}: {tweet.text[:60]}...")
        
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        print("\nPossible issues:")
        print("- Wrong username/password")
        print("- Account has 2FA enabled")
        print("- Twitter detected automation")
        return False

if __name__ == "__main__":
    success = asyncio.run(login())
    exit(0 if success else 1)
