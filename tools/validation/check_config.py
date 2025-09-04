#!/usr/bin/env python3
"""
Azure App Service Configuration Checker for CoPPA
This script checks if all required environment variables are set.
"""

import os
from backend.settings import app_settings
from backend import settings

def check_configuration():
    """Check if all required configuration is present"""
    errors = []
    warnings = []
    
    print("🔍 Checking CoPPA Configuration...")
    print("=" * 50)
    
    # Required Azure OpenAI settings
    if not app_settings.azure_openai.model:
        errors.append("❌ AZURE_OPENAI_MODEL is required")
    else:
        print(f"✅ Azure OpenAI Model: {app_settings.azure_openai.model}")
    
    if not app_settings.azure_openai.endpoint and not app_settings.azure_openai.resource:
        errors.append("❌ AZURE_OPENAI_ENDPOINT or AZURE_OPENAI_RESOURCE is required")
    else:
        endpoint = app_settings.azure_openai.endpoint or f"https://{app_settings.azure_openai.resource}.openai.azure.com"
        print(f"✅ Azure OpenAI Endpoint: {endpoint}")
    
    # Check API version
    if app_settings.azure_openai.preview_api_version < settings.MINIMUM_SUPPORTED_AZURE_OPENAI_PREVIEW_API_VERSION:
        errors.append(f"❌ Azure OpenAI API version must be at least {settings.MINIMUM_SUPPORTED_AZURE_OPENAI_PREVIEW_API_VERSION}")
    else:
        print(f"✅ Azure OpenAI API Version: {app_settings.azure_openai.preview_api_version}")
    
    # Check authentication
    if not app_settings.azure_openai.key:
        print("⚠️ No AZURE_OPENAI_KEY found, will use Managed Identity")
        warnings.append("Using Managed Identity for Azure OpenAI authentication")
    else:
        print("✅ Azure OpenAI Key configured")
    
    # Check search configuration
    if app_settings.datasource:
        print("✅ Search datasource configured")
        if hasattr(app_settings.datasource, 'service') and app_settings.datasource.service:
            print(f"✅ Azure Search Service: {app_settings.datasource.service}")
        if hasattr(app_settings.datasource, 'index') and app_settings.datasource.index:
            print(f"✅ Azure Search Index: {app_settings.datasource.index}")
    else:
        warnings.append("⚠️ No search datasource configured - search functionality will be disabled")
    
    # Check chat history
    if app_settings.chat_history:
        print(f"✅ CosmosDB configured: {app_settings.chat_history.account}")
    else:
        warnings.append("⚠️ CosmosDB not configured - chat history will be disabled")
    
    # Print results
    print("\n" + "=" * 50)
    print("📋 CONFIGURATION SUMMARY")
    print("=" * 50)
    
    if errors:
        print("❌ ERRORS (must be fixed):")
        for error in errors:
            print(f"  {error}")
        print()
    
    if warnings:
        print("⚠️ WARNINGS (optional):")
        for warning in warnings:
            print(f"  {warning}")
        print()
    
    if not errors and not warnings:
        print("✅ All configuration looks good!")
    elif not errors:
        print("✅ Required configuration is complete!")
        print("⚠️ Some optional features may not be available due to warnings above")
    else:
        print("❌ Configuration errors found - app may not start properly")
        return False
    
    return True

if __name__ == "__main__":
    try:
        success = check_configuration()
        exit(0 if success else 1)
    except Exception as e:
        print(f"❌ Configuration check failed: {str(e)}")
        print("\nThis usually means required environment variables are missing.")
        print("Please check your Azure App Service configuration.")
        exit(1)
