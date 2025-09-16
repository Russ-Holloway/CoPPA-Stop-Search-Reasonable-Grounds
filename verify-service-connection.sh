#!/bin/bash

# Script to verify BTP-Production service connection exists and is configured correctly

echo "🔍 Checking BTP-Production Service Connection..."

# Source the PAT token
source ./set-pat.sh

# List all service connections
echo "📋 Current Service Connections:"
SERVICE_CONNECTIONS=$(az devops service-endpoint list --project "CoPA-Stop-Search-Secure-Deployment" --organization "https://dev.azure.com/uk-police-copa/" 2>/dev/null)

if [ "$SERVICE_CONNECTIONS" = "[]" ]; then
    echo "❌ No service connections found"
    echo ""
    echo "🛠️  You need to create the BTP-Production service connection"
    echo "   Option 1: Run './create-service-connection.sh' (requires az login)"
    echo "   Option 2: Create manually in Azure DevOps portal:"
    echo "            https://dev.azure.com/uk-police-copa/CoPA-Stop-Search-Secure-Deployment/_settings/adminservices"
    echo ""
    echo "Required Service Connection Details:"
    echo "   Name: BTP-Production"
    echo "   Type: Azure Resource Manager"
    echo "   Scope: Subscription"
    echo "   Authentication: Service Principal (automatic)"
else
    echo "✅ Service connections found:"
    echo "$SERVICE_CONNECTIONS" | jq -r '.[] | "   \(.name) (\(.type)) - \(.description // "No description")"'
    
    # Check specifically for BTP-Production
    BTP_CONNECTION=$(echo "$SERVICE_CONNECTIONS" | jq -r '.[] | select(.name=="BTP-Production") | .name')
    
    if [ "$BTP_CONNECTION" = "BTP-Production" ]; then
        echo "✅ BTP-Production service connection exists!"
        
        # Show details
        echo ""
        echo "📋 BTP-Production Connection Details:"
        echo "$SERVICE_CONNECTIONS" | jq -r '.[] | select(.name=="BTP-Production") | "   ID: \(.id)\n   Type: \(.type)\n   Ready: \(.isReady)\n   Description: \(.description // "None")"'
    else
        echo "❌ BTP-Production service connection not found"
        echo "   Available connections:"
        echo "$SERVICE_CONNECTIONS" | jq -r '.[] | "   - \(.name)"'
    fi
fi

echo ""
echo "🎯 Next Steps:"
echo "   1. Ensure BTP-Production service connection exists"
echo "   2. Verify it has access to your BTP Azure subscription"
echo "   3. Check it has Contributor permissions"
echo "   4. Test the pipeline can access it"