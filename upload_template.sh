#!/bin/bash

# Upload ARM Template to Storage Account with CORS Support
# This script uploads the deployment template to your storage account

STORAGE_ACCOUNT="stcoppadeployment02"
CONTAINER_NAME="coppa-deployment"
RESOURCE_GROUP="rg-coppa-test-02"
TEMPLATE_FILE="infrastructure/deployment.json"
UI_DEFINITION_FILE="infrastructure/createUiDefinition.json"

echo "🚀 Uploading ARM template with CORS support..."
echo "=================================================="

# Check if files exist
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Template file not found: $TEMPLATE_FILE"
    exit 1
fi

if [ ! -f "$UI_DEFINITION_FILE" ]; then
    echo "❌ UI definition file not found: $UI_DEFINITION_FILE"
    exit 1
fi

echo "✅ Found template files"

# Upload deployment.json
echo "📤 Uploading deployment.json..."
az storage blob upload \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER_NAME \
    --name deployment.json \
    --file $TEMPLATE_FILE \
    --overwrite

if [ $? -eq 0 ]; then
    echo "✅ deployment.json uploaded successfully"
else
    echo "❌ Failed to upload deployment.json"
    exit 1
fi

# Upload createUiDefinition-pds.json
echo "📤 Uploading createUiDefinition-pds.json..."
az storage blob upload \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER_NAME \
    --name createUiDefinition.json \
    --file $UI_DEFINITION_FILE \
    --overwrite

if [ $? -eq 0 ]; then
    echo "✅ createUiDefinition.json uploaded successfully"
else
    echo "❌ Failed to upload createUiDefinition.json"
    exit 1
fi

# Update CORS settings
echo "🔧 Updating CORS settings..."
az storage cors add \
    --account-name $STORAGE_ACCOUNT \
    --services b \
    --methods GET HEAD OPTIONS \
    --origins "https://portal.azure.com" "https://ms.portal.azure.com" "https://preview.portal.azure.com" \
    --allowed-headers "*" \
    --exposed-headers "*" \
    --max-age 200

if [ $? -eq 0 ]; then
    echo "✅ CORS settings updated successfully"
else
    echo "❌ Failed to update CORS settings"
    exit 1
fi

# Generate SAS token for the template
echo "🔑 Generating SAS token..."
TEMPLATE_SAS=$(az storage blob generate-sas \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER_NAME \
    --name deployment.json \
    --permissions r \
    --expiry $(date -d "+1 year" +%Y-%m-%d) \
    --output tsv)

UI_SAS=$(az storage blob generate-sas \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER_NAME \
    --name createUiDefinition.json \
    --permissions r \
    --expiry $(date -d "+1 year" +%Y-%m-%d) \
    --output tsv)

if [ $? -eq 0 ]; then
    echo "✅ SAS tokens generated successfully"
    echo ""
    echo "🔗 Template URLs:"
    echo "=================================================="
    echo "Template URL:"
    echo "https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER_NAME/deployment.json?$TEMPLATE_SAS"
    echo ""
    echo "UI Definition URL:"
    echo "https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER_NAME/createUiDefinition.json?$UI_SAS"
    echo ""
    echo "🎯 Azure Portal Deploy Button URL:"
    echo "https://portal.azure.com/#create/Microsoft.Template/uri/$(echo "https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER_NAME/deployment.json?$TEMPLATE_SAS" | python3 -c "import urllib.parse; print(urllib.parse.quote(input()))")"
else
    echo "❌ Failed to generate SAS tokens"
    exit 1
fi

echo ""
echo "🎉 Upload completed successfully!"
echo "You can now use the template URL in Azure Portal"
