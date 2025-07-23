#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates the deployment storage account with latest files
    
.DESCRIPTION
    This script uploads all required files for the PDS-compliant deployment
    to the Azure Storage account stcoppadeployment/coppa-deployment
    
.PARAMETER StorageAccount
    The storage account name (default: stcoppadeployment)
    
.PARAMETER Container
    The container name (default: coppa-deployment)
    
.EXAMPLE
    .\scripts\update_storage_deployment.ps1
#>

param(
    [Parameter()]
    [string]$StorageAccount = "stcoppadeployment",
    
    [Parameter()]
    [string]$Container = "coppa-deployment"
)

# Colors for output
$Green = "`e[32m"
$Blue = "`e[34m"  
$Yellow = "`e[33m"
$Reset = "`e[0m"

Write-Host "${Blue}🚀 Updating Deployment Storage Account${Reset}" -ForegroundColor Blue
Write-Host "Storage Account: $StorageAccount"
Write-Host "Container: $Container"
Write-Host ""

# Check if Azure CLI is available
if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI not found. Please install Azure CLI first."
    exit 1
}

# Check if logged in to Azure
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "${Yellow}Please log in to Azure CLI...${Reset}"
    az login
}

Write-Host "${Blue}📁 Files to Upload:${Reset}"

# Define files to upload with their local paths and blob names
$filesToUpload = @(
    # Core deployment files
    @{
        LocalPath = "infrastructure\deployment.json"
        BlobName = "deployment.json"
        Description = "Main ARM template"
        Required = $true
    },
    @{
        LocalPath = "infrastructure\createUiDefinition-pds.json"
        BlobName = "createUiDefinition-pds.json"
        Description = "PDS UI definition"
        Required = $true
    },
    
    # PowerShell scripts
    @{
        LocalPath = "scripts\setup_search_components.ps1"
        BlobName = "setup_search_components.ps1"
        Description = "Search setup script"
        Required = $true
    },
    @{
        LocalPath = "scripts\copy_sample_document.ps1"
        BlobName = "copy_sample_document.ps1"
        Description = "Sample document script"
        Required = $true
    },
    
    # New validation scripts
    @{
        LocalPath = "scripts\validate-pds-compliance.ps1"
        BlobName = "validate-pds-compliance.ps1"
        Description = "PDS compliance validation"
        Required = $false
    },
    @{
        LocalPath = "scripts\validate-template-pds.ps1"
        BlobName = "validate-template-pds.ps1"
        Description = "Template PDS validation"
        Required = $false
    },
    
    # Authentication scripts
    @{
        LocalPath = "scripts\setup_azure_ad_auth.ps1"
        BlobName = "setup_azure_ad_auth.ps1"
        Description = "Azure AD setup script"
        Required = $false
    }
)

$uploadedCount = 0
$skippedCount = 0

foreach ($file in $filesToUpload) {
    $localPath = Join-Path $PWD $file.LocalPath
    
    if (Test-Path $localPath) {
        Write-Host "  📄 $($file.Description): $($file.BlobName)"
        
        try {
            # Upload file with overwrite
            az storage blob upload `
                --account-name $StorageAccount `
                --container-name $Container `
                --name $file.BlobName `
                --file $localPath `
                --overwrite `
                --output none
                
            Write-Host "     ${Green}✅ Uploaded successfully${Reset}"
            $uploadedCount++
        }
        catch {
            Write-Host "     ❌ Upload failed: $($_.Exception.Message)"
            if ($file.Required) {
                Write-Error "Required file upload failed!"
                exit 1
            }
        }
    }
    else {
        Write-Host "  ⚠️  $($file.Description): File not found - $localPath"
        $skippedCount++
        
        if ($file.Required) {
            Write-Error "Required file missing: $localPath"
            exit 1
        }
    }
}

Write-Host ""
Write-Host "${Green}📊 Upload Summary:${Reset}"
Write-Host "  ✅ Uploaded: $uploadedCount files"
Write-Host "  ⏭️  Skipped: $skippedCount files"

Write-Host ""
Write-Host "${Blue}🔗 Your Deploy Button URL:${Reset}"
Write-Host "[![Deploy PDS Compliant](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2F$StorageAccount.blob.core.windows.net%2F$Container%2Fdeployment.json%3Fsv%3D2024-11-04%26ss%3Dbt%26srt%3Dsco%26sp%3Drltf%26se%3D2026-08-01T18%3A11%3A42Z%26st%3D2025-07-19T09%3A56%3A42Z%26spr%3Dhttps%26sig%3D8ZzA5IXoU%252FGgPS0XOkC738gYQY67DFv%252FWD0%252BI9zkioI%253D/createUIDefinitionUri/https%3A%2F%2F$StorageAccount.blob.core.windows.net%2F$Container%2FcreateUiDefinition-pds.json%3Fsv%3D2024-11-04%26ss%3Dbt%26srt%3Dsco%26sp%3Drltf%26se%3D2026-08-01T18%3A11%3A42Z%26st%3D2025-07-19T09%3A56%3A42Z%26spr%3Dhttps%26sig%3D8ZzA5IXoU%252FGgPS0XOkC738gYQY67DFv%252FWD0%252BI9zkioI%253D)"

Write-Host ""
Write-Host "${Green}🎉 Storage account update complete!${Reset}"
Write-Host ""
Write-Host "${Yellow}Next steps:${Reset}"
Write-Host "1. Test the deploy button to verify it works"
Write-Host "2. Run PDS validation: .\scripts\validate-pds-compliance.ps1 -ForceCode 'btp' -Environment 'prod' -InstanceNumber '01'"
Write-Host "3. Check deployment succeeds with compliant naming"
