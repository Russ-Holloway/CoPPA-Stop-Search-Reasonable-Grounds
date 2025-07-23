#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Upload files using storage account key (bypasses Azure CLI auth)
    
.DESCRIPTION
    Alternative upload method when Azure CLI login is blocked by Conditional Access
    
.PARAMETER StorageAccountKey
    The storage account access key (get from Azure Portal)
    
.EXAMPLE
    .\upload_with_key.ps1 -StorageAccountKey "your-storage-key-here"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountKey
)

# Colors for output
$Green = "`e[32m"
$Blue = "`e[34m"  
$Yellow = "`e[33m"
$Reset = "`e[0m"

Write-Host "${Blue}🔑 Uploading via Storage Account Key${Reset}"
Write-Host ""

# Storage account details
$StorageAccountName = "stcoppadeployment"
$ContainerName = "coppa-deployment"

# Create storage context
try {
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    Write-Host "${Green}✅ Storage context created${Reset}"
}
catch {
    Write-Error "Failed to create storage context. Check your storage account key."
    exit 1
}

# Files to upload
$filesToUpload = @(
    @{
        LocalPath = "infrastructure\deployment.json"
        BlobName = "deployment.json"
        Description = "Enhanced ARM template with auto-parameters"
    },
    @{
        LocalPath = "infrastructure\createUiDefinition-simple.json" 
        BlobName = "createUiDefinition-simple.json"
        Description = "Simplified UI definition"
    }
)

foreach ($file in $filesToUpload) {
    $localPath = Join-Path $PWD $file.LocalPath
    
    if (Test-Path $localPath) {
        Write-Host "${Blue}📤 Uploading: $($file.Description)${Reset}"
        
        try {
            Set-AzStorageBlobContent `
                -File $localPath `
                -Container $ContainerName `
                -Blob $file.BlobName `
                -Context $ctx `
                -Force
                
            Write-Host "     ${Green}✅ Uploaded successfully${Reset}"
        }
        catch {
            Write-Host "     ❌ Upload failed: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "  ⚠️  File not found: $localPath"
    }
}

Write-Host ""
Write-Host "${Green}🎉 Upload complete! Your simplified deployment is ready.${Reset}"
Write-Host ""
Write-Host "${Blue}🔗 Updated Deploy Button URL:${Reset}"
Write-Host "https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fstcoppadeployment.blob.core.windows.net%2Fcoppa-deployment%2Fdeployment.json%3Fsv%3D2024-11-04%26ss%3Dbt%26srt%3Dsco%26sp%3Drltf%26se%3D2026-08-01T18%3A11%3A42Z%26st%3D2025-07-19T09%3A56%3A42Z%26spr%3Dhttps%26sig%3D8ZzA5IXoU%252FGgPS0XOkC738gYQY67DFv%252FWD0%252BI9zkioI%253D/createUIDefinitionUri/https%3A%2F%2Fstcoppadeployment.blob.core.windows.net%2Fcoppa-deployment%2FcreateUiDefinition-simple.json%3Fsv%3D2024-11-04%26ss%3Dbt%26srt%3Dsco%26sp%3Drltf%26se%3D2026-08-01T18%3A11%3A42Z%26st%3D2025-07-19T09%3A56%3A42Z%26spr%3Dhttps%26sig%3D8ZzA5IXoU%252FGgPS0XOkC738gYQY67DFv%252FWD0%252BI9zkioI%253D"
