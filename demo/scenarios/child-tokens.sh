#!/bin/bash

echo "👨‍👩‍👧‍👦 Akeyless Universal Identity: Child Tokens Demo"
echo "====================================================="
echo ""
echo "This demo shows secretless hierarchical token management:"
echo "1. Create child tokens from parent (service isolation)"
echo "2. View token tree structure (organizational hierarchy)"
echo "3. Use child tokens for authentication (independent TTLs)"
echo "4. Demonstrate revocation scenarios (granular control)"
echo ""
echo "🔑 Secretless Hierarchy Benefits:"
echo "   • Dynamic token trees vs. static shared credentials"
echo "   • Independent TTLs vs. one-size-fits-all expiration"
echo "   • Granular revocation vs. all-or-nothing access control"
echo ""

# Load tokens from previous demo or create new ones
if [ -f "./tokens/demo-tokens" ]; then
    echo "📂 Loading tokens from previous demo..."
    source ./tokens/demo-tokens
    echo "✅ Loaded parent UID token: ${UID_TOKEN:0:20}..."
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
    
    echo "✅ New parent UID token generated: ${UID_TOKEN:0:20}..."
fi

echo ""

# Step 1: View initial token tree
echo "🌳 Step 1: Initial token tree structure..."
echo "Command: akeyless uid-list-children --uid-token '$UID_TOKEN'"

echo "Current token tree:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""

# Step 2: Create first child token
echo "👶 Step 2: Creating first child token..."
echo "Command: akeyless uid-create-child-token --uid-token '$UID_TOKEN' --child-ttl 30"

CHILD_TOKEN_OUTPUT_1=$(akeyless uid-create-child-token --uid-token "$UID_TOKEN" --child-ttl 30)
CHILD_TOKEN_1=$(echo "$CHILD_TOKEN_OUTPUT_1" | grep "Child Token:" | awk '{print $3}')

if [ -z "$CHILD_TOKEN_1" ]; then
    echo "❌ Failed to create child token"
    echo "Output: $CHILD_TOKEN_OUTPUT_1"
    exit 1
fi

echo "✅ First child token created: ${CHILD_TOKEN_1:0:20}..."
echo ""

# Step 3: Create second child token with different TTL
echo "👶 Step 3: Creating second child token (longer TTL)..."
echo "Command: akeyless uid-create-child-token --uid-token '$UID_TOKEN' --child-ttl 60"

CHILD_TOKEN_OUTPUT_2=$(akeyless uid-create-child-token --uid-token "$UID_TOKEN" --child-ttl 60)
CHILD_TOKEN_2=$(echo "$CHILD_TOKEN_OUTPUT_2" | grep "Child Token:" | awk '{print $3}')

if [ -z "$CHILD_TOKEN_2" ]; then
    echo "❌ Failed to create second child token"
    echo "Output: $CHILD_TOKEN_OUTPUT_2"
    exit 1
fi

echo "✅ Second child token created: ${CHILD_TOKEN_2:0:20}..."
echo ""

# Step 4: Create grandchild token (child of child)
echo "👶👶 Step 4: Creating grandchild token..."
echo "Command: akeyless uid-create-child-token --uid-token '$CHILD_TOKEN_1' --child-ttl 15"

GRANDCHILD_TOKEN_OUTPUT=$(akeyless uid-create-child-token --uid-token "$CHILD_TOKEN_1" --child-ttl 15)
GRANDCHILD_TOKEN=$(echo "$GRANDCHILD_TOKEN_OUTPUT" | grep "Child Token:" | awk '{print $3}')

if [ -z "$GRANDCHILD_TOKEN" ]; then
    echo "❌ Failed to create grandchild token"
    echo "Output: $GRANDCHILD_TOKEN_OUTPUT"
    exit 1
fi

echo "✅ Grandchild token created: ${GRANDCHILD_TOKEN:0:20}..."
echo ""

# Step 5: View complete token tree
echo "🌳 Step 5: Complete token tree structure..."
echo "Command: akeyless uid-list-children --uid-token '$UID_TOKEN'"

echo "Complete token tree:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""

# Step 6: Test authentication with child tokens
echo "🔐 Step 6: Testing authentication with child tokens..."

echo ""
echo "Testing first child token:"
echo "Command: akeyless auth --access-id '$ACCESS_ID' --access-type universal_identity --uid_token '$CHILD_TOKEN_1'"

