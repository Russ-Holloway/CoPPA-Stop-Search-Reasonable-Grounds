#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Uploads the setup-search-components.ps1 script to Azure Blob Storage to be used by the ARM template.
.DESCRIPTION
    This script uploads the setup-search-components.ps1 script to the Azure Blob Storage location 
    specified in the ARM template. This ensures that the ARM template uses our latest script.
.PARAMETER StorageAccountName
    The name of the Azure Storage account where the script should be uploaded.
.PARAMETER ContainerName
    The name of the container in the storage account.
.PARAMETER SasToken
    The SAS token for accessing the storage account.
.EXAMPLE
    .\upload_search_script.ps1 -StorageAccountName "stbtpukssandopenai" -ContainerName "policing-assistant-azure-deployment-template" -SasToken "?sp=racwdl&st=..."
#>

param(
    [Parameter(Mandatory=$true)]
    [string] $StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string] $ContainerName,
    
    [Parameter(Mandatory=$true)]
    [string] $SasToken
)

# Verify script exists
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "setup-search-components.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Error "Script not found at: $scriptPath"
    exit 1
}

# Construct the destination URL
$destinationUrl = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/setup_search_components.ps1$SasToken"

# Upload the script to blob storage
Write-Host "Uploading script to: $destinationUrl"
$headers = @{
    "x-ms-blob-type" = "BlockBlob"
    "Content-Type" = "text/plain"
}

try {
    $scriptContent = Get-Content -Path $scriptPath -Raw
    $response = Invoke-RestMethod -Uri $destinationUrl -Method Put -Headers $headers -Body $scriptContent
    Write-Host "Script uploaded successfully! The ARM template will now use your local script."
}
catch {
    Write-Error "Failed to upload script: $_"
    exit 1
}

# Verify upload by downloading the script
Write-Host "Verifying upload..."
$downloadUrl = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/setup_search_components.ps1$SasToken"

try {
    $downloadedScript = Invoke-RestMethod -Uri $downloadUrl -Method Get
    Write-Host "Verification successful. Script is available at the destination URL."
    
    # Compare file sizes as a basic verification
    $originalSize = (Get-Item $scriptPath).Length
    $downloadedSize = $downloadedScript.Length
    
    Write-Host "Original script size: $originalSize bytes"
    Write-Host "Uploaded script size: $downloadedSize bytes"
    
    if ($originalSize -ne $downloadedSize) {
        Write-Warning "Script sizes don't match. The upload might be incomplete or modified."
    }
}
catch {
    Write-Error "Failed to verify upload: $_"
    exit 1
}

Write-Host -ForegroundColor Green "Complete! The ARM template will now use your local script during deployment."
Write-Host "Note: Make sure the SAS token has sufficient permissions and validity period."
