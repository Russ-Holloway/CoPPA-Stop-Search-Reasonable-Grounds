param(
    [Parameter(Mandatory=$true)]
    [string] $ForceCode,
    [Parameter(Mandatory=$true)]
    [string] $Environment,
    [Parameter(Mandatory=$true)]
    [string] $InstanceNumber,
    [Parameter(Mandatory=$false)]
    [string] $ResourceGroupName
)

# PDS Naming Validation Script
# This script validates that resource names comply with PDS naming standards

Write-Host "=== PDS Naming Compliance Validation ===" -ForegroundColor Green
Write-Host "Force Code: $ForceCode"
Write-Host "Environment: $Environment"
Write-Host "Instance: $InstanceNumber"
Write-Host ""

$validationErrors = @()
$validationWarnings = @()

# Validate Force Code
if ($ForceCode -cnotmatch '^[a-z]{2,3}$') {
    $validationErrors += "Force code '$ForceCode' must be 2-3 lowercase letters only"
}

# Validate Environment
$validEnvironments = @('dev', 'test', 'prod')
if ($Environment -notin $validEnvironments) {
    $validationErrors += "Environment '$Environment' must be one of: $($validEnvironments -join ', ')"
}

# Validate Instance Number
if ($InstanceNumber -notmatch '^\d{2}$') {
    $validationErrors += "Instance number '$InstanceNumber' must be exactly 2 digits (e.g., '01', '02')"
}

# Generate expected resource names following PDS naming conventions
$expectedNames = @{
    "WebApp" = "app-$ForceCode-policing-$Environment-$InstanceNumber"
    "SearchService" = "srch-$ForceCode-policing-$Environment-$InstanceNumber"
    "OpenAIService" = "ai-$ForceCode-policing-$Environment-$InstanceNumber"
    "StorageAccount" = "st$($ForceCode)policing$($Environment)$($InstanceNumber)"
    "CosmosDB" = "db-$ForceCode-policing-$Environment-$InstanceNumber"
    "AppInsights" = "appi-$ForceCode-policing-$Environment-$InstanceNumber"
    "SearchIndex" = "$ForceCode-policing-index-$Environment"
    "SearchIndexer" = "$ForceCode-policing-indexer-$Environment"
    "SearchDataSource" = "$ForceCode-policing-datasource-$Environment"
}

# PDS Naming Pattern Validation
$pdsPatterns = @{
    "WebApp" = "^app-.*"
    "CosmosDB" = "^db-.*"
    "StorageAccount" = "^st.*"
    "AppInsights" = "^appi-.*"
    "SearchService" = "^srch-.*"  # Assumed pattern
    "OpenAIService" = "^ai-.*"    # Assumed pattern
}

# Validate resource name lengths
$lengthLimits = @{
    "WebApp" = 60
    "SearchService" = 60
    "OpenAIService" = 64
    "StorageAccount" = 24
    "CosmosDB" = 44
    "AppInsights" = 260
    "SearchIndex" = 128
    "SearchIndexer" = 128
    "SearchDataSource" = 128
}

Write-Host "Generated Resource Names:" -ForegroundColor Yellow
foreach ($resource in $expectedNames.GetEnumerator()) {
    $name = $resource.Value
    $limit = $lengthLimits[$resource.Key]
    $pattern = $pdsPatterns[$resource.Key]
    
    # Check PDS naming compliance
    $pdsCompliant = $true
    if ($pattern -and $name -notmatch $pattern) {
        $validationErrors += "$($resource.Key) name '$name' does not comply with PDS naming pattern '$pattern'"
        $pdsCompliant = $false
    }
    
    if ($name.Length -gt $limit) {
        $validationErrors += "$($resource.Key) name '$name' exceeds length limit of $limit characters"
        Write-Host "  $($resource.Key): $name (ERROR: Too long - $($name.Length)/$limit chars)" -ForegroundColor Red
    }
    elseif (-not $pdsCompliant) {
        Write-Host "  $($resource.Key): $name (ERROR: PDS non-compliant - $($name.Length)/$limit chars)" -ForegroundColor Red
    }
    elseif ($name.Length -gt ($limit * 0.8)) {
        $validationWarnings += "$($resource.Key) name '$name' is close to length limit ($($name.Length)/$limit characters)"
        Write-Host "  $($resource.Key): $name (WARNING: Close to limit - $($name.Length)/$limit chars)" -ForegroundColor Yellow
    }
    else {
        Write-Host "  $($resource.Key): $name (✅ PDS Compliant - $($name.Length)/$limit chars)" -ForegroundColor Green
    }
}

# Validate storage account name (special rules)
$storageAccountName = $expectedNames["StorageAccount"]
if ($storageAccountName -cnotmatch '^[a-z0-9]{3,24}$') {
    $validationErrors += "Storage account name '$storageAccountName' must contain only lowercase letters and numbers"
}

# Check for globally unique names (best effort)
Write-Host ""
Write-Host "Checking global uniqueness (where applicable)..." -ForegroundColor Yellow

# Storage account uniqueness check
try {
    $storageCheck = Get-AzStorageAccountNameAvailability -Name $storageAccountName -ErrorAction SilentlyContinue
    if ($storageCheck -and -not $storageCheck.NameAvailable) {
        $validationErrors += "Storage account name '$storageAccountName' is not globally unique: $($storageCheck.Reason)"
        Write-Host "  Storage Account: NOT AVAILABLE ($($storageCheck.Reason))" -ForegroundColor Red
    }
    else {
        Write-Host "  Storage Account: Available" -ForegroundColor Green
    }
}
catch {
    Write-Host "  Storage Account: Could not check availability (you may need to be logged in)" -ForegroundColor Yellow
}

# Resource Group validation
if ($ResourceGroupName) {
    Write-Host ""
    Write-Host "Resource Group Validation:" -ForegroundColor Yellow
    
    if ($ResourceGroupName -notmatch '^rg-') {
        $validationWarnings += "Resource group '$ResourceGroupName' should start with 'rg-' for PDS compliance"
        Write-Host "  Resource Group: $ResourceGroupName (WARNING: Should start with 'rg-')" -ForegroundColor Yellow
    }
    else {
        Write-Host "  Resource Group: $ResourceGroupName (Compliant)" -ForegroundColor Green
    }
}

# Summary
Write-Host ""
Write-Host "=== Validation Summary ===" -ForegroundColor Green

if ($validationErrors.Count -eq 0) {
    Write-Host "✅ All validations passed!" -ForegroundColor Green
    
    if ($validationWarnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $validationWarnings) {
            Write-Host "  ⚠️  $warning" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Your deployment is ready and PDS compliant!" -ForegroundColor Green
    Write-Host "You can proceed with the deployment using these parameters." -ForegroundColor Green
    
    # Output parameters for easy copy/paste
    Write-Host ""
    Write-Host "Parameters for deployment:" -ForegroundColor Cyan
    Write-Host "  -ForceCode $ForceCode" -ForegroundColor White
    Write-Host "  -EnvironmentSuffix $Environment" -ForegroundColor White
    Write-Host "  -InstanceNumber $InstanceNumber" -ForegroundColor White
    
    exit 0
}
else {
    Write-Host "❌ Validation failed with errors:" -ForegroundColor Red
    foreach ($error in $validationErrors) {
        Write-Host "  ❌ $error" -ForegroundColor Red
    }
    
    if ($validationWarnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $validationWarnings) {
            Write-Host "  ⚠️  $warning" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Please fix the errors above before proceeding with deployment." -ForegroundColor Red
    exit 1
}
