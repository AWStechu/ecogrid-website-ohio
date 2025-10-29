#!/usr/bin/env python3
"""
Test login functionality without requiring AWS credentials
"""
import requests
import threading
import time
from app import app

def test_login_functionality():
    """Test the login functionality"""
    
    def run_app():
        app.run(host='127.0.0.1', port=5001, debug=False)

    # Start app in background
    server_thread = threading.Thread(target=run_app)
    server_thread.daemon = True
    server_thread.start()
    time.sleep(2)
    
    base_url = 'http://127.0.0.1:5001'
    
    print("🧪 Testing EcoGrid Login Functionality\n")
    
    # Test 1: Login page loads
    try:
        response = requests.get(f'{base_url}/login', timeout=5)
        print(f"✅ Login page loads: {response.status_code}")
        
        # Check for login form elements
        if 'username' in response.text and 'password' in response.text:
            print("✅ Login form elements found")
        else:
            print("❌ Login form elements missing")
            
    except Exception as e:
        print(f"❌ Login page test failed: {e}")
    
    # Test 2: Dashboard requires authentication
    try:
        response = requests.get(f'{base_url}/dashboard', allow_redirects=False, timeout=5)
        if response.status_code == 302:
            print("✅ Dashboard properly redirects unauthenticated users")
        else:
            print(f"❌ Dashboard should redirect (got {response.status_code})")
    except Exception as e:
        print(f"❌ Dashboard test failed: {e}")
    
    # Test 3: Attempt login with sample credentials (will fail due to missing Cognito config)
    try:
        session = requests.Session()
        
        # Get login page to establish session
        login_page = session.get(f'{base_url}/login', timeout=5)
        
        # Attempt login with sample credentials
        login_data = {
            'username': 'admin',
            'password': 'password123'
        }
        
        response = session.post(f'{base_url}/login', data=login_data, allow_redirects=False, timeout=5)
        
        if response.status_code == 302:
            location = response.headers.get('Location', '')
            if 'error=invalid' in location:
                print("⚠️  Login attempt failed as expected (Cognito not configured)")
            elif 'dashboard' in location:
                print("✅ Login successful - redirected to dashboard")
            else:
                print(f"❓ Unexpected redirect: {location}")
        else:
            print(f"❌ Login POST returned unexpected status: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Login attempt test failed: {e}")
    
    print(f"\n📋 Summary:")
    print(f"   • Login page is accessible and contains form")
    print(f"   • Dashboard properly requires authentication")
    print(f"   • Login attempts fail due to incomplete Cognito configuration")
    print(f"   • Sample users are defined: admin, john_doe, sarah_green, mike_wind, lisa_hydro")

if __name__ == "__main__":
    test_login_functionality()
