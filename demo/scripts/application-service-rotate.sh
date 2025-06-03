#!/bin/bash
# Automated rotation script for Application Service
# Deployed by Platform Engineer

TOKEN_FILE="./tokens/application-service-token"
LOG_FILE="./logs/rotation.log"

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

# Load current token
source "$TOKEN_FILE"

if [ -z "$UID_TOKEN" ]; then
    log "ERROR: UID_TOKEN not found in token file"
    exit 1
fi

log "Starting Application Service token rotation..."

# Backup current token
cp "$TOKEN_FILE" "$TOKEN_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Rotate token
ROTATION_OUTPUT=$(akeyless uid-rotate-token --uid-token "$UID_TOKEN" 2>&1)
NEW_TOKEN=$(echo "$ROTATION_OUTPUT" | grep -E "(ROTATED TOKEN|Token):" | sed 's/.*\[//' | sed 's/\].*//')

if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "null" ]; then
    # Update token file
    sed -i "s/UID_TOKEN=.*/UID_TOKEN=$NEW_TOKEN/" "$TOKEN_FILE"
    log "Application Service rotation successful: ${NEW_TOKEN:0:20}..."
else
    log "ERROR: Application Service rotation failed: $ROTATION_OUTPUT"
    exit 1
fi

# Clean up old backups (keep last 3)
find "$(dirname "$TOKEN_FILE")" -name "$(basename "$TOKEN_FILE").backup.*" -type f | sort | head -n -3 | xargs rm -f 2>/dev/null || true

log "Application Service rotation completed successfully"
