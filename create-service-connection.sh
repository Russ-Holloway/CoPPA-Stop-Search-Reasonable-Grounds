#!/bin/bash

# Script to create BTP-Production service connection
# This script requires you to be logged into Azure CLI first

echo "🔐 Creating BTP-Production Service Connection..."

# Check if logged into Azure
if ! az account show &> /dev/null; then
    echo "❌ You need to login to Azure first:"
    echo "   az login"
    exit 1
fi

# Get current subscription details
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "📋 Current Azure Context:"
echo "   Subscription: $SUBSCRIPTION_NAME"
echo "   ID: $SUBSCRIPTION_ID"
echo "   Tenant: $TENANT_ID"

# Create service connection using Azure DevOps CLI
echo "🚀 Creating service connection..."

az devops service-endpoint azurerm create \
    --azure-rm-service-principal-id "" \
    --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
    --azure-rm-subscription-name "$SUBSCRIPTION_NAME" \
    --azure-rm-tenant-id "$TENANT_ID" \
    --name "BTP-Production" \
    --project "CoPA-Stop-Search-Secure-Deployment" \
    --organization "https://dev.azure.com/uk-police-copa/"

if [ $? -eq 0 ]; then
    echo "✅ BTP-Production service connection created successfully!"
    echo "🔍 Listing all service connections:"
    az devops service-endpoint list --project "CoPA-Stop-Search-Secure-Deployment" --organization "https://dev.azure.com/uk-police-copa/" --output table
else
    echo "❌ Failed to create service connection"
    echo "💡 You may need to create it manually through the Azure DevOps portal"
fi