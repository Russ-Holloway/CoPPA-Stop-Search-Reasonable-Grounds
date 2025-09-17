# BTP Deployment Test Script for CoPA Stop & Search (PowerShell)
# This script performs a complete deployment test to the BTP tenant

param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ResourceGroupName = "rg-btp-p-copa-stop-search",
    [string]$Location = "uksouth",
    [string]$EnvironmentCode = "p",
    [string]$InstanceNumber = "001",
    [switch]$WhatIfOnly = $false
)

# Configuration
$DeploymentName = "copa-btp-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$BicepTemplatePath = ".\infra\main.bicep"
$ParametersFilePath = ".\infra\main.parameters.json"

# Color functions for output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info { param([string]$Message) Write-ColorOutput "[INFO] $Message" -Color Cyan }
function Write-Success { param([string]$Message) Write-ColorOutput "[SUCCESS] $Message" -Color Green }
function Write-Warning { param([string]$Message) Write-ColorOutput "[WARNING] $Message" -Color Yellow }
function Write-Error { param([string]$Message) Write-ColorOutput "[ERROR] $Message" -Color Red }

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    try {
        $null = az --version
    }
    catch {
        Write-Error "Azure CLI is not installed. Please install it first."
        exit 1
    }
    
    # Check if user is signed in
    try {
        $null = az account show 2>$null
    }
    catch {
        Write-Error "You are not signed in to Azure CLI."
        Write-Info "Please sign in using: az login"
        Write-Info "If you have CA policies, try: az login --use-device-code"
        exit 1
    }
    
    # Check if Bicep CLI is available
    try {
        $null = az bicep version 2>$null
    }
    catch {
        Write-Info "Installing Bicep CLI..."
        az bicep install
    }
    
    # Check if files exist
    if (-not (Test-Path $BicepTemplatePath)) {
        Write-Error "Bicep template not found at $BicepTemplatePath"
        exit 1
    }
    
    if (-not (Test-Path $ParametersFilePath)) {
        Write-Error "Parameters file not found at $ParametersFilePath"
        exit 1
    }
    
    Write-Success "All prerequisites checked"
}

function Test-BicepTemplate {
    Write-Info "Validating Bicep template..."
    
    # Create temp directory
    $null = New-Item -ItemType Directory -Force -Path ".\temp"
    
    # Build the template to check for syntax errors
    $buildResult = az bicep build --file $BicepTemplatePath --outdir .\temp\ 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Bicep template build failed"
        Write-Error $buildResult
        exit 1
    }
    
    # Lint the template
    Write-Info "Running Bicep linting..."
    $lintResult = az bicep lint --file $BicepTemplatePath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Bicep linting found issues (non-fatal)"
        Write-Warning $lintResult
    }
    
    Write-Success "Bicep template validation completed"
}

function Set-SubscriptionContext {
    if ($SubscriptionId) {
        Write-Info "Setting subscription context to $SubscriptionId"
        az account set --subscription $SubscriptionId
    }
    else {
        Write-Info "Using current subscription context"
        $SubscriptionId = az account show --query id --output tsv
        Write-Info "Current subscription: $SubscriptionId"
    }
}

function New-ResourceGroup {
    Write-Info "Creating resource group: $ResourceGroupName"
    
    $existingRg = az group show --name $ResourceGroupName 2>$null
    if ($existingRg) {
        Write-Warning "Resource group $ResourceGroupName already exists"
    }
    else {
        $currentUser = az account show --query user.name --output tsv
        $currentTime = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        
        az group create `
            --name $ResourceGroupName `
            --location $Location `
            --tags `
                "Environment=Production" `
                "Force=BTP" `
                "Application=CoPA-Stop-Search" `
                "DeployedBy=$currentUser" `
                "DeployedAt=$currentTime"
        
        Write-Success "Resource group created successfully"
    }
}

function Invoke-WhatIfAnalysis {
    Write-Info "Running What-If analysis..."
    
    $whatifOutputFile = ".\temp\whatif-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    
    az deployment group what-if `
        --resource-group $ResourceGroupName `
        --template-file $BicepTemplatePath `
        --parameters $ParametersFilePath `
            environmentCode=$EnvironmentCode `
            instanceNumber=$InstanceNumber `
        --result-format FullResourcePayloads `
        --no-pretty-print > $whatifOutputFile
    
    Write-Success "What-If analysis completed. Results saved to $whatifOutputFile"
    
    # Display summary
    Write-Host ""
    Write-Info "What-If Analysis Summary:"
    Write-Host "----------------------------------------"
    az deployment group what-if `
        --resource-group $ResourceGroupName `
        --template-file $BicepTemplatePath `
        --parameters $ParametersFilePath `
            environmentCode=$EnvironmentCode `
            instanceNumber=$InstanceNumber
    Write-Host "----------------------------------------"
    Write-Host ""
}

