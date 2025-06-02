#!/bin/bash

echo "🚀 Setting up Akeyless Universal Identity Demo Environment"
echo "========================================================="
echo ""

# Check if Akeyless CLI is installed
if ! command -v akeyless &> /dev/null; then
    echo "❌ Akeyless CLI not found. Installing..."
    
    # Download and install Akeyless CLI
    curl -o akeyless https://akeyless-releases.s3.us-east-2.amazonaws.com/cli/latest/production/cli-linux-amd64
    chmod +x akeyless
    sudo mv akeyless /usr/local/bin/
    
    echo "✅ Akeyless CLI installed successfully"
else
    echo "✅ Akeyless CLI found: $(akeyless --version)"
fi

echo ""

# Check for required environment variables
if [ -z "$AKEYLESS_GATEWAY" ]; then
    echo "⚠️  AKEYLESS_GATEWAY not set. Using default SaaS endpoint."
    export AKEYLESS_GATEWAY="https://api.akeyless.io"
fi

echo "🌐 Akeyless Gateway: $AKEYLESS_GATEWAY"
echo ""

# Configure Akeyless CLI
akeyless configure --access-id "$AKEYLESS_ACCESS_ID" --access-key "$AKEYLESS_ACCESS_KEY" --gateway-url "$AKEYLESS_GATEWAY"

echo "🔧 Configuring Akeyless CLI..."
echo ""

# Check authentication
echo "🔐 Testing authentication..."
if akeyless auth --access-id "$AKEYLESS_ACCESS_ID" --access-key "$AKEYLESS_ACCESS_KEY" > /dev/null 2>&1; then
    echo "✅ Authentication successful"
else
    echo "❌ Authentication failed. Please check your credentials:"
    echo "   - AKEYLESS_ACCESS_ID"
    echo "   - AKEYLESS_ACCESS_KEY"
    echo "   - AKEYLESS_GATEWAY"
    exit 1
fi

echo ""
echo "📝 Creating demo resources..."

# Create Universal Identity authentication method using correct syntax
echo "🆔 Creating Universal Identity authentication method..."
akeyless auth-method create universal-identity \
    --name "/demo/uid-non-human-auth" \
    --description "Demo Universal Identity for secretless non-human authentication" \
    --ttl 60 \
    --jwt-ttl 720 || echo "Auth method may already exist"

# Create a demo secret to access
echo "🔑 Creating demo secret..."
akeyless create-secret \
    --name "/demo/database-config" \
    --value '{
        "host": "demo-db.company.com",
        "port": 5432,
        "database": "production",
        "username": "app_user",
        "password": "super_secure_password_123"
    }' || echo "Secret may already exist"

# Create access role for the Universal Identity
echo "🎭 Creating access role..."
akeyless create-role \
    --name "/demo/non-human-access-role" \
    --description "Demo role for secretless non-human access" || echo "Role may already exist"

# Associate the secret with the role
echo "🔗 Associating secret with role..."
akeyless assoc-role-am \
    --role-name "/demo/non-human-access-role" \
    --am-name "/demo/uid-non-human-auth" || echo "Association may already exist"

akeyless set-role-rule \
    --role-name "/demo/non-human-access-role" \
    --path "/demo/*" \
    --capability read || echo "Rule may already exist"

echo ""
echo "🎉 Demo environment setup complete!"
echo ""
echo "📋 Created resources:"
echo "   - Authentication Method: /demo/uid-non-human-auth"
echo "   - Demo Secret: /demo/database-config" 
echo "   - Access Role: /demo/non-human-access-role"
echo ""
echo "🚀 Next steps:"
echo "   1. Run: ./scenarios/basic-workflow.sh"
echo "   2. Try: ./scenarios/token-rotation.sh"
echo "   3. Explore: ./scenarios/child-tokens.sh"
echo ""
echo "📚 For more details, see the demo scenarios in ./scenarios/" 