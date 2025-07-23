#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up deployment files in the new storage account stcoppadeployment02 and generates new SAS tokens.

.DESCRIPTION
    This script:
    1. Uploads deployment files to stcoppadeployment02
    2. Generates new SAS tokens valid for 1 year
    3. Updates all relevant files with the new storage account name and SAS tokens
    4. Provides the new deployment URLs

.PARAMETER ResourceGroupName
    The resource group containing the storage account (required)

.PARAMETER StorageAccountName
    The storage account name (default: stcoppadeployment02)

.PARAMETER ContainerName
    The container name (default: coppa-deployment)

.EXAMPLE
    .\setup_new_storage_deployment.ps1 -ResourceGroupName "rg-coppa-deployment"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [string]$StorageAccountName = "stcoppadeployment02",
    
    [string]$ContainerName = "coppa-deployment"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 Setting up deployment files in storage account: $StorageAccountName" -ForegroundColor Green
Write-Host "📁 Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "📦 Container: $ContainerName" -ForegroundColor Yellow

# Check if Azure CLI is installed and logged in
try {
    $account = az account show --query "name" -o tsv 2>$null
    if (-not $account) {
        throw "Not logged in"
    }
    Write-Host "✅ Logged in to Azure as: $account" -ForegroundColor Green
} catch {
    Write-Host "❌ Please log in to Azure CLI first: az login" -ForegroundColor Red
    exit 1
}

# Verify storage account exists
Write-Host "🔍 Checking if storage account exists..." -ForegroundColor Yellow
try {
    $storageExists = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
    if (-not $storageExists) {
        throw "Storage account not found"
    }
    Write-Host "✅ Storage account found: $StorageAccountName" -ForegroundColor Green
} catch {
    Write-Host "❌ Storage account '$StorageAccountName' not found in resource group '$ResourceGroupName'" -ForegroundColor Red
    Write-Host "Please create the storage account first or check the resource group name." -ForegroundColor Yellow
    exit 1
}

# Create container if it doesn't exist
Write-Host "📦 Creating container if it doesn't exist..." -ForegroundColor Yellow
try {
    az storage container create `
        --name $ContainerName `
        --account-name $StorageAccountName `
        --public-access blob `
        --only-show-errors
    Write-Host "✅ Container '$ContainerName' is ready" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create container" -ForegroundColor Red
    exit 1
}

# Enable CORS for the storage account
Write-Host "🌐 Configuring CORS settings..." -ForegroundColor Yellow
try {
    az storage cors add `
        --methods GET POST PUT `
        --origins "https://portal.azure.com" "https://ms.portal.azure.com" "*" `
        --allowed-headers "*" `
        --exposed-headers "*" `
        --max-age 3600 `
        --services b `
        --account-name $StorageAccountName `
        --only-show-errors
    Write-Host "✅ CORS configured successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Warning: Could not configure CORS. You may need to set this manually." -ForegroundColor Yellow
}

# Upload deployment files
Write-Host "📤 Uploading deployment files..." -ForegroundColor Yellow

$filesToUpload = @(
    @{ Local = "infrastructure\deployment.json"; Blob = "deployment.json" },
    @{ Local = "infrastructure\createUiDefinition-simple.json"; Blob = "createUiDefinition-simple.json" },
    @{ Local = "infrastructure\createUiDefinition-pds.json"; Blob = "createUiDefinition-pds.json" },
    @{ Local = "infrastructure\createUiDefinition.json"; Blob = "createUiDefinition.json" }
)

foreach ($file in $filesToUpload) {
    $localPath = Join-Path $PSScriptRoot ".." $file.Local
    if (Test-Path $localPath) {
        Write-Host "  📄 Uploading $($file.Local)..." -ForegroundColor Cyan
        try {
            az storage blob upload `
                --file $localPath `
                --name $file.Blob `
                --container-name $ContainerName `
                --account-name $StorageAccountName `
                --overwrite `
                --only-show-errors
            Write-Host "    ✅ Uploaded successfully" -ForegroundColor Green
        } catch {
            Write-Host "    ❌ Failed to upload $($file.Local)" -ForegroundColor Red
        }
    } else {
        Write-Host "    ⚠️  File not found: $localPath" -ForegroundColor Yellow
    }
}

