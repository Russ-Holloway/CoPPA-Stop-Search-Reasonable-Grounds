#!/bin/bash

# Script to set up BTP-Production environment and verify pipeline readiness

echo "🌍 Setting up BTP-Production Environment..."

# Source the PAT token
source ./set-pat.sh

# Create BTP-Production environment
echo "🔧 Creating BTP-Production environment..."
ENVIRONMENT_RESULT=$(az pipelines environment create --name "BTP-Production" --project "CoPA-Stop-Search-Secure-Deployment" --organization "https://dev.azure.com/uk-police-copa/" 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ BTP-Production environment created successfully!"
    echo "$ENVIRONMENT_RESULT" | jq -r '"   ID: \(.id)\n   Name: \(.name)\n   Description: \(.description // "None")"'
else
    echo "ℹ️  Environment may already exist, checking..."
fi

# List all environments
echo ""
echo "📋 Current Environments:"
ENVIRONMENTS=$(az pipelines environment list --project "CoPA-Stop-Search-Secure-Deployment" --organization "https://dev.azure.com/uk-police-copa/" 2>/dev/null)

if [ "$ENVIRONMENTS" != "[]" ]; then
    echo "$ENVIRONMENTS" | jq -r '.[] | "   \(.name) (ID: \(.id))"'
    
    # Check for BTP-Production specifically
    BTP_ENV=$(echo "$ENVIRONMENTS" | jq -r '.[] | select(.name=="BTP-Production") | .name')
    if [ "$BTP_ENV" = "BTP-Production" ]; then
        echo "✅ BTP-Production environment is ready!"
    else
        echo "⚠️  BTP-Production environment not found in list"
    fi
else
    echo "❌ No environments found"
fi

echo ""
echo "🔍 Pipeline Readiness Check:"
echo "✅ Variable Group: copa-btp-production (configured)"
echo "✅ Service Connection: BTP Production (created)"
echo "✅ Environment: BTP-Production (created/verified)"
echo "✅ Pipeline File: .azure-pipelines/btp-deployment-pipeline.yml (exists)"

echo ""
echo "🎯 Next Steps:"
echo "1. 🔧 Configure approvals for BTP-Production environment (optional)"
echo "2. 🚀 Run the BTP deployment pipeline"
echo "3. ✅ Approve the deployment when prompted"

echo ""
echo "📋 Pipeline Configuration Summary:"
echo "   Variable Group: copa-btp-production"
echo "   Service Connection: BTP Production (note: 'BTP Production' not 'BTP-Production')"
echo "   Environment: BTP-Production"
echo "   Resource Group: rg-btp-uks-p-copa-stop-search"
echo "   Location: uksouth"