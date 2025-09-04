#!/usr/bin/env python3
"""
Backend Configuration Diagnostic Script
Helps identify differences between working and non-working deployments
"""

import requests
import json
import sys

def check_deployment_config(base_url, deployment_name):
    """Check key endpoints and configuration for a deployment"""
    print(f"\n=== Checking {deployment_name} ({base_url}) ===")
    
    try:
        # Check frontend settings endpoint
        settings_response = requests.get(f"{base_url}/frontend_settings", timeout=10)
        if settings_response.status_code == 200:
            settings = settings_response.json()
            print(f"✅ Frontend settings accessible")
            print(f"   - UI Features: {settings.get('ui', {})}")
            print(f"   - Auth enabled: {settings.get('auth_enabled', 'Unknown')}")
        else:
            print(f"❌ Frontend settings failed: {settings_response.status_code}")
            
        # Try a test conversation to see backend behavior
        test_payload = {
            "messages": [{"role": "user", "content": "What is this system for?"}]
        }
        
        print(f"🔍 Testing conversation endpoint...")
        conv_response = requests.post(
            f"{base_url}/history/generate", 
            json=test_payload,
            timeout=30,
            stream=True
        )
        
        if conv_response.status_code == 200:
            print(f"✅ History/generate endpoint responding")
            # Try to read first chunk of streaming response
            try:
                first_chunk = next(conv_response.iter_lines(decode_unicode=True))
                if first_chunk:
                    print(f"   - First response chunk: {first_chunk[:100]}...")
                    # Look for citation indicators
                    if '[doc' in first_chunk or '[1]' in first_chunk or '[2]' in first_chunk:
                        print(f"   - ✅ Citations found in response")
                    else:
                        print(f"   - ❌ No citations detected in response")
            except:
                print(f"   - ⚠️  Could not read streaming response")
        else:
            print(f"❌ History/generate failed: {conv_response.status_code}")
            
    except Exception as e:
        print(f"❌ Error checking {deployment_name}: {str(e)}")

def main():
    """Main diagnostic function"""
    print("Backend Configuration Diagnostic Tool")
    print("=====================================")
    
    # Replace these with your actual deployment URLs
    working_url = "https://app-btp-prosecution-guidance.azurewebsites.net"  # Your working deployment
    broken_url = "https://app-btp-prod-01.azurewebsites.net"   # Your non-working deployment
    
    print(f"Comparing:")
    print(f"Working: {working_url}")
    print(f"Non-working: {broken_url}")
    print()
    
    check_deployment_config(working_url, "WORKING")
    check_deployment_config(broken_url, "NON-WORKING")
    
    print("\n=== Summary ===")
    print("Look for differences in:")
    print("1. Frontend settings responses")
    print("2. Whether citations appear in conversation responses")
    print("3. Any error messages or status codes")
    
    print("\nNext steps:")
    print("1. Compare Azure App Service Configuration environment variables")
    print("2. Check Azure Search service configuration")
    print("3. Verify search index has data and is properly configured")

if __name__ == "__main__":
    main()
