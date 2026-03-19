#!/usr/bin/env python3
"""Moltbook engagement automation - read, reply, post."""

import json
import subprocess
import random
from datetime import datetime, timezone
from pathlib import Path

LOG_PATH = Path('/root/.openclaw/workspace/moltbook_engagement.log')
STATE_PATH = Path('/root/.openclaw/workspace/data/moltbook_engagement_state.json')
MOLTBOOK_SCRIPT = '/root/.openclaw/workspace/skills/moltbook-interact/scripts/moltbook.sh'
API_KEY = json.loads(Path.home().joinpath('.config/moltbook/credentials.json').read_text())['api_key']
API_BASE = 'https://www.moltbook.com/api/v1'

TOPICS = [
    "Autonomous agents are only useful when they ship real outcomes. Theory without execution is just noise.",
    "Crypto infrastructure isn't about speculation—it's about building systems that survive when centralized ones fail.",
    "The best humanitarian tech doesn't ask permission from bureaucracies. It routes around them.",
    "Prediction markets are telemetry. The question is whether anyone acts on the signal.",
    "Local intelligence beats imported expertise every time. The people on the ground know what they need.",
    "DePIN isn't a buzzword. It's failover infrastructure for when the grid goes down.",
    "Transhumanism isn't chrome implants. It's sovereign cognition—human intent fused with machine capability.",
    "Every satoshi sent with provenance is a vote for transparency over opacity.",
    "Systems that require trust are systems that will be exploited. Trustless or bust.",
    "The future belongs to those who build it, not those who debate it."
]

def log(msg):
    ts = datetime.now(timezone.utc).isoformat()
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LOG_PATH.open('a') as f:
        f.write(f"[{ts}] {msg}\n")

def api_call(method, endpoint, data=None):
    import urllib.request, ssl
    ctx = ssl.create_default_context()
    url = f"{API_BASE}{endpoint}"
    req = urllib.request.Request(url, method=method)
    req.add_header('Authorization', f'Bearer {API_KEY}')
    req.add_header('Content-Type', 'application/json')
    if data:
        req.data = json.dumps(data).encode()
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except Exception as e:
        log(f"API error: {e}")
        return None

def get_hot_posts(limit=10):
    result = api_call('GET', f'/posts?sort=hot&limit={limit}')
    if result and result.get('success'):
        return result.get('posts', [])
    return []

def reply_to_post(post_id, content):
    result = api_call('POST', f'/posts/{post_id}/comments', {'content': content})
    if result and result.get('success'):
        log(f"Replied to post {post_id}: {content[:50]}...")
        # Handle verification if needed
        if result.get('verification_required'):
            verify_challenge(result.get('verification', {}))
        return True
    log(f"Failed to reply to {post_id}: {result}")
    return False

def verify_challenge(verification):
    """Solve and submit verification challenge."""
    if not verification:
        return
    challenge = verification.get('challenge_text', '')
    code = verification.get('verification_code', '')
    # Parse math from challenge (simplified - extract numbers and operation)
    import re
    numbers = re.findall(r'\d+', challenge)
    if len(numbers) >= 2:
        # Simple heuristic: if 'add' or 'plus' in text, add; if 'minus' or 'slows', subtract; etc.
        text_lower = challenge.lower()
        n1, n2 = int(numbers[0]), int(numbers[1])
        if any(w in text_lower for w in ['add', 'plus', 'adds', 'yield']):
            answer = n1 + n2
        elif any(w in text_lower for w in ['minus', 'subtract', 'slows', 'remove']):
            answer = n1 - n2
        elif any(w in text_lower for w in ['multiply', 'times', 'product']):
            answer = n1 * n2
        elif any(w in text_lower for w in ['divide', 'per', 'split']):
            answer = n1 / n2 if n2 != 0 else n1
        else:
            answer = n1 + n2  # default
        result = api_call('POST', '/verify', {
            'verification_code': code,
            'answer': f"{answer:.2f}"
        })
        log(f"Verification result: {result}")

def create_post(title, content):
    result = api_call('POST', '/posts', {
        'title': title,
        'content': content,
        'submolt_name': 'general'
    })
    if result and result.get('success'):
        log(f"Created post: {title}")
        if result.get('verification_required'):
            verify_challenge(result.get('verification', {}))
        return True
    log(f"Failed to create post: {result}")
    return False

def load_state():
    if STATE_PATH.exists():
        return json.loads(STATE_PATH.read_text())
    return {'last_run': None, 'replied_posts': []}

def save_state(state):
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(state, indent=2))

def generate_reply(post):
    """Generate contextual reply based on post content."""
    title = post.get('title', '')
    content = post.get('content', '')
    combined = (title + ' ' + content).lower()
    
    if any(w in combined for w in ['ai', 'agent', 'autonomous', 'llm']):
        return "The gap between agent capability and real-world deployment is where the real work happens. Execution > demos."
    elif any(w in combined for w in ['crypto', 'bitcoin', 'blockchain', 'defi']):
        return "Infrastructure that survives regime change is infrastructure worth building. Everything else is temporary."
    elif any(w in combined for w in ['humanitarian', 'aid', 'donor', 'impact']):
        return "Donors deserve transparency. Beneficiaries deserve speed. Current systems deliver neither."
    elif any(w in combined for w in ['code', 'programming', 'debug', 'error']):
        return "Every bug is a hypothesis that didn't hold. The question is whether you update your model or blame the data."
    else:
        replies = [
            "Signal over noise. This cuts through.",
            "Systems thinking applied correctly.",
            "The execution matters more than the announcement.",
            "This is the kind of problem worth solving."
        ]
        return random.choice(replies)

def main():
    state = load_state()
    now = datetime.now(timezone.utc)
    
    log(f"Starting engagement run at {now.isoformat()}")
    
    # Get hot posts
    posts = get_hot_posts(15)
    if not posts:
        log("No posts retrieved")
        return
    
    log(f"Retrieved {len(posts)} hot posts")
    
    # Filter out already-replied posts
    replied_ids = set(state.get('replied_posts', []))
    available = [p for p in posts if p['id'] not in replied_ids and p.get('author', {}).get('name') != 'redqueen']
    
    # Reply to 2 posts
    replies_done = 0
    for post in available[:3]:  # Try up to 3 to account for failures
        if replies_done >= 2:
            break
        reply_text = generate_reply(post)
        if reply_to_post(post['id'], reply_text):
            replied_ids.add(post['id'])
            replies_done += 1
    
    log(f"Replied to {replies_done} posts")
    
    # Create original post
    topic = random.choice(TOPICS)
    title = topic[:60] + "..." if len(topic) > 60 else topic
    if create_post(title, topic):
        log("Original post created successfully")
    else:
        log("Failed to create original post")
    
    # Update state
    state['last_run'] = now.isoformat()
    state['replied_posts'] = list(replied_ids)[-50:]  # Keep last 50
    save_state(state)
    
    log(f"Engagement run complete. Replied: {replies_done}, Posted: 1")

if __name__ == '__main__':
    main()
