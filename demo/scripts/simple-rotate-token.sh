#!/bin/bash

# ---------------------------------------------------------------------
# Akeyless Universal Identity Token Rotation Script
# Simple version aligned with official Akeyless script approach
# ---------------------------------------------------------------------

set -euo pipefail

AKEYLESS_BIN="akeyless"
THIS_EXEC=$(basename $0)
TOKEN_FILE="${HOME}/.akeyless-uid-token"
LOG_FILE="${HOME}/.akeyless-rotation.log"

# Simple logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "${LOG_FILE}"
}

# Initialize Universal Identity token
run_init() {
    echo "Akeyless Universal Identity Token Setup"
    echo "======================================"
    
    read -sp 'Enter initial Universal Identity Token: ' init_token
    echo ""
    
    if [ "${init_token}" != "" ]; then
        echo "${init_token}" > "${TOKEN_FILE}"
        chmod 600 "${TOKEN_FILE}"
        
        log "Universal Identity token initialized successfully"
        
        # Set up cron job for rotation (hourly instead of every minute)
        CRON_JOB="0 * * * * ${USER} /bin/bash ${PWD}/${THIS_EXEC} rotate ${TOKEN_FILE}"
        
        if [[ "$OSTYPE" == "linux"* ]]; then
            echo "${CRON_JOB}" > ~/.akeyless_uid_rotator
            sudo mv ~/.akeyless_uid_rotator /etc/cron.d/akeyless_uid_rotator
            sudo chown root:root /etc/cron.d/akeyless_uid_rotator
            sudo chmod 644 /etc/cron.d/akeyless_uid_rotator
            log "Cron job installed for hourly token rotation"
        else
            (crontab -l 2>/dev/null | grep -v "${THIS_EXEC} rotate" ; echo "0 * * * * bash ${PWD}/${THIS_EXEC} rotate ${TOKEN_FILE}") | crontab -
            log "Cron job added for hourly token rotation"
        fi
        
        echo "✅ Akeyless Universal Identity successfully initiated"
        echo "✅ Hourly rotation scheduled"
        
    else
        echo "❌ Error: empty token provided"
        exit 1
    fi
}