CHILD_T_TOKEN_OUTPUT_1=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$CHILD_TOKEN_1" 2>/dev/null)
CHILD_T_TOKEN_1=$(echo "$CHILD_T_TOKEN_OUTPUT_1" | grep -E "(token|Token)" | head -n1 | awk '{print $NF}')

if [ -z "$CHILD_T_TOKEN_1" ]; then
    echo "❌ Failed to authenticate with first child token"
else
    echo "✅ First child token authentication successful: ${CHILD_T_TOKEN_1:0:20}..."
fi

echo ""
echo "Testing grandchild token:"
echo "Command: akeyless auth --access-id '$ACCESS_ID' --access-type universal_identity --uid_token '$GRANDCHILD_TOKEN'"

GRANDCHILD_T_TOKEN_OUTPUT=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$GRANDCHILD_TOKEN" 2>/dev/null)
GRANDCHILD_T_TOKEN=$(echo "$GRANDCHILD_T_TOKEN_OUTPUT" | grep -E "(token|Token)" | head -n1 | awk '{print $NF}')

if [ -z "$GRANDCHILD_T_TOKEN" ]; then
    echo "❌ Failed to authenticate with grandchild token"
else
    echo "✅ Grandchild token authentication successful: ${GRANDCHILD_T_TOKEN:0:20}..."
fi

echo ""

# Step 7: Demonstrate revocation scenarios
echo "🚫 Step 7: Demonstrating token revocation..."

echo ""
echo "Option A: Revoke only the second child token"
echo "Command: akeyless uid-revoke-token --revoke-token '$CHILD_TOKEN_2' --revoke-type revokeSelf --auth-method-name '$AUTH_METHOD'"

if akeyless uid-revoke-token --revoke-token "$CHILD_TOKEN_2" --revoke-type revokeSelf --auth-method-name "$AUTH_METHOD" > /dev/null 2>&1; then
    echo "✅ Second child token revoked successfully"
else
    echo "❌ Failed to revoke second child token"
fi

echo ""
echo "Token tree after revoking second child:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""
echo "Option B: Revoke first child token and all its children"
echo "Command: akeyless uid-revoke-token --revoke-token '$CHILD_TOKEN_1' --revoke-type revokeAll --auth-method-name '$AUTH_METHOD'"

if akeyless uid-revoke-token --revoke-token "$CHILD_TOKEN_1" --revoke-type revokeAll --auth-method-name "$AUTH_METHOD" > /dev/null 2>&1; then
    echo "✅ First child token and its children revoked successfully"
else
    echo "❌ Failed to revoke first child token and children"
fi

echo ""
echo "Final token tree after revocation:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""

# Use case examples
echo "💼 Step 8: Real-world use case examples..."
echo "=========================================="
echo ""

echo "🏢 Use Case 1: Service Isolation"
echo "• Parent token: Main application service"
echo "• Child tokens: Individual microservices"
echo "• Benefit: Revoke access for specific services without affecting others"
echo ""

echo "🏢 Use Case 2: Environment Segregation"
echo "• Parent token: Organization-level access"
echo "• Child tokens: Environment-specific (dev, staging, prod)"
echo "• Benefit: Manage environments independently"
echo ""

echo "🏢 Use Case 3: Team-based Access"
echo "• Parent token: Department-level access"
echo "• Child tokens: Team-specific access"
echo "• Benefit: Hierarchical access control and audit trails"
echo ""

echo "🏢 Use Case 4: Temporary Access"
echo "• Parent token: Long-lived service account"
echo "• Child tokens: Short-lived task-specific access"
echo "• Benefit: Minimize exposure window for specific operations"
echo ""

echo "✅ Child tokens demonstration complete!"
echo ""
echo "🎯 Key Takeaways:"
echo "  • Child tokens inherit parent permissions but have independent TTL (flexible lifecycle)"
echo "  • Token trees enable hierarchical access control (organizational structure)"
echo "  • Revocation can be targeted (self-only) or cascading (self+children)"
echo "  • Secretless architecture: dynamic hierarchy vs. static credential sharing"
echo "  • Ideal for service isolation and environment segregation"
echo ""
echo "🚀 Next steps:"
echo "  • See production example: ./scenarios/production-example.sh"
echo "  • For Windows setup: https://docs.akeyless.io/docs/setting-up-universal-identity-for-windows-machines" 