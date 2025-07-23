# Test Setup Search Components Script
# This script tests the setup_search_components.ps1 without full ARM deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$SearchServiceName = "test-search-service",
    
    [Parameter(Mandatory=$true)]
    [string]$SearchServiceKey = "YOUR_SEARCH_KEY",
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName = "teststorage001",
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountKey = "YOUR_STORAGE_KEY",
    
    [Parameter(Mandatory=$true)]
    [string]$OpenAIEndpoint = "https://your-openai.openai.azure.com/",
    
    [Parameter(Mandatory=$true)]
    [string]$OpenAIKey = "YOUR_OPENAI_KEY",
    
    [Parameter(Mandatory=$false)]
    [string]$DataSourceName = "policing-assistant-data-source",
    
    [Parameter(Mandatory=$false)]
    [string]$IndexName = "policing-assistant-index",
    
    [Parameter(Mandatory=$false)]
    [string]$IndexerName = "policing-assistant-indexer",
    
    [Parameter(Mandatory=$false)]
    [string]$Skillset1Name = "police-skillset-1",
    
    [Parameter(Mandatory=$false)]
    [string]$Skillset2Name = "police-skillset-2",
    
    [Parameter(Mandatory=$false)]
    [string]$StorageContainerName = "docs",
    
    [Parameter(Mandatory=$false)]
    [string]$OpenAIEmbeddingDeployment = "text-embedding-ada-002",
    
    [Parameter(Mandatory=$false)]
    [string]$OpenAIGptDeployment = "policingGptDeployment",
    
    [Parameter(Mandatory=$false)]
    [switch]$DownloadScript
)

Write-Host "🔍 Testing Setup Search Components Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Download the script if requested
if ($DownloadScript) {
    Write-Host "📥 Downloading script from Azure Storage..." -ForegroundColor Yellow
    $scriptUri = "https://stbtpukssandopenai.blob.core.windows.net/policing-assistant-azure-deployment-template/setup_search_components.ps1"
    $scriptPath = ".\setup_search_components_downloaded.ps1"
    
    try {
        Invoke-WebRequest -Uri $scriptUri -OutFile $scriptPath
        Write-Host "✅ Script downloaded to: $scriptPath" -ForegroundColor Green
        $ScriptToRun = $scriptPath
    }
    catch {
        Write-Host "❌ Failed to download script: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Using local script instead..." -ForegroundColor Yellow
        $ScriptToRun = ".\setup_search_components.ps1"
    }
} else {
    $ScriptToRun = ".\setup_search_components.ps1"
}

# Check if script exists
if (-not (Test-Path $ScriptToRun)) {
    Write-Host "❌ Script not found: $ScriptToRun" -ForegroundColor Red
    Write-Host "Please ensure the script exists or use -DownloadScript parameter" -ForegroundColor Yellow
    exit 1
}

Write-Host "📋 Script Parameters:" -ForegroundColor Cyan
Write-Host "  Search Service: $SearchServiceName" -ForegroundColor Gray
Write-Host "  Storage Account: $StorageAccountName" -ForegroundColor Gray
Write-Host "  OpenAI Endpoint: $OpenAIEndpoint" -ForegroundColor Gray
Write-Host "  Data Source: $DataSourceName" -ForegroundColor Gray
Write-Host "  Index: $IndexName" -ForegroundColor Gray
Write-Host "  Indexer: $IndexerName" -ForegroundColor Gray
Write-Host ""

# Build the arguments string (same format as ARM template)
$arguments = @(
    "-searchServiceName `"$SearchServiceName`"",
    "-searchServiceKey `"$SearchServiceKey`"",
    "-dataSourceName `"$DataSourceName`"",
    "-indexName `"$IndexName`"",
    "-indexerName `"$IndexerName`"",
    "-skillset1Name `"$Skillset1Name`"",
    "-skillset2Name `"$Skillset2Name`"",
    "-storageAccountName `"$StorageAccountName`"",
    "-storageAccountKey `"$StorageAccountKey`"",
    "-storageContainerName `"$StorageContainerName`"",
    "-openAIEndpoint `"$OpenAIEndpoint`"",
    "-openAIKey `"$OpenAIKey`"",
    "-openAIEmbeddingDeployment `"$OpenAIEmbeddingDeployment`"",
    "-openAIGptDeployment `"$OpenAIGptDeployment`""
)

$argumentString = $arguments -join " "

Write-Host "🚀 Running script with test parameters..." -ForegroundColor Cyan
Write-Host "Command: $ScriptToRun $argumentString" -ForegroundColor Gray
Write-Host ""

try {
    # Execute the script
    $scriptBlock = [ScriptBlock]::Create("& `"$ScriptToRun`" $argumentString")
    Invoke-Command -ScriptBlock $scriptBlock
    
    Write-Host ""
    Write-Host "✅ Script execution completed!" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "❌ Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📊 Test Summary:" -ForegroundColor Cyan
Write-Host "- Script file: $ScriptToRun"
Write-Host "- Parameters: $(if($arguments.Count -gt 0) { 'Provided' } else { 'Missing' })"
Write-Host "- Execution: $(if($?) { 'Success' } else { 'Failed' })"
