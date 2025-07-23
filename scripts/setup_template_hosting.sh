#!/bin/bash

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <resource_group_name> <storage_account_name> [container_name]"
    exit 1
fi

# Get parameters
resource_group_name=$1
storage_account_name=$2
container_name=${3:-templates}

# Get storage account keys
echo "Getting storage account key..."
storage_key=$(az storage account keys list --resource-group $resource_group_name --account-name $storage_account_name --query "[0].value" --output tsv)

if [ -z "$storage_key" ]; then
    echo "Failed to get storage account key. Check if the storage account exists."
    exit 1
fi

# Check if container exists, create if not
container_exists=$(az storage container exists --name $container_name --account-name $storage_account_name --account-key $storage_key --query "exists" --output tsv)

if [ "$container_exists" != "true" ]; then
    echo "Container '$container_name' not found. Creating new container."
    az storage container create --name $container_name --account-name $storage_account_name --account-key $storage_key --public-access blob
fi

# Set CORS policy
echo "Setting CORS policy to allow all origins..."
az storage cors add --services b --origins "*" --methods GET HEAD OPTIONS --allowed-headers "*" --exposed-headers "*" --max-age 3600 --account-name $storage_account_name --account-key $storage_key

# Upload createUiDefinition-pds.json
echo "Uploading createUiDefinition-pds.json to container..."
az storage blob upload --file "./infrastructure/createUiDefinition-pds.json" --container-name $container_name --name "createUiDefinition-pds.json" --account-name $storage_account_name --account-key $storage_key --content-type "application/json" --overwrite

# Check if deployment.json exists, upload if not
deployment_exists=$(az storage blob exists --container-name $container_name --name "deployment.json" --account-name $storage_account_name --account-key $storage_key --query "exists" --output tsv)

if [ "$deployment_exists" != "true" ]; then
    echo "deployment.json not found in container. Uploading..."
    az storage blob upload --file "./infrastructure/deployment.json" --container-name $container_name --name "deployment.json" --account-name $storage_account_name --account-key $storage_key --content-type "application/json" --overwrite
fi

# Get storage account endpoint
storage_endpoint=$(az storage account show --name $storage_account_name --resource-group $resource_group_name --query "primaryEndpoints.blob" --output tsv)

# Output URLs
deployment_url="${storage_endpoint}${container_name}/deployment.json"
create_ui_url="${storage_endpoint}${container_name}/createUiDefinition-pds.json"

echo "Template URLs:"
echo "Deployment Template URL: $deployment_url"
echo "Create UI Definition URL: $create_ui_url"

# URL encode for Azure portal link
encoded_deployment_url=$(python -c "import urllib.parse; print(urllib.parse.quote('$deployment_url', safe=''))")
encoded_create_ui_url=$(python -c "import urllib.parse; print(urllib.parse.quote('$create_ui_url', safe=''))")

portal_url="https://portal.azure.com/#create/Microsoft.Template/uri/${encoded_deployment_url}/createUIDefinitionUri/${encoded_create_ui_url}"

echo "-----------------------------------------------------------"
echo "Azure Portal Deployment URL (Copy this for one-click deployment):"
echo "$portal_url"
echo "-----------------------------------------------------------"

echo "To test if the files are accessible and CORS is working correctly, run:"
echo "curl -X OPTIONS $create_ui_url -H 'Origin: https://portal.azure.com' -I"
