#!/bin/bash

echo "🚀 APPLICATION SERVICE: Child Tokens Demo"
echo "========================================="
echo ""
echo "This demo shows Application Service hierarchical token management:"
echo "1. Application Service creates child tokens for microservices (service isolation)"
echo "2. View token tree structure (organizational hierarchy)"
echo "3. Use child tokens for authentication (independent TTLs)"
echo "4. Demonstrate revocation scenarios (granular control)"
echo ""
echo "🔑 Application Service Hierarchy Benefits:"
echo "   • Dynamic token trees vs. static shared credentials"
echo "   • Independent TTLs vs. one-size-fits-all expiration"
echo "   • Granular revocation vs. all-or-nothing access control"
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
    echo "3. Then: Application Service can manage child tokens"
    exit 1
fi

source "$TOKEN_FILE"

if [ -z "$UID_TOKEN" ]; then
    echo "❌ No UID token found in token file"
    echo "Please ensure Application Service is properly provisioned"
    exit 1
fi

echo "✅ Application Service loaded parent UID token: ${UID_TOKEN:0:20}..."
echo ""

# Configure Application Service CLI
akeyless configure --gateway-url "${AKEYLESS_GATEWAY:-https://api.akeyless.io}"

# Step 1: View initial token tree
echo "🌳 Step 1: Application Service initial token tree structure..."
echo "Command: akeyless uid-list-children --uid-token '$UID_TOKEN'"

echo "Current token tree:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""

# Step 2: Create first child token for database microservice
echo "🗄️ Step 2: Application Service creating child token for database microservice..."
echo "Command: akeyless uid-create-child-token --uid-token '$UID_TOKEN' --child-ttl 30"

CHILD_TOKEN_OUTPUT_1=$(akeyless uid-create-child-token --uid-token "$UID_TOKEN" --child-ttl 30)
CHILD_TOKEN_1=$(echo "$CHILD_TOKEN_OUTPUT_1" | grep "Child Token:" | awk '{print $3}')

if [ -z "$CHILD_TOKEN_1" ]; then
    echo "❌ Failed to create child token"
    echo "Output: $CHILD_TOKEN_OUTPUT_1"
    exit 1
fi

echo "✅ Database microservice child token created: ${CHILD_TOKEN_1:0:20}..."
echo ""

# Step 3: Create second child token for API gateway
echo "🌐 Step 3: Application Service creating child token for API gateway..."
echo "Command: akeyless uid-create-child-token --uid-token '$UID_TOKEN' --child-ttl 60"

CHILD_TOKEN_OUTPUT_2=$(akeyless uid-create-child-token --uid-token "$UID_TOKEN" --child-ttl 60)
CHILD_TOKEN_2=$(echo "$CHILD_TOKEN_OUTPUT_2" | grep "Child Token:" | awk '{print $3}')

if [ -z "$CHILD_TOKEN_2" ]; then
    echo "❌ Failed to create second child token"
    echo "Output: $CHILD_TOKEN_OUTPUT_2"
    exit 1
fi

echo "✅ API gateway child token created: ${CHILD_TOKEN_2:0:20}..."
echo ""

# Step 4: Create grandchild token (database cache service)
echo "⚡ Step 4: Application Service creating grandchild token for database cache..."
echo "Command: akeyless uid-create-child-token --uid-token '$CHILD_TOKEN_1' --child-ttl 15"

GRANDCHILD_TOKEN_OUTPUT=$(akeyless uid-create-child-token --uid-token "$CHILD_TOKEN_1" --child-ttl 15)
GRANDCHILD_TOKEN=$(echo "$GRANDCHILD_TOKEN_OUTPUT" | grep "Child Token:" | awk '{print $3}')

if [ -z "$GRANDCHILD_TOKEN" ]; then
    echo "❌ Failed to create grandchild token"
    echo "Output: $GRANDCHILD_TOKEN_OUTPUT"
    exit 1
fi

echo "✅ Database cache grandchild token created: ${GRANDCHILD_TOKEN:0:20}..."
echo ""

# Step 5: View complete token tree
echo "🌳 Step 5: Application Service complete token tree structure..."
echo "Command: akeyless uid-list-children --uid-token '$UID_TOKEN'"

echo "Complete token tree:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""

# Step 6: Test authentication with child tokens
echo "🔐 Step 6: Testing Application Service child token authentication..."

echo ""
echo "Testing database microservice child token:"
echo "Command: akeyless auth --access-id '$ACCESS_ID' --access-type universal_identity --uid_token '$CHILD_TOKEN_1'"

