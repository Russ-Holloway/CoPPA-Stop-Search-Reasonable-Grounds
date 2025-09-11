# Comprehensive Deployment Readiness Checker
# This script performs a complete check of all Azure resources for the College of Policing Assistant app

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$OpenAIServiceName,
    
    [Parameter(Mandatory = $true)]
    [string]$SearchServiceName,
    
    [Parameter(Mandatory = $false)]
    [string]$AppServiceName,
    
    [Parameter(Mandatory = $false)]
    [string]$EmbeddingModelName = "text-embedding-ada-002",
    
    [Parameter(Mandatory = $false)]
    [string]$ChatModelName = "gpt-35-turbo",
    
    [Parameter(Mandatory = $false)]
    [int]$TimeoutMinutes = 15,
    
    [Parameter(Mandatory = $false)]
    [switch]$WaitForCompletion,
    
    [Parameter(Mandatory = $false)]
    [switch]$FixPermissions,
    
    [Parameter(Mandatory = $false)]
    [switch]$QuickCheck
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "=== College of Policing Assistant Deployment Readiness Checker ===" -ForegroundColor Green
Write-Host "Subscription: $SubscriptionId" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Check Mode: $(if ($QuickCheck) { 'Quick' } else { 'Comprehensive' })" -ForegroundColor Cyan
Write-Host ""

