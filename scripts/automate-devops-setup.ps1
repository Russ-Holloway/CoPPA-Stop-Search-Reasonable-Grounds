# Azure DevOps Automation Script (PowerShell)
# This script automates the creation of service connections, variable groups, and environments
# Prerequisites: Azure DevOps project created and repository imported

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ForceCode = "met",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "uksouth"
)

# Configuration
# Configuration Variables
$ORG_URL = "https://dev.azure.com/uk-police-copa/"
$PROJECT_NAME = "CoPA-Stop-Search-Secure-Deployment"
$REPO_NAME = "CoPA-Stop-Search-Reasonable-Grounds"

function Write-Status {
    param(
        [string]$Color,
        [string]$Message
    )
    
    switch ($Color) {
        "Red" { Write-Host "❌ $Message" -ForegroundColor Red }
        "Green" { Write-Host "✅ $Message" -ForegroundColor Green }
        "Yellow" { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        "Blue" { Write-Host "🔍 $Message" -ForegroundColor Blue }
        default { Write-Host $Message }
    }
}

function Test-Prerequisites {
    Write-Status "Blue" "Checking prerequisites..."
    
    # Check Azure CLI
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Status "Red" "Azure CLI is not installed. Please install it first."
        exit 1
    }
    
    # Check if logged into Azure
    try {
        az account show | Out-Null
    }
    catch {
        Write-Status "Red" "Please login to Azure: az login"
        exit 1
    }
    
    # Check Azure DevOps extension
    $devOpsExtension = az extension list --query "[?name=='azure-devops']" --output json | ConvertFrom-Json
    if (-not $devOpsExtension) {
        Write-Status "Yellow" "Installing Azure DevOps extension..."
        az extension add --name azure-devops
    }
    
    Write-Status "Green" "Prerequisites check completed"
}

function Get-SubscriptionId {
    if (-not $SubscriptionId) {
        Write-Status "Blue" "Available Azure subscriptions:"
        az account list --output table --query "[].{Name:name, SubscriptionId:id, State:state}"
        
        $SubscriptionId = Read-Host "Enter your Azure Subscription ID"
        
        if (-not $SubscriptionId) {
            Write-Status "Red" "Subscription ID is required"
            exit 1
        }
    }
    
    # Set the subscription
    az account set --subscription $SubscriptionId
    Write-Status "Green" "Using subscription: $SubscriptionId"
    
    return $SubscriptionId
}

function Initialize-DevOps {
    Write-Status "Blue" "Configuring Azure DevOps CLI..."
    
    # Configure defaults
    az devops configure --defaults organization=$OrgUrl project=$ProjectName
    
    # Test access
    Write-Status "Yellow" "You may be prompted to authenticate with Azure DevOps..."
    try {
        az devops project show --project $ProjectName | Out-Null
    }
    catch {
        Write-Status "Red" "Cannot access project '$ProjectName'. Please ensure:"
        Write-Status "Red" "1. The project exists at $OrgUrl"
        Write-Status "Red" "2. You have access to the project" 
        Write-Status "Red" "3. You've authenticated with Azure DevOps (PAT token)"
        exit 1
    }
    
    Write-Status "Green" "Azure DevOps access confirmed"
}

function New-ServiceConnections {
    param([string]$SubscriptionId)
    
    Write-Status "Blue" "Creating service connections..."
    
    $tenantId = az account show --query tenantId --output tsv
    $subscriptionName = az account show --query name --output tsv
    
    # Create development service connection
    Write-Status "Yellow" "Creating development service connection..."
    try {
        az devops service-endpoint azurerm create `
            --azure-rm-service-principal-id "" `
            --azure-rm-subscription-id $SubscriptionId `
            --azure-rm-subscription-name $subscriptionName `
            --azure-rm-tenant-id $tenantId `
            --name "copa-azure-service-connection-dev" `
            --project $ProjectName `
            --org $OrgUrl | Out-Null
    }
    catch {
        Write-Status "Yellow" "Dev service connection might already exist"
    }
    
    # Create production service connection
    Write-Status "Yellow" "Creating production service connection..."
    try {
        az devops service-endpoint azurerm create `
            --azure-rm-service-principal-id "" `
            --azure-rm-subscription-id $SubscriptionId `
            --azure-rm-subscription-name $subscriptionName `
            --azure-rm-tenant-id $tenantId `
            --name "copa-azure-service-connection-prod" `
            --project $ProjectName `
            --org $OrgUrl | Out-Null
    }
    catch {
        Write-Status "Yellow" "Prod service connection might already exist"
    }
    
    Write-Status "Green" "Service connections created"
}