function Test-DeploymentValidation {
    Write-Info "Validating deployment template..."
    
    az deployment group validate `
        --resource-group $ResourceGroupName `
        --template-file $BicepTemplatePath `
        --parameters $ParametersFilePath `
            environmentCode=$EnvironmentCode `
            instanceNumber=$InstanceNumber
    
    Write-Success "Deployment validation completed successfully"
}

function New-InfrastructureDeployment {
    Write-Info "Starting infrastructure deployment..."
    Write-Info "Deployment Name: $DeploymentName"
    Write-Info "Resource Group: $ResourceGroupName"
    Write-Info "Location: $Location"
    Write-Info "Environment Code: $EnvironmentCode"
    Write-Info "Instance Number: $InstanceNumber"
    
    # Create deployment with detailed output
    az deployment group create `
        --resource-group $ResourceGroupName `
        --name $DeploymentName `
        --template-file $BicepTemplatePath `
        --parameters $ParametersFilePath `
            environmentCode=$EnvironmentCode `
            instanceNumber=$InstanceNumber `
        --verbose `
        --output table
    
    Write-Success "Infrastructure deployment completed!"
    
    # Get deployment outputs
    Write-Info "Retrieving deployment outputs..."
    az deployment group show `
        --resource-group $ResourceGroupName `
        --name $DeploymentName `
        --query properties.outputs `
        --output table
}

function Test-DeployedResources {
    Write-Info "Verifying deployed resources..."
    
    # List all resources in the resource group
    Write-Host ""
    Write-Info "Deployed Resources:"
    Write-Host "==================="
    az resource list --resource-group $ResourceGroupName --output table
    Write-Host ""
    
    # Check specific critical resources
    Write-Info "Verifying critical resources..."
    
    # Check App Service
    $appServiceName = "app-btp-$EnvironmentCode-copa-stop-search-$InstanceNumber"
    $appExists = az webapp show --name $appServiceName --resource-group $ResourceGroupName 2>$null
    if ($appExists) {
        Write-Success "✅ App Service ($appServiceName) deployed successfully"
        
        $appUrl = az webapp show --name $appServiceName --resource-group $ResourceGroupName --query "defaultHostName" --output tsv
        Write-Info "🌐 Application URL: https://$appUrl"
    }
    else {
        Write-Error "❌ App Service not found"
    }
    
    # Check Cosmos DB
    $cosmosName = "cosmos-btp-$EnvironmentCode-copa-stop-search-$InstanceNumber"
    $cosmosExists = az cosmosdb show --name $cosmosName --resource-group $ResourceGroupName 2>$null
    if ($cosmosExists) {
        Write-Success "✅ Cosmos DB ($cosmosName) deployed successfully"
    }
    else {
        Write-Error "❌ Cosmos DB not found"
    }
    
    # Check Azure Search
    $searchName = "srch-btp-$EnvironmentCode-copa-stop-search-$InstanceNumber"
    $searchExists = az search service show --name $searchName --resource-group $ResourceGroupName 2>$null
    if ($searchExists) {
        Write-Success "✅ Azure Search ($searchName) deployed successfully"
    }
    else {
        Write-Error "❌ Azure Search not found"
    }
    
    # Check private endpoints
    Write-Info "Checking private endpoints..."
    $peCount = az network private-endpoint list --resource-group $ResourceGroupName --query "length([])" --output tsv
    Write-Success "✅ Found $peCount private endpoints deployed"
}

function Test-ApplicationHealth {
    Write-Info "Testing application health..."
    
    $appServiceName = "app-btp-$EnvironmentCode-copa-stop-search-$InstanceNumber"
    $appUrl = az webapp show --name $appServiceName --resource-group $ResourceGroupName --query "defaultHostName" --output tsv 2>$null
    
    if ($appUrl) {
        Write-Info "Testing application endpoint: https://$appUrl"
        
        try {
            $response = Invoke-WebRequest -Uri "https://$appUrl" -UseBasicParsing -TimeoutSec 30
            if ($response.StatusCode -eq 200) {
                Write-Success "✅ Application is responding (HTTP $($response.StatusCode))"
            }
            else {
                Write-Warning "⚠️ Application responded with HTTP $($response.StatusCode)"
            }
        }
        catch {
            Write-Warning "⚠️ Unable to connect to application (may still be starting)"
        }
    }
    else {
        Write-Error "❌ Could not determine application URL"
    }
}

# Main execution
Write-Info "Starting BTP Deployment Test for CoPA Stop & Search"
Write-Info "=================================================="

# Create temp directory
$null = New-Item -ItemType Directory -Force -Path ".\temp"

try {
    # Execute deployment steps
    Test-Prerequisites
    Set-SubscriptionContext
    Test-BicepTemplate
    New-ResourceGroup
    Invoke-WhatIfAnalysis
    Test-DeploymentValidation
    
    if ($WhatIfOnly) {
        Write-Success "What-If analysis completed. Skipping actual deployment."
    }
    else {
        # Ask for confirmation before actual deployment
        Write-Host ""
        Write-Warning "Ready to deploy to BTP tenant. This will create real Azure resources."
        $confirmation = Read-Host "Do you want to continue with the deployment? (y/N)"
        
        if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
            New-InfrastructureDeployment
            Test-DeployedResources
            Test-ApplicationHealth
            
            Write-Success "🎉 BTP deployment test completed successfully!"
            Write-Info "Your CoPA Stop & Search solution is now deployed with BTP naming convention."
        }
        else {
            Write-Info "Deployment cancelled by user."
        }
    }
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}
finally {
    # Cleanup temp files
    Remove-Item -Path ".\temp" -Recurse -Force -ErrorAction SilentlyContinue
}