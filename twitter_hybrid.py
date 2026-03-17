#!/usr/bin/env python3
"""
Hybrid Twitter: Bearer token for search, OAuth for posting
With credit tracking
"""

import tweepy
import json
import sys
import subprocess
from pathlib import Path

# Load credentials
with open('/root/.config/twitter/credentials.json') as f:
    creds = json.load(f)

class TwitterHybrid:
    def __init__(self):
        # Bearer token client (for search)
        self.search_client = tweepy.Client(bearer_token=creds['bearer_token'])
        
        # OAuth client (for posting)
        self.post_client = tweepy.Client(
            consumer_key=creds['api_key'],
            consumer_secret=creds['api_secret'],
            access_token=creds['access_token'],
            access_token_secret=creds['access_secret']
        )
    
    def search(self, query, count=10):
        """Search tweets using Bearer token (tracks cost)"""
        try:
            count = max(10, min(count, 100))
            
            tweets = self.search_client.search_recent_tweets(query=query, max_results=count)
            
            if tweets.data:
                print(f"✓ Found {len(tweets.data)} tweets for '{query}':\n")
                for i, tweet in enumerate(tweets.data, 1):
                    print(f"{i}. {tweet.text[:120]}...")
                    print()
                
                # Log usage
                subprocess.run([
                    'python3', '/root/.openclaw/workspace/twitter_credit_monitor.py',
                    'search', query
                ], capture_output=True)
                
                return tweets.data
            else:
                print("No tweets found")
                return []
                
        except Exception as e:
            print(f"✗ Search error: {e}")
            return []
    
    def post(self, text):
        """Post tweet using OAuth (tracks cost)"""
        try:
            tweet = self.post_client.create_tweet(text=text)
            print(f"✓ Tweet posted!")
            print(f"ID: {tweet.data['id']}")
            print(f"URL: https://twitter.com/i/web/status/{tweet.data['id']}")
            
            # Log usage
            subprocess.run([
                'python3', '/root/.openclaw/workspace/twitter_credit_monitor.py',
                'post', text
            ], capture_output=True)
            
            return tweet.data['id']
        except Exception as e:
            print(f"✗ Post error: {e}")
            return None

# CLI
if __name__ == "__main__":
    twitter = TwitterHybrid()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print(f"  {sys.argv[0]} search 'bitcoin' [count]")
        print(f"  {sys.argv[0]} post 'Your tweet'")
        print(f"  {sys.argv[0]} status")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "search":
        query = sys.argv[2] if len(sys.argv) > 2 else "crypto"
        count = int(sys.argv[3]) if len(sys.argv) > 3 else 10
        twitter.search(query, count)
        
    elif cmd == "post":
        text = sys.argv[2] if len(sys.argv) > 2 else "Test tweet"
        twitter.post(text)
        
    elif cmd == "status":
        subprocess.run(['python3', '/root/.openclaw/workspace/twitter_credit_monitor.py', 'status'])
        
    else:
        print(f"Unknown: {cmd}")