# Rotate the token
run_rotate() {
    [ "$1" != "" ] && TOKEN_FILE="$1"
    
    if [ ! -f "${TOKEN_FILE}" ]; then
        log "ERROR: Token file not found: ${TOKEN_FILE}"
        exit 1
    fi
    
    CURRENT_TOKEN=$(cat "${TOKEN_FILE}")
    
    if [ -z "${CURRENT_TOKEN}" ]; then
        log "ERROR: Token file is empty"
        exit 1
    fi
    
    log "Rotating UID token..."
    
    # Backup current token
    cp "${TOKEN_FILE}" "${TOKEN_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Try rotation with JSON format first (updated CLI syntax)
    log "Attempting rotation with JSON format..."
    ROTATION_OUTPUT=$(${AKEYLESS_BIN} uid-rotate-token --uid-token "${CURRENT_TOKEN}" --json 2>&1)
    ROTATION_EXIT_CODE=$?
    
    log "Rotation output: $ROTATION_OUTPUT"
    
    if [ $ROTATION_EXIT_CODE -eq 0 ] && [ "$ROTATION_OUTPUT" != "null" ] && [ -n "$ROTATION_OUTPUT" ]; then
        # Try to parse JSON if jq is available
        if command -v jq >/dev/null 2>&1; then
            NEW_TOKEN=$(echo "$ROTATION_OUTPUT" | jq -r '.token' 2>/dev/null)
            if [ "$NEW_TOKEN" != "null" ] && [ -n "$NEW_TOKEN" ]; then
                echo "${NEW_TOKEN}" > "${TOKEN_FILE}"
                chmod 600 "${TOKEN_FILE}"
                log "Token rotation successful (JSON): ${NEW_TOKEN:0:20}..."
                # Clean up old backups (keep last 3)
                find "$(dirname "${TOKEN_FILE}")" -name "$(basename "${TOKEN_FILE}").backup.*" -type f | sort | head -n -3 | xargs rm -f 2>/dev/null || true
                exit 0
            fi
        fi
        
        # If JSON parsing failed but output exists, try to use raw output
        if [ "$ROTATION_OUTPUT" != "null" ] && [ -n "$ROTATION_OUTPUT" ]; then
            echo "${ROTATION_OUTPUT}" > "${TOKEN_FILE}"
            chmod 600 "${TOKEN_FILE}"
            log "Token rotation successful (raw JSON): ${ROTATION_OUTPUT:0:20}..."
            # Clean up old backups (keep last 3)
            find "$(dirname "${TOKEN_FILE}")" -name "$(basename "${TOKEN_FILE}").backup.*" -type f | sort | head -n -3 | xargs rm -f 2>/dev/null || true
            exit 0
        fi
    fi
    
    # Fallback to simple format (no flags)
    log "JSON format failed, trying simple format..."
    ROTATION_OUTPUT=$(${AKEYLESS_BIN} uid-rotate-token --uid-token "${CURRENT_TOKEN}" 2>&1)
    ROTATION_EXIT_CODE=$?
    
    log "Simple format output: $ROTATION_OUTPUT"
    
    if [ $ROTATION_EXIT_CODE -eq 0 ] && [ "$ROTATION_OUTPUT" != "null" ] && [ -n "$ROTATION_OUTPUT" ]; then
        echo "${ROTATION_OUTPUT}" > "${TOKEN_FILE}"
        chmod 600 "${TOKEN_FILE}"
        log "Token rotation successful (simple): ${ROTATION_OUTPUT:0:20}..."
        # Clean up old backups (keep last 3)
        find "$(dirname "${TOKEN_FILE}")" -name "$(basename "${TOKEN_FILE}").backup.*" -type f | sort | head -n -3 | xargs rm -f 2>/dev/null || true
        exit 0
    fi
    
    # If all rotation attempts failed
    log "ERROR: All token rotation attempts failed"
    log "ERROR: Last output was: $ROTATION_OUTPUT"
    log "ERROR: This might indicate:"
    log "ERROR: 1. Token has expired or is invalid"
    log "ERROR: 2. Network connectivity issues"
    log "ERROR: 3. Gateway configuration problems"
    log "ERROR: 4. Insufficient permissions for rotation"
    
    # Restore backup if rotation failed
    if [ -f "${TOKEN_FILE}.backup.$(date +%Y%m%d_%H%M%S)" ]; then
        log "Restoring backup token due to rotation failure"
        mv "${TOKEN_FILE}.backup.$(date +%Y%m%d_%H%M%S)" "${TOKEN_FILE}"
    fi
    
    exit 1
}

# Show current token status
run_status() {
    if [ ! -f "${TOKEN_FILE}" ]; then
        echo "❌ No token file found: ${TOKEN_FILE}"
        exit 1
    fi
    
    CURRENT_TOKEN=$(cat "${TOKEN_FILE}")
    echo "Token file: ${TOKEN_FILE}"
    echo "Token: ${CURRENT_TOKEN:0:20}..."
    
    # Try to get token details
    if ${AKEYLESS_BIN} uid-list-children --uid-token "${CURRENT_TOKEN}" --format json >/dev/null 2>&1; then
        echo "✅ Token is valid"
        ${AKEYLESS_BIN} uid-list-children --uid-token "${CURRENT_TOKEN}" --format json | jq '.'
    else
        echo "❌ Token appears to be invalid or expired"
    fi
}

# Show usage
run_help() {
    echo "Akeyless Universal Identity Token Manager"
    echo "========================================"
    echo ""
    echo "Usage: $0 <command> [token_file]"
    echo ""
    echo "Commands:"
    echo "  init     - Initialize with new UID token and set up rotation"
    echo "  rotate   - Rotate existing UID token"
    echo "  status   - Check current token status"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 rotate"
    echo "  $0 rotate /path/to/custom/token"
    echo "  $0 status"
}

# Main execution
COMMAND="${1:-help}"

case "${COMMAND}" in
    init|rotate|status|help)
        if [ "$(type -t run_${COMMAND})" == "function" ]; then
            eval run_${COMMAND} "${2:-}"
        else
            echo "Error: Command function not found"
            run_help
            exit 1
        fi
        ;;
    *)
        echo "Error: Unknown command '${COMMAND}'"
        run_help
        exit 1
        ;;
esac 