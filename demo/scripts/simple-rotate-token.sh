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
    
    # Rotate token using the new CLI format
    if NEW_TOKEN=$(${AKEYLESS_BIN} uid-rotate-token --uid-token "${CURRENT_TOKEN}" --format json 2>/dev/null | jq -r '.token' 2>/dev/null); then
        if [ "${NEW_TOKEN}" != "null" ] && [ -n "${NEW_TOKEN}" ]; then
            echo "${NEW_TOKEN}" > "${TOKEN_FILE}"
            chmod 600 "${TOKEN_FILE}"
            log "Token rotation successful: ${NEW_TOKEN:0:20}..."
        else
            log "ERROR: Token rotation returned invalid token"
            exit 1
        fi
    else
        # Fallback to simple format if JSON parsing fails
        ${AKEYLESS_BIN} uid-rotate-token --uid-token "${CURRENT_TOKEN}" > "${TOKEN_FILE}.tmp" 2>/dev/null
        if [ -s "${TOKEN_FILE}.tmp" ]; then
            mv "${TOKEN_FILE}.tmp" "${TOKEN_FILE}"
            chmod 600 "${TOKEN_FILE}"
            log "Token rotation successful (fallback method)"
        else
            log "ERROR: Token rotation failed"
            rm -f "${TOKEN_FILE}.tmp"
            exit 1
        fi
    fi
    
    # Clean up old backups (keep last 3)
    find "$(dirname "${TOKEN_FILE}")" -name "$(basename "${TOKEN_FILE}").backup.*" -type f | sort | head -n -3 | xargs rm -f 2>/dev/null || true
    
    exit 0
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