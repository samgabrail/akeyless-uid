# Akeyless Universal Identity Demo & Content Package
## Secretless Non-Human Identity Authentication with UID Tokens

This repository contains a complete demo and content package showcasing **Akeyless Universal Identity** - a sophisticated secretless non-human identity authentication system built around dynamic UID (Universal Identity) tokens with hierarchical management capabilities.

## What "Secretless" Really Means

**Common Question:** *"You use tokens—aren't those secrets?"*

**Answer:** Secretless ≠ No credentials at all. 

**Secretless = No static, long-lived, manually-managed credentials**

- **Traditional Approach:** Static API keys hardcoded for months/years
- **Secretless Approach:** Dynamic tokens that auto-rotate every 60 minutes
- **Key Benefit:** Bootstrap once, self-manage forever with zero human intervention

*Think hotel key cards (expire daily) vs. master keys (work forever)*

## 📦 What's Included

### 1. Interactive Demo (`/demo/`)
A comprehensive demonstration of secretless Universal Identity token management:

- **Three-Persona Workflow**: Admin → Platform Engineer → Application Service
- **Token Rotation**: Automatic rotation with TTL reset
- **Hierarchical Tokens**: Parent-child token relationships
- **Real-world Examples**: Python integration patterns

For **Windows Setup**, see the [official Akeyless documentation](https://docs.akeyless.io/docs/setting-up-universal-identity-for-windows-machines).

### 2. Blog Post (`blog-post.md`)
A detailed 2000+ word article covering:

- Non-human identity challenges beyond human identity management
- Universal Identity's secretless token-based approach
- Hierarchical token management and use cases
- Implementation patterns for CI/CD and microservices
- Secretless architecture principles and benefits
- Production deployment strategies

### 3. Demo Scenarios (`demo/scenarios/`)
Hands-on scenarios demonstrating:

- **Client Workflow** (`client-workflow.sh`): Complete application service workflow with token rotation (Steps 4-9)
- **Child Tokens** (`child-tokens.sh`): Hierarchical token management

## 🚀 Quick Start

### Prerequisites

1. **Akeyless CLI** installed
2. **Akeyless Account** with admin access
3. **Environment Variables** set:
   ```bash
   export AKEYLESS_ACCESS_ID="your-access-id"
   export AKEYLESS_ACCESS_KEY="your-access-key"
   export AKEYLESS_GATEWAY="https://api.akeyless.io"
   ```

### Running the Demo

**Using start.sh (Recommended)**

1. **Run the interactive demo**:
   ```bash
   ./start.sh
   ```
   
   The interactive script provides:
   - **🎯 Complete Workflow**: Runs all three personas automatically
   - **🎭 Individual Steps**: Choose specific personas to run
   - **🐍 Python Integration**: Real-world secretless authentication example
   - **📊 Status Tracking**: See which steps are complete
   - **⚠️ Prerequisites Check**: Validates environment setup
   - **🔄 Smart Skipping**: Avoids re-running completed steps

**Manual Three-Persona Workflow**

1. **Admin Setup** (Steps 1-3 from diagram)
   ```bash
   cd demo
   ./scripts/admin-setup.sh
   ```

2. **Platform Engineer Deployment**
   ```bash
   ./scripts/platform-deploy.sh
   ```

3. **Application Service Operations** (Steps 4-9 from diagram)
   ```bash
   ./scenarios/client-workflow.sh
   ```

4. **Explore Advanced Features**
   ```bash
   ./scenarios/child-tokens.sh
   python3 ./examples/machine-auth.py
   ```

## 🏗️ Demo Architecture

```
demo/
├── scenarios/
│   ├── client-workflow.sh          # 🚀 Application Service workflow with rotation (Steps 4-9)
│   └── child-tokens.sh             # Hierarchical token management
├── scripts/
│   ├── admin-setup.sh              # 🧑‍💼 Admin setup (Steps 1-3)
│   ├── platform-deploy.sh          # 👷 Platform Engineer deployment
│   ├── application-service-rotate.sh # Automated rotation for application services
│   └── (rotation scripts removed - using application-service-rotate.sh)
├── tokens/
│   ├── client-tokens               # 🧑‍💼 Admin-generated tokens
│   └── application-service-token   # 👷 Platform Engineer deployed tokens
├── logs/
│   └── rotation.log                # Automated rotation logging
├── examples/
│   └── machine-auth.py             # 🐍 Python secretless authentication example
├── start.sh                        # 🚀 Interactive demo entry point
└── README.md                       # Demo documentation
```

**Windows Integration**: For complete Windows machine setup, see the [official Akeyless documentation](https://docs.akeyless.io/docs/setting-up-universal-identity-for-windows-machines).

## 🔑 Key Universal Identity Features

### ✅ Dynamic UID Tokens for True Secretless Architecture
- **Generate**: Create non-human identity tokens on-demand (dynamic vs. static)
- **Rotate**: Automatic rotation every 60 minutes with TTL reset (zero human intervention)
- **Manage**: Full lifecycle control including revocation (self-managing credentials)
- **Secretless**: No static credentials stored on systems (bootstrap once, rotate forever)

### ✅ Hierarchical Token Management
- **Parent-Child Relationships**: Organize tokens by service/environment (dynamic hierarchy)
- **Granular Revocation**: Revoke individual tokens or entire trees (precise control)
- **Flexible TTL**: Different expiration times for different use cases (risk-appropriate)

### ✅ Best Practice Secretless Workflow
- **UID → T-Token Pattern**: Exchange UID tokens for optimized t-tokens (separation of concerns)
- **Performance**: T-tokens optimized for high-frequency operations (short-lived sessions)
- **Security**: Short-lived t-tokens minimize exposure window (hours, not months)

### ✅ Enterprise Features
- **Audit Trails**: Complete token lifecycle logging (full visibility)
- **Policy-Based Access**: Fine-grained access control (least privilege)
- **Multi-Environment**: Hierarchical isolation across environments (organizational structure)

## 💼 Use Cases Demonstrated

### CI/CD Pipeline Integration (Secretless)
```yaml
# GitHub Actions example
- name: Authenticate with Akeyless (Secretless)
  run: |
    T_TOKEN=$(akeyless auth --access-id "/ci-cd/github-actions" \
                           --uid-token "${{ secrets.AKEYLESS_UID_TOKEN }}" \
                           --format json | jq -r '.token')
    echo "AKEYLESS_TOKEN=$T_TOKEN" >> $GITHUB_ENV
```

### Microservices Architecture
```python
# Python service integration (secretless authentication)
client = AkeylessClient("/production/user-service", "/secure/akeyless-token")
db_password = client.get_secret("/production/user-db-password")
```

### Automated Token Rotation
```bash
# Hourly rotation via cron (secretless self-rotation)
0 * * * * /path/to/simple-rotate-token.sh rotate
```

### Hierarchical Organization
```bash
# Environment-based hierarchy
ORG_TOKEN="u-org-level-token"
DEV_TOKEN=$(akeyless uid-create-child-token --uid-token "$ORG_TOKEN" --child-ttl 480)
PROD_TOKEN=$(akeyless uid-create-child-token --uid-token "$ORG_TOKEN" --child-ttl 60)
```

## 📊 Secretless Architecture Benefits

| Feature | Universal Identity | Traditional Approaches |
|---------|-------------------|------------------------|
| **Rotation** | ✅ Automatic | ❌ Manual |
| **Hierarchical** | ✅ Yes | ❌ No |
| **TTL Management** | ✅ Built-in | ❌ None |
| **Revocation** | ✅ Granular | ❌ All-or-nothing |
| **Scaling** | ✅ Dynamic | ❌ Static |
| **Secretless** | ✅ No static secrets | ❌ Static credentials |

## 🎯 Target Audiences

### Security Teams
- **Enable secretless architecture** through dynamic token management
- **Reduce attack surface** with short-lived t-tokens
- **Enhance auditability** with complete token lifecycle logging

### Operations Teams
- **Simplify credential management** with automated rotation
- **Scale efficiently** with dynamic token creation
- **Reduce operational overhead** through hierarchical organization

### Development Teams
- **Integrate easily** with existing CI/CD pipelines
- **Secure microservices** with service-specific child tokens
- **Implement secretless patterns** with UID → T-token workflow

## 🛠️ Implementation Examples

### Python Integration (Secretless)
```python
class AkeylessClient:
    def authenticate(self):
        # Exchange UID token for t-token (secretless pattern)
        result = subprocess.run([
            'akeyless', 'auth',
            '--access-id', self.auth_method,
            '--uid-token', self.uid_token,
            '--format', 'json'
        ], capture_output=True, text=True, check=True)
        
        return json.loads(result.stdout)['token']
```

### Production Rotation Script
```bash
#!/bin/bash
# Automated token rotation (secretless self-rotation)
NEW_TOKEN=$(akeyless uid-rotate-token --uid-token "$CURRENT_TOKEN" --format json | jq -r '.token')

if [[ "$NEW_TOKEN" != "null" ]]; then
    echo "$NEW_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    logger "Akeyless secretless token rotation successful"
fi
```

### Windows PowerShell
```powershell
# For complete Windows integration including PowerShell scripts,
# scheduled tasks, and C# examples, see the official documentation:
# https://docs.akeyless.io/docs/setting-up-universal-identity-for-windows-machines

# Example: Get token for Windows applications
function Get-AkeylessToken {
    $uidToken = Get-Content "C:\SecureStorage\akeyless-token.txt"
    $result = akeyless auth --access-id "/windows/non-human-auth" --uid-token $uidToken --format json
    return ($result | ConvertFrom-Json).token
}
```

## 📈 Getting Started Journey

### Phase 1: Demo & Learning
1. **Run the demo scenarios** to understand secretless concepts
2. **Explore the blog post** for comprehensive background
3. **Review implementation examples** for your tech stack

### Phase 2: Pilot Implementation
1. **Set up Universal Identity** auth methods for non-production
2. **Implement secretless workflow** in development environment
3. **Validate token rotation** and monitoring processes

### Phase 3: Production Deployment
1. **Deploy to production** with proper monitoring
2. **Implement hierarchical structure** reflecting your organization
3. **Scale across infrastructure** with automated secretless processes

## 🔗 Resources

### Documentation
- **Universal Identity Official Docs**: [docs.akeyless.io/docs/universal-identity](https://docs.akeyless.io/docs/universal-identity)
- **Windows Setup Guide**: [docs.akeyless.io/docs/setting-up-universal-identity-for-windows-machines](https://docs.akeyless.io/docs/setting-up-universal-identity-for-windows-machines)

### Demo Components
- **Blog Post**: `blog-post.md` - Complete technical article on secretless non-human identity
- **Demo Entry Point**: `start.sh` - Interactive three-persona workflow
- **Admin Setup**: `demo/scripts/admin-setup.sh` - Initial setup (Steps 1-3)
- **Platform Deploy**: `demo/scripts/platform-deploy.sh` - Service deployment
- **Client Workflow**: `demo/scenarios/client-workflow.sh` - Application service operations (Steps 4-9)
- **Child Tokens**: `demo/scenarios/child-tokens.sh` - Hierarchical management
- **Python Integration**: `demo/examples/machine-auth.py` - Real-world secretless authentication
- **Windows Guide**: [Official Akeyless Documentation](https://docs.akeyless.io/docs/setting-up-universal-identity-for-windows-machines) - Windows integration

### Support
- **Demo Issues**: Check scenario scripts for troubleshooting
- **Implementation Questions**: Reference example code in `/demo/examples/`
- **Production Planning**: Use the blog post deployment strategies section

## 🚀 Next Steps

Ready to revolutionize your non-human identity management with secretless architecture?

1. **Start with the demo**: `./start.sh` (guided three-persona workflow)
2. **Read the blog post**: Comprehensive background and implementation guidance
3. **Try the examples**: Integrate with your technology stack
4. **Plan your rollout**: Use the phased deployment approach

---

