# Akeyless Universal Identity Demo

This directory contains hands-on demonstrations of Universal Identity token management capabilities.

## 🚀 Quick Start

### 1. Setup Demo Environment
```bash
./scripts/setup-demo-environment.sh
```

### 2. Try Core Scenarios
```bash
# Basic UID token workflow
./scenarios/basic-workflow.sh

# Token rotation examples
./scenarios/token-rotation.sh

# Hierarchical token management
./scenarios/child-tokens.sh
```

### 3. Windows Integration
For complete Windows machine setup and PowerShell integration, see the [official Akeyless documentation](https://docs.akeyless.io/docs/setting-up-universal-identity-for-windows-machines).

## 📁 Demo Structure

```
demo/
├── scenarios/                     # Interactive demo scenarios
│   ├── basic-workflow.sh          # Core UID → T-token operations
│   ├── token-rotation.sh          # Token rotation examples
│   └── child-tokens.sh            # Hierarchical token management
├── scripts/                       # Setup and automation scripts
│   ├── setup-demo-environment.sh  # Initialize demo with Akeyless
│   ├── simple-rotate-token.sh     # Simple token rotation (Akeyless aligned)
│   └── auto-rotate-token.sh       # Enterprise rotation with full features
├── tokens/                        # Local token storage (for demo only)
│   └── demo-tokens                # Current demo tokens (auto-generated)
└── examples/                      # Implementation examples
    └── machine-auth.py            # Python client example
```

## 🔄 Token Rotation Scripts

### Simple Rotation (`simple-rotate-token.sh`)
**Recommended for most users** - Aligned with official Akeyless approach:

```bash
# Initialize with token and setup cron
./scripts/simple-rotate-token.sh init

# Manual rotation
./scripts/simple-rotate-token.sh rotate

# Check token status
./scripts/simple-rotate-token.sh status
```

**Features:**
- ✅ Simple init/rotate pattern
- ✅ Auto-configures hourly cron job
- ✅ Basic logging and backup
- ✅ Follows official Akeyless conventions

### Enterprise Rotation (`auto-rotate-token.sh`)
**For enterprise environments** - Advanced features:

```bash
# Run with custom config
./scripts/auto-rotate-token.sh --config /etc/akeyless/rotation-config.json
```

**Features:**
- ✅ JSON configuration files
- ✅ Webhook notifications
- ✅ Retry logic with exponential backoff
- ✅ Pre/post rotation hooks
- ✅ Comprehensive logging and monitoring
- ✅ Lock file management

## 📋 Demo Scenarios

### Basic Workflow (`basic-workflow.sh`)
Demonstrates the core Universal Identity pattern:
1. Generate UID token
2. Authenticate to get T-token
3. Access secrets using T-token

### Token Rotation (`token-rotation.sh`)
Shows automated token rotation:
1. Check current token status
2. Rotate UID token (resets TTL)
3. Verify new token works
4. Production automation examples

### Child Tokens (`child-tokens.sh`)
Demonstrates hierarchical token management:
1. Create parent-child token relationships
2. View token tree structure
3. Use child tokens for authentication
4. Revocation scenarios (self vs. self+children)

## 💼 Real-World Examples

### Python Integration
```python
from examples.machine_auth import AkeylessClient

client = AkeylessClient("/demo/uid-machine-auth", "/secure/token")
secret = client.get_secret("/demo/database-config")
```

### CI/CD Integration
```bash
# In your pipeline
T_TOKEN=$(akeyless auth --access-id "/ci-cd/pipeline" --uid-token "$UID_TOKEN" --format json | jq -r '.token')
DB_PASSWORD=$(akeyless get-secret-value --name "/prod/db-password" --token "$T_TOKEN")
```

### Automated Rotation
```bash
# Simple approach - auto-configured during init
./scripts/simple-rotate-token.sh init

# Enterprise approach - with monitoring
./scripts/auto-rotate-token.sh --config /etc/akeyless/config.json
```

## ⚙️ Configuration

### Environment Variables
Required for demo scenarios:
```bash
export AKEYLESS_ACCESS_ID="your-access-id"
export AKEYLESS_ACCESS_KEY="your-access-key"
export AKEYLESS_GATEWAY="https://api.akeyless.io"
```

### Simple Rotation Config
No configuration needed - uses sensible defaults:
- Token file: `~/.akeyless-uid-token`
- Log file: `~/.akeyless-rotation.log`
- Rotation: Hourly via cron

### Enterprise Rotation Config
JSON configuration file example:
```json
{
  "token_file": "/secure/akeyless-token",
  "log_file": "/var/log/akeyless-rotation.log",
  "backup_tokens": 3,
  "notification_webhook": "https://your-webhook.com/alerts",
  "pre_rotation_script": "/path/to/pre-rotation.sh",
  "post_rotation_script": "/path/to/post-rotation.sh"
}
```

## 🎯 Next Steps

1. **Start with basic workflow**: `./scenarios/basic-workflow.sh`
2. **Set up simple rotation**: `./scripts/simple-rotate-token.sh init`
3. **Explore hierarchical tokens**: `./scenarios/child-tokens.sh`
4. **Review implementation examples**: `examples/machine-auth.py`
5. **Plan production deployment**: Use enterprise rotation for production

## 🗂️ Demo Token Storage

The demo scripts store tokens locally in `./tokens/demo-tokens` for easy demonstration purposes:

```bash
# View current demo tokens
cat tokens/demo-tokens

# Example content:
UID_TOKEN=u-AQAAADwAAAA...
T_TOKEN=t-79d83f429fb...
AUTH_METHOD=/demo/uid-non-human-auth
ACCESS_ID=p-4io8civv4u9fum
```

**Note**: The `tokens/` directory is git-ignored to prevent accidental commit of actual tokens.

## 📚 Additional Resources