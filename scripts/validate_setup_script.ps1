# Enhanced PowerShell Script Validator
param(
    [string]$ScriptPath = "setup_search_components.ps1"
)

function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    try {
        Write-Host "Validating PowerShell syntax..." -ForegroundColor Yellow
        $script = Get-Content $FilePath -Raw
        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput($script, [ref]$tokens, [ref]$errors)
        
        if ($errors.Count -eq 0) {
            Write-Host "✓ PowerShell syntax is valid" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ PowerShell syntax errors found:" -ForegroundColor Red
            foreach ($error in $errors) {
                Write-Host "Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Red
            }
            return $false
        }
    }
    catch {
        Write-Host "❌ Error validating syntax: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-RequiredParameters {
    param([string]$FilePath)
    
    Write-Host "Checking required parameters..." -ForegroundColor Yellow
    $content = Get-Content $FilePath -Raw
    
    $requiredParams = @(
        'searchServiceName',
        'searchServiceKey',
        'dataSourceName',
        'indexName',
        'indexerName',
        'skillset1Name',
        'storageAccountName',
        'storageAccountKey',
        'storageContainerName',
        'openAIEndpoint',
        'openAIKey',
        'openAIEmbeddingDeployment'
    )
    
    $foundParams = @()
    foreach ($param in $requiredParams) {
        if ($content -match "param\s*\(\s*.*?\[\w+\]\s*\`$$param" -or $content -match "\`$$param\s*=") {
            $foundParams += $param
        }
    }
    
    $missingParams = $requiredParams | Where-Object { $_ -notin $foundParams }
    
    if ($missingParams.Count -eq 0) {
        Write-Host "✓ All required parameters are defined" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Missing or incorrectly defined parameters:" -ForegroundColor Red
        $missingParams | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        return $false
    }
}

function Test-JSONStructures {
    param([string]$FilePath)
    
    Write-Host "Validating JSON structures..." -ForegroundColor Yellow
    $content = Get-Content $FilePath -Raw
    
    # Extract hashtables that represent JSON structures
    $jsonStructures = @()
    
    # Look for common JSON structure patterns
    if ($content -match '\$index\s*=\s*@\{') {
        $jsonStructures += "Index definition"
    }
    if ($content -match '\$skillset\s*=\s*@\{') {
        $jsonStructures += "Skillset definition"
    }
    if ($content -match '\$dataSource\s*=\s*@\{') {
        $jsonStructures += "Data source definition"
    }
    if ($content -match '\$indexer\s*=\s*@\{') {
        $jsonStructures += "Indexer definition"
    }
    
    if ($jsonStructures.Count -gt 0) {
        Write-Host "✓ Found JSON structures: $($jsonStructures -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No JSON structures found - this may be expected" -ForegroundColor Yellow
    }
    return $true
}

function Test-CommonIssues {
    param([string]$FilePath)
    
    Write-Host "Checking for common issues..." -ForegroundColor Yellow
    $content = Get-Content $FilePath -Raw
    $lines = Get-Content $FilePath
    $issues = @()
    
    # Check for unmatched braces
    $openBraces = ($content -split '' | Where-Object { $_ -eq '{' }).Count
    $closeBraces = ($content -split '' | Where-Object { $_ -eq '}' }).Count
    if ($openBraces -ne $closeBraces) {
        $issues += "Unmatched braces: $openBraces open, $closeBraces close"
    }
    
    # Check for unmatched parentheses
    $openParens = ($content -split '' | Where-Object { $_ -eq '(' }).Count
    $closeParens = ($content -split '' | Where-Object { $_ -eq ')' }).Count
    if ($openParens -ne $closeParens) {
        $issues += "Unmatched parentheses: $openParens open, $closeParens close"
    }
    
    # Check for missing line breaks in hashtables
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '"\s*[a-zA-Z]+\s*=\s*') {
            $issues += "Line $($i + 1): Potential missing line break in hashtable"
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-Host "✓ No common issues found" -ForegroundColor Green
        return $true
    } else {
        Write-Host "⚠️  Potential issues found:" -ForegroundColor Yellow
        $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        return $true  # These are warnings, not errors
    }
}

# Run all validations
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  PowerShell Script Validation Tool" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Script: $ScriptPath" -ForegroundColor White
Write-Host ""

$allValid = $true

$allValid = (Test-PowerShellSyntax -FilePath $ScriptPath) -and $allValid
$allValid = (Test-RequiredParameters -FilePath $ScriptPath) -and $allValid
$allValid = (Test-JSONStructures -FilePath $ScriptPath) -and $allValid
$allValid = (Test-CommonIssues -FilePath $ScriptPath) -and $allValid

Write-Host ""
if ($allValid) {
    Write-Host "🎉 All validations passed! Script should work in Azure deployment." -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Validation failed. Please fix the issues above." -ForegroundColor Red
    exit 1
}
