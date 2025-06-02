#!/bin/bash

echo "🎯 Akeyless Universal Identity: Basic Secretless Workflow Demo"
echo "============================================================="
echo ""
echo "This demo shows the core secretless Universal Identity workflow:"
echo "1. Generate UID token (dynamic, auto-rotating credential)"
echo "2. Use UID token to authenticate and get t-token (short-lived session)"
echo "3. Access secrets using t-token (no static credentials stored)"
echo ""
echo "🔑 What 'Secretless' Means:"
echo "   • NOT 'no credentials at all'"
echo "   • Dynamic, self-rotating credentials vs. static hardcoded secrets"
echo "   • 60-minute TTL vs. months/years of exposure"
echo "   • Zero human intervention vs. manual rotation"
echo ""

# Check if we have the required auth method
AUTH_METHOD="/demo/uid-non-human-auth"

echo "🔍 Checking if authentication method exists..."
if ! akeyless auth-method get --name "$AUTH_METHOD" > /dev/null 2>&1; then
    echo "❌ Authentication method '$AUTH_METHOD' not found."
    echo "Please run ./scripts/setup-demo-environment.sh first"
    exit 1
fi

# Get the access ID for authentication
ACCESS_ID=$(akeyless auth-method get --name "$AUTH_METHOD" | grep "auth_method_access_id" | cut -d'"' -f4)

echo "✅ Authentication method found: $AUTH_METHOD"
echo "✅ Access ID: $ACCESS_ID"
echo ""

# Step 1: Generate UID token
echo "🎫 Step 1: Generating UID token (secretless non-human identity)..."
echo "Command: akeyless uid-generate-token --auth-method-name '$AUTH_METHOD'"

UID_TOKEN_OUTPUT=$(akeyless uid-generate-token --auth-method-name "$AUTH_METHOD")
UID_TOKEN=$(echo "$UID_TOKEN_OUTPUT" | grep "Token:" | awk '{print $2}')

if [ -z "$UID_TOKEN" ]; then
    echo "❌ Failed to generate UID token"
    echo "Output: $UID_TOKEN_OUTPUT"
    exit 1
fi

echo "✅ UID token generated: ${UID_TOKEN:0:20}..."
echo ""

# Step 2: Authenticate with UID token to get t-token
echo "🔐 Step 2: Authenticating with UID token to get t-token (secretless pattern)..."
echo "Command: akeyless auth --access-id '$ACCESS_ID' --access-type universal_identity --uid_token '$UID_TOKEN'"

T_TOKEN_OUTPUT=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$UID_TOKEN")
T_TOKEN=$(echo "$T_TOKEN_OUTPUT" | grep -E "(token|Token)" | head -n1 | awk '{print $NF}')

if [ -z "$T_TOKEN" ]; then
    echo "❌ Failed to authenticate and get t-token"
    echo "Output: $T_TOKEN_OUTPUT"
    exit 1
fi

echo "✅ Authentication successful! t-token received: ${T_TOKEN:0:20}..."
echo ""

# Step 3: Access secret using t-token
echo "🔑 Step 3: Accessing secret using t-token (secretless access)..."
SECRET_NAME="/demo/database-config"
echo "Command: akeyless get-secret-value --name '$SECRET_NAME' --token '$T_TOKEN'"

SECRET_VALUE=$(akeyless get-secret-value --name "$SECRET_NAME" --token "$T_TOKEN" 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Secret retrieved successfully!"
    echo ""
    echo "📄 Secret content:"
    echo "$SECRET_VALUE" | jq .
else
    echo "❌ Failed to retrieve secret. This might be a permissions issue."
    echo "Make sure the role is properly configured in setup."
fi

echo ""
echo "📊 Token Information:"
echo "--------------------"
echo "UID Token:  ${UID_TOKEN:0:30}..."
echo "T-Token:    ${T_TOKEN:0:30}..."
echo ""

# Show token details if possible
echo "🔍 UID Token Details:"
echo "Command: akeyless uid-list-children --uid-token '$UID_TOKEN'"
akeyless uid-list-children --uid-token "$UID_TOKEN" 2>/dev/null || echo "Unable to fetch token details"

echo ""
echo "✅ Secretless workflow demonstration complete!"
echo ""
echo "🎯 Key Takeaways:"
echo "  • UID tokens are dynamic, self-rotating non-human identity credentials"
echo "  • T-tokens are short-lived tokens for API operations (hours, not months)"
echo "  • Secretless = No static credentials hardcoded in your infrastructure"
echo "  • Best practice: Bootstrap once → Auto-rotate → Access resources"
echo "  • Zero human intervention after initial setup"
echo ""
echo "🚀 Next steps:"
echo "  • Try token rotation: ./scenarios/token-rotation.sh"
echo "  • Explore child tokens: ./scenarios/child-tokens.sh"
echo ""

# Save tokens for other demos
echo "💾 Saving tokens for other demo scenarios..."
mkdir -p ./tokens
echo "UID_TOKEN=$UID_TOKEN" > ./tokens/demo-tokens
echo "T_TOKEN=$T_TOKEN" >> ./tokens/demo-tokens
echo "AUTH_METHOD=$AUTH_METHOD" >> ./tokens/demo-tokens
echo "ACCESS_ID=$ACCESS_ID" >> ./tokens/demo-tokens

echo "Tokens saved to ./tokens/demo-tokens" 