# Function to check if Azure CLI is installed and logged in
function Test-AzureCLI {
    try {
        $account = az account show --query "id" -o tsv 2>$null
        if ($LASTEXITCODE -eq 0 -and $account) {
            Write-Host "✓ Azure CLI is installed and logged in" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "✗ Azure CLI not available or not logged in" -ForegroundColor Red
        Write-Host "Please run: az login" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "✗ Azure CLI not available or not logged in" -ForegroundColor Red
    Write-Host "Please run: az login" -ForegroundColor Yellow
    return $false
}

# Function to check resource group existence
function Test-ResourceGroup {
    param([string]$subscriptionId, [string]$resourceGroup)
    
    Write-Host "Checking resource group existence..." -ForegroundColor Yellow
    
    try {
        $rg = az group show --subscription $subscriptionId --name $resourceGroup --query "{name:name,location:location,provisioningState:properties.provisioningState}" -o json 2>$null | ConvertFrom-Json
        
        if ($LASTEXITCODE -eq 0 -and $rg) {
            Write-Host "✓ Resource group '$resourceGroup' found" -ForegroundColor Green
            Write-Host "  Location: $($rg.location)" -ForegroundColor Cyan
            Write-Host "  Provisioning State: $($rg.provisioningState)" -ForegroundColor Cyan
            return $true
        }
    }
    catch {
        Write-Host "✗ Failed to check resource group: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✗ Resource group '$resourceGroup' not found" -ForegroundColor Red
    return $false
}

# Function to check Search Service basic properties
function Test-SearchService {
    param([string]$subscriptionId, [string]$resourceGroup, [string]$searchService)
    
    Write-Host "Checking Search Service..." -ForegroundColor Yellow
    
    try {
        $search = az search service show --subscription $subscriptionId --resource-group $resourceGroup --name $searchService --query "{name:name,location:location,status:status,provisioningState:provisioningState,sku:sku.name}" -o json 2>$null | ConvertFrom-Json
        
        if ($LASTEXITCODE -eq 0 -and $search) {
            Write-Host "✓ Search Service '$searchService' found" -ForegroundColor Green
            Write-Host "  Location: $($search.location)" -ForegroundColor Cyan
            Write-Host "  Status: $($search.status)" -ForegroundColor Cyan
            Write-Host "  Provisioning State: $($search.provisioningState)" -ForegroundColor Cyan
            Write-Host "  SKU: $($search.sku)" -ForegroundColor Cyan
            return $search
        }
    }
    catch {
        Write-Host "✗ Failed to check Search Service: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
    
    Write-Host "✗ Search Service '$searchService' not found" -ForegroundColor Red
    return $null
}

# Function to check App Service (if provided)
function Test-AppService {
    param([string]$subscriptionId, [string]$resourceGroup, [string]$appService)
    
    if (-not $appService) {
        Write-Host "⚠ App Service name not provided, skipping check" -ForegroundColor Yellow
        return $null
    }
    
    Write-Host "Checking App Service..." -ForegroundColor Yellow
    
    try {
        $app = az webapp show --subscription $subscriptionId --resource-group $resourceGroup --name $appService --query "{name:name,location:location,state:state,defaultHostName:defaultHostName}" -o json 2>$null | ConvertFrom-Json
        
        if ($LASTEXITCODE -eq 0 -and $app) {
            Write-Host "✓ App Service '$appService' found" -ForegroundColor Green
            Write-Host "  Location: $($app.location)" -ForegroundColor Cyan
            Write-Host "  State: $($app.state)" -ForegroundColor Cyan
            Write-Host "  URL: https://$($app.defaultHostName)" -ForegroundColor Cyan
            return $app
        }
    }
    catch {
        Write-Host "✗ Failed to check App Service: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
    
    Write-Host "✗ App Service '$appService' not found" -ForegroundColor Red
    return $null
}

# Function to perform quick connectivity tests
function Test-QuickConnectivity {
    param([string]$subscriptionId, [string]$resourceGroup, [hashtable]$services)
    
    Write-Host "Performing quick connectivity tests..." -ForegroundColor Yellow
    
    $results = @{}
    
    # Test OpenAI endpoint
    if ($services.OpenAI) {
        try {
            $endpoint = az cognitiveservices account show --subscription $subscriptionId --resource-group $resourceGroup --name $services.OpenAI --query "properties.endpoint" -o tsv 2>$null
            if ($LASTEXITCODE -eq 0 -and $endpoint) {
                $testResult = Test-Connection -TargetName ([System.Uri]$endpoint).Host -Count 1 -Quiet
                $results["OpenAI"] = $testResult
                if ($testResult) {
                    Write-Host "✓ OpenAI endpoint connectivity" -ForegroundColor Green
                } else {
                    Write-Host "✗ OpenAI endpoint not reachable" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "⚠ Could not test OpenAI connectivity" -ForegroundColor Yellow
            $results["OpenAI"] = $false
        }
    }
    
    # Test Storage account endpoint
    if ($services.Storage) {
        try {
            $storageHost = "$($services.Storage).blob.core.windows.net"
            $testResult = Test-Connection -TargetName $storageHost -Count 1 -Quiet
            $results["Storage"] = $testResult
            if ($testResult) {
                Write-Host "✓ Storage account endpoint connectivity" -ForegroundColor Green
            } else {
                Write-Host "✗ Storage account endpoint not reachable" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "⚠ Could not test Storage connectivity" -ForegroundColor Yellow
            $results["Storage"] = $false
        }
    }
    
    # Test Search service endpoint
    if ($services.Search) {
        try {
            $searchHost = "$($services.Search).search.windows.net"
            $testResult = Test-Connection -TargetName $searchHost -Count 1 -Quiet
            $results["Search"] = $testResult
            if ($testResult) {
                Write-Host "✓ Search service endpoint connectivity" -ForegroundColor Green
            } else {
                Write-Host "✗ Search service endpoint not reachable" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "⚠ Could not test Search connectivity" -ForegroundColor Yellow
            $results["Search"] = $false
        }
    }
    
    return $results
}

# Main execution
try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $checkResults = @{}
    
    # Check prerequisites
    if (-not (Test-AzureCLI)) {
        exit 1
    }
    
    # Set subscription
    Write-Host "Setting Azure subscription..." -ForegroundColor Yellow
    az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to set subscription" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    
    # Check resource group
    $rgExists = Test-ResourceGroup -subscriptionId $SubscriptionId -resourceGroup $ResourceGroupName
    if (-not $rgExists) {
        Write-Host "✗ Cannot proceed without resource group" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    
    # Check basic service existence
    $searchService = Test-SearchService -subscriptionId $SubscriptionId -resourceGroup $ResourceGroupName -searchService $SearchServiceName
    Write-Host ""
    
    $appService = Test-AppService -subscriptionId $SubscriptionId -resourceGroup $ResourceGroupName -appService $AppServiceName
    Write-Host ""
    
    # Quick connectivity check
    if ($QuickCheck) {
        $services = @{
            OpenAI = $OpenAIServiceName
            Storage = $StorageAccountName
            Search = $SearchServiceName
        }
        $connectivityResults = Test-QuickConnectivity -subscriptionId $SubscriptionId -resourceGroup $ResourceGroupName -services $services
        Write-Host ""
    }
    
    # Run OpenAI deployment check
    if (-not $QuickCheck) {
        Write-Host "=== OpenAI Deployment Check ===" -ForegroundColor Cyan
        $openaiParams = @{
            SubscriptionId = $SubscriptionId
            ResourceGroupName = $ResourceGroupName
            OpenAIServiceName = $OpenAIServiceName
            EmbeddingModelName = $EmbeddingModelName
            ChatModelName = $ChatModelName
            TimeoutMinutes = $TimeoutMinutes
        }
        if ($WaitForCompletion) { $openaiParams.WaitForCompletion = $true }
        
        $openaiCheckScript = Join-Path $scriptDir "check_openai_deployments.ps1"
        if (Test-Path $openaiCheckScript) {
            try {
                $openaiResult = & $openaiCheckScript @openaiParams
                $checkResults["OpenAI"] = @{ Success = $true; Output = $openaiResult }
                Write-Host "✓ OpenAI deployment check completed successfully" -ForegroundColor Green
            }
            catch {
                $checkResults["OpenAI"] = @{ Success = $false; Error = $_.Exception.Message }
                Write-Host "✗ OpenAI deployment check failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "⚠ OpenAI check script not found at: $openaiCheckScript" -ForegroundColor Yellow
            $checkResults["OpenAI"] = @{ Success = $false; Error = "Script not found" }
        }
        
        Write-Host ""
    }
    
    # Final Summary
    Write-Host "=== Deployment Readiness Summary ===" -ForegroundColor Green
    Write-Host ""
    
    $overallSuccess = $true
    $criticalIssues = @()
    $warnings = @()
    
    # Resource existence checks
    Write-Host "Resource Existence:" -ForegroundColor Cyan
    Write-Host "  ✓ Resource Group: $ResourceGroupName" -ForegroundColor Green
    
    if ($searchService -and $searchService.provisioningState -eq "Succeeded") {
        Write-Host "  ✓ Search Service: $SearchServiceName" -ForegroundColor Green
    } elseif ($searchService) {
        Write-Host "  ⚠ Search Service: $SearchServiceName (state: $($searchService.provisioningState))" -ForegroundColor Yellow
        $warnings += "Search Service not fully provisioned"
    } else {
        Write-Host "  ✗ Search Service: $SearchServiceName" -ForegroundColor Red
        $criticalIssues += "Search Service not found"
        $overallSuccess = $false
    }
    
    if ($appService -and $appService.state -eq "Running") {
        Write-Host "  ✓ App Service: $AppServiceName" -ForegroundColor Green
    } elseif ($appService) {
        Write-Host "  ⚠ App Service: $AppServiceName (state: $($appService.state))" -ForegroundColor Yellow
        $warnings += "App Service not running"
    } elseif ($AppServiceName) {
        Write-Host "  ✗ App Service: $AppServiceName" -ForegroundColor Red
        $warnings += "App Service not found"
    }
    
    Write-Host ""
    
    # Check results summary
    if (-not $QuickCheck) {
        Write-Host "Service Checks:" -ForegroundColor Cyan
        
        if ($checkResults["OpenAI"]) {
            if ($checkResults["OpenAI"].Success) {
                Write-Host "  ✓ OpenAI Service and Models: Ready" -ForegroundColor Green
            } else {
                Write-Host "  ✗ OpenAI Service and Models: Issues detected" -ForegroundColor Red
                $criticalIssues += "OpenAI deployment not ready"
                $overallSuccess = $false
            }
        }
    }
    
    # Connectivity results (if quick check)
    if ($QuickCheck -and $connectivityResults) {
        Write-Host "Connectivity Tests:" -ForegroundColor Cyan
        foreach ($service in $connectivityResults.Keys) {
            if ($connectivityResults[$service]) {
                Write-Host "  ✓ $service: Reachable" -ForegroundColor Green
            } else {
                Write-Host "  ✗ $service: Not reachable" -ForegroundColor Red
                $warnings += "$service endpoint not reachable"
            }
        }
    }
    
    Write-Host ""
    
    # Final verdict
    if ($overallSuccess -and $criticalIssues.Count -eq 0) {
        Write-Host "🎉 DEPLOYMENT READY!" -ForegroundColor Green
        Write-Host "All critical components are properly configured and ready for deployment." -ForegroundColor Green
        
        if ($warnings.Count -gt 0) {
            Write-Host ""
            Write-Host "Warnings (non-critical):" -ForegroundColor Yellow
            foreach ($warning in $warnings) {
                Write-Host "  ⚠ $warning" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "❌ DEPLOYMENT NOT READY" -ForegroundColor Red
        Write-Host "Critical issues must be resolved before deployment:" -ForegroundColor Red
        foreach ($issue in $criticalIssues) {
            Write-Host "  ✗ $issue" -ForegroundColor Red
        }
        
        if ($warnings.Count -gt 0) {
            Write-Host ""
            Write-Host "Additional warnings:" -ForegroundColor Yellow
            foreach ($warning in $warnings) {
                Write-Host "  ⚠ $warning" -ForegroundColor Yellow
            }
        }
        
        Write-Host ""
        Write-Host "Suggested actions:" -ForegroundColor Cyan
        if ($criticalIssues -contains "OpenAI deployment not ready") {
            Write-Host "  - Wait for OpenAI model deployments to complete (use -WaitForCompletion)" -ForegroundColor Cyan
            Write-Host "  - Check Azure OpenAI service quotas and limits" -ForegroundColor Cyan
        }
        if ($criticalIssues -contains "Search Service not found") {
            Write-Host "  - Deploy the ARM template to create missing resources" -ForegroundColor Cyan
        }
        
        exit 1
    }
    
}
catch {
    Write-Host "✗ Unexpected error during readiness check: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