# Generate SAS tokens (valid for 1 year from today)
Write-Host "🔑 Generating SAS tokens..." -ForegroundColor Yellow
$startDate = (Get-Date).ToString("yyyy-MM-dd")
$endDate = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")

try {
    $sasToken = az storage account generate-sas `
        --account-name $StorageAccountName `
        --services b `
        --resource-types sco `
        --permissions rltp `
        --expiry $endDate `
        --start $startDate `
        --https-only `
        --output tsv

    if (-not $sasToken) {
        throw "Failed to generate SAS token"
    }
    
    Write-Host "✅ SAS token generated successfully" -ForegroundColor Green
    Write-Host "📅 Valid from: $startDate" -ForegroundColor Cyan
    Write-Host "📅 Valid until: $endDate" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Failed to generate SAS token" -ForegroundColor Red
    exit 1
}

# Generate the new URLs
$baseUrl = "https://$StorageAccountName.blob.core.windows.net/$ContainerName"
$deploymentUrl = "$baseUrl/deployment.json?$sasToken"
$createUiSimpleUrl = "$baseUrl/createUiDefinition-simple.json?$sasToken"
$createUiPdsUrl = "$baseUrl/createUiDefinition-pds.json?$sasToken"

# URL encode the URLs for use in the Deploy to Azure button
$encodedDeploymentUrl = [System.Web.HttpUtility]::UrlEncode($deploymentUrl)
$encodedCreateUiSimpleUrl = [System.Web.HttpUtility]::UrlEncode($createUiSimpleUrl)
$encodedCreateUiPdsUrl = [System.Web.HttpUtility]::UrlEncode($createUiPdsUrl)

# Generate the Deploy to Azure URLs
$deployToAzureSimple = "https://portal.azure.com/#create/Microsoft.Template/uri/$encodedDeploymentUrl/createUIDefinitionUri/$encodedCreateUiSimpleUrl"
$deployToAzurePds = "https://portal.azure.com/#create/Microsoft.Template/uri/$encodedDeploymentUrl/createUIDefinitionUri/$encodedCreateUiPdsUrl"

Write-Host ""
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 New Deployment URLs:" -ForegroundColor Yellow
Write-Host "├─ Simple UI: $deployToAzureSimple" -ForegroundColor Cyan
Write-Host "└─ PDS UI: $deployToAzurePds" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run the update script to modify all files:" -ForegroundColor White
Write-Host "   .\scripts\update_files_for_new_storage.ps1 -SasToken '$sasToken'" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Or manually update the following in your markdown files:" -ForegroundColor White
Write-Host "   Replace: stcoppadeployment.blob.core.windows.net" -ForegroundColor Red
Write-Host "   With: $StorageAccountName.blob.core.windows.net" -ForegroundColor Green
Write-Host ""
Write-Host "📝 SAS Token (save this for updates):" -ForegroundColor Yellow
Write-Host "$sasToken" -ForegroundColor Cyan

# Save the information to a file for later reference
$infoFile = Join-Path $PSScriptRoot "deployment-info-$StorageAccountName.txt"
@"
Deployment Information for $StorageAccountName
Generated: $(Get-Date)
Valid until: $endDate

Storage Account: $StorageAccountName
Resource Group: $ResourceGroupName
Container: $ContainerName

SAS Token: $sasToken

Deployment URLs:
- Simple UI: $deployToAzureSimple
- PDS UI: $deployToAzurePds

Base URLs for manual construction:
- Deployment JSON: $deploymentUrl
- Simple CreateUI: $createUiSimpleUrl
- PDS CreateUI: $createUiPdsUrl
"@ | Out-File -FilePath $infoFile -Encoding UTF8

Write-Host ""
Write-Host "💾 Deployment information saved to: $infoFile" -ForegroundColor Green
