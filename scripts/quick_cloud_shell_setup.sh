#!/bin/bash
# Quick Azure Cloud Shell Setup for stcoppadeployment02
# Copy and paste this entire script into Azure Cloud Shell

RESOURCE_GROUP="rg-btp-uks-prod-ai-coppa-stop-search"
STORAGE_ACCOUNT="stcoppadeployment02"
CONTAINER_NAME="coppa-deployment"

echo "🚀 Setting up $STORAGE_ACCOUNT..."

# Check storage account
if ! az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP >/dev/null 2>&1; then
    echo "❌ Storage account not found"
    exit 1
fi
echo "✅ Storage account found"

# Create container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --public-access blob >/dev/null 2>&1
echo "✅ Container ready"

# Configure CORS
az storage cors add --methods GET POST PUT --origins "https://portal.azure.com" "https://ms.portal.azure.com" "*" --allowed-headers "*" --exposed-headers "*" --max-age 3600 --services b --account-name $STORAGE_ACCOUNT >/dev/null 2>&1
echo "✅ CORS configured"

# Generate SAS token
SAS_TOKEN=$(az storage account generate-sas --account-name $STORAGE_ACCOUNT --services b --resource-types sco --permissions rltp --expiry $(date -u -d "+1 year" +"%Y-%m-%dT%H:%M:%SZ") --https-only --output tsv)
echo "✅ SAS token generated"

# Build URLs
BASE_URL="https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER_NAME"
DEPLOYMENT_URL="$BASE_URL/deployment.json?$SAS_TOKEN"
CREATE_UI_SIMPLE_URL="$BASE_URL/createUiDefinition-simple.json?$SAS_TOKEN"

# URL encode
ENCODED_DEPLOYMENT_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$DEPLOYMENT_URL', safe=''))")
ENCODED_CREATE_UI_SIMPLE_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CREATE_UI_SIMPLE_URL', safe=''))")

# Final Deploy URL
DEPLOY_URL="https://portal.azure.com/#create/Microsoft.Template/uri/$ENCODED_DEPLOYMENT_URL/createUIDefinitionUri/$ENCODED_CREATE_UI_SIMPLE_URL"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Deploy to Azure URL:"
echo "$DEPLOY_URL"
echo ""
echo "📝 SAS Token:"
echo "$SAS_TOKEN"
echo ""
echo "📤 Upload commands (run these after script completes):"
echo "curl -o deployment.json https://raw.githubusercontent.com/Russ-Holloway/CoPPA-Stop-Search-Reasonable-Grounds/Dev/Test/infrastructure/deployment.json"
echo "curl -o createUiDefinition-simple.json https://raw.githubusercontent.com/Russ-Holloway/CoPPA-Stop-Search-Reasonable-Grounds/Dev/Test/infrastructure/createUiDefinition-simple.json"
echo "az storage blob upload --file deployment.json --name deployment.json --container-name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --overwrite"
echo "az storage blob upload --file createUiDefinition-simple.json --name createUiDefinition-simple.json --container-name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --overwrite"
