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

echo "✅ Using application-service-rotate.sh script for rotation"
echo "✅ Rotation will use existing application-service-token file"
echo ""

# Step 3: Platform Engineer sets up cron job (simulation)
echo "📅 Step 3: Platform Engineer configures hourly rotation schedule..."

# Create cron job template using the working application-service-rotate.sh
cat > ./scripts/application-service-cron.txt << EOF
# Akeyless Universal Identity - Application Service Token Rotation
# Installed by Platform Engineer on $(date)
# Runs every hour to rotate UID token using application-service-rotate.sh

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
echo "Access ID:" $ACCESS_ID
echo "UID Token:" $UID_TOKEN
# Test authentication with deployed token
TEST_OUTPUT=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$UID_TOKEN" 2>/dev/null)
TEST_TOKEN=$(echo "$TEST_OUTPUT" | grep -E "(token|Token)" | head -n1 | awk '{print $NF}')
echo "Test Token:" $TEST_TOKEN

if [ -n "$TEST_TOKEN" ]; then
    echo "✅ Application Service authentication test successful"
else
    echo "❌ Application Service authentication test failed"
    exit 1
fi

echo ""
echo "🎉 PLATFORM ENGINEER DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "📋 Platform Engineer configured:"
echo "   - Token deployed to application service"
echo "   - Using working simple-rotate-token.sh script for rotation"
echo "   - Hourly cron job template created"
echo "   - Application service tested and verified"
echo ""
echo "📦 Application Service ready for:"
echo "   - Autonomous operations: ./scenarios/client-workflow.sh"
echo "   - Child token management: ./scenarios/child-tokens.sh"
echo "   - Manual rotation testing: ./scripts/simple-rotate-token.sh"
echo ""
echo "🚀 Next steps:"
echo "   1. Application Service can now run autonomous workflows"
echo "   2. Rotation happens automatically every hour using simple-rotate-token.sh"
echo "   3. No human intervention required"
echo ""
echo "💡 In production:"
echo "   - Platform Engineer deploys to actual application services"
echo "   - Installs cron job with: crontab ./scripts/application-service-cron.txt"
echo "   - Removes admin tokens from admin machine"
echo "   - Monitors rotation logs in ~/.akeyless-rotation.log" 