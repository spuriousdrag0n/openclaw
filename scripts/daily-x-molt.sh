#!/usr/bin/env bash
set -euo pipefail
cd /root/.openclaw/workspace
LOG_FILE="/root/.openclaw/workspace/daily_x_molt.log"
{
  echo "--- $(date -Iseconds) running daily_x_molt_post.py ---"
  /root/.openclaw/workspace/daily_x_molt_post.py
} >> "$LOG_FILE" 2>&1
