#!/usr/bin/env python3
"""
Test script to verify Cognito configuration and login functionality
"""
import json
import os
from pycognito import Cognito

def test_cognito_config():
    """Test if Cognito configuration is complete"""
    print("🔍 Testing Cognito Configuration...")
    
    # Load config
    try:
        with open('cognito-config.json', 'r') as f:
            config = json.load(f)
        
        print(f"✅ Config file loaded")
        print(f"   User Pool ID: {config.get('USER_POOL_ID', 'MISSING')}")
        print(f"   Client ID: {config.get('CLIENT_ID', 'MISSING')}")
        print(f"   Client Secret: {'SET' if config.get('CLIENT_SECRET') else 'MISSING'}")
        print(f"   Region: {config.get('REGION', 'MISSING')}")
        
        # Check if required fields are present
        missing_fields = []
        if not config.get('USER_POOL_ID'):
            missing_fields.append('USER_POOL_ID')
        if not config.get('CLIENT_ID'):
            missing_fields.append('CLIENT_ID')
        if not config.get('CLIENT_SECRET'):
            missing_fields.append('CLIENT_SECRET')
            
        if missing_fields:
            print(f"❌ Missing required fields: {', '.join(missing_fields)}")
            return False
        else:
            print("✅ All required configuration fields are present")
            return True
            
    except FileNotFoundError:
        print("❌ cognito-config.json not found")
        return False
    except json.JSONDecodeError:
        print("❌ Invalid JSON in cognito-config.json")
        return False

def test_sample_users():
    """Display sample users that should be available"""
    print("\n👥 Sample Users (from setup script):")
    users = [
        ("admin", "password123", "admin@ecogrid.com"),
        ("john_doe", "energy2025", "john@ecogrid.com"),
        ("sarah_green", "solar123", "sarah@ecogrid.com"),
        ("mike_wind", "turbine456", "mike@ecogrid.com"),
        ("lisa_hydro", "water789", "lisa@ecogrid.com")
    ]
    
    for username, password, email in users:
        print(f"   • {username} / {password} ({email})")

def test_app_integration():
    """Test if the Flask app can load with Cognito config"""
    print("\n🔧 Testing Flask App Integration...")
    
    try:
        # Set environment variables from config
        with open('cognito-config.json', 'r') as f:
            config = json.load(f)
        
        os.environ['COGNITO_USER_POOL_ID'] = config.get('USER_POOL_ID', '')
        os.environ['COGNITO_CLIENT_ID'] = config.get('CLIENT_ID', '')
        os.environ['COGNITO_REGION'] = config.get('REGION', 'us-east-1')
        
        # Try to import the app
        from app import app, COGNITO_USER_POOL_ID, COGNITO_CLIENT_ID, COGNITO_REGION
        
        print(f"✅ Flask app loaded successfully")
        print(f"   App User Pool ID: {COGNITO_USER_POOL_ID}")
        print(f"   App Client ID: {COGNITO_CLIENT_ID}")
        print(f"   App Region: {COGNITO_REGION}")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to load Flask app: {str(e)}")
        return False

def main():
    print("🧪 EcoGrid Cognito Functionality Test\n")
    
    config_ok = test_cognito_config()
    test_sample_users()
    app_ok = test_app_integration()
    
    print(f"\n📊 Test Results:")
    print(f"   Configuration: {'✅ PASS' if config_ok else '❌ FAIL'}")
    print(f"   App Integration: {'✅ PASS' if app_ok else '❌ FAIL'}")
    
    if config_ok and app_ok:
        print(f"\n🎉 Cognito setup appears functional!")
        print(f"   Next steps:")
        print(f"   1. Ensure AWS credentials are configured")
        print(f"   2. Run setup-cognito.sh to create users")
        print(f"   3. Test login at /login endpoint")
    else:
        print(f"\n⚠️  Issues found - Cognito may not work properly")

if __name__ == "__main__":
    main()
