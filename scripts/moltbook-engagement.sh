#!/usr/bin/env bash
set -euo pipefail
cd /root/.openclaw/workspace
LOG_FILE="/root/.openclaw/workspace/moltbook_engagement.log"
{
  echo "--- $(date -Iseconds) running moltbook_engagement.py ---"
  /root/.openclaw/workspace/moltbook_engagement.py
} >> "$LOG_FILE" 2>&1
