#!/bin/bash

echo "🔄 Akeyless Universal Identity: Token Rotation Demo"
echo "==================================================="
echo ""
echo "This demo shows secretless token rotation capabilities:"
echo "1. Check current token status (60-minute TTL)"
echo "2. Rotate UID token (resets TTL, invalidates old token)"
echo "3. Verify new token works (seamless transition)"
echo "4. Show automated rotation example (zero human intervention)"
echo ""
echo "🔑 Secretless Architecture Benefits:"
echo "   • Automatic rotation vs. manual secret management"
echo "   • Short-lived exposure vs. permanent static credentials"
echo "   • Self-managing lifecycle vs. human error prone processes"
echo ""

# Load tokens from previous demo or create new ones
if [ -f "./tokens/demo-tokens" ]; then
    echo "📂 Loading tokens from previous demo..."
    source ./tokens/demo-tokens
    echo "✅ Loaded UID token: ${UID_TOKEN:0:20}..."
else
    echo "⚠️  No existing tokens found. Generating new UID token..."
    AUTH_METHOD="/demo/uid-non-human-auth"
    
    # Get the access ID for authentication
    ACCESS_ID=$(akeyless auth-method get --name "$AUTH_METHOD" | grep "auth_method_access_id" | cut -d'"' -f4)
    
    UID_TOKEN_OUTPUT=$(akeyless uid-generate-token --auth-method-name "$AUTH_METHOD")
    UID_TOKEN=$(echo "$UID_TOKEN_OUTPUT" | grep "Token:" | awk '{print $2}')
    
    if [ -z "$UID_TOKEN" ]; then
        echo "❌ Failed to generate UID token"
        echo "Please run ./scripts/setup-demo-environment.sh first"
        exit 1
    fi
    
    echo "✅ New UID token generated: ${UID_TOKEN:0:20}..."
fi

echo ""

# Step 1: Check current token status
echo "📊 Step 1: Checking current token status..."
echo "Command: akeyless uid-list-children --uid-token '$UID_TOKEN'"

echo "Current token tree:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""

# Step 2: Rotate the UID token
echo "🔄 Step 2: Rotating UID token..."
echo "Command: akeyless uid-rotate-token --uid-token '$UID_TOKEN'"

OLD_TOKEN=$UID_TOKEN
NEW_TOKEN_OUTPUT=$(akeyless uid-rotate-token --uid-token "$UID_TOKEN")
NEW_TOKEN=$(echo "$NEW_TOKEN_OUTPUT" | grep -E "(ROTATED TOKEN|Token):" | sed 's/.*\[//' | sed 's/\].*//')

if [ -z "$NEW_TOKEN" ]; then
    echo "❌ Failed to rotate UID token"
    echo "Output: $NEW_TOKEN_OUTPUT"
    exit 1
fi

echo "✅ Token rotation successful!"
echo "Old token: ${OLD_TOKEN:0:20}..."
echo "New token: ${NEW_TOKEN:0:20}..."
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
echo "📊 Step 4: Token details after rotation..."
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

# Show automated rotation script example
echo "🤖 Step 6: Automated Rotation Example"
echo "======================================"
echo ""
echo "For production use, here's an example rotation script:"
echo ""

cat << 'EOF'
#!/bin/bash
# Production token rotation script
# Save as: /usr/local/bin/rotate-akeyless-token.sh

TOKEN_FILE="/secure/path/akeyless-token"
LOG_FILE="/var/log/akeyless-rotation.log"

# Read current token
CURRENT_TOKEN=$(cat $TOKEN_FILE)

# Rotate token
echo "$(date): Rotating token..." >> $LOG_FILE
NEW_TOKEN=$(akeyless uid-rotate-token --uid-token "$CURRENT_TOKEN" --format json | jq -r '.token')

if [ "$NEW_TOKEN" != "null" ] && [ -n "$NEW_TOKEN" ]; then
    # Save new token securely
    echo "$NEW_TOKEN" > $TOKEN_FILE
    chmod 600 $TOKEN_FILE
    
    echo "$(date): Token rotation successful" >> $LOG_FILE
    echo "$(date): New token: ${NEW_TOKEN:0:10}..." >> $LOG_FILE
else
    echo "$(date): Token rotation failed!" >> $LOG_FILE
    exit 1
fi
EOF

echo ""
echo "📅 Recommended cron job for hourly rotation:"
echo "0 * * * * /usr/local/bin/rotate-akeyless-token.sh"

echo ""

# Update saved tokens
echo "💾 Updating saved tokens..."
echo "UID_TOKEN=$NEW_TOKEN" > ./tokens/demo-tokens
echo "T_TOKEN=$T_TOKEN" >> ./tokens/demo-tokens
echo "AUTH_METHOD=$AUTH_METHOD" >> ./tokens/demo-tokens
echo "ACCESS_ID=$ACCESS_ID" >> ./tokens/demo-tokens

echo ""
echo "✅ Token rotation demonstration complete!"
echo ""
echo "🎯 Key Takeaways:"
echo "  • Token rotation resets TTL and invalidates old token (limited exposure)"
echo "  • Rotation should be automated (recommended: hourly for secretless architecture)"
echo "  • Always verify new token works before discarding old one"
echo "  • Zero human intervention after setup (true secretless operation)"
echo "  • Dynamic credentials vs. static secrets = reduced security risk"
echo ""
echo "🚀 Next steps:"
echo "  • Explore child tokens: ./scenarios/child-tokens.sh"