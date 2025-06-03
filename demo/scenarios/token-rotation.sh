#!/bin/bash

echo "🚀 APPLICATION SERVICE: Token Rotation Demo"
echo "==========================================="
echo ""
echo "This demo shows Application Service token rotation capabilities:"
echo "1. Check current token status (60-minute TTL)"
echo "2. Rotate UID token (resets TTL, invalidates old token)"
echo "3. Verify new token works (seamless transition)"
echo "4. Show automated rotation setup (zero human intervention)"
echo ""
echo "🔑 Application Service Benefits:"
echo "   • Automatic rotation vs. manual secret management"
echo "   • Short-lived exposure vs. permanent static credentials"
echo "   • Self-managing lifecycle vs. human error prone processes"
echo ""

# Check if Application Service has been provisioned with tokens
APPLICATION_SERVICE_TOKEN_FILE="./tokens/application-service-token"
LEGACY_TOKEN_FILE="./tokens/demo-tokens"

# Support both new and legacy token files
if [ -f "$APPLICATION_SERVICE_TOKEN_FILE" ]; then
    TOKEN_FILE="$APPLICATION_SERVICE_TOKEN_FILE"
    echo "📂 Loading Application Service tokens (deployed by Platform Engineer)..."
elif [ -f "$LEGACY_TOKEN_FILE" ]; then
    TOKEN_FILE="$LEGACY_TOKEN_FILE"
    echo "📂 Loading legacy demo tokens..."
else
    echo "❌ Application Service token file not found"
    echo ""
    echo "This Application Service needs to be provisioned first:"
    echo "1. Run: ./scripts/admin-setup.sh (as admin)"
    echo "2. Run: ./scripts/platform-deploy.sh (as platform engineer)"
    echo "3. Then: Application Service can rotate tokens"
    exit 1
fi

source "$TOKEN_FILE"

if [ -z "$UID_TOKEN" ]; then
    echo "❌ No UID token found in token file"
    echo "Please ensure Application Service is properly provisioned"
    exit 1
fi

echo "✅ Application Service loaded UID token: ${UID_TOKEN:0:20}..."
echo ""

# Configure Application Service CLI
akeyless configure --gateway-url "${AKEYLESS_GATEWAY:-https://api.akeyless.io}"

# Step 1: Check current token status
echo "📊 Step 1: Checking Application Service token status..."
echo "Command: akeyless uid-list-children --uid-token '$UID_TOKEN'"

echo "Current token tree:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""

# Step 2: Rotate the UID token
echo "🔄 Step 2: Application Service rotating UID token..."
echo "Command: akeyless uid-rotate-token --uid-token '$UID_TOKEN'"

OLD_TOKEN=$UID_TOKEN
NEW_TOKEN_OUTPUT=$(akeyless uid-rotate-token --uid-token "$UID_TOKEN")
NEW_TOKEN=$(echo "$NEW_TOKEN_OUTPUT" | grep -E "(ROTATED TOKEN|Token):" | sed 's/.*\[//' | sed 's/\].*//')

if [ -z "$NEW_TOKEN" ]; then
    echo "❌ Failed to rotate UID token"
    echo "Output: $NEW_TOKEN_OUTPUT"
    exit 1
fi

echo "✅ Application Service token rotation successful!"
echo "Old token: ${OLD_TOKEN:0:20}..."
echo "New token: ${NEW_TOKEN:0:20}..."

# Update the token file
sed -i "s/UID_TOKEN=.*/UID_TOKEN=$NEW_TOKEN/" "$TOKEN_FILE"
UID_TOKEN=$NEW_TOKEN

echo "✅ Application Service token file updated"
echo ""

# Step 3: Verify the new token works
echo "🔐 Step 3: Verifying new token works..."
echo "Command: akeyless auth --access-id '$ACCESS_ID' --access-type universal_identity --uid_token '$NEW_TOKEN'"

T_TOKEN_OUTPUT=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$NEW_TOKEN")
T_TOKEN=$(echo "$T_TOKEN_OUTPUT" | grep -E "(token|Token)" | head -n1 | awk '{print $NF}')

if [ -z "$T_TOKEN" ]; then
    echo "❌ Failed to authenticate with new token"
    exit 1
fi

echo "✅ Authentication successful with new token!"
echo "New t-token: ${T_TOKEN:0:20}..."
echo ""

# Step 4: Show token details after rotation
echo "📊 Step 4: Application Service token details after rotation..."
echo "Command: akeyless uid-list-children --uid-token '$NEW_TOKEN'"

echo "Token tree after rotation:"
akeyless uid-list-children --uid-token "$NEW_TOKEN"

echo ""

# Step 5: Demonstrate the old token is no longer valid
echo "🚫 Step 5: Verify old token is no longer valid..."
echo "Command: akeyless auth --access-id '$ACCESS_ID' --access-type universal_identity --uid_token '$OLD_TOKEN'"
echo ""

# Capture both stdout and stderr to show the actual error
OLD_TOKEN_TEST_OUTPUT=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$OLD_TOKEN" 2>&1)
OLD_TOKEN_TEST_EXIT_CODE=$?

if [ $OLD_TOKEN_TEST_EXIT_CODE -eq 0 ]; then
    echo "⚠️  Old token still works (this might happen immediately after rotation)"
    echo "Output: $OLD_TOKEN_TEST_OUTPUT"
else
    echo "✅ Old token correctly invalidated"
    echo "🔍 Authentication failure output:"
    echo "$OLD_TOKEN_TEST_OUTPUT"
fi

echo ""

# Show automated rotation setup
echo "🤖 Step 6: Application Service Automated Rotation Setup"
echo "======================================================="
echo ""
echo "Platform Engineer has already configured automated rotation:"
echo ""

if [ -f "./scripts/application-service-rotate.sh" ]; then
    echo "✅ Rotation script installed: ./scripts/application-service-rotate.sh"
else
    echo "❌ Rotation script not found. Run: ./scripts/platform-deploy.sh"
fi

if [ -f "./scripts/application-service-cron.txt" ]; then
    echo "✅ Cron job template available: ./scripts/application-service-cron.txt"
    echo ""
    echo "📅 Cron job content:"
    cat ./scripts/application-service-cron.txt
else
    echo "❌ Cron job template not found. Run: ./scripts/platform-deploy.sh"
fi

echo ""
echo "🧪 Testing automated rotation script..."
if [ -f "./scripts/application-service-rotate.sh" ]; then
    echo "Command: ./scripts/application-service-rotate.sh"
    if ./scripts/application-service-rotate.sh; then
        echo "✅ Automated rotation script works correctly"
    else
        echo "❌ Automated rotation script failed"
    fi
else
    echo "⚠️  Automated rotation script not available"
fi

echo ""
echo "✅ Application Service token rotation demonstration complete!"
echo ""
echo "🎯 Key Takeaways:"
echo "  • Application Service can self-rotate without human intervention (autonomous)"
echo "  • Token rotation resets TTL and invalidates old token (limited exposure)"
echo "  • Platform Engineer sets up automation once (zero ongoing maintenance)"
echo "  • Rotation should be automated (recommended: hourly)"
echo "  • Always verify new token works before discarding old one"
echo ""
echo "🔄 Production Operations:"
echo "  • Automated script runs every hour via cron (zero human intervention)"
echo "  • Application Service manages its own identity lifecycle"
echo "  • Logs rotation activities for monitoring"
echo "  • Backup tokens maintained automatically"
echo ""
echo "🚀 Next steps:"
echo "  • Explore child tokens: ./scenarios/child-tokens.sh"
echo "  • Monitor rotation logs: ./logs/rotation.log"