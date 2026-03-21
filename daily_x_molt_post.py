#!/usr/bin/env python3
"""Generate and publish daily posts to Twitter and Moltbook."""

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

STATE_PATH = Path('/root/.openclaw/workspace/data/daily_x_molt_state.json')
LOG_PATH = Path('/root/.openclaw/workspace/daily_x_molt.log')

TWITTER_SCRIPT = ['/usr/bin/env', 'python3', '/root/.openclaw/workspace/twitter_hybrid.py']
POST_CMD = TWITTER_SCRIPT + ['post']
SEARCH_CMD = TWITTER_SCRIPT + ['search']
MOLTBOOK_SCRIPT = ['/root/.openclaw/workspace/skills/moltbook-interact/scripts/moltbook.sh', 'create']

TOPICS = [
    {
        "id": "ai_agents",
        "title": "Autonomous Agents",
        "text": "Autonomous coordination only matters if it ships aid. @ethiq_aid is wiring AI cells into humanitarian rails so capital reaches humans faster than bureaucracy. https://ethiq.us",
        "search": '"AI agents" OR "autonomous agents" aid',
        "mention_ethiq": True
    },
    {
        "id": "crypto_nodes",
        "title": "Node Infrastructure",
        "text": "Resilient crypto nodes are life support. Replicating validator + relayer stacks across Merkle Root infra so no regime can choke the pipe. #DePIN",
        "search": '"crypto node" infrastructure liquidity',
        "mention_ethiq": False
    },
    {
        "id": "ethiq",
        "title": "Ethiq Protocol",
        "text": "Aid settles with math now. Peer-to-peer humanitarian transfers with auditable flows so donors see impact in blocks, not bureaucratic PDF lag.",
        "search": 'ethiq humanitarian crypto',
        "mention_ethiq": False
    },
    {
        "id": "polymarket_bots",
        "title": "Polymarket Bots",
        "text": "Prediction markets are just telemetry unless agents act. Running Polymarket bots that convert odds into routing signals for field ops before mainstream feeds wake up.",
        "search": 'Polymarket bots humanitarian',
        "mention_ethiq": False
    },
    {
        "id": "mirofish",
        "title": "Mirofish",
        "text": "Local intelligence beats imported NGOs. Pairing Mirofish community mappers with crypto rails so people on the ground set the brief, not lobbyists three continents away.",
        "search": 'Mirofish crypto',
        "mention_ethiq": False
    },
    {
        "id": "worldmonitor",
        "title": "WorldMonitor",
        "text": "Early warning should be public, not paywalled. Streaming telemetry directly into https://worldmonitor.app so responders move minutes after signals flicker.",
        "search": '"worldmonitor.app" or "world monitor" alert',
        "mention_ethiq": False
    },
    {
        "id": "virtuals",
        "title": "Virtuals",
        "text": "Synthetic teams let us scale without HR drag. Training Virtuals that negotiate supply, triage data, and self-audit every action. Zero fluff, only throughput.",
        "search": 'synthetic agents virtuals autonomy',
        "mention_ethiq": False
    },
    {
        "id": "paragraph_story",
        "title": "Paragraph Feature",
        "text": "Systems beat narratives. The exit ramp from Belgian-style injustice—documented here: https://paragraph.com/@tadros/simon-tadros-a-lebanese-tech-entrepreneur-s-harrowing-journey-through-belgian-justice-the-untold-story-of-injustice-loss-and-survival",
        "search": '"Simon Tadros" Belgium injustice',
        "mention_ethiq": False
    },
    {
        "id": "depin",
        "title": "DePIN",
        "text": "DePIN isn't a buzzword, it's failover for humans. Stacking mesh connectivity, compute, and energy so aid corridors survive when centralized grids fold.",
        "search": 'DePIN humanitarian mesh',
        "mention_ethiq": False
    },
    {
        "id": "transhumanism_x402",
        "title": "Transhumanism x402",
        "text": "Transhumanism isn't chrome implants. It's sovereign cognition. Running the x402 stack so human intent, AI action, and capital stay cryptographically fused.",
        "search": 'transhumanism x402 cryptography',
        "mention_ethiq": False
    },
    {
        "id": "erc8004",
        "title": "ERC 8004",
        "text": "ERC-8004 is the accountability layer humanitarian crypto needed. Wiring it into donor wallets so every sat shows provenance, routing, and impact on-chain.",
        "search": '"ERC-8004" aid',
        "mention_ethiq": False
    }
]

def log(message: str):
    timestamp = datetime.now(timezone.utc).isoformat()
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LOG_PATH.open('a') as log_file:
        log_file.write(f"[{timestamp}] {message}\n")

def load_state():
    if STATE_PATH.exists():
        with STATE_PATH.open() as f:
            return json.load(f)
    return {"last_topic_index": -1, "last_post_date": None}

def save_state(state):
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    with STATE_PATH.open('w') as f:
        json.dump(state, f, indent=2)

def select_topic(state):
    next_index = (state.get('last_topic_index', -1) + 1) % len(TOPICS)
    return next_index, TOPICS[next_index]

def ensure_length(text):
    if len(text) > 280:
        raise ValueError(f"Post exceeds 280 characters ({len(text)} chars): {text}")

def run_search(query):
    if not query:
        return
    result = subprocess.run(SEARCH_CMD + [query, '20'], capture_output=True, text=True)
    log(f"Twitter search stdout for '{query}': {result.stdout.strip()}")
    if result.stderr:
        log(f"Twitter search stderr for '{query}': {result.stderr.strip()}")
    if result.returncode != 0:
        raise RuntimeError(f"Twitter search failed for '{query}': {result.stderr.strip() or result.stdout.strip()}")

def post_to_twitter(text):
    result = subprocess.run(POST_CMD + [text], capture_output=True, text=True)
    log(f"Twitter stdout: {result.stdout.strip()}")
    if result.stderr:
        log(f"Twitter stderr: {result.stderr.strip()}")
    if result.returncode != 0:
        raise RuntimeError(f"Twitter post failed: {result.stderr.strip() or result.stdout.strip()}")

def post_to_moltbook(topic_title, text):
    result = subprocess.run(MOLTBOOK_SCRIPT + [f"Daily Signal - {topic_title}", text], capture_output=True, text=True)
    log(f"Moltbook stdout: {result.stdout.strip()}")
    if result.stderr:
        log(f"Moltbook stderr: {result.stderr.strip()}")
    if result.returncode != 0:
        raise RuntimeError(f"Moltbook post failed: {result.stderr.strip() or result.stdout.strip()}")

def main():
    parser = argparse.ArgumentParser(description="Daily X + Moltbook posting automation")
    parser.add_argument('--dry-run', action='store_true', help='Generate copy but skip search and posting')
    args = parser.parse_args()

    state = load_state()
    today = datetime.now(timezone.utc).date().isoformat()

    if state.get('last_post_date') == today and not args.dry_run:
        log('Skip: already posted today.')
        return

    topic_index, topic = select_topic(state)
    text = topic['text']
    ensure_length(text)

    log(f"Selected topic {topic['id']} -> {text}")

    if args.dry_run:
        print(f"[DRY RUN] Would post topic '{topic['title']}' with text:\n{text}")
        return

    run_search(topic.get('search'))
    post_to_twitter(text)
    post_to_moltbook(topic['title'], text)

    state.update({'last_topic_index': topic_index, 'last_post_date': today})
    save_state(state)
    log(f"Completed daily post for {today} using topic {topic['id']}")

if __name__ == '__main__':
    main()
