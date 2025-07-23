#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates all files to use the new storage account stcoppadeployment02 and new SAS tokens.

.DESCRIPTION
    This script updates:
    - README.md
    - All documentation files
    - All PowerShell scripts
    - Any other files containing the old storage account references

.PARAMETER SasToken
    The new SAS token generated for stcoppadeployment02 (required)

.PARAMETER StorageAccountName
    The new storage account name (default: stcoppadeployment02)

.EXAMPLE
    .\update_files_for_new_storage.ps1 -SasToken "sv=2024-11-04&ss=bt&srt=sco&sp=rltf&se=2026-07-23T18:00:00Z&st=2025-07-23T10:00:00Z&spr=https&sig=ABC123"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SasToken,
    
    [string]$StorageAccountName = "stcoppadeployment02"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🔄 Updating files to use new storage account: $StorageAccountName" -ForegroundColor Green

# URL encode the SAS token
Add-Type -AssemblyName System.Web
$encodedSasToken = [System.Web.HttpUtility]::UrlEncode($SasToken)

# Define the old and new base URLs
$oldStorageAccount = "stcoppadeployment"
$newStorageAccount = $StorageAccountName

# Build the new URLs
$baseUrl = "https://$newStorageAccount.blob.core.windows.net/coppa-deployment"
$deploymentUrl = "$baseUrl/deployment.json?$SasToken"
$createUiSimpleUrl = "$baseUrl/createUiDefinition-simple.json?$SasToken"
$createUiPdsUrl = "$baseUrl/createUiDefinition-pds.json?$SasToken"

# URL encode for Deploy to Azure buttons
$encodedDeploymentUrl = [System.Web.HttpUtility]::UrlEncode($deploymentUrl)
$encodedCreateUiSimpleUrl = [System.Web.HttpUtility]::UrlEncode($createUiSimpleUrl)
$encodedCreateUiPdsUrl = [System.Web.HttpUtility]::UrlEncode($createUiPdsUrl)

# Generate the new Deploy to Azure URLs
$newDeployButtonSimple = "https://portal.azure.com/#create/Microsoft.Template/uri/$encodedDeploymentUrl/createUIDefinitionUri/$encodedCreateUiSimpleUrl"
$newDeployButtonPds = "https://portal.azure.com/#create/Microsoft.Template/uri/$encodedDeploymentUrl/createUIDefinitionUri/$encodedCreateUiPdsUrl"

# Find all files that might contain the old storage account name
$filesToUpdate = @()

# Get all markdown files
$filesToUpdate += Get-ChildItem -Path $PSScriptRoot\.. -Filter "*.md" -Recurse | Where-Object { $_.Name -notlike "node_modules*" }

# Get all PowerShell scripts
$filesToUpdate += Get-ChildItem -Path $PSScriptRoot\.. -Filter "*.ps1" -Recurse | Where-Object { $_.Name -notlike "node_modules*" -and $_.Name -ne "update_files_for_new_storage.ps1" }

# Get documentation files
$filesToUpdate += Get-ChildItem -Path $PSScriptRoot\..\docs -Filter "*.*" -Recurse -ErrorAction SilentlyContinue

Write-Host "📁 Found $($filesToUpdate.Count) files to check for updates" -ForegroundColor Yellow

$updatedFiles = 0
$skippedFiles = 0

foreach ($file in $filesToUpdate) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        $originalContent = $content
        
        # Check if file contains the old storage account name
        if ($content -match $oldStorageAccount) {
            Write-Host "📝 Updating: $($file.Name)" -ForegroundColor Cyan
            
            # Replace the storage account name in all contexts
            $content = $content -replace [regex]::Escape($oldStorageAccount), $newStorageAccount
            
            # For markdown files, also update the Deploy to Azure button URLs completely
            if ($file.Extension -eq ".md") {
                # Replace the entire Deploy button URL for simple UI
                $content = $content -replace 'https://portal\.azure\.com/#create/Microsoft\.Template/uri/https%3A%2F%2F[^)]+createUiDefinition-simple\.json[^)]+', $newDeployButtonSimple
                
                # Replace the entire Deploy button URL for PDS UI  
                $content = $content -replace 'https://portal\.azure\.com/#create/Microsoft\.Template/uri/https%3A%2F%2F[^)]+createUiDefinition-pds\.json[^)]+', $newDeployButtonPds
                
                # Also replace any standalone URLs that might be in the documentation
                $content = $content -replace 'https://portal\.azure\.com/#create/Microsoft\.Template/uri/https%3A%2F%2F[^"]+createUiDefinition\.json[^"]+', $newDeployButtonSimple
            }
            
            # For PowerShell scripts, update the account name parameter
            if ($file.Extension -eq ".ps1") {
                $content = $content -replace '--account-name\s+"stcoppadeployment"', "--account-name `"$newStorageAccount`""
                $content = $content -replace '\$StorageAccountName\s*=\s*"stcoppadeployment"', "`$StorageAccountName = `"$newStorageAccount`""
            }
            
            # Only write if content actually changed
            if ($content -ne $originalContent) {
                Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
                $updatedFiles++
                Write-Host "  ✅ Updated successfully" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  No changes needed" -ForegroundColor Yellow
                $skippedFiles++
            }
        } else {
            $skippedFiles++
        }
    } catch {
        Write-Host "  ❌ Error updating $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Update Summary:" -ForegroundColor Yellow
Write-Host "├─ Files updated: $updatedFiles" -ForegroundColor Green
Write-Host "├─ Files skipped: $skippedFiles" -ForegroundColor Cyan
Write-Host "└─ Total checked: $($filesToUpdate.Count)" -ForegroundColor White

Write-Host ""
Write-Host "🎉 File updates completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 New Deploy to Azure URLs:" -ForegroundColor Yellow
Write-Host "├─ Simple UI: $newDeployButtonSimple" -ForegroundColor Cyan
Write-Host "└─ PDS UI: $newDeployButtonPds" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Important: Please verify the updates in key files:" -ForegroundColor Yellow
Write-Host "├─ README.md" -ForegroundColor White
Write-Host "├─ docs/PDS-DEPLOYMENT-GUIDE.md" -ForegroundColor White
Write-Host "└─ Any deployment scripts" -ForegroundColor White

# Save a summary
$summaryFile = Join-Path $PSScriptRoot "update-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
@"
File Update Summary - $(Get-Date)
Storage Account: $newStorageAccount
SAS Token: $SasToken

Files Updated: $updatedFiles
Files Skipped: $skippedFiles
Total Checked: $($filesToUpdate.Count)

New Deploy URLs:
- Simple: $newDeployButtonSimple
- PDS: $newDeployButtonPds
"@ | Out-File -FilePath $summaryFile -Encoding UTF8

Write-Host ""
Write-Host "💾 Update summary saved to: $summaryFile" -ForegroundColor Green
