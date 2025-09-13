#!/usr/bin/env python3
"""
Debug script to identify what's causing the Flask app boot failure.
"""
import os
import logging
import traceback

# Configure logging to see detailed error messages
logging.basicConfig(level=logging.DEBUG)

def test_environment_variables():
    """Test if all required environment variables are present"""
    print("=== Environment Variable Check ===")
    required_vars = [
        "AZURE_OPENAI_ENDPOINT",
        "AZURE_SEARCH_SERVICE", 
        "AZURE_SEARCH_INDEX",
        "AZURE_OPENAI_API_VERSION"
    ]
    
    missing = []
    for var in required_vars:
        value = os.environ.get(var)
        if value:
            print(f"✓ {var}: {value[:20]}...")
        else:
            print(f"✗ {var}: MISSING")
            missing.append(var)
    
    return missing

def test_security_validation():
    """Test security validation function"""
    print("\n=== Security Validation Test ===")
    try:
        from backend.settings import validate_security_environment
        validate_security_environment()
        print("✓ Security validation passed")
        return True
    except Exception as e:
        print(f"✗ Security validation failed: {e}")
        traceback.print_exc()
        return False

def test_app_settings():
    """Test app settings initialization"""
    print("\n=== App Settings Test ===")
    try:
        from backend.settings import _AppSettings
        settings = _AppSettings()
        print("✓ App settings initialized successfully")
        print(f"  - UI title: {settings.ui.title}")
        print(f"  - Azure OpenAI endpoint: {settings.azure_openai.endpoint}")
        return True
    except Exception as e:
        print(f"✗ App settings initialization failed: {e}")
        traceback.print_exc()
        return False

def test_minimal_app():
    """Test creating minimal Quart app"""
    print("\n=== Minimal App Creation Test ===")
    try:
        from quart import Quart
        app = Quart(__name__)
        print("✓ Quart app created successfully")
        return True
    except Exception as e:
        print(f"✗ Quart app creation failed: {e}")
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🔍 Debugging Flask App Boot Failure\n")
    
    # Run tests in order
    missing_vars = test_environment_variables()
    
    if missing_vars:
        print(f"\n❌ Missing required environment variables: {missing_vars}")
        print("Please ensure all required environment variables are set in Azure App Service.")
    else:
        security_ok = test_security_validation()
        if security_ok:
            settings_ok = test_app_settings()
            if settings_ok:
                app_ok = test_minimal_app()
                if app_ok:
                    print("\n✅ All tests passed! The issue might be in app startup logic.")
                else:
                    print("\n❌ Quart app creation failed.")
            else:
                print("\n❌ App settings initialization failed.")
        else:
            print("\n❌ Security validation failed.")
    
    print("\n🔧 Try these fixes:")
    print("1. Check Azure App Service environment variables configuration")
    print("2. Restart the Azure App Service") 
    print("3. Check for any recent code changes that might have broken initialization")