#!/usr/bin/env python3
"""
Script to complete Cognito setup and verify functionality
"""
import json
import subprocess
import os

def check_aws_credentials():
    """Check if AWS credentials are configured"""
    try:
        result = subprocess.run(['aws', 'sts', 'get-caller-identity'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ AWS credentials are configured")
            return True
        else:
            print("❌ AWS credentials not configured")
            print("   Run: aws configure")
            return False
    except Exception as e:
        print(f"❌ Error checking AWS credentials: {e}")
        return False

def run_cognito_setup():
    """Run the Cognito setup script"""
    print("\n🔧 Running Cognito setup script...")
    
    if not os.path.exists('./setup-cognito.sh'):
        print("❌ setup-cognito.sh not found")
        return False
    
    try:
        # Make script executable
        subprocess.run(['chmod', '+x', './setup-cognito.sh'], check=True)
        
        # Run setup script
        result = subprocess.run(['./setup-cognito.sh'], 
                              capture_output=True, text=True, timeout=120)
        
        if result.returncode == 0:
            print("✅ Cognito setup completed successfully")
            print(result.stdout)
            return True
        else:
            print("❌ Cognito setup failed")
            print(result.stderr)
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ Cognito setup timed out")
        return False
    except Exception as e:
        print(f"❌ Error running setup: {e}")
        return False

def verify_cognito_config():
    """Verify the Cognito configuration is complete"""
    try:
        with open('cognito-config.json', 'r') as f:
            config = json.load(f)
        
        required_fields = ['USER_POOL_ID', 'CLIENT_ID', 'CLIENT_SECRET', 'REGION']
        missing = [field for field in required_fields if not config.get(field)]
        
        if missing:
            print(f"❌ Missing configuration: {', '.join(missing)}")
            return False
        else:
            print("✅ Cognito configuration is complete")
            return True
            
    except Exception as e:
        print(f"❌ Error reading config: {e}")
        return False

def test_cognito_users():
    """Test if Cognito users can be listed"""
    try:
        with open('cognito-config.json', 'r') as f:
            config = json.load(f)
        
        user_pool_id = config.get('USER_POOL_ID')
        if not user_pool_id:
            print("❌ No User Pool ID found")
            return False
        
        result = subprocess.run([
            'aws', 'cognito-idp', 'list-users',
            '--user-pool-id', user_pool_id,
            '--region', config.get('REGION', 'us-east-1')
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            users_data = json.loads(result.stdout)
            users = users_data.get('Users', [])
            print(f"✅ Found {len(users)} users in Cognito")
            
            for user in users:
                username = user.get('Username', 'Unknown')
                status = user.get('UserStatus', 'Unknown')
                print(f"   • {username} ({status})")
            
            return len(users) > 0
        else:
            print("❌ Failed to list Cognito users")
            print(result.stderr)
            return False
            
    except Exception as e:
        print(f"❌ Error testing users: {e}")
        return False

def main():
    print("🔐 EcoGrid Cognito Setup Completion\n")
    
    # Step 1: Check AWS credentials
    if not check_aws_credentials():
        print("\n❌ Cannot proceed without AWS credentials")
        print("   Please run: aws configure")
        return
    
    # Step 2: Check current config
    config_complete = verify_cognito_config()
    
    # Step 3: Run setup if needed
    if not config_complete:
        print("\n🔧 Cognito configuration incomplete, running setup...")
        if run_cognito_setup():
            config_complete = verify_cognito_config()
    
    # Step 4: Test users
    if config_complete:
        print("\n👥 Testing Cognito users...")
        users_exist = test_cognito_users()
        
        if users_exist:
            print("\n🎉 Cognito setup is complete and functional!")
            print("\n📋 Next steps:")
            print("   1. Test login at: http://your-domain/login")
            print("   2. Use sample credentials:")
            print("      • admin / password123")
            print("      • john_doe / energy2025")
            print("      • sarah_green / solar123")
            print("      • mike_wind / turbine456")
            print("      • lisa_hydro / water789")
        else:
            print("\n⚠️  Configuration complete but no users found")
    else:
        print("\n❌ Cognito setup incomplete")

if __name__ == "__main__":
    main()