function New-VariableGroups {
    Write-Status "Blue" "Creating variable groups..."
    
    $devRg = "rg-dev-$Location-$ForceCode-copa-stop-search"
    $prodRg = "rg-prod-$Location-$ForceCode-copa-stop-search"
    
    # Development variables
    $devVariables = @{
        resourceGroupName = $devRg
        azureLocation = $Location
        environmentName = "development"
        openAIModel = "gpt-4o"
        embeddingModel = "text-embedding-ada-002"
        webAppName = "`$(webAppName)"
        deploymentSlotName = "staging"
        enableDebugMode = "true"
        azureServiceConnection = "copa-azure-service-connection-dev"
    }
    
    # Create development variable group
    Write-Status "Yellow" "Creating development variable group..."
    $devVariables | ConvertTo-Json | Out-File -FilePath "dev-variables.json" -Encoding UTF8
    try {
        az pipelines variable-group create `
            --name "copa-dev-variables" `
            --variables "@dev-variables.json" `
            --description "Development environment variables for CoPA Stop & Search" `
            --project $ProjectName `
            --org $OrgUrl | Out-Null
    }
    catch {
        Write-Status "Yellow" "Dev variable group might already exist"
    }
    
    # Production variables
    $prodVariables = @{
        resourceGroupName = $prodRg
        azureLocation = $Location
        environmentName = "production"
        openAIModel = "gpt-4o"
        embeddingModel = "text-embedding-ada-002"
        webAppName = "`$(webAppName)"
        deploymentSlotName = "production"
        enableDebugMode = "false"
        azureServiceConnection = "copa-azure-service-connection-prod"
        enableApplicationInsights = "true"
        enableMonitoring = "true"
    }
    
    # Create production variable group
    Write-Status "Yellow" "Creating production variable group..."
    $prodVariables | ConvertTo-Json | Out-File -FilePath "prod-variables.json" -Encoding UTF8
    try {
        az pipelines variable-group create `
            --name "copa-prod-variables" `
            --variables "@prod-variables.json" `
            --description "Production environment variables for CoPA Stop & Search" `
            --project $ProjectName `
            --org $OrgUrl | Out-Null
    }
    catch {
        Write-Status "Yellow" "Prod variable group might already exist"
    }
    
    # Clean up
    Remove-Item -Path "dev-variables.json", "prod-variables.json" -ErrorAction SilentlyContinue
    
    Write-Status "Green" "Variable groups created"
}

function New-Environments {
    Write-Status "Blue" "Creating environments..."
    
    # Create development environment
    Write-Status "Yellow" "Creating development environment..."
    $devEnvPayload = @{
        name = "copa-development"
        description = "Development environment for CoPA Stop & Search"
    } | ConvertTo-Json
    
    try {
        az devops invoke `
            --area distributedtask `
            --resource environments `
            --route-parameters project=$ProjectName `
            --http-method POST `
            --in-file $devEnvPayload `
            --org $OrgUrl | Out-Null
    }
    catch {
        Write-Status "Yellow" "Dev environment might already exist"
    }
    
    # Create production environment
    Write-Status "Yellow" "Creating production environment..."
    $prodEnvPayload = @{
        name = "copa-production"
        description = "Production environment for CoPA Stop & Search"
    } | ConvertTo-Json
    
    try {
        az devops invoke `
            --area distributedtask `
            --resource environments `
            --route-parameters project=$ProjectName `
            --http-method POST `
            --in-file $prodEnvPayload `
            --org $OrgUrl | Out-Null
    }
    catch {
        Write-Status "Yellow" "Prod environment might already exist"
    }
    
    Write-Status "Green" "Environments created"
    Write-Status "Yellow" "Note: Production approvals need to be configured manually in the Azure DevOps web interface"
}

function New-Pipeline {
    Write-Status "Blue" "Creating pipeline..."
    
    # Check if repository exists
    $repoId = az repos list --query "[?name=='CoPA-Stop-Search-Reasonable-Grounds'].id" --output tsv
    if (-not $repoId) {
        Write-Status "Red" "Repository 'CoPA-Stop-Search-Reasonable-Grounds' not found"
        Write-Status "Red" "Please import the repository first"
        return
    }
    
    # Create pipeline
    Write-Status "Yellow" "Creating main deployment pipeline..."
    try {
        az pipelines create `
            --name "CoPA-Stop-Search-Main-Deploy" `
            --description "Main deployment pipeline for CoPA Stop & Search" `
            --repository $repoId `
            --repository-type tfsgit `
            --branch "Dev-Ops-Deployment" `
            --yml-path "/azure-pipelines.yml" `
            --project $ProjectName `
            --org $OrgUrl | Out-Null
    }
    catch {
        Write-Status "Yellow" "Pipeline might already exist"
    }
    
    Write-Status "Green" "Pipeline created"
}

function New-AzureResourceGroups {
    Write-Status "Blue" "Creating Azure resource groups..."
    
    $devRg = "rg-dev-$Location-$ForceCode-copa-stop-search"
    $prodRg = "rg-prod-$Location-$ForceCode-copa-stop-search"
    
    # Create development resource group
    Write-Status "Yellow" "Creating development resource group: $devRg"
    try {
        az group create --name $devRg --location $Location | Out-Null
    }
    catch {
        Write-Status "Yellow" "Resource group might already exist"
    }
    
    # Create production resource group
    Write-Status "Yellow" "Creating production resource group: $prodRg"
    try {
        az group create --name $prodRg --location $Location | Out-Null
    }
    catch {
        Write-Status "Yellow" "Resource group might already exist"
    }
    
    Write-Status "Green" "Azure resource groups created"
}

# Main execution
Write-Status "Blue" "🚀 Starting Azure DevOps automation for CoPA Stop & Search"
Write-Host

# Get configuration from user
if (-not $ForceCode -or $ForceCode -eq "met") {
    $ForceCode = Read-Host "Enter your police force code (e.g., met, gmp, west-midlands)"
    if (-not $ForceCode) {
        $ForceCode = "met"
    }
}

Test-Prerequisites
$SubscriptionId = Get-SubscriptionId
Initialize-DevOps

Write-Host
Write-Status "Blue" "Creating Azure DevOps components..."

New-ServiceConnections -SubscriptionId $SubscriptionId
New-VariableGroups
New-Environments  
New-Pipeline

Write-Host
Write-Status "Blue" "Creating Azure resources..."
New-AzureResourceGroups

Write-Host
Write-Status "Green" "🎉 Automation completed!"

Write-Status "Yellow" "Manual steps still required:"
Write-Host "1. Configure production environment approvals in Azure DevOps web interface"
Write-Host "2. Grant pipeline permissions to service connections and environments"
Write-Host "3. Test pipeline run"

Write-Status "Blue" "Next: Run the pipeline to test deployment!"