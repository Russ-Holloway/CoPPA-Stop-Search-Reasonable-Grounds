# Test CoPPA ARM Template
# This script specifically tests the CoPPA deployment template

Write-Host "🚔 CoPPA - ARM Template Validation" -ForegroundColor Blue
Write-Host "===================================" -ForegroundColor Blue
Write-Host ""

# Set paths
$TemplateFile = Join-Path $PSScriptRoot "..\infrastructure\deployment.json"
$ResourceGroupName = "coppa-test-" + (Get-Random -Maximum 9999)

Write-Host "📁 Template: $TemplateFile" -ForegroundColor Gray
Write-Host "📦 Test RG: $ResourceGroupName" -ForegroundColor Gray
Write-Host ""

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Cyan

# Check if Azure PowerShell is available
try {
    Import-Module Az -ErrorAction Stop
    Write-Host "✅ Azure PowerShell module found" -ForegroundColor Green
}
catch {
    Write-Host "❌ Azure PowerShell module not found. Install with: Install-Module Az" -ForegroundColor Red
    exit 1
}

# Check Azure login
try {
    $context = Get-AzContext
    if ($null -eq $context) {
        Write-Host "❌ Not logged into Azure. Run: Connect-AzAccount" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Logged into Azure: $($context.Account.Id)" -ForegroundColor Green
    Write-Host "   Subscription: $($context.Subscription.Name)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Azure context error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check template file
if (-not (Test-Path $TemplateFile)) {
    Write-Host "❌ Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Template file found" -ForegroundColor Green

Write-Host ""

# Validate JSON syntax
Write-Host "🔍 Validating JSON syntax..." -ForegroundColor Cyan
try {
    $template = Get-Content $TemplateFile -Raw | ConvertFrom-Json
    Write-Host "✅ JSON syntax is valid" -ForegroundColor Green
    
    # Check specific policing assistant components
    $requiredVariables = @(
        'AzureSearchService',
        'AzureOpenAIResource', 
        'StorageAccountName',
        'WebsiteName',
        'ApplicationInsightsName'
    )
    
    $missingVariables = @()
    foreach ($var in $requiredVariables) {
        if (-not $template.variables.PSObject.Properties.Name.Contains($var)) {
            $missingVariables += $var
        }
    }
    
    if ($missingVariables.Count -eq 0) {
        Write-Host "✅ All required variables found" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Missing variables: $($missingVariables -join ', ')" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ JSON syntax error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Create temporary resource group
Write-Host "🔨 Creating temporary resource group..." -ForegroundColor Cyan
try {
    $rg = New-AzResourceGroup -Name $ResourceGroupName -Location "East US" -Force
    Write-Host "✅ Created: $($rg.ResourceGroupName)" -ForegroundColor Green
    $cleanupNeeded = $true
}
catch {
    Write-Host "❌ Failed to create resource group: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Run ARM template validation
Write-Host "🔍 Running ARM template validation..." -ForegroundColor Cyan
try {
    $validation = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile
    
    if ($validation) {
        Write-Host "❌ Template validation failed:" -ForegroundColor Red
        foreach ($error in $validation) {
            Write-Host "   • $($error.Message)" -ForegroundColor Red
            if ($error.Details) {
                foreach ($detail in $error.Details) {
                    Write-Host "     Details: $($detail.Message)" -ForegroundColor Red
                }
            }
        }
        $validationPassed = $false
    }
    else {
        Write-Host "✅ ARM template validation passed!" -ForegroundColor Green
        $validationPassed = $true
    }
}
catch {
    Write-Host "❌ Validation error: $($_.Exception.Message)" -ForegroundColor Red
    $validationPassed = $false
}

Write-Host ""

# Run What-If analysis if validation passed
if ($validationPassed) {
    Write-Host "🔮 Running What-If analysis..." -ForegroundColor Cyan
    try {
        $whatIf = Get-AzResourceGroupDeploymentWhatIf -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile
        
        Write-Host "📋 What-If Results:" -ForegroundColor Yellow
        Write-Host $whatIf -ForegroundColor Gray
    }
    catch {
        Write-Host "⚠️ What-If analysis failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Cleanup
if ($cleanupNeeded) {
    Write-Host "🧹 Cleaning up temporary resource group..." -ForegroundColor Cyan
    try {
        Remove-AzResourceGroup -Name $ResourceGroupName -Force | Out-Null
        Write-Host "✅ Cleanup completed" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Cleanup failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   Please manually delete: $ResourceGroupName" -ForegroundColor Yellow
    }
}

# Final summary
Write-Host ""
Write-Host "📊 Validation Summary" -ForegroundColor Blue
Write-Host "===================" -ForegroundColor Blue

if ($validationPassed) {
    Write-Host "🎉 SUCCESS: Template is ready for deployment!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Review the What-If results above" -ForegroundColor Gray
    Write-Host "2. Deploy to your target resource group" -ForegroundColor Gray
    Write-Host "3. Run post-deployment setup scripts" -ForegroundColor Gray
    exit 0
}
else {
    Write-Host "🚫 FAILED: Please fix the validation errors before deploying" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Cyan
    Write-Host "1. Check the error messages above" -ForegroundColor Gray
    Write-Host "2. Verify all resource names are valid" -ForegroundColor Gray
    Write-Host "3. Ensure API versions are current" -ForegroundColor Gray
    Write-Host "4. Check Azure service availability in your region" -ForegroundColor Gray
    exit 1
}
