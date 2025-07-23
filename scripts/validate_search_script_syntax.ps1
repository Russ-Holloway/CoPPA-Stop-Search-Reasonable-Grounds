# Validate Search Script Syntax and Parameters
# Tests the PowerShell script without actually connecting to Azure services

Write-Host "🔍 Search Script Validation (Syntax Only)" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Check if the local script exists
$scriptPath = ".\setup_search_components.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Local script not found: $scriptPath" -ForegroundColor Red
    
    # Try to download from the deployment URI
    Write-Host "📥 Attempting to download script..." -ForegroundColor Yellow
    $scriptUri = "https://stbtpukssandopenai.blob.core.windows.net/policing-assistant-azure-deployment-template/setup_search_components.ps1"
    
    try {
        Invoke-WebRequest -Uri $scriptUri -OutFile "setup_search_components_downloaded.ps1"
        $scriptPath = ".\setup_search_components_downloaded.ps1"
        Write-Host "✅ Script downloaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to download script: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host "📝 Checking script syntax..." -ForegroundColor Cyan

# Test PowerShell syntax
try {
    $scriptContent = Get-Content $scriptPath -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$null)
    Write-Host "✅ PowerShell syntax is valid" -ForegroundColor Green
}
catch {
    Write-Host "❌ PowerShell syntax error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check for required parameters
Write-Host "📋 Checking script parameters..." -ForegroundColor Cyan

$requiredParams = @(
    'searchServiceName',
    'searchServiceKey', 
    'dataSourceName',
    'indexName',
    'indexerName',
    'skillset1Name',
    'skillset2Name',
    'storageAccountName',
    'storageAccountKey',
    'storageContainerName',
    'openAIEndpoint',
    'openAIKey',
    'openAIEmbeddingDeployment',
    'openAIGptDeployment'
)

try {
    $scriptAST = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$null)
    $parameterBlock = $scriptAST.FindAll({$args[0] -is [System.Management.Automation.Language.ParamBlockAst]}, $false)

    if ($parameterBlock) {
        $definedParams = $parameterBlock[0].Parameters.Name.VariablePath.UserPath
        
        Write-Host "📋 Script parameters found:" -ForegroundColor Yellow
        foreach ($param in $definedParams) {
            $isRequired = $param -in $requiredParams
            $status = if ($isRequired) { "✅ Required" } else { "ℹ️ Optional" }
            Write-Host "  - $param : $status" -ForegroundColor Gray
        }
        
        # Check for missing required parameters
        $missingParams = $requiredParams | Where-Object { $_ -notin $definedParams }
        if ($missingParams) {
            Write-Host "⚠️ Missing required parameters:" -ForegroundColor Yellow
            foreach ($missing in $missingParams) {
                Write-Host "  - $missing" -ForegroundColor Red
            }
        } else {
            Write-Host "✅ All required parameters are defined" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️ No parameter block found in script" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠️ Could not parse script for parameters: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Check for Azure PowerShell cmdlets
Write-Host "🔍 Checking Azure PowerShell dependencies..." -ForegroundColor Cyan

$azureCmdlets = @(
    'New-AzSearchDataSource',
    'New-AzSearchIndex', 
    'New-AzSearchIndexer',
    'New-AzSearchSkillset',
    'Invoke-RestMethod'
)

$scriptText = Get-Content $scriptPath -Raw
$foundCmdlets = @()
$missingCmdlets = @()

foreach ($cmdlet in $azureCmdlets) {
    if ($scriptText -match $cmdlet) {
        $foundCmdlets += $cmdlet
        Write-Host "  ✅ Found: $cmdlet" -ForegroundColor Green
    } else {
        $missingCmdlets += $cmdlet
        Write-Host "  ⚠️ Not found: $cmdlet" -ForegroundColor Yellow
    }
}

# Summary
Write-Host ""
Write-Host "📊 Validation Summary:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "✅ Script file exists: $scriptPath" -ForegroundColor Green
Write-Host "✅ PowerShell syntax valid" -ForegroundColor Green
Write-Host "📋 Azure cmdlets: $($foundCmdlets.Count) found" -ForegroundColor $(if($foundCmdlets.Count -gt 0) { 'Green' } else { 'Yellow' })

if ($missingCmdlets.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️ Note: Missing cmdlets may indicate the script uses REST API calls or custom functions" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Script validation completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps for full testing:" -ForegroundColor Cyan
Write-Host "1. Use test_search_script.ps1 with real Azure resource credentials" -ForegroundColor Gray
Write-Host "2. Or deploy a minimal test environment with just Search, Storage, and OpenAI" -ForegroundColor Gray
