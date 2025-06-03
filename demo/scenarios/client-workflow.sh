#!/bin/bash

echo "🚀 APPLICATION SERVICE: Universal Identity Workflow Demo"
echo "======================================================="
echo ""
echo "This script represents the APPLICATION SERVICE persona from the workflow diagram:"
echo "4. Application Service runs auth command using UID init token (from admin)"
echo "5. SaaS responds with JWT (t-token)"
echo "6. Application Service runs commands using t-token"
echo "7. Application Service rotates UID using u-token"
echo "8. SaaS returns ACK + new u-token"
echo "9. Application Service runs auth command with new u-token"
echo ""
echo "🔑 Key Point: Application Service starts with admin-provided UID token"
echo ""

# Check if application service has been provisioned with tokens
APPLICATION_SERVICE_TOKEN_FILE="./tokens/application-service-token"

# Support both new and legacy token files
if [ -f "$APPLICATION_SERVICE_TOKEN_FILE" ]; then
    TOKEN_FILE="$APPLICATION_SERVICE_TOKEN_FILE"
    echo "📂 Loading Application Service tokens (deployed by Platform Engineer)..."
else
    echo "❌ Application Service token file not found"
    echo ""
    echo "This Application Service needs to be provisioned first:"
    echo "1. Run: ./scripts/admin-setup.sh (as admin)"
    echo "2. Run: ./scripts/platform-deploy.sh (as platform engineer)"
    echo "3. Then: Application Service can run autonomous workflows"
    exit 1
fi

source "$TOKEN_FILE"

echo "✅ Application Service provisioned with:"
echo "   - UID Token: ${UID_TOKEN:0:20}..."
echo "   - Access ID: $ACCESS_ID"
echo ""

# Application Service CLI setup (no admin credentials needed)
echo "⚙️ Application Service ready - configuring gateway without admin credentials..."

# Step 4: Application Service runs auth command using UID init token
echo "🔐 Step 4: Application Service authenticates using admin-provided UID token..."
echo "Command: akeyless auth --access-id '$ACCESS_ID' --access-type universal_identity --uid_token '***'"

T_TOKEN_OUTPUT=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$UID_TOKEN")
echo "T_TOKEN_OUTPUT:" $T_TOKEN_OUTPUT
T_TOKEN=$(echo "$T_TOKEN_OUTPUT" | grep -E "(token|Token)" | head -n1 | awk '{print $NF}')
echo "T_TOKEN:" $T_TOKEN

if [ -z "$T_TOKEN" ]; then
    echo "❌ Application Service authentication failed"
    echo "Output: $T_TOKEN_OUTPUT"
    exit 1
fi

echo "✅ Step 5: SaaS responded with JWT (t-token): ${T_TOKEN:0:20}..."
echo ""

# Step 6: Application Service runs commands using t-token
echo "🔑 Step 6: Application Service accesses database secret using t-token..."
SECRET_NAME="/demo/database-config"
echo "Command: akeyless get-secret-value --name '$SECRET_NAME' --token '***'"

SECRET_VALUE=$(akeyless get-secret-value --name "$SECRET_NAME" --token "$T_TOKEN" 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Database secret retrieved successfully!"
    echo ""
    echo "📄 Database configuration for application:"
    echo "$SECRET_VALUE" | jq .
else
    echo "❌ Failed to retrieve database secret"
    echo "💡 This might be a permissions issue - check if the role has access to $SECRET_NAME"
fi

echo ""

# Step 7: Application Service rotates UID using u-token  
echo "🔄 Step 7: Application Service rotates UID token (self-rotation)..."
echo "Command: akeyless uid-rotate-token --uid-token '***'"

OLD_UID_TOKEN=$UID_TOKEN
ROTATION_OUTPUT=$(akeyless uid-rotate-token --uid-token "$UID_TOKEN")
NEW_UID_TOKEN=$(echo "$ROTATION_OUTPUT" | grep -E "(ROTATED TOKEN|Token):" | sed 's/.*\[//' | sed 's/\].*//')

if [ -z "$NEW_UID_TOKEN" ]; then
    echo "❌ Token rotation failed"
    echo "Output: $ROTATION_OUTPUT"
    exit 1
fi

echo "✅ Step 8: SaaS returned ACK + new u-token: ${NEW_UID_TOKEN:0:20}..."

# Update Application Service token file
sed -i "s/UID_TOKEN=.*/UID_TOKEN=$NEW_UID_TOKEN/" "$TOKEN_FILE"
UID_TOKEN=$NEW_UID_TOKEN

echo "✅ Application Service token file updated with new UID token"
echo "📁 Persisted rotated UID token to: $TOKEN_FILE"
echo "🔄 This ensures service can restart with valid token (no manual intervention needed)"
echo ""

# Step 9: Application Service runs auth command with new u-token
echo "🔐 Step 9: Application Service authenticates with new UID token..."
echo "Command: akeyless auth --access-id '$ACCESS_ID' --access-type universal_identity --uid_token '***'"

NEW_T_TOKEN_OUTPUT=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$NEW_UID_TOKEN")
NEW_T_TOKEN=$(echo "$NEW_T_TOKEN_OUTPUT" | grep "Token:" | awk '{print $2}')

if [ -z "$NEW_T_TOKEN" ]; then
    echo "❌ Authentication with new UID token failed"
    exit 1
fi

echo "✅ Authentication successful with new UID token!"
echo "New t-token: ${NEW_T_TOKEN:0:20}..."
echo ""

# Verify old UID token is invalidated
echo "🚫 Verification: Testing if old UID token is invalidated..."
OLD_TOKEN_TEST=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$OLD_UID_TOKEN" 2>&1)
OLD_TOKEN_EXIT_CODE=$?

if [ $OLD_TOKEN_EXIT_CODE -eq 0 ]; then
    echo "⚠️  Old UID token still works (may happen immediately after rotation)"
else
    echo "✅ Old UID token correctly invalidated"
fi

echo ""
echo "🎉 APPLICATION SERVICE WORKFLOW COMPLETE!"
echo "========================================"
echo ""
echo "📊 Workflow Summary:"
echo "   4. ✅ Application Service authenticated with admin-provided UID token"
echo "   5. ✅ Received t-token from SaaS"
echo "   6. ✅ Used t-token to access database secrets"
echo "   7. ✅ Rotated UID token (self-rotation)"
echo "   8. ✅ Received new UID token from SaaS"
echo "   9. ✅ Authenticated with new UID token"
echo ""
echo "🎯 Key Takeaways:"
echo "  • Application Service started with admin-provisioned UID token (realistic)"
echo "  • Application Service can self-rotate without admin intervention (autonomous)"
echo "  • T-tokens are short-lived for actual operations (security)"
echo "  • UID tokens provide long-term service identity with automatic refresh"
echo ""
echo "🔄 Ongoing Operations:"
echo "  • Application Service can now repeat steps 4-6 for normal operations"
echo "  • Rotation (steps 7-9) should be automated every 60 minutes"
echo "  • No admin intervention required after initial provisioning" 