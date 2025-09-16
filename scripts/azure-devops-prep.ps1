# PowerShell script to prepare Azure resources for CoPA DevOps deployment
# Run this script to set up initial Azure resources before DevOps deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "uksouth",
    
    [Parameter(Mandatory=$false)]
    [string]$ForceCode = "met",  # Change this to your force code
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"  # dev or prod
)

# Login check
Write-Host "🔐 Checking Azure login status..." -ForegroundColor Blue
$context = az account show --output json | ConvertFrom-Json
if (-not $context) {
    Write-Host "❌ Please login to Azure first: az login" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Logged in as: $($context.user.name)" -ForegroundColor Green
Write-Host "✅ Current subscription: $($context.name)" -ForegroundColor Green

# Set subscription
Write-Host "🎯 Setting subscription to: $SubscriptionId" -ForegroundColor Blue
az account set --subscription $SubscriptionId

# Define resource group name following PDS convention
$resourceGroupName = "rg-$Environment-$Location-$ForceCode-copa-stop-search"

Write-Host "📦 Creating resource group: $resourceGroupName" -ForegroundColor Blue

# Create resource group
$rgResult = az group create `
    --name $resourceGroupName `
    --location $Location `
    --output json | ConvertFrom-Json

if ($rgResult) {
    Write-Host "✅ Resource group created successfully!" -ForegroundColor Green
    Write-Host "   Name: $($rgResult.name)" -ForegroundColor Gray
    Write-Host "   Location: $($rgResult.location)" -ForegroundColor Gray
    Write-Host "   Status: $($rgResult.properties.provisioningState)" -ForegroundColor Gray
} else {
    Write-Host "❌ Failed to create resource group" -ForegroundColor Red
    exit 1
}

# Check Azure service provider registrations
Write-Host "🔍 Checking required Azure providers..." -ForegroundColor Blue

$requiredProviders = @(
    "Microsoft.CognitiveServices",
    "Microsoft.Search", 
    "Microsoft.DocumentDB",
    "Microsoft.Web",
    "Microsoft.Storage",
    "Microsoft.Insights",
    "Microsoft.KeyVault",
    "Microsoft.Authorization"
)

foreach ($provider in $requiredProviders) {
    $status = az provider show --namespace $provider --query "registrationState" --output tsv
    if ($status -ne "Registered") {
        Write-Host "🔄 Registering provider: $provider" -ForegroundColor Yellow
        az provider register --namespace $provider
    } else {
        Write-Host "✅ Provider registered: $provider" -ForegroundColor Green
    }
}

# Check quotas for key services
Write-Host "📊 Checking Azure quotas..." -ForegroundColor Blue

# Check OpenAI quota
Write-Host "   Checking OpenAI quota in $Location..." -ForegroundColor Gray
$openAIQuota = az cognitiveservices usage list `
    --location $Location `
    --query "[?name.value=='OpenAI.Standard.Tokens']" `
    --output json | ConvertFrom-Json

if ($openAIQuota) {
    Write-Host "✅ OpenAI quota available in $Location" -ForegroundColor Green
} else {
    Write-Host "⚠️  OpenAI might not be available in $Location - check manually" -ForegroundColor Yellow
}

# Check App Service quota
$appServiceQuota = az vm list-usage --location $Location --query "[?name.localizedValue=='App Services']" --output json | ConvertFrom-Json
if ($appServiceQuota) {
    foreach ($quota in $appServiceQuota) {
        $used = $quota.currentValue
        $limit = $quota.limit
        $available = $limit - $used
        Write-Host "✅ App Service quota: $available/$limit available" -ForegroundColor Green
    }
}

# Validate Bicep template
Write-Host "🔍 Validating Bicep template..." -ForegroundColor Blue

$bicepPath = "infra/main-pds-converted.bicep"
if (Test-Path $bicepPath) {
    Write-Host "   Found Bicep template: $bicepPath" -ForegroundColor Gray
    
    # Build Bicep template
    $buildResult = az bicep build --file $bicepPath 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Bicep template is valid" -ForegroundColor Green
    } else {
        Write-Host "❌ Bicep template has errors:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
        exit 1
    }
    
    # Run what-if analysis
    Write-Host "🧪 Running deployment what-if analysis..." -ForegroundColor Blue
    $whatIfResult = az deployment group what-if `
        --resource-group $resourceGroupName `
        --template-file $bicepPath `
        --parameters location=$Location azureOpenAIModelName="gpt-4o" azureOpenAIEmbeddingName="text-embedding-ada-002" `
        --output json 2>&1
        
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ What-if analysis completed successfully" -ForegroundColor Green
        Write-Host "   Resources will be created/updated based on Bicep template" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  What-if analysis had issues (this might be normal):" -ForegroundColor Yellow
        Write-Host $whatIfResult -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Bicep template not found at: $bicepPath" -ForegroundColor Red
    Write-Host "   Make sure you're running this from the repository root" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n🎉 Azure preparation completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Use resource group name in DevOps variable groups: $resourceGroupName" -ForegroundColor Gray
Write-Host "2. Continue with Azure DevOps setup using the checklist" -ForegroundColor Gray
Write-Host "3. Test deployment using the DevOps pipeline" -ForegroundColor Gray

# Output summary for use in DevOps
$summary = @{
    SubscriptionId = $SubscriptionId
    ResourceGroupName = $resourceGroupName
    Location = $Location
    ForceCode = $ForceCode
    Environment = $Environment
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
}

$summary | ConvertTo-Json | Out-File "azure-setup-summary.json"
Write-Host "`n📄 Setup summary saved to: azure-setup-summary.json" -ForegroundColor Gray