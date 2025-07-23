# Diagnose and Fix Azure OpenAI Quota Issues
# This script helps identify and resolve quota-related deployment failures

param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName = "rg-policing-assistant",
    [string]$Region = "uksouth"
)

Write-Host "🔍 Azure OpenAI Quota Diagnostic Tool" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor White

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
    $currentSub = (Get-AzContext).Subscription.Id
    Write-Host "✅ Using subscription: $currentSub" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to authenticate to Azure: $_"
    exit 1
}

# Check current quotas
Write-Host ""
Write-Host "📊 Checking Azure OpenAI Quotas..." -ForegroundColor Cyan
try {
    # Get available OpenAI resources in the subscription
    $openAIResources = Get-AzCognitiveServicesAccount | Where-Object { $_.Kind -eq "OpenAI" }
    
    if ($openAIResources) {
        Write-Host "🔍 Found existing OpenAI resources:" -ForegroundColor Yellow
        foreach ($resource in $openAIResources) {
            Write-Host "   - $($resource.AccountName) in $($resource.Location)" -ForegroundColor White
            
            # Try to get deployments
            try {
                $deployments = Get-AzCognitiveServicesAccountDeployment -ResourceGroupName $resource.ResourceGroupName -AccountName $resource.AccountName
                if ($deployments) {
                    Write-Host "     Deployments:" -ForegroundColor Gray
                    foreach ($deployment in $deployments) {
                        Write-Host "       - $($deployment.Name): $($deployment.Properties.Model.Name) (Capacity: $($deployment.Sku.Capacity))" -ForegroundColor Gray
                    }
                }
            } catch {
                Write-Host "     Could not retrieve deployments: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "✅ No existing OpenAI resources found - starting fresh" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Could not check existing resources: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Provide quota recommendations
Write-Host ""
Write-Host "💡 Quota Recommendations for Successful Deployment:" -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Recommended Model Capacities (Low Quota):" -ForegroundColor Green
Write-Host "   - GPT-4o: 5 tokens/minute" -ForegroundColor White
Write-Host "   - text-embedding-ada-002: 5 tokens/minute" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Standard Model Capacities (Normal Quota):" -ForegroundColor Cyan
Write-Host "   - GPT-4o: 10 tokens/minute" -ForegroundColor White
Write-Host "   - text-embedding-ada-002: 10 tokens/minute" -ForegroundColor White
Write-Host ""
Write-Host "🌍 Alternative Regions to Try:" -ForegroundColor Yellow
Write-Host "   - eastus (often has better availability)" -ForegroundColor White
Write-Host "   - westeurope (good for European users)" -ForegroundColor White
Write-Host "   - australiaeast (good for APAC users)" -ForegroundColor White
Write-Host "   - canadaeast (alternative North American region)" -ForegroundColor White

# Generate deployment files with different capacity options
Write-Host ""
Write-Host "📝 Generating deployment files with different capacities..." -ForegroundColor Cyan

$originalDeployment = Get-Content "infrastructure\deployment.json" -Raw

# Ultra-low quota version (capacity 5)
$ultraLowQuota = $originalDeployment -replace '"capacity": 10', '"capacity": 5'
$ultraLowQuota | Out-File -FilePath "infrastructure\deployment-ultra-low-quota.json" -Encoding UTF8
Write-Host "✅ Created ultra-low quota version: deployment-ultra-low-quota.json" -ForegroundColor Green

# Very low quota version (capacity 3)
$veryLowQuota = $originalDeployment -replace '"capacity": 10', '"capacity": 3'
$veryLowQuota | Out-File -FilePath "infrastructure\deployment-very-low-quota.json" -Encoding UTF8
Write-Host "✅ Created very-low quota version: deployment-very-low-quota.json" -ForegroundColor Green

# Check for common quota error patterns
Write-Host ""
Write-Host "🔍 Common Quota Error Solutions:" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor White
Write-Host ""
Write-Host "Error: 'Insufficient quota'" -ForegroundColor Red
Write-Host "Solution: Use deployment-ultra-low-quota.json (capacity 5)" -ForegroundColor Green
Write-Host ""
Write-Host "Error: 'Region quota exceeded'" -ForegroundColor Red
Write-Host "Solution: Try a different region like eastus or westeurope" -ForegroundColor Green
Write-Host ""
Write-Host "Error: 'Model not available'" -ForegroundColor Red
Write-Host "Solution: Check model availability in your region" -ForegroundColor Green
Write-Host ""
Write-Host "Error: 'Deployment quota exceeded'" -ForegroundColor Red
Write-Host "Solution: Delete existing deployments or use deployment-very-low-quota.json" -ForegroundColor Green

Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor White
Write-Host "1. Upload the appropriate deployment file to Azure Storage" -ForegroundColor White
Write-Host "2. Try the Deploy to Azure button again" -ForegroundColor White
Write-Host "3. If it still fails, try a different Azure region" -ForegroundColor White
Write-Host "4. Consider requesting a quota increase if needed" -ForegroundColor White

Write-Host ""
Write-Host "📋 Upload Commands:" -ForegroundColor Yellow
Write-Host ".\scripts\upload_quota_fixed_deployment.ps1 -QuotaLevel Ultra" -ForegroundColor Gray
Write-Host ".\scripts\upload_quota_fixed_deployment.ps1 -QuotaLevel VeryLow" -ForegroundColor Gray
