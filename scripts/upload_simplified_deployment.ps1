#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Uploads the simplified PDS deployment files to Azure Storage
    
.DESCRIPTION
    This script uploads the updated deployment.json and new simplified UI definition
    that automatically handles PDS naming behind the scenes.
    
.EXAMPLE
    .\scripts\upload_simplified_deployment.ps1
#>

# Colors for output
$Green = "`e[32m"
$Blue = "`e[34m"  
$Yellow = "`e[33m"
$Reset = "`e[0m"

Write-Host "${Blue}🚀 Uploading Simplified PDS Deployment${Reset}" -ForegroundColor Blue
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

Write-Host "${Blue}📋 What's New in Simplified Deployment:${Reset}"
Write-Host "✅ Environment automatically set to 'prod'"
Write-Host "✅ Instance number automatically set to '01'" 
Write-Host "✅ Force code extracted from resource group name"
Write-Host "✅ Only OpenAI model selection required from user"
Write-Host "✅ All PDS naming happens behind the scenes"
Write-Host ""

# Files to upload
$filesToUpload = @(
    @{
        LocalPath = "infrastructure\deployment.json"
        BlobName = "deployment.json"
        Description = "Updated ARM template with automatic PDS parameters"
        Required = $true
    },
    @{
        LocalPath = "infrastructure\createUiDefinition-simple.json"
        BlobName = "createUiDefinition-simple.json"
        Description = "Simplified UI definition (automatic naming)"
        Required = $true
    }
)

$uploadedCount = 0

foreach ($file in $filesToUpload) {
    $localPath = Join-Path $PWD $file.LocalPath
    
    if (Test-Path $localPath) {
        Write-Host "${Blue}📤 Uploading: $($file.Description)${Reset}"
        
        try {
            # Upload file with overwrite
            az storage blob upload `
                --account-name "stcoppadeployment" `
                --container-name "coppa-deployment" `
                --name $file.BlobName `
                --file $localPath `
                --overwrite `
                --auth-mode login
                
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
        Write-Host "  ⚠️  File not found: $localPath"
        if ($file.Required) {
            Write-Error "Required file missing: $localPath"
            exit 1
        }
    }
}

Write-Host ""
Write-Host "${Green}📊 Upload Summary: $uploadedCount files uploaded${Reset}"
Write-Host ""
Write-Host "${Blue}🔗 Updated Deploy Button URL:${Reset}"
Write-Host "[![Deploy PDS Compliant](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fstcoppadeployment.blob.core.windows.net%2Fcoppa-deployment%2Fdeployment.json%3Fsv%3D2024-11-04%26ss%3Dbt%26srt%3Dsco%26sp%3Drltf%26se%3D2026-08-01T18%3A11%3A42Z%26st%3D2025-07-19T09%3A56%3A42Z%26spr%3Dhttps%26sig%3D8ZzA5IXoU%252FGgPS0XOkC738gYQY67DFv%252FWD0%252BI9zkioI%253D/createUIDefinitionUri/https%3A%2F%2Fstcoppadeployment.blob.core.windows.net%2Fcoppa-deployment%2FcreateUiDefinition-simple.json%3Fsv%3D2024-11-04%26ss%3Dbt%26srt%3Dsco%26sp%3Drltf%26se%3D2026-08-01T18%3A11%3A42Z%26st%3D2025-07-19T09%3A56%3A42Z%26spr%3Dhttps%26sig%3D8ZzA5IXoU%252FGgPS0XOkC738gYQY67DFv%252FWD0%252BI9zkioI%253D)"

Write-Host ""
Write-Host "${Green}🎉 Simplified Deployment Ready!${Reset}"
Write-Host ""
Write-Host "${Blue}🎯 New User Experience:${Reset}"
Write-Host "1. User creates resource group: 'rg-btp-prod-01'"
Write-Host "2. Clicks deploy button"
Write-Host "3. Selects OpenAI models"
Write-Host "4. Everything deploys with perfect PDS naming!"
Write-Host ""
Write-Host "${Yellow}📝 Example Resource Names Generated:${Reset}"
Write-Host "• App Service: app-btp-prod-01"
Write-Host "• Storage Account: stbtpprod01"
Write-Host "• Search Service: srch-btp-prod-01"  
Write-Host "• OpenAI Service: cog-btp-prod-01"
Write-Host ""
Write-Host "${Green}✨ Users never see the complexity - it just works!${Reset}"
