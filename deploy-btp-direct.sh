#!/bin/bash

# Direct BTP Deployment Script
# Use this as a temporary solution while waiting for Azure DevOps parallelism approval

echo "🚀 Direct BTP Deployment Script"
echo "This will deploy BTP infrastructure directly using Azure CLI"

# Check if logged into Azure
if ! az account show &> /dev/null; then
    echo "❌ You need to login to Azure first:"
    echo "   az login"
    exit 1
fi

# Configuration from copa-btp-production variable group
AZURE_RESOURCE_GROUP="rg-btp-uks-p-copa-stop-search"
AZURE_LOCATION="uksouth"
FORCE_CODE="btp"
AZURE_WEBAPP_NAME="app-btp-uks-p-copa-stop-search"

echo "📋 Deployment Configuration:"
echo "   Resource Group: $AZURE_RESOURCE_GROUP"
echo "   Location: $AZURE_LOCATION"
echo "   Force Code: $FORCE_CODE"
echo "   Web App: $AZURE_WEBAPP_NAME"

# Create resource group
echo "🏗️  Creating resource group..."
az group create \
  --name "$AZURE_RESOURCE_GROUP" \
  --location "$AZURE_LOCATION" \
  --tags "Environment=Production" "Force=BTP" "Application=CoPA-Stop-Search"

if [ $? -eq 0 ]; then
    echo "✅ Resource group created successfully"
else
    echo "❌ Failed to create resource group"
    exit 1
fi

# Deploy Bicep template
echo "🚀 Deploying BTP infrastructure..."
az deployment group create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --template-file "infrastructure/deployment-btp.bicep" \
  --parameters "infrastructure/deployment-btp.bicepparam" \
  --verbose

if [ $? -eq 0 ]; then
    echo "✅ BTP infrastructure deployed successfully!"
    
    # Get the web app URL
    webAppUrl=$(az webapp show \
      --name "$AZURE_WEBAPP_NAME" \
      --resource-group "$AZURE_RESOURCE_GROUP" \
      --query "defaultHostName" \
      --output tsv 2>/dev/null)
    
    if [ ! -z "$webAppUrl" ]; then
        echo "🌐 Application URL: https://$webAppUrl"
    fi
    
    echo ""
    echo "🎉 BTP deployment completed successfully!"
    echo "📋 Next steps:"
    echo "   1. Test the application at: https://$webAppUrl"
    echo "   2. Request Azure DevOps parallelism approval for future deployments"
    echo "   3. Set up automated CI/CD once parallelism is approved"
    
else
    echo "❌ Deployment failed"
    echo "Check the error messages above for details"
    exit 1
fi