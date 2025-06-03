#!/usr/bin/env python3
"""
Akeyless Universal Identity Python Example
==========================================

This example demonstrates how to use Universal Identity tokens
in a Python application for secretless non-human authentication.

What "Secretless" Means:
- NOT "no credentials at all"
- Dynamic, auto-rotating UID tokens vs. static hardcoded API keys
- Short-lived t-tokens (hours) vs. permanent credentials (months/years)  
- Self-managing lifecycle vs. manual rotation
- Zero human intervention after bootstrap

Key concepts:
- Load UID token from secure storage (dynamic, rotates every 60 minutes)
- Authenticate to get t-token (short-lived session credentials)
- Use t-token for secret retrieval (no static secrets in application code)
- Handle token rotation (automatic, zero human intervention)
"""

import os
import json
import subprocess
import time
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import re

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Get the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# Token file is in the parent directory's tokens folder
DEFAULT_TOKEN_FILE = os.path.join(SCRIPT_DIR, "..", "tokens", "application-service-token")

class AkeylessClient:
    """
    Akeyless Universal Identity client for Python applications enabling secretless authentication
    """
    
    def __init__(self, 
                 auth_method: str,
                 token_file: str = DEFAULT_TOKEN_FILE,
                 gateway_url: str = "https://api.akeyless.io"):
        """
        Initialize the Akeyless client
        
        Args:
            auth_method: Universal Identity authentication method name
            token_file: Path to UID token storage file
            gateway_url: Akeyless gateway URL
        """
        self.auth_method = auth_method
        self.token_file = token_file
        self.gateway_url = gateway_url
        self._current_t_token = None
        self._t_token_expiry = None
        
    def _run_akeyless_command(self, command: list, use_json: bool = False) -> Optional[Dict[str, Any]]:
        """
        Run an Akeyless CLI command and return JSON result
        
        Args:
            command: Command arguments list
            use_json: Whether to add --format json and parse JSON response
            
        Returns:
            Parsed JSON response, raw string response, or None on error
        """
        try:
            cmd = ["akeyless"] + command
            if use_json:
                cmd += ["--format", "json"]
                
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True
            )
            
            if use_json and result.stdout.strip():
                return json.loads(result.stdout)
            elif result.stdout.strip():
                return {"raw_output": result.stdout.strip()}
            return {}
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Akeyless command failed: {e}")
            logger.error(f"Command: {' '.join(cmd)}")
            logger.error(f"Stderr: {e.stderr}")
            return None
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Akeyless response: {e}")
            return None
    
    def _load_uid_token(self) -> Optional[str]:
        """
        Load UID token from secure storage
        
        Returns:
            UID token string or None if not found
        """
        try:
            if os.path.exists(self.token_file):
                with open(self.token_file, 'r') as f:
                    content = f.read().strip()
                
                # Handle demo-tokens format (key=value pairs)
                if '=' in content:
                    for line in content.split('\n'):
                        if line.startswith('UID_TOKEN='):
                            token = line.split('=', 1)[1]
                            logger.debug(f"Loaded UID token from {self.token_file}")
                            return token
                    logger.warning(f"UID_TOKEN not found in {self.token_file}")
                    return None
                else:
                    # Handle single token format
                    logger.debug(f"Loaded UID token from {self.token_file}")
                    return content
            else:
                logger.warning(f"UID token file not found: {self.token_file}")
                return None
        except Exception as e:
            logger.error(f"Failed to load UID token: {e}")
            return None
    
    def _save_uid_token(self, token: str):
        """
        Save UID token to secure storage
        
        Args:
            token: UID token to save
        """
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(self.token_file), exist_ok=True)
            
            # Read existing content if file exists
            existing_content = {}
            if os.path.exists(self.token_file):
                with open(self.token_file, 'r') as f:
                    for line in f:
                        if '=' in line:
                            key, value = line.strip().split('=', 1)
                            existing_content[key] = value
            
            # Update UID_TOKEN
            existing_content['UID_TOKEN'] = token
            
            # Write back all content
            with open(self.token_file, 'w') as f:
                for key, value in existing_content.items():
                    f.write(f"{key}={value}\n")
            
            # Set secure permissions (600)
            os.chmod(self.token_file, 0o600)
            
            logger.info(f"UID token saved to {self.token_file}")
            
        except Exception as e:
            logger.error(f"Failed to save UID token: {e}")
            raise
    
    def authenticate(self, force_refresh: bool = False) -> Optional[str]:
        """
        Authenticate and get t-token using UID token (secretless pattern)
        
        Args:
            force_refresh: Force getting a new t-token even if current one is valid
            
        Returns:
            t-token string or None on failure
        """
        # Check if we have a valid t-token
        if not force_refresh and self._current_t_token and self._t_token_expiry:
            if datetime.now() < self._t_token_expiry - timedelta(minutes=5):
                logger.debug("Using cached t-token")
                return self._current_t_token
        
        # Load UID token
        uid_token = self._load_uid_token()
        if not uid_token:
            logger.error("No UID token available for secretless authentication")
            return None
        
        # Authenticate with UID token
        logger.info("Exchanging UID token for T-token (secretless pattern)...")
        
        result = self._run_akeyless_command([
            "auth",
            "--access-id", self.auth_method,
            "--access-type", "universal_identity",
            "--uid_token", uid_token
        ])
        
        if result and "raw_output" in result:
            output = result["raw_output"]
            # Parse token from output - look for token pattern
            lines = output.split('\n')
            for line in lines:
                if 'token' in line.lower() and 't-' in line:
                    # Extract token (format may vary)
                    match = re.search(r't-[a-zA-Z0-9]+', line)
                    if match:
                        self._current_t_token = match.group(0)
                        # Assume 1 hour expiry (should parse from result in real implementation)
                        self._t_token_expiry = datetime.now() + timedelta(hours=1)
                        
                        logger.info("UID → T-token exchange successful (secretless authentication)")
                        return self._current_t_token
        
        logger.error("UID → T-token exchange failed")
        return None
    
    def rotate_uid_token(self) -> bool:
        """
        Rotate the UID token and save the new one (secretless self-rotation)
        
        Returns:
            True if rotation successful, False otherwise
        """
        uid_token = self._load_uid_token()
        if not uid_token:
            logger.error("No UID token available for rotation")
            return False
        
        logger.info("Rotating UID token (secretless self-rotation)...")
        
        # Rotate token using the CLI command
        result = self._run_akeyless_command([
            "uid-rotate-token",
            "--uid-token", uid_token
        ])
        
        if result and "raw_output" in result:
            output = result["raw_output"]
            # Parse token from output like "ROTATED TOKEN: [u-XXXXXXX]"
            if "ROTATED TOKEN:" in output:
                match = re.search(r'ROTATED TOKEN: \[([^]]+)\]', output)
                if match:
                    new_token = match.group(1)
                    self._save_uid_token(new_token)
                    
                    # Clear cached t-token as it might be invalidated
                    self._current_t_token = None
                    self._t_token_expiry = None
                    
                    logger.info("Secretless UID token rotation successful")
                    return True
        
        logger.error("UID token rotation failed")
        return False
    
    def get_secret(self, secret_name: str) -> Optional[str]:
        """
        Retrieve a secret value from Akeyless using secretless authentication
        
        Args:
            secret_name: Name of the secret to retrieve
            
        Returns:
            Secret value or None on failure
        """
        t_token = self.authenticate()
        if not t_token:
            logger.error("Failed to get T-token for secret retrieval")
            return None
        
        logger.info(f"Retrieving secret '{secret_name}' using T-token...")
        
        result = self._run_akeyless_command([
            "get-secret-value",
            "--name", secret_name,
            "--token", t_token
        ])
        
        if result and "raw_output" in result:
            # Return the raw secret value
            return result["raw_output"]
        else:
            logger.error(f"Failed to retrieve secret: {secret_name}")
            return None
    
    def create_child_token(self, ttl_minutes: int = 60) -> Optional[str]:
        """
        Create a child token from the current UID token
        
        Args:
            ttl_minutes: TTL for the child token in minutes
            
        Returns:
            Child UID token or None on failure
        """
        uid_token = self._load_uid_token()
        if not uid_token:
            logger.error("No UID token available for child token creation")
            return None
        
        logger.info(f"Creating child token with TTL: {ttl_minutes} minutes")
        
        result = self._run_akeyless_command([
            "uid-create-child-token",
            "--uid-token", uid_token,
            "--child-ttl", str(ttl_minutes)
        ])
        
        if result and "raw_output" in result:
            output = result["raw_output"]
            # Parse child token from output like "Child Token: u-XXXXXXX"
            if "Child Token:" in output:
                match = re.search(r'Child Token: (u-[a-zA-Z0-9]+)', output)
                if match:
                    child_token = match.group(1)
                    logger.info(f"Child token created: {child_token[:20]}...")
                    return child_token
        
        logger.error("Failed to create child token")
        return None


