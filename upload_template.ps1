# PowerShell script to upload templates to Azure Storage
# Run this if you can authenticate with PowerShell instead of Azure CLI

param(
    [string]$StorageAccountName = "stcoppadeployment02",
    [string]$ContainerName = "coppa-deployment",
    [string]$ResourceGroupName = "rg-coppa-test-02"
)

Write-Host "🚀 Uploading ARM template with PowerShell..." -ForegroundColor Blue
Write-Host "=================================================="

# Check if files exist
$templateFile = "infrastructure/deployment.json"
$uiDefinitionFile = "infrastructure/createUiDefinition.json"

if (-not (Test-Path $templateFile)) {
    Write-Host "❌ Template file not found: $templateFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $uiDefinitionFile)) {
    Write-Host "❌ UI definition file not found: $uiDefinitionFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found template files" -ForegroundColor Green

try {
    # Connect to Azure (this will prompt for authentication)
    Connect-AzAccount

    # Get storage account context
    $ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Context

    # Upload deployment.json
    Write-Host "📤 Uploading deployment.json..." -ForegroundColor Blue
    Set-AzStorageBlobContent -File $templateFile -Container $ContainerName -Blob "deployment.json" -Context $ctx -Force
    Write-Host "✅ deployment.json uploaded successfully" -ForegroundColor Green

    # Upload createUiDefinition.json
    Write-Host "📤 Uploading createUiDefinition.json..." -ForegroundColor Blue
    Set-AzStorageBlobContent -File $uiDefinitionFile -Container $ContainerName -Blob "createUiDefinition.json" -Context $ctx -Force
    Write-Host "✅ createUiDefinition.json uploaded successfully" -ForegroundColor Green

    Write-Host "🎉 Upload completed successfully!" -ForegroundColor Green
    Write-Host "The Deploy to Azure button should now work without authentication errors!" -ForegroundColor Cyan

} catch {
    Write-Host "❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
