# Quick ARM Template Validation
# Simple validation script for quick checks

param(
    [string]$TemplateFile = "../infrastructure/deployment.json",
    [string]$ResourceGroupName = "policing-validation-rg"
)

Write-Host "🔍 Quick ARM Template Validation" -ForegroundColor Cyan
Write-Host "Template: $TemplateFile" -ForegroundColor Gray
Write-Host ""

# Check if logged into Azure
try {
    $context = Get-AzContext
    if ($null -eq $context) {
        Write-Host "❌ Not logged into Azure. Run: Connect-AzAccount" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Azure Login: $($context.Account.Id)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Azure PowerShell not available. Install: Install-Module Az" -ForegroundColor Red
    exit 1
}

# Check template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Host "❌ Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Template file found" -ForegroundColor Green

# Validate JSON syntax
try {
    $null = Get-Content $TemplateFile -Raw | ConvertFrom-Json
    Write-Host "✅ JSON syntax valid" -ForegroundColor Green
}
catch {
    Write-Host "❌ JSON syntax error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check if resource group exists, create temp one if needed
$rgExists = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
$createdTempRg = $false

if (-not $rgExists) {
    Write-Host "ℹ️ Creating temporary resource group for validation..." -ForegroundColor Yellow
    try {
        New-AzResourceGroup -Name $ResourceGroupName -Location "East US" | Out-Null
        $createdTempRg = $true
        Write-Host "✅ Temporary resource group created" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to create resource group: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Run ARM template validation
Write-Host "🔍 Running ARM template validation..." -ForegroundColor Cyan
try {
    $validation = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile
    
    if ($validation) {
        Write-Host "❌ Template validation failed:" -ForegroundColor Red
        foreach ($error in $validation) {
            Write-Host "   • $($error.Message)" -ForegroundColor Red
        }
        $success = $false
    }
    else {
        Write-Host "✅ ARM template validation passed!" -ForegroundColor Green
        $success = $true
    }
}
catch {
    Write-Host "❌ Validation error: $($_.Exception.Message)" -ForegroundColor Red
    $success = $false
}

# Cleanup temporary resource group
if ($createdTempRg) {
    Write-Host "🧹 Cleaning up temporary resource group..." -ForegroundColor Yellow
    try {
        Remove-AzResourceGroup -Name $ResourceGroupName -Force | Out-Null
        Write-Host "✅ Cleanup completed" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Cleanup failed (manual cleanup may be needed): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($success) {
    Write-Host "🎉 Template is ready for deployment!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "🚫 Please fix validation errors before deploying." -ForegroundColor Red
    exit 1
}
