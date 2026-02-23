#!/bin/bash
# Workspace Backup Script - Runs every 2 days
# Backs up workspace and pushes to GitHub

WORKSPACE_DIR="/root/.openclaw/workspace"
BACKUP_DIR="$WORKSPACE_DIR/backups"
LOG_FILE="/var/log/workspace-backup.log"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting workspace backup..." >> "$LOG_FILE"

# Create local tarball backup
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/workspace_backup_$TIMESTAMP.tar.gz" \
    -C "$(dirname "$WORKSPACE_DIR")" \
    --exclude='*.tar.gz' \
    --exclude='.git/objects' \
    "$(basename "$WORKSPACE_DIR")" 2>> "$LOG_FILE"

if [[ $? -eq 0 ]]; then
    echo "[$DATE] Local backup created: workspace_backup_$TIMESTAMP.tar.gz" >> "$LOG_FILE"
else
    echo "[$DATE] ERROR: Local backup failed" >> "$LOG_FILE"
fi

# Git commit and push
cd "$WORKSPACE_DIR" || exit 1

# Check if there are changes to commit
if [[ -n $(git status --porcelain) ]]; then
    echo "[$DATE] Changes detected, committing..." >> "$LOG_FILE"
    
    # Add all changes
    git add -A 2>> "$LOG_FILE"
    
    # Commit with timestamp
    git commit -m "Auto-backup: $DATE" 2>> "$LOG_FILE"
    
    if [[ $? -eq 0 ]]; then
        echo "[$DATE] Commit successful" >> "$LOG_FILE"
        
        # Push to GitHub using token
        git remote set-url origin "https://spuriousdrag0n:$(gh auth token)@github.com/spuriousdrag0n/openclaw.git" 2>> "$LOG_FILE"
        
        if git push origin main 2>> "$LOG_FILE"; then
            echo "[$DATE] Push successful" >> "$LOG_FILE"
        else
            echo "[$DATE] ERROR: Push failed" >> "$LOG_FILE"
        fi
        
        # Reset remote URL to remove token
        git remote set-url origin "https://github.com/spuriousdrag0n/openclaw.git" 2>> "$LOG_FILE"
    else
        echo "[$DATE] ERROR: Commit failed" >> "$LOG_FILE"
    fi
else
    echo "[$DATE] No changes to commit" >> "$LOG_FILE"
fi

# Cleanup old backups (keep last 10)
ls -t "$BACKUP_DIR"/workspace_backup_*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm 2>> "$LOG_FILE"

echo "[$DATE] Backup complete." >> "$LOG_FILE"
