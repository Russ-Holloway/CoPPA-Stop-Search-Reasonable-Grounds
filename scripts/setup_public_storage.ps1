param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location
)

# Login to Azure (you may need to be logged in first)
# az login

# Create resource group if it doesn't exist
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "Creating resource group $ResourceGroupName..."
    az group create --name $ResourceGroupName --location $Location
}

# Create storage account if it doesn't exist
$storageAccountExists = az storage account check-name --name $StorageAccountName --query "nameAvailable"
if ($storageAccountExists -ne "false") {
    Write-Host "Creating storage account $StorageAccountName..."
    az storage account create `
        --name $StorageAccountName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --allow-blob-public-access true
}

# Get storage account key
$storageKey = $(az storage account keys list --resource-group $ResourceGroupName --account-name $StorageAccountName --query "[0].value" -o tsv)

# Create container if it doesn't exist
$containerExists = az storage container exists --name $ContainerName --account-name $StorageAccountName --account-key $storageKey --query "exists"
if ($containerExists -ne "true") {
    Write-Host "Creating container $ContainerName..."
    az storage container create `
        --name $ContainerName `
        --account-name $StorageAccountName `
        --account-key $storageKey `
        --public-access blob
}

# Set CORS policy for the storage account
Write-Host "Configuring CORS policy..."
az storage account cors add `
    --account-name $StorageAccountName `
    --account-key $storageKey `
    --services b `
    --methods GET OPTIONS `
    --origins "*" `
    --allowed-headers "*" `
    --exposed-headers "*" `
    --max-age 3600

Write-Host "Public blob storage container setup complete!"
Write-Host "Container URL: https://$StorageAccountName.blob.core.windows.net/$ContainerName"
