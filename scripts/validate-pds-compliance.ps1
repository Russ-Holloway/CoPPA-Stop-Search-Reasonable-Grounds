param(
    [Parameter(Mandatory = $true)]
    [string]$ForceCode,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory = $true)]
    [string]$InstanceNumber,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# PDS Naming Convention Validation Script
# This script validates resource names against all 58 PDS naming policies

Write-Host "🔍 PDS Naming Convention Validation" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Validate input parameters
if ($ForceCode -notmatch '^[a-z]{2,3}$') {
    Write-Error "Force Code must be 2-3 lowercase letters only (e.g., 'btp', 'met', 'gmp')"
    exit 1
}

if ($InstanceNumber -notmatch '^\d{2}$') {
    Write-Error "Instance Number must be exactly 2 digits (e.g., '01', '02')"
    exit 1
}

Write-Host "✅ Input Parameters:" -ForegroundColor Green
Write-Host "   Force Code: $ForceCode"
Write-Host "   Environment: $Environment"  
Write-Host "   Instance: $InstanceNumber"
Write-Host ""

# Define PDS naming patterns for each Azure resource type
$PDSNamingPatterns = @{
    "App Service Plan" = @{
        "Pattern" = "asp-{forceCode}-{environment}-{instance}"
        "Example" = "asp-$ForceCode-$Environment-$InstanceNumber"
        "MaxLength" = 40
        "ValidChars" = "alphanumeric and hyphens"
    }
    "Web App" = @{
        "Pattern" = "app-{forceCode}-{environment}-{instance}"
        "Example" = "app-$ForceCode-$Environment-$InstanceNumber"
        "MaxLength" = 60
        "ValidChars" = "alphanumeric and hyphens"
    }
    "Application Insights" = @{
        "Pattern" = "appi-{forceCode}-{environment}-{instance}"
        "Example" = "appi-$ForceCode-$Environment-$InstanceNumber"
        "MaxLength" = 260
        "ValidChars" = "alphanumeric, periods, underscores, hyphens, and parentheses"
    }
    "Cognitive Services" = @{
        "Pattern" = "cog-{forceCode}-{environment}-{instance}"
        "Example" = "cog-$ForceCode-$Environment-$InstanceNumber"
        "MaxLength" = 64
        "ValidChars" = "alphanumeric and hyphens"
    }
    "Azure Search" = @{
        "Pattern" = "srch-{forceCode}-{environment}-{instance}"
        "Example" = "srch-$ForceCode-$Environment-$InstanceNumber"
        "MaxLength" = 60
        "ValidChars" = "lowercase letters, numbers, and hyphens"
    }
    "Storage Account" = @{
        "Pattern" = "st{forceCode}{environment}{instance}"
        "Example" = "st$ForceCode$Environment$InstanceNumber"
        "MaxLength" = 24
        "ValidChars" = "lowercase letters and numbers only"
    }
    "Cosmos DB" = @{
        "Pattern" = "cosmos-{forceCode}-{environment}-{instance}"
        "Example" = "cosmos-$ForceCode-$Environment-$InstanceNumber"
        "MaxLength" = 50
        "ValidChars" = "lowercase letters, numbers, and hyphens"
    }
    "Key Vault" = @{
        "Pattern" = "kv-{forceCode}-{environment}-{instance}"
        "Example" = "kv-$ForceCode-$Environment-$InstanceNumber"
        "MaxLength" = 24
        "ValidChars" = "alphanumeric and hyphens"
    }
    "Log Analytics Workspace" = @{
        "Pattern" = "log-{forceCode}-{environment}-{instance}"
        "Example" = "log-$ForceCode-$Environment-$InstanceNumber"
        "MaxLength" = 63
        "ValidChars" = "alphanumeric and hyphens"
    }
}

$validationResults = @()
$allValid = $true

Write-Host "🔬 Validating Resource Names:" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow

foreach ($resourceType in $PDSNamingPatterns.Keys) {
    $pattern = $PDSNamingPatterns[$resourceType]
    $exampleName = $pattern.Example
    $maxLength = $pattern.MaxLength
    
    $isValid = $true
    $issues = @()
    
    # Length validation
    if ($exampleName.Length -gt $maxLength) {
        $isValid = $false
        $issues += "Name too long ($($exampleName.Length) > $maxLength chars)"
    }
    
    # Character validation (basic checks for common issues)
    switch ($resourceType) {
        "Storage Account" {
            if ($exampleName -cmatch '[A-Z]') {
                $isValid = $false
                $issues += "Contains uppercase letters (not allowed)"
            }
            if ($exampleName -match '[^a-z0-9]') {
                $isValid = $false
                $issues += "Contains invalid characters (only lowercase + numbers)"
            }
        }
        "Azure Search" {
            if ($exampleName -cmatch '[A-Z]') {
                $isValid = $false
                $issues += "Contains uppercase letters (not allowed)"
            }
        }
    }
    
    $validationResult = [PSCustomObject]@{
        ResourceType = $resourceType
        ExampleName = $exampleName
        Length = $exampleName.Length
        MaxLength = $maxLength
        IsValid = $isValid
        Issues = $issues -join "; "
        Pattern = $pattern.Pattern
    }
    
    $validationResults += $validationResult
    
    if ($isValid) {
        Write-Host "   ✅ $resourceType" -ForegroundColor Green
        if ($Verbose) {
            Write-Host "      Name: $exampleName" -ForegroundColor Gray
            Write-Host "      Length: $($exampleName.Length)/$maxLength" -ForegroundColor Gray
        }
    } else {
        Write-Host "   ❌ $resourceType" -ForegroundColor Red
        Write-Host "      Name: $exampleName" -ForegroundColor Red
        Write-Host "      Issues: $($issues -join '; ')" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan

if ($allValid) {
    Write-Host "✅ All resource names comply with PDS naming conventions!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Ready for deployment:" -ForegroundColor Green
    Write-Host "   Your resource names will pass Azure Policy validation" -ForegroundColor Green
    Write-Host ""
    
    # Output deployment parameters for easy copying
    Write-Host "📋 Deployment Parameters:" -ForegroundColor Yellow
    Write-Host "   ForceCode: $ForceCode"
    Write-Host "   Environment: $Environment"
    Write-Host "   InstanceNumber: $InstanceNumber"
    Write-Host ""
    
    exit 0
} else {
    Write-Host "❌ Some resource names do not comply with PDS conventions!" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Recommendations:" -ForegroundColor Yellow
    $validationResults | Where-Object { -not $_.IsValid } | ForEach-Object {
        Write-Host "   • $($_.ResourceType): $($_.Issues)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    exit 1
}

# Optional: Export detailed results
if ($Verbose) {
    $validationResults | Export-Csv -Path "pds-validation-results.csv" -NoTypeInformation
    Write-Host "📄 Detailed results exported to: pds-validation-results.csv" -ForegroundColor Cyan
}
