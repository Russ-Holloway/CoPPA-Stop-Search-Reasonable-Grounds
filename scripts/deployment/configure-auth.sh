#!/bin/bash

# Post-Deployment Authentication Configuration Script
# Run this after deploying the Azure resources to configure authentication

set -e

echo "🔧 Configuring authentication for deployed application..."

# Check if required environment variables are set
if [ -z "$AZURE_ENV_NAME" ]; then
    echo "❌ Error: AZURE_ENV_NAME environment variable is required"
    exit 1
fi

# Source environment variables if they exist
if [ -f "./.azure/$AZURE_ENV_NAME/.env" ]; then
    echo "📋 Loading environment variables from .azure/$AZURE_ENV_NAME/.env"
    source "./.azure/$AZURE_ENV_NAME/.env"
fi

# Check if we have the web app URL
if [ -z "$AZURE_APP_SERVICE_URL" ]; then
    echo "⚠️  AZURE_APP_SERVICE_URL not found. Attempting to retrieve from Azure..."
    
    # Get the app service URL from Azure CLI
    if command -v az &> /dev/null; then
        resource_group=$(az group list --query "[?tags.\"azd-env-name\"=='$AZURE_ENV_NAME'].name" -o tsv)
        if [ -n "$resource_group" ]; then
            app_name=$(az webapp list --resource-group "$resource_group" --query "[0].name" -o tsv)
            if [ -n "$app_name" ]; then
                export AZURE_APP_SERVICE_URL="https://${app_name}.azurewebsites.net"
                echo "✅ Found app service URL: $AZURE_APP_SERVICE_URL"
            fi
        fi
    fi
    
    if [ -z "$AZURE_APP_SERVICE_URL" ]; then
        echo "❌ Could not determine app service URL. Please set AZURE_APP_SERVICE_URL manually."
        exit 1
    fi
fi

echo "🔐 Initializing Azure AD application..."
python ./scripts/auth_init.py --appid "${AUTH_APP_ID:-}"

echo "🔄 Updating Azure AD application configuration..."
python ./scripts/auth_update.py

echo "✅ Authentication configuration completed!"
echo ""
echo "Next steps:"
echo "1. The Azure AD application has been created/updated"
echo "2. Authentication is now configured for your web app"
echo "3. Users can now sign in using Azure AD"
echo ""
echo "Important: Make sure to update your app service configuration with the new AUTH_CLIENT_ID and AUTH_CLIENT_SECRET values."
