#!/bin/bash

echo "👷 PLATFORM ENGINEER: Deploying UID to Application Service"
echo "=========================================================="
echo ""
echo "This script represents the PLATFORM ENGINEER persona:"
echo "• Deploy admin-generated tokens to application services"
echo "• Set up automated rotation on application services"
echo "• Configure service identity infrastructure"
echo ""
echo "🔑 Key Point: Platform Engineer bridges Admin and Application Service"
echo ""

# Check for platform engineer credentials
if [ -z "$AKEYLESS_ACCESS_ID" ] || [ -z "$AKEYLESS_ACCESS_KEY" ]; then
    echo "❌ Platform Engineer credentials required:"
    echo "   export AKEYLESS_ACCESS_ID=\"your-admin-access-id\""
    echo "   export AKEYLESS_ACCESS_KEY=\"your-admin-access-key\""
    echo ""
    echo "💡 Platform Engineer typically uses admin-level credentials for deployment"
    exit 1
fi

# Check if admin has provisioned tokens
ADMIN_TOKEN_FILE="./tokens/client-tokens"

if [ ! -f "$ADMIN_TOKEN_FILE" ]; then
    echo "❌ Admin token file not found: $ADMIN_TOKEN_FILE"
    echo ""
    echo "Platform Engineer needs admin-generated tokens first."
    echo "Run: ./scripts/admin-setup.sh (as admin)"
    echo "Then: Platform Engineer can deploy to application services"
    exit 1
fi

echo "📂 Loading admin-generated tokens..."
source "$ADMIN_TOKEN_FILE"

echo "✅ Platform Engineer received from admin:"
echo "   - UID Token: ${UID_TOKEN:0:20}..."
echo "   - Access ID: $ACCESS_ID"
echo "   - Auth Method: $AUTH_METHOD"
echo ""

# Configure Platform Engineer CLI with admin credentials
echo "🔐 Configuring Platform Engineer CLI with admin credentials..."
akeyless configure --access-id "$AKEYLESS_ACCESS_ID" --access-key "$AKEYLESS_ACCESS_KEY" --gateway-url "${AKEYLESS_GATEWAY:-https://api.akeyless.io}"

# Test Platform Engineer authentication
echo "🧪 Testing Platform Engineer authentication..."
if ! akeyless auth --access-id "$AKEYLESS_ACCESS_ID" --access-key "$AKEYLESS_ACCESS_KEY" > /dev/null 2>&1; then
    echo "❌ Platform Engineer authentication failed"
    exit 1
fi
echo "✅ Platform Engineer authentication successful"
echo ""

# Step 1: Platform Engineer deploys token to application service
echo "🚀 Step 1: Platform Engineer deploys token to application service..."

# In production, this would be:
# scp ./tokens/client-tokens production-server:/secure/akeyless-token
# For demo, we simulate this:

APPLICATION_SERVICE_TOKEN_FILE="./tokens/application-service-token"
cp "$ADMIN_TOKEN_FILE" "$APPLICATION_SERVICE_TOKEN_FILE"
chmod 600 "$APPLICATION_SERVICE_TOKEN_FILE"

echo "✅ Token deployed to application service: $APPLICATION_SERVICE_TOKEN_FILE"
echo ""

# Step 2: Platform Engineer sets up automated rotation
echo "⚙️ Step 2: Platform Engineer configures automated rotation..."

# Create rotation script for application service
cat > ./scripts/application-service-rotate.sh << 'EOF'
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
EOF

chmod +x ./scripts/application-service-rotate.sh

echo "✅ Application Service rotation script created: ./scripts/application-service-rotate.sh"
echo ""

# Step 3: Platform Engineer sets up cron job (simulation)
echo "📅 Step 3: Platform Engineer configures hourly rotation schedule..."

# Create cron job template
cat > ./scripts/application-service-cron.txt << EOF
# Akeyless Universal Identity - Application Service Token Rotation
# Installed by Platform Engineer on $(date)
# Runs every hour to rotate UID token

0 * * * * cd $(pwd) && ./scripts/application-service-rotate.sh
EOF

echo "✅ Cron job template created: ./scripts/application-service-cron.txt"
echo ""
echo "💡 To install on actual application service:"
echo "   crontab ./scripts/application-service-cron.txt"
echo ""

# Step 4: Platform Engineer tests the setup
echo "🧪 Step 4: Platform Engineer tests application service setup..."

echo "Testing initial application service authentication..."
akeyless configure --gateway-url "$AKEYLESS_GATEWAY"

# Test authentication with deployed token
TEST_OUTPUT=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$UID_TOKEN" 2>/dev/null)
TEST_TOKEN=$(echo "$TEST_OUTPUT" | grep -E "(token|Token)" | head -n1 | awk '{print $NF}')

if [ -n "$TEST_TOKEN" ]; then
    echo "✅ Application Service authentication test successful"
else
    echo "❌ Application Service authentication test failed"
    exit 1
fi

# Test rotation script
echo "Testing rotation script..."
if ./scripts/application-service-rotate.sh; then
    echo "✅ Application Service rotation test successful"
else
    echo "❌ Application Service rotation test failed"
    exit 1
fi

echo ""
echo "🎉 PLATFORM ENGINEER DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "📋 Platform Engineer configured:"
echo "   - Token deployed to application service"
echo "   - Automated rotation script installed"
echo "   - Hourly cron job template created"
echo "   - Application service tested and verified"
echo ""
echo "📦 Application Service ready for:"
echo "   - Autonomous operations: ./scenarios/client-workflow.sh"
echo "   - Child token management: ./scenarios/child-tokens.sh"
echo "   - Manual rotation testing: ./scenarios/token-rotation.sh"
echo ""
echo "🚀 Next steps:"
echo "   1. Application Service can now run autonomous workflows"
echo "   2. Rotation happens automatically every hour"
echo "   3. No human intervention required"
echo ""
echo "💡 In production:"
echo "   - Platform Engineer deploys to actual application services"
echo "   - Installs cron job with: crontab ./scripts/application-service-cron.txt"
echo "   - Removes admin tokens from admin machine"
echo "   - Monitors rotation logs: ./logs/rotation.log" 