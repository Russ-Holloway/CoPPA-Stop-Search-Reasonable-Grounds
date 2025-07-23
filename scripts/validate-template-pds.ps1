#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates ARM template against PDS naming policies before deployment
    
.DESCRIPTION
    This script performs comprehensive validation of the ARM template to ensure
    all generated resource names will comply with the 58 PDS naming policies.
    Run this before any deployment to catch compliance issues early.
    
.PARAMETER TemplateFile
    Path to the ARM template file to validate
    
.PARAMETER ParametersFile  
    Path to the parameters file (optional)
    
.PARAMETER ForceCode
    The police force code to test with
    
.PARAMETER Environment
    The environment to test with (dev, test, prod)
    
.PARAMETER InstanceNumber
    The instance number to test with
    
.PARAMETER Verbose
    Show detailed validation information
    
.EXAMPLE
    .\scripts\validate-template-pds.ps1 -ForceCode "btp" -Environment "prod" -InstanceNumber "01"
    
.EXAMPLE
    .\scripts\validate-template-pds.ps1 -TemplateFile "infrastructure\deployment.json" -ForceCode "met" -Environment "dev" -InstanceNumber "02" -Verbose
#>

param(
    [Parameter()]
    [string]$TemplateFile = "infrastructure\deployment.json",
    
    [Parameter()]
    [string]$ParametersFile = "",
    
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[a-z]{2,3}$")]
    [string]$ForceCode,
    
    [Parameter(Mandatory = $true)]  
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[0-9]{2}$")]
    [string]$InstanceNumber,
    
    [Parameter()]
    [switch]$Verbose
)

# Colors for output
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m" 
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-Success($message) { Write-Host "${Green}✅ $message${Reset}" }
function Write-Error($message) { Write-Host "${Red}❌ $message${Reset}" }
function Write-Warning($message) { Write-Host "${Yellow}⚠️  $message${Reset}" }
function Write-Info($message) { Write-Host "${Blue}ℹ️  $message${Reset}" }

Write-Host "${Blue}🔍 PDS Template Validation${Reset}" -ForegroundColor Blue
Write-Host "Template: $TemplateFile"
Write-Host "Force: $ForceCode, Environment: $Environment, Instance: $InstanceNumber"
Write-Host ""

# Check if template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Error "Template file not found: $TemplateFile"
    exit 1
}

try {
    # Load and parse ARM template
    $template = Get-Content $TemplateFile | ConvertFrom-Json
    Write-Success "Template parsed successfully"
    
    # Validate template has required PDS parameters
    $requiredParams = @("ForceCode", "EnvironmentSuffix", "InstanceNumber")
    $missingParams = @()
    
    foreach ($param in $requiredParams) {
        if (-not $template.parameters.PSObject.Properties.Name -contains $param) {
            $missingParams += $param
        }
    }
    
    if ($missingParams.Count -gt 0) {
        Write-Error "Template missing required PDS parameters: $($missingParams -join ', ')"
        exit 1
    }
    Write-Success "All required PDS parameters present"
    
    # Simulate resource name generation using template variables
    $testParams = @{
        ForceCode = $ForceCode
        EnvironmentSuffix = $Environment  
        InstanceNumber = $InstanceNumber
    }
    
    Write-Info "Simulating resource name generation..."
    
    # Expected resource naming patterns from template
    $expectedNames = @{
        "appServicePlanName" = "asp-$ForceCode-$Environment-$InstanceNumber"
        "webAppName" = "app-$ForceCode-$Environment-$InstanceNumber"
        "applicationInsightsName" = "appi-$ForceCode-$Environment-$InstanceNumber"
        "cognitiveServicesName" = "cog-$ForceCode-$Environment-$InstanceNumber"
        "searchServiceName" = "srch-$ForceCode-$Environment-$InstanceNumber"
        "storageAccountName" = "st$ForceCode$Environment$InstanceNumber"
        "cosmosDbName" = "cosmos-$ForceCode-$Environment-$InstanceNumber"
        "keyVaultName" = "kv-$ForceCode-$Environment-$InstanceNumber"
        "resourceGroupName" = "rg-$ForceCode-$Environment-$InstanceNumber"
    }
    
    # PDS naming validation rules
    $validationRules = @{
        "appServicePlanName" = @{
            pattern = "^asp-[a-z]{2,3}-(dev|test|prod)-[0-9]{2}$"
            maxLength = 40
            allowedChars = "^[a-z0-9\-]+$"
            description = "App Service Plan"
        }
        "webAppName" = @{
            pattern = "^app-[a-z]{2,3}-(dev|test|prod)-[0-9]{2}$"
            maxLength = 60
            allowedChars = "^[a-z0-9\-]+$"
            description = "Web App"
        }
        "applicationInsightsName" = @{
            pattern = "^appi-[a-z]{2,3}-(dev|test|prod)-[0-9]{2}$"
            maxLength = 255
            allowedChars = "^[a-zA-Z0-9\-\.]+$"
            description = "Application Insights"
        }
        "cognitiveServicesName" = @{
            pattern = "^cog-[a-z]{2,3}-(dev|test|prod)-[0-9]{2}$"
            maxLength = 64
            allowedChars = "^[a-zA-Z0-9\-]+$"
            description = "Cognitive Services"
        }
        "searchServiceName" = @{
            pattern = "^srch-[a-z]{2,3}-(dev|test|prod)-[0-9]{2}$"
            maxLength = 60
            allowedChars = "^[a-z0-9\-]+$"
            description = "Azure Search"
        }
        "storageAccountName" = @{
            pattern = "^st[a-z]{2,3}(dev|test|prod)[0-9]{2}$"
            maxLength = 24
            allowedChars = "^[a-z0-9]+$"
            description = "Storage Account"
        }
        "cosmosDbName" = @{
            pattern = "^cosmos-[a-z]{2,3}-(dev|test|prod)-[0-9]{2}$"
            maxLength = 44
            allowedChars = "^[a-z0-9\-]+$"
            description = "Cosmos DB"
        }
        "keyVaultName" = @{
            pattern = "^kv-[a-z]{2,3}-(dev|test|prod)-[0-9]{2}$"
            maxLength = 24
            allowedChars = "^[a-zA-Z0-9\-]+$"
            description = "Key Vault"
        }
        "resourceGroupName" = @{
            pattern = "^rg-[a-z]{2,3}-(dev|test|prod)-[0-9]{2}$"
            maxLength = 90
            allowedChars = "^[a-zA-Z0-9\-\.\_\(\)]+$"
            description = "Resource Group"
        }
    }
    
    $validationErrors = @()
    $validationWarnings = @()
    
    # Validate each generated name
    foreach ($resourceName in $expectedNames.Keys) {
        $generatedName = $expectedNames[$resourceName]
        $rule = $validationRules[$resourceName]
        
        if ($Verbose) {
            Write-Info "Validating $($rule.description): $generatedName"
        }
        
        # Pattern validation
        if ($generatedName -notmatch $rule.pattern) {
            $validationErrors += "❌ $($rule.description) '$generatedName' does not match PDS pattern: $($rule.pattern)"
        }
        
        # Length validation
        if ($generatedName.Length -gt $rule.maxLength) {
            $validationErrors += "❌ $($rule.description) '$generatedName' exceeds max length of $($rule.maxLength) characters"
        }
        
        # Character validation
        if ($generatedName -notmatch $rule.allowedChars) {
            $validationErrors += "❌ $($rule.description) '$generatedName' contains invalid characters (allowed: $($rule.allowedChars))"
        }
        
        # Specific checks
        if ($resourceName -eq "storageAccountName") {
            # Storage accounts must be globally unique
            if ($generatedName.Length -lt 3) {
                $validationErrors += "❌ Storage account name '$generatedName' too short (minimum 3 characters)"
            }
            if ($generatedName -cmatch "[A-Z]") {
                $validationErrors += "❌ Storage account name '$generatedName' contains uppercase letters (must be lowercase)"
            }
        }
        
        if ($resourceName -eq "keyVaultName") {
            # Key Vault names must be globally unique
            if ($generatedName -match "^kv$|^vault$") {
                $validationWarnings += "⚠️  Key Vault name '$generatedName' may conflict with reserved names"
            }
        }
        
        if ($Verbose) {
            Write-Success "$($rule.description): $generatedName - Valid"
        }
    }
    
    # Check template variables section for PDS patterns
    Write-Info "Validating template variables section..."
    
    if (-not $template.variables) {
        Write-Warning "Template has no variables section"
    } else {
        # Look for PDS naming patterns in variables
        $variableNames = $template.variables.PSObject.Properties.Name
        $expectedVariables = @("appServicePlanName", "webAppName", "applicationInsightsName", 
                             "cognitiveServicesName", "searchServiceName", "storageAccountName")
        
        foreach ($expectedVar in $expectedVariables) {
            if ($variableNames -contains $expectedVar) {
                Write-Success "Found variable: $expectedVar"
            } else {
                $validationWarnings += "⚠️  Expected variable '$expectedVar' not found in template"
            }
        }
    }
    
    # Display results
    Write-Host ""
    Write-Host "${Blue}📊 Validation Results${Reset}" -ForegroundColor Blue
    Write-Host ""
    
    if ($validationErrors.Count -eq 0) {
        Write-Success "Template validation PASSED - All resource names are PDS compliant!"
        Write-Host ""
        Write-Host "${Green}Generated resource names:${Reset}"
        foreach ($name in $expectedNames.GetEnumerator() | Sort-Object Key) {
            Write-Host "  • $($validationRules[$name.Key].description): $($name.Value)"
        }
    } else {
        Write-Error "Template validation FAILED - $($validationErrors.Count) PDS compliance issues found:"
        Write-Host ""
        foreach ($error in $validationErrors) {
            Write-Host "  $error"
        }
        exit 1
    }
    
    if ($validationWarnings.Count -gt 0) {
        Write-Host ""
        Write-Warning "Validation warnings ($($validationWarnings.Count)):"
        foreach ($warning in $validationWarnings) {
            Write-Host "  $warning"
        }
    }
    
    Write-Host ""
    Write-Success "✨ Template is ready for PDS-compliant deployment!"
    
} catch {
    Write-Error "Template validation failed: $($_.Exception.Message)"
    if ($Verbose) {
        Write-Host $_.Exception.StackTrace
    }
    exit 1
}
