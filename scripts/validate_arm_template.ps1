# ARM Template Validation Script
# This script validates the ARM template before actual deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$TemplateFile,
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "policing-assistant-validation-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateTestResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanupAfterValidation
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-AzureLogin {
    Write-ColorOutput "Checking Azure login status..." $InfoColor
    try {
        $context = Get-AzContext
        if ($null -eq $context) {
            Write-ColorOutput "Not logged into Azure. Please run 'Connect-AzAccount' first." $ErrorColor
            return $false
        }
        Write-ColorOutput "✓ Logged into Azure as: $($context.Account.Id)" $SuccessColor
        return $true
    }
    catch {
        Write-ColorOutput "Error checking Azure login: $($_.Exception.Message)" $ErrorColor
        return $false
    }
}

function Test-TemplateFileExists {
    Write-ColorOutput "Checking if template file exists..." $InfoColor
    if (-not (Test-Path $TemplateFile)) {
        Write-ColorOutput "✗ Template file not found: $TemplateFile" $ErrorColor
        return $false
    }
    Write-ColorOutput "✓ Template file found: $TemplateFile" $SuccessColor
    return $true
}

function Test-TemplateJsonSyntax {
    Write-ColorOutput "Validating JSON syntax..." $InfoColor
    try {
        $templateContent = Get-Content $TemplateFile -Raw | ConvertFrom-Json
        Write-ColorOutput "✓ Template JSON syntax is valid" $SuccessColor
        return $true
    }
    catch {
        Write-ColorOutput "✗ Template JSON syntax error: $($_.Exception.Message)" $ErrorColor
        return $false
    }
}

function Test-ParametersFileExists {
    if ($ParametersFile) {
        Write-ColorOutput "Checking if parameters file exists..." $InfoColor
        if (-not (Test-Path $ParametersFile)) {
            Write-ColorOutput "✗ Parameters file not found: $ParametersFile" $ErrorColor
            return $false
        }
        Write-ColorOutput "✓ Parameters file found: $ParametersFile" $SuccessColor
    }
    return $true
}

function New-TestResourceGroup {
    if ($CreateTestResourceGroup) {
        Write-ColorOutput "Creating test resource group: $ResourceGroupName" $InfoColor
        try {
            $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
            Write-ColorOutput "✓ Test resource group created: $($rg.ResourceGroupName)" $SuccessColor
            return $true
        }
        catch {
            Write-ColorOutput "✗ Failed to create test resource group: $($_.Exception.Message)" $ErrorColor
            return $false
        }
    }
    return $true
}

function Test-ArmTemplateValidation {
    Write-ColorOutput "Running ARM template validation..." $InfoColor
    try {
        $validationParams = @{
            ResourceGroupName = $ResourceGroupName
            TemplateFile = $TemplateFile
        }
        
        if ($ParametersFile) {
            $validationParams.TemplateParameterFile = $ParametersFile
        }
        
        $validation = Test-AzResourceGroupDeployment @validationParams
        
        if ($validation) {
            Write-ColorOutput "✗ Template validation failed:" $ErrorColor
            foreach ($error in $validation) {
                Write-ColorOutput "  - $($error.Message)" $ErrorColor
                if ($error.Details) {
                    foreach ($detail in $error.Details) {
                        Write-ColorOutput "    Details: $($detail.Message)" $ErrorColor
                    }
                }
            }
            return $false
        }
        else {
            Write-ColorOutput "✓ ARM template validation passed!" $SuccessColor
            return $true
        }
    }
    catch {
        Write-ColorOutput "✗ Validation error: $($_.Exception.Message)" $ErrorColor
        return $false
    }
}

function Test-WhatIfDeployment {
    Write-ColorOutput "Running What-If deployment analysis..." $InfoColor
    try {
        $whatIfParams = @{
            ResourceGroupName = $ResourceGroupName
            TemplateFile = $TemplateFile
            Mode = 'Incremental'
        }
        
        if ($ParametersFile) {
            $whatIfParams.TemplateParameterFile = $ParametersFile
        }
        
        $whatIf = Get-AzResourceGroupDeploymentWhatIf @whatIfParams
        
        Write-ColorOutput "What-If Results:" $InfoColor
        Write-ColorOutput $whatIf $InfoColor
        
        return $true
    }
    catch {
        Write-ColorOutput "✗ What-If analysis failed: $($_.Exception.Message)" $ErrorColor
        return $false
    }
}

function Remove-TestResourceGroup {
    if ($CleanupAfterValidation -and $CreateTestResourceGroup) {
        Write-ColorOutput "Cleaning up test resource group..." $InfoColor
        try {
            Remove-AzResourceGroup -Name $ResourceGroupName -Force
            Write-ColorOutput "✓ Test resource group cleaned up" $SuccessColor
        }
        catch {
            Write-ColorOutput "⚠ Failed to cleanup test resource group: $($_.Exception.Message)" $WarningColor
        }
    }
}

function Test-AzureQuotas {
    Write-ColorOutput "Checking Azure quotas and limits..." $InfoColor
    try {
        # Check compute quotas
        $location = (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue).Location
        if (-not $location) { $location = $Location }
        
        $usage = Get-AzVMUsage -Location $location
        Write-ColorOutput "Compute quotas in $location:" $InfoColor
        $usage | Where-Object { $_.CurrentValue -gt 0 } | ForEach-Object {
            $percentUsed = [math]::Round(($_.CurrentValue / $_.Limit) * 100, 2)
            if ($percentUsed -gt 80) {
                Write-ColorOutput "  ⚠ $($_.Name.LocalizedValue): $($_.CurrentValue)/$($_.Limit) ($percentUsed%)" $WarningColor
            }
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "⚠ Could not check quotas: $($_.Exception.Message)" $WarningColor
        return $true  # Non-critical failure
    }
}

# Main execution
Write-ColorOutput "=== ARM Template Validation Script ===" $InfoColor
Write-ColorOutput "Template: $TemplateFile" $InfoColor
if ($ParametersFile) { Write-ColorOutput "Parameters: $ParametersFile" $InfoColor }
Write-ColorOutput "Resource Group: $ResourceGroupName" $InfoColor
Write-ColorOutput "Location: $Location" $InfoColor
Write-ColorOutput ""

$validationSteps = @(
    { Test-AzureLogin },
    { Test-TemplateFileExists },
    { Test-TemplateJsonSyntax },
    { Test-ParametersFileExists },
    { New-TestResourceGroup },
    { Test-AzureQuotas },
    { Test-ArmTemplateValidation },
    { Test-WhatIfDeployment }
)

$allPassed = $true
foreach ($step in $validationSteps) {
    if (-not (& $step)) {
        $allPassed = $false
        break
    }
    Write-ColorOutput ""
}

# Cleanup
Remove-TestResourceGroup

# Final result
Write-ColorOutput "=== Validation Summary ===" $InfoColor
if ($allPassed) {
    Write-ColorOutput "✓ All validation checks passed! Template is ready for deployment." $SuccessColor
    exit 0
}
else {
    Write-ColorOutput "✗ Some validation checks failed. Please fix the issues before deploying." $ErrorColor
    exit 1
}
