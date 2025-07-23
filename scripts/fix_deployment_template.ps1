#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fixes the deployment template issue by uploading the updated ARM template
    
.DESCRIPTION
    This script uploads the updated deployment.json template with PDS parameters
    to fix the "ForceCode parameter not found" error.
    
.EXAMPLE
    .\scripts\fix_deployment_template.ps1
#>

# Colors for output
$Green = "`e[32m"
$Red = "`e[31m"
$Blue = "`e[34m"  
$Yellow = "`e[33m"
$Reset = "`e[0m"

Write-Host "${Blue}🔧 Fixing Deployment Template Issue${Reset}" -ForegroundColor Blue
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

Write-Host "${Red}🚨 Problem Identified:${Reset}"
Write-Host "Your storage account has an old version of deployment.json without PDS parameters"
Write-Host ""

Write-Host "${Blue}📝 Solution:${Reset}"
Write-Host "Uploading updated deployment.json with PDS parameters (ForceCode, EnvironmentSuffix, InstanceNumber)"
Write-Host ""

# Verify local template has the required parameters
$templatePath = "infrastructure\deployment.json"
if (-not (Test-Path $templatePath)) {
    Write-Error "Template file not found: $templatePath"
    exit 1
}

try {
    $template = Get-Content $templatePath | ConvertFrom-Json
    $hasForceCode = $template.parameters.PSObject.Properties.Name -contains "ForceCode"
    $hasEnvironmentSuffix = $template.parameters.PSObject.Properties.Name -contains "EnvironmentSuffix" 
    $hasInstanceNumber = $template.parameters.PSObject.Properties.Name -contains "InstanceNumber"
    
    if ($hasForceCode -and $hasEnvironmentSuffix -and $hasInstanceNumber) {
        Write-Host "${Green}✅ Local template has all required PDS parameters${Reset}"
    } else {
        Write-Error "❌ Local template is missing PDS parameters. Please ensure you have the updated version."
        exit 1
    }
    
} catch {
    Write-Error "Failed to parse local template: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "${Blue}📤 Uploading updated template...${Reset}"

try {
    # Upload the updated template
    az storage blob upload `
        --account-name "stcoppadeployment" `
        --container-name "coppa-deployment" `
        --name "deployment.json" `
        --file $templatePath `
        --overwrite `
        --auth-mode login
        
    Write-Host "${Green}✅ Template uploaded successfully!${Reset}"
    
    # Also upload the UI definition to ensure compatibility
    $uiDefinitionPath = "infrastructure\createUiDefinition-pds.json"
    if (Test-Path $uiDefinitionPath) {
        Write-Host "${Blue}📤 Uploading PDS UI definition...${Reset}"
        az storage blob upload `
            --account-name "stcoppadeployment" `
            --container-name "coppa-deployment" `
            --name "createUiDefinition-pds.json" `
            --file $uiDefinitionPath `
            --overwrite `
            --auth-mode login
            
        Write-Host "${Green}✅ PDS UI definition uploaded successfully!${Reset}"
    }
    
} catch {
    Write-Error "Upload failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "${Yellow}💡 Alternative upload methods:${Reset}"
    Write-Host "1. Upload via Azure Portal (Storage Account -> Containers -> coppa-deployment)"
    Write-Host "2. Use connection string: az storage blob upload --connection-string 'your-connection-string' ..."
    Write-Host "3. Use account key: az storage blob upload --account-key 'your-key' ..."
    exit 1
}

Write-Host ""
Write-Host "${Green}🎉 Fix Complete!${Reset}"
Write-Host ""
Write-Host "${Blue}📋 Next Steps:${Reset}"
Write-Host "1. Try the Deploy to Azure button again"
Write-Host "2. You should now see the PDS parameters: ForceCode, Environment, Instance Number"
Write-Host "3. Fill them in (e.g., ForceCode: 'btp', Environment: 'prod', InstanceNumber: '01')"
Write-Host ""
Write-Host "${Green}✨ The deployment should now work with PDS compliance!${Reset}"
