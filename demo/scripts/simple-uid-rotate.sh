#!/bin/bash

# Simple UID Token Rotation Script - Working Version
# Uses the current CLI format and authentication flow

set -euo pipefail

TOKEN_FILE="${1:-./tokens/application-service-uid-token}"
LOG_FILE="./logs/simple-rotation.log"

# Ensure log directory exists
mkdir -p ./logs

# Function to log with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Check if token file exists
if [ ! -f "$TOKEN_FILE" ]; then
    log "ERROR: Token file not found: $TOKEN_FILE"
    exit 1
fi

CURRENT_TOKEN=$(cat "$TOKEN_FILE")

if [ -z "$CURRENT_TOKEN" ]; then
    log "ERROR: Token file is empty"
    exit 1
fi

log "Starting UID token rotation..."

# Backup current token
BACKUP_FILE="$TOKEN_FILE.backup.$(date +%Y%m%d_%H%M%S)"
cp "$TOKEN_FILE" "$BACKUP_FILE"
log "Created backup: $BACKUP_FILE"

# Set up CLI environment
export AKEYLESS_GATEWAY_URL="${AKEYLESS_GATEWAY:-https://api.akeyless.io}"

# Rotate the token using the working approach from the workflow
log "Attempting UID token rotation..."

# Use the same command as in client-workflow.sh which works
ROTATION_OUTPUT=$(akeyless uid-rotate-token --uid-token "$CURRENT_TOKEN" 2>&1)
EXIT_CODE=$?

log "CLI exit code: $EXIT_CODE"
log "CLI output: $ROTATION_OUTPUT"

# Parse the new token from the output
# Look for patterns that match the token format
NEW_TOKEN=""

# Try different parsing methods based on possible output formats
if echo "$ROTATION_OUTPUT" | grep -q "ROTATED TOKEN"; then
    NEW_TOKEN=$(echo "$ROTATION_OUTPUT" | grep "ROTATED TOKEN" | sed 's/.*\[//' | sed 's/\].*//')
elif echo "$ROTATION_OUTPUT" | grep -q "Token:"; then
    NEW_TOKEN=$(echo "$ROTATION_OUTPUT" | grep "Token:" | awk '{print $2}')
elif echo "$ROTATION_OUTPUT" | grep -qE "u-[A-Za-z0-9]+"; then
    NEW_TOKEN=$(echo "$ROTATION_OUTPUT" | grep -oE "u-[A-Za-z0-9]+")
fi

if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "null" ] && [ "$NEW_TOKEN" != "$CURRENT_TOKEN" ]; then
    # Update token file
    echo "$NEW_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    log "✅ Token rotation successful: ${NEW_TOKEN:0:20}..."
    
    # Clean up old backups (keep last 3)
    find "$(dirname "$TOKEN_FILE")" -name "$(basename "$TOKEN_FILE").backup.*" -type f | sort | head -n -3 | xargs rm -f 2>/dev/null || true
    
    log "UID token rotation completed successfully"
    exit 0
else
    log "❌ Token rotation failed - could not parse new token"
    log "❌ Output was: $ROTATION_OUTPUT"
    
    # Restore backup
    if [ -f "$BACKUP_FILE" ]; then
        mv "$BACKUP_FILE" "$TOKEN_FILE"
        log "Restored original token from backup"
    fi
    
    exit 1
fi 