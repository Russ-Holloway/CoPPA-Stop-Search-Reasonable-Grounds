#!/bin/bash
# Azure Cloud Shell Script for Setting Up stcoppadeployment02
# Run this in Azure Cloud Shell (shell.azure.com) to bypass CA policies

# Configuration
RESOURCE_GROUP="rg-btp-uks-prod-ai-coppa-stop-search"
STORAGE_ACCOUNT="stcoppadeployment02"
CONTAINER_NAME="coppa-deployment"

echo "🚀 Setting up deployment files in storage account: $STORAGE_ACCOUNT"
echo "📁 Resource Group: $RESOURCE_GROUP"
echo "📦 Container: $CONTAINER_NAME"

# Verify storage account exists
echo "🔍 Checking if storage account exists..."
STORAGE_EXISTS=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "name" -o tsv 2>/dev/null)
if [ -z "$STORAGE_EXISTS" ]; then
    echo "❌ Storage account '$STORAGE_ACCOUNT' not found in resource group '$RESOURCE_GROUP'"
    echo "Please create the storage account first or check the resource group name."
    exit 1
fi
echo "✅ Storage account found: $STORAGE_ACCOUNT"

# Create container if it doesn't exist
echo "📦 Creating container if it doesn't exist..."
az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT \
    --public-access blob \
    --only-show-errors
echo "✅ Container '$CONTAINER_NAME' is ready"

# Enable CORS for the storage account
echo "🌐 Configuring CORS settings..."
az storage cors add \
    --methods GET POST PUT \
    --origins "https://portal.azure.com" "https://ms.portal.azure.com" "*" \
    --allowed-headers "*" \
    --exposed-headers "*" \
    --max-age 3600 \
    --services b \
    --account-name $STORAGE_ACCOUNT \
    --only-show-errors
echo "✅ CORS configured successfully"

# Generate SAS tokens (valid for 1 year from today)
echo "🔑 Generating SAS tokens..."
START_DATE=$(date -u +"%Y-%m-%d")
END_DATE=$(date -u -d "+1 year" +"%Y-%m-%d")

SAS_TOKEN=$(az storage account generate-sas \
    --account-name $STORAGE_ACCOUNT \
    --services b \
    --resource-types sco \
    --permissions rltp \
    --expiry $END_DATE \
    --start $START_DATE \
    --https-only \
    --output tsv)

if [ -z "$SAS_TOKEN" ]; then
    echo "❌ Failed to generate SAS token"
    exit 1
fi

echo "✅ SAS token generated successfully"
echo "📅 Valid from: $START_DATE"
echo "📅 Valid until: $END_DATE"

# Generate the new URLs
BASE_URL="https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER_NAME"
DEPLOYMENT_URL="$BASE_URL/deployment.json?$SAS_TOKEN"
CREATE_UI_SIMPLE_URL="$BASE_URL/createUiDefinition-simple.json?$SAS_TOKEN"
CREATE_UI_PDS_URL="$BASE_URL/createUiDefinition-pds.json?$SAS_TOKEN"

# URL encode the URLs for use in the Deploy to Azure button
ENCODED_DEPLOYMENT_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$DEPLOYMENT_URL', safe=''))")
ENCODED_CREATE_UI_SIMPLE_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CREATE_UI_SIMPLE_URL', safe=''))")
ENCODED_CREATE_UI_PDS_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CREATE_UI_PDS_URL', safe=''))")

# Generate the Deploy to Azure URLs
DEPLOY_TO_AZURE_SIMPLE="https://portal.azure.com/#create/Microsoft.Template/uri/$ENCODED_DEPLOYMENT_URL/createUIDefinitionUri/$ENCODED_CREATE_UI_SIMPLE_URL"
DEPLOY_TO_AZURE_PDS="https://portal.azure.com/#create/Microsoft.Template/uri/$ENCODED_DEPLOYMENT_URL/createUIDefinitionUri/$ENCODED_CREATE_UI_PDS_URL"

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 New Deployment URLs:"
echo "├─ Simple UI: $DEPLOY_TO_AZURE_SIMPLE"
echo "└─ PDS UI: $DEPLOY_TO_AZURE_PDS"
echo ""
echo "📝 SAS Token (save this for updates):"
echo "$SAS_TOKEN"
echo ""
echo "📤 Now you need to upload these files to the storage account:"
echo "1. Upload infrastructure/deployment.json as deployment.json"
echo "2. Upload infrastructure/createUiDefinition-simple.json as createUiDefinition-simple.json"
echo "3. Upload infrastructure/createUiDefinition-pds.json as createUiDefinition-pds.json"
echo "4. Upload infrastructure/createUiDefinition.json as createUiDefinition.json"
echo ""
echo "🔧 Upload commands:"
echo "az storage blob upload --file ./infrastructure/deployment.json --name deployment.json --container-name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --overwrite"
echo "az storage blob upload --file ./infrastructure/createUiDefinition-simple.json --name createUiDefinition-simple.json --container-name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --overwrite"
echo "az storage blob upload --file ./infrastructure/createUiDefinition-pds.json --name createUiDefinition-pds.json --container-name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --overwrite"
echo "az storage blob upload --file ./infrastructure/createUiDefinition.json --name createUiDefinition.json --container-name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --overwrite"

# Save the information to a file for later reference
INFO_FILE="deployment-info-$STORAGE_ACCOUNT.txt"
cat > $INFO_FILE << EOF
Deployment Information for $STORAGE_ACCOUNT
Generated: $(date)
Valid until: $END_DATE

Storage Account: $STORAGE_ACCOUNT
Resource Group: $RESOURCE_GROUP
Container: $CONTAINER_NAME

SAS Token: $SAS_TOKEN

Deployment URLs:
- Simple UI: $DEPLOY_TO_AZURE_SIMPLE
- PDS UI: $DEPLOY_TO_AZURE_PDS

Base URLs for manual construction:
- Deployment JSON: $DEPLOYMENT_URL
- Simple CreateUI: $CREATE_UI_SIMPLE_URL
- PDS CreateUI: $CREATE_UI_PDS_URL
EOF

echo ""
echo "💾 Deployment information saved to: $INFO_FILE"