CHILD_T_TOKEN_OUTPUT_1=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$CHILD_TOKEN_1" 2>/dev/null)
CHILD_T_TOKEN_1=$(echo "$CHILD_T_TOKEN_OUTPUT_1" | grep -E "(token|Token)" | head -n1 | awk '{print $NF}')

if [ -z "$CHILD_T_TOKEN_1" ]; then
    echo "❌ Failed to authenticate with database microservice child token"
else
    echo "✅ Database microservice child token authentication successful: ${CHILD_T_TOKEN_1:0:20}..."
fi

echo ""
echo "Testing database cache grandchild token:"
echo "Command: akeyless auth --access-id '$ACCESS_ID' --access-type universal_identity --uid_token '$GRANDCHILD_TOKEN'"

GRANDCHILD_T_TOKEN_OUTPUT=$(akeyless auth --access-id "$ACCESS_ID" --access-type universal_identity --uid_token "$GRANDCHILD_TOKEN" 2>/dev/null)
GRANDCHILD_T_TOKEN=$(echo "$GRANDCHILD_T_TOKEN_OUTPUT" | grep -E "(token|Token)" | head -n1 | awk '{print $NF}')

if [ -z "$GRANDCHILD_T_TOKEN" ]; then
    echo "❌ Failed to authenticate with database cache grandchild token"
else
    echo "✅ Database cache grandchild token authentication successful: ${GRANDCHILD_T_TOKEN:0:20}..."
fi

echo ""

# Step 7: Demonstrate revocation scenarios
echo "🚫 Step 7: Application Service demonstrating token revocation..."

echo ""
echo "Option A: Revoke only the API gateway child token"
echo "Command: akeyless uid-revoke-token --revoke-token '$CHILD_TOKEN_2' --revoke-type revokeSelf --auth-method-name '$AUTH_METHOD'"

if akeyless uid-revoke-token --revoke-token "$CHILD_TOKEN_2" --revoke-type revokeSelf --auth-method-name "$AUTH_METHOD" > /dev/null 2>&1; then
    echo "✅ API gateway child token revoked successfully"
else
    echo "❌ Failed to revoke API gateway child token"
fi

echo ""
echo "Token tree after revoking API gateway:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""
echo "Option B: Revoke database microservice child token and all its children"
echo "Command: akeyless uid-revoke-token --revoke-token '$CHILD_TOKEN_1' --revoke-type revokeAll --auth-method-name '$AUTH_METHOD'"

if akeyless uid-revoke-token --revoke-token "$CHILD_TOKEN_1" --revoke-type revokeAll --auth-method-name "$AUTH_METHOD" > /dev/null 2>&1; then
    echo "✅ Database microservice child token and its children revoked successfully"
else
    echo "❌ Failed to revoke database microservice child token and children"
fi

echo ""
echo "Final token tree after revocation:"
akeyless uid-list-children --uid-token "$UID_TOKEN"

echo ""

# Use case examples
echo "💼 Step 8: Application Service real-world use cases..."
echo "==================================================="
echo ""

echo "🏢 Use Case 1: Microservices Architecture"
echo "• Parent token: Main Application Service"
echo "• Child tokens: Database Service, API Gateway, Cache Service"
echo "• Benefit: Revoke access for specific microservices without affecting others"
echo ""

echo "🏢 Use Case 2: Container Orchestration"
echo "• Parent token: Application deployment"
echo "• Child tokens: Individual container instances"
echo "• Benefit: Service isolation with independent TTLs"
echo ""

echo "🏢 Use Case 3: Event-Driven Processing"
echo "• Parent token: Event processor Application Service"
echo "• Child tokens: Short-lived event handler functions"
echo "• Benefit: Minimize exposure window for specific operations"
echo ""

echo "🏢 Use Case 4: Multi-Tenant Applications"
echo "• Parent token: Application Service per tenant"
echo "• Child tokens: Feature-specific access within tenant"
echo "• Benefit: Tenant isolation with hierarchical management"
echo ""

echo "✅ Application Service child tokens demonstration complete!"
echo ""
echo "🎯 Key Takeaways:"
echo "  • Application Service can create hierarchical token structures (microservice isolation)"
echo "  • Child tokens inherit parent permissions but have independent TTL (flexible lifecycle)"
echo "  • Token trees enable organized access control (microservices architecture)"
echo "  • Revocation can be targeted (self-only) or cascading (self+children)"
echo "  • Perfect for Application Service managing multiple microservices or components"
echo ""
echo "🚀 Next steps:"
echo "  • Set up automated rotation: ./scripts/application-service-rotate.sh"
echo "  • For Windows Application Services: https://docs.akeyless.io/docs/setting-up-universal-identity-for-windows-machines" 