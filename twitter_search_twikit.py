#!/usr/bin/env python3
"""
Twitter search using twikit (unofficial) 
+ Official API for posting
"""

import asyncio
import json
import sys
from pathlib import Path

# Add twikit to path
from twikit import Client

# Load credentials
with open('/root/.config/twitter/credentials.json') as f:
    creds = json.load(f)

# Initialize twikit client
client = Client(language='en-US')

async def search_tweets(query, count=20):
    """Search tweets using twikit (no API limits)"""
    try:
        # Login with credentials
        await client.login(
            auth_info_1='spuriousdragon@gmail.com',  # Your Twitter email
            password='Avadakadavra##33'  # Your Twitter password
        )
        
        # Search tweets
        tweets = await client.search_tweet(query, count=count)
        
        print(f"Found {len(tweets)} tweets for: {query}\n")
        
        for tweet in tweets:
            print(f"[@{tweet.user.screen_name}] {tweet.text[:100]}...")
            print(f"Likes: {tweet.favorite_count} | RTs: {tweet.retweet_count}")
            print(f"Date: {tweet.created_at}")
            print("-" * 60)
            
    except Exception as e:
        print(f"Error: {e}")
        print("\nNote: Twikit requires Twitter username/password, not API keys")

if __name__ == "__main__":
    query = sys.argv[1] if len(sys.argv) > 1 else "crypto"
    count = int(sys.argv[2]) if len(sys.argv) > 2 else 20
    
    asyncio.run(search_tweets(query, count))
