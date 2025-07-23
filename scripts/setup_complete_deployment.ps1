#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete setup for the new storage account deployment configuration.

.DESCRIPTION
    This script runs the complete process to:
    1. Upload files to your new storage account stcoppadeployment02
    2. Generate new SAS tokens
    3. Update all files in the repository with the new URLs

.PARAMETER ResourceGroupName
    The resource group containing your stcoppadeployment02 storage account

.EXAMPLE
    .\setup_complete_deployment.ps1 -ResourceGroupName "rg-coppa-deployment"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting complete deployment setup for stcoppadeployment02" -ForegroundColor Green
Write-Host "📁 Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host ""

# Step 1: Setup storage and upload files
Write-Host "📤 Step 1: Setting up storage account and uploading files..." -ForegroundColor Cyan
& "$PSScriptRoot\setup_new_storage_deployment.ps1" -ResourceGroupName $ResourceGroupName

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Storage setup failed. Please check the errors above." -ForegroundColor Red
    exit 1
}

# Get the SAS token from the generated info file
$infoFile = Join-Path $PSScriptRoot "deployment-info-stcoppadeployment02.txt"
if (Test-Path $infoFile) {
    $infoContent = Get-Content $infoFile -Raw
    if ($infoContent -match "SAS Token: (.+)") {
        $sasToken = $matches[1].Trim()
        Write-Host "✅ Retrieved SAS token from info file" -ForegroundColor Green
        
        # Step 2: Update all files
        Write-Host ""
        Write-Host "🔄 Step 2: Updating all files with new storage account..." -ForegroundColor Cyan
        & "$PSScriptRoot\update_files_for_new_storage.ps1" -SasToken $sasToken
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "🎉 Complete setup finished successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "✅ Your deployment is now configured to use stcoppadeployment02" -ForegroundColor Green
            Write-Host "✅ All files have been updated with new URLs" -ForegroundColor Green
            Write-Host "✅ SAS tokens are valid for 1 year" -ForegroundColor Green
            Write-Host ""
            Write-Host "📋 Next steps:" -ForegroundColor Yellow
            Write-Host "1. Review the updated README.md file" -ForegroundColor White
            Write-Host "2. Test the Deploy to Azure button" -ForegroundColor White
            Write-Host "3. Commit and push your changes" -ForegroundColor White
        } else {
            Write-Host "❌ File update failed. Please check the errors above." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "❌ Could not extract SAS token from info file" -ForegroundColor Red
        Write-Host "Please run the update script manually with your SAS token" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "❌ Could not find deployment info file: $infoFile" -ForegroundColor Red
    Write-Host "Please run the update script manually with your SAS token" -ForegroundColor Yellow
    exit 1
}
