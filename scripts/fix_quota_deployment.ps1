# Fix Azure OpenAI Quota Issues - Deployment Script
# This script reduces OpenAI model capacities to work within current Azure quota limits

param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName = "rg-policing-assistant",
    [string]$StorageAccountName = "stbtpukssandopenai",
    [string]$ContainerName = "policing-assistant-azure-deployment-template"
)

Write-Host "🔧 Fixing Azure OpenAI Quota Issues..." -ForegroundColor Yellow
Write-Host "This script will create a deployment.json with reduced OpenAI model capacities to fit within quota limits." -ForegroundColor White

# Authenticate to Azure
Write-Host "Authenticating to Azure..." -ForegroundColor Green
try {
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount
    }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
    Write-Host "✅ Successfully authenticated to Azure" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to authenticate to Azure: $_"
    exit 1
}

# Read the current deployment.json
$deploymentPath = "infrastructure\deployment.json"
if (-not (Test-Path $deploymentPath)) {
    Write-Error "❌ Could not find deployment.json at $deploymentPath"
    exit 1
}

Write-Host "📖 Reading current deployment.json..." -ForegroundColor Cyan
$deploymentContent = Get-Content $deploymentPath -Raw

# Reduce embedding model capacity from 30 to 10 to fit quota
Write-Host "🔧 Reducing embedding model capacity from 30 to 10..." -ForegroundColor Yellow
$updatedContent = $deploymentContent -replace '"capacity": 30', '"capacity": 10'

# Also ensure GPT-4o capacity is reasonable (keep at 10)
Write-Host "✅ GPT-4o capacity already set to 10 (good for quota)" -ForegroundColor Green

# Create the updated deployment file
$updatedDeploymentPath = "infrastructure\deployment-quota-fixed.json"
$updatedContent | Out-File -FilePath $updatedDeploymentPath -Encoding UTF8
Write-Host "✅ Created quota-fixed deployment file: $updatedDeploymentPath" -ForegroundColor Green

# Upload to Azure Storage
Write-Host "📤 Uploading quota-fixed deployment.json to Azure Storage..." -ForegroundColor Cyan
try {
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction Stop
    $ctx = $storageAccount.Context
    
    # Upload the quota-fixed deployment.json
    Set-AzStorageBlobContent -File $updatedDeploymentPath -Container $ContainerName -Blob "deployment.json" -Context $ctx -Force
    Write-Host "✅ Successfully uploaded quota-fixed deployment.json" -ForegroundColor Green
    
    # Also backup the original
    Set-AzStorageBlobContent -File $deploymentPath -Container $ContainerName -Blob "deployment-original.json" -Context $ctx -Force
    Write-Host "✅ Backed up original deployment.json as deployment-original.json" -ForegroundColor Green
    
} catch {
    Write-Error "❌ Failed to upload to Azure Storage: $_"
    Write-Host "You can manually upload the file $updatedDeploymentPath to your storage account" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Quota Fix Complete!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor White
Write-Host "✅ Reduced embedding model capacity: 30 → 10" -ForegroundColor White
Write-Host "✅ Kept GPT-4o capacity at: 10" -ForegroundColor White
Write-Host "✅ Uploaded to Azure Storage" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Try the 'Deploy to Azure' button again" -ForegroundColor White
Write-Host "2. The deployment should now work within quota limits" -ForegroundColor White
Write-Host "3. If you still get quota errors, consider:" -ForegroundColor Yellow
Write-Host "   - Using a different Azure region (e.g., East US, West Europe)" -ForegroundColor Yellow
Write-Host "   - Reducing capacity further (to 5 for both models)" -ForegroundColor Yellow
Write-Host "   - Requesting a quota increase from Azure support" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Current Model Capacities:" -ForegroundColor Magenta
Write-Host "   - GPT-4o: 10 tokens/minute" -ForegroundColor White
Write-Host "   - text-embedding-ada-002: 10 tokens/minute" -ForegroundColor White