class DatabaseService:
    """
    Example service that uses Akeyless for database credentials with secretless authentication
    """
    
    def __init__(self, akeyless_client: AkeylessClient):
        self.akeyless = akeyless_client
        self._db_connection = None
    
    def connect_to_database(self):
        """
        Connect to database using credentials from Akeyless (secretless pattern)
        """
        try:
            # Get database credentials from Akeyless
            db_config = self.akeyless.get_secret("/demo/database-config")
            if not db_config:
                raise Exception("Failed to retrieve database configuration")
            
            config = json.loads(db_config)
            
            logger.info(f"Connecting to database: {config.get('host')}:{config.get('port')}")
            
            # In a real application, you would use these credentials
            # to establish an actual database connection
            self._db_connection = {
                "host": config.get("host"),
                "port": config.get("port"),
                "database": config.get("database"),
                "username": config.get("username"),
                # Don't log the actual password
                "connected": True
            }
            
            logger.info("Database connection established successfully via secretless authentication")
            return True
            
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            return False
    
    def query_data(self, query: str):
        """
        Execute a database query (simulated)
        """
        if not self._db_connection or not self._db_connection.get("connected"):
            logger.error("Not connected to database")
            return None
        
        logger.info(f"Executing query: {query}")
        
        # Simulate query execution
        return {"status": "success", "rows": 42, "query": query}


def main():
    """
    Example usage of Universal Identity in a Python application for secretless authentication
    """
    print("🐍 Akeyless Universal Identity Python Example")
    print("=" * 50)
    
    # Load access ID from demo tokens file
    access_id = "/demo/uid-non-human-auth"  # Default fallback
    try:
        with open(DEFAULT_TOKEN_FILE, 'r') as f:
            for line in f:
                if line.startswith('ACCESS_ID='):
                    access_id = line.split('=', 1)[1].strip()
                    break
    except FileNotFoundError:
        pass
    
    # Initialize Akeyless client
    client = AkeylessClient(
        auth_method=access_id,
        token_file=DEFAULT_TOKEN_FILE
    )
    
    # Example 1: Basic authentication and secret retrieval
    print("\n1. Basic Secretless Authentication and Secret Retrieval")
    print("-" * 55)
    
    secret = client.get_secret("/demo/database-config")
    if secret:
        print(f"✅ Secret retrieved successfully via secretless authentication")
        print(f"📄 Secret content: {secret}")
    else:
        print("❌ Failed to retrieve secret")
    
    # Example 2: Token rotation
    print("\n2. Secretless Token Rotation")
    print("-" * 30)
    
    if client.rotate_uid_token():
        print("✅ UID token rotated successfully (secretless self-rotation)")
    else:
        print("❌ Token rotation failed")
    
    # Example 3: Child token creation
    print("\n3. Child Token Management")
    print("-" * 25)
    
    child_token = client.create_child_token(ttl_minutes=30)
    if child_token:
        print(f"✅ Child token created: {child_token[:20]}...")
    else:
        print("❌ Failed to create child token")
    
    # Example 4: Using in a service
    print("\n4. Service Integration Example (Secretless)")
    print("-" * 40)
    
    db_service = DatabaseService(client)
    if db_service.connect_to_database():
        result = db_service.query_data("SELECT * FROM users")
        print(f"✅ Query result: {result}")
    else:
        print("❌ Database service failed")
    
    print("\n✅ Python secretless authentication example completed successfully!")
    print("\n💡 Key Takeaways:")
    print("  • UID tokens enable secretless non-human authentication (dynamic vs. static)")
    print("  • T-tokens are used for actual API operations (short-lived sessions)")
    print("  • Token rotation should be automated (zero human intervention)")
    print("  • Child tokens enable hierarchical access control (service isolation)")
    print("  • No static credentials are stored anywhere (true secretless architecture)")
    print("  • Bootstrap once, self-manage forever (minimal human intervention)")


if __name__ == "__main__":
    main() 