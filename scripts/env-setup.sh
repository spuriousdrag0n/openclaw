#!/bin/bash
# Universal environment setup for all OpenClaw cron scripts
# Source this at the beginning of every script

export PATH="/root/.nvm/versions/node/v22.22.0/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export HOME="/root"
export NODE_PATH="/root/.nvm/versions/node/v22.22.0/lib/node_modules"

# OpenClaw binary location
export OPENCLAW_BIN="/root/.nvm/versions/node/v22.22.0/bin/openclaw"

# Common directories
export WORKSPACE_DIR="/root/.openclaw/workspace"
export SCRIPTS_DIR="$WORKSPACE_DIR/scripts"
export DATA_DIR="$WORKSPACE_DIR/data"
export LOG_DIR="/var/log"
