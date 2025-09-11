# Deployment script for CoPA - College of Policing Assistant
# This script will deploy all the necessary Azure resources for CoPPA

# Default values
$RESOURCE_GROUP = "coppa-rg"
$LOCATION = "eastus"
$DEPLOYMENT_NAME = "coppa-deployment"
$WEBSITE_NAME = "coppa-" + (-join ((97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_}))
$OPENAI_NAME = "oai-" + (-join ((97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_}))
$SEARCH_NAME = "search-" + (-join ((97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_}))

Write-Host "╔════════════════════════════════════════════════════════════╗"
Write-Host "║              CoPA - College of Policing Assistant         ║"
Write-Host "╚════════════════════════════════════════════════════════════╝"

# Check if Azure PowerShell is installed
if (-not (Get-Module -ListAvailable -Name Az)) {
    Write-Host "Azure PowerShell is not installed. Please install it first."
    Write-Host "Run: Install-Module -Name Az -AllowClobber -Scope CurrentUser"
    exit 1
}

# Check if user is logged in
Write-Host "Checking Azure login status..."
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "You are not logged in to Azure. Please login first."
        Connect-AzAccount
    }
} catch {
    Write-Host "You are not logged in to Azure. Please login first."
    Connect-AzAccount
}

# Display available subscriptions
Write-Host "Available subscriptions:"
Get-AzSubscription | Format-Table Name, Id, TenantId

# Confirm subscription
$useDefault = Read-Host "Do you want to use the default subscription? (y/n)"
if ($useDefault -ne "y" -and $useDefault -ne "Y") {
    Get-AzSubscription | Format-Table Name, Id, TenantId
    $subscriptionId = Read-Host "Enter the subscription ID to use"
    Set-AzContext -SubscriptionId $subscriptionId
}

# Display current subscription
Write-Host "Using subscription:"
Get-AzContext | Format-Table Name, Subscription

# Customize deployment
$input = Read-Host "Resource Group Name [$RESOURCE_GROUP]"
if ($input) { $RESOURCE_GROUP = $input }

$input = Read-Host "Location [$LOCATION]"
if ($input) { $LOCATION = $input }

$input = Read-Host "Web App Name [$WEBSITE_NAME]"
if ($input) { $WEBSITE_NAME = $input }

$input = Read-Host "OpenAI Service Name [$OPENAI_NAME]"
if ($input) { $OPENAI_NAME = $input }

$input = Read-Host "Search Service Name [$SEARCH_NAME]"
if ($input) { $SEARCH_NAME = $input }

$CHAT_HISTORY = Read-Host "Enable Chat History? (y/n) [n]"
if ($CHAT_HISTORY -eq "y" -or $CHAT_HISTORY -eq "Y") {
    $ENABLE_CHAT_HISTORY = $true
} else {
    $ENABLE_CHAT_HISTORY = $false
}

# Create resource group if it doesn't exist
Write-Host "Creating resource group if it doesn't exist..."
New-AzResourceGroup -Name $RESOURCE_GROUP -Location $LOCATION -Force

# Model deployment settings
$input = Read-Host "OpenAI Model Name (gpt-4o recommended) [gpt-4o]"
if ($input) { $MODEL_NAME = $input } else { $MODEL_NAME = "gpt-4o" }

$input = Read-Host "OpenAI Model Deployment Name [$MODEL_NAME-deployment]"
if ($input) { $MODEL_DEPLOYMENT = $input } else { $MODEL_DEPLOYMENT = "$MODEL_NAME-deployment" }

# Start deployment
Write-Host "Starting deployment..."
Write-Host "This may take up to 15-20 minutes to complete..."

New-AzResourceGroupDeployment `
  -Name $DEPLOYMENT_NAME `
  -ResourceGroupName $RESOURCE_GROUP `
  -TemplateFile "infrastructure/deployment.json" `
  -WebsiteName $WEBSITE_NAME `
  -AzureSearchService $SEARCH_NAME `
  -AzureOpenAIResource $OPENAI_NAME `
  -AzureOpenAIModel $MODEL_DEPLOYMENT `
  -AzureOpenAIModelName $MODEL_NAME `
  -WebAppEnableChatHistory $ENABLE_CHAT_HISTORY `
  -Verbose

# Check deployment status
if ($?) {
    Write-Host "╔════════════════════════════════════════════════════════════╗"
    Write-Host "║             Deployment completed successfully!              ║"
    Write-Host "╚════════════════════════════════════════════════════════════╝"
    
    # Get the Web App URL
    $webapp = Get-AzWebApp -Name $WEBSITE_NAME -ResourceGroupName $RESOURCE_GROUP
    $WEBAPP_URL = "https://" + $webapp.DefaultHostName
    
    Write-Host "Your College of Policing Assistant is now deployed!"
    Write-Host "Web App URL: $WEBAPP_URL"
    Write-Host ""
    Write-Host "Note: It may take a few minutes for the application to be fully deployed and ready to use."
    Write-Host "If you see a 'deployment in progress' message, please wait a few minutes and refresh the page."
} else {
    Write-Host "Deployment failed. Please check the error messages above."
    exit 1
}
