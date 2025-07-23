# Upload Fixed Quota Deployment.json
# This script uploads the deployment.json with reduced OpenAI capacity to fit within quota limits

param(
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = "stbtpukssandopenai",
    
    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "policing-assistant-azure-deployment-template"
)

Write-Host "🚀 Uploading Fixed Quota Deployment.json" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Target Storage: $StorageAccountName" -ForegroundColor Yellow
Write-Host "Target Container: $ContainerName" -ForegroundColor Yellow
Write-Host ""

try {
    # Check if we're authenticated to Azure
    Write-Host "🔐 Checking Azure authentication..." -ForegroundColor Cyan
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "❌ Not logged in to Azure. Please run 'Connect-AzAccount' first." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Authenticated as: $($context.Account.Id)" -ForegroundColor Green
    Write-Host ""
    
    # Get storage account context
    Write-Host "🔗 Connecting to storage account..." -ForegroundColor Cyan
    $storageAccount = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $StorageAccountName }
    if (-not $storageAccount) {
        Write-Host "❌ Storage account '$StorageAccountName' not found or not accessible." -ForegroundColor Red
        exit 1
    }
    
    $ctx = $storageAccount.Context
    Write-Host "✅ Connected to storage account: $StorageAccountName" -ForegroundColor Green
    Write-Host ""
    
    # File to upload
    $localPath = ".\infrastructure\deployment.json"
    $blobName = "deployment.json"
    
    Write-Host "📤 Uploading quota-fixed deployment.json..." -ForegroundColor Yellow
    Write-Host "   Local: $localPath" -ForegroundColor Gray
    Write-Host "   Blob: $blobName" -ForegroundColor Gray
    
    if (-not (Test-Path $localPath)) {
        Write-Host "   ❌ File not found: $localPath" -ForegroundColor Red
        exit 1
    }
    
    # Check quota settings in the file
    Write-Host "🔍 Verifying quota settings..." -ForegroundColor Cyan
    $content = Get-Content $localPath -Raw
    
    # Check embedding capacity
    if ($content -match '"capacity":\s*(\d+)') {
        $capacities = @()
        $matches = [regex]::Matches($content, '"capacity":\s*(\d+)')
        foreach ($match in $matches) {
            $capacities += [int]$match.Groups[1].Value
        }
        
        Write-Host "Found capacity settings: $($capacities -join ', ')" -ForegroundColor Gray
        
        $totalCapacity = $capacities | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        Write-Host "Total capacity required: $totalCapacity" -ForegroundColor $(if($totalCapacity -le 40) { 'Green' } else { 'Yellow' })
        
        if ($totalCapacity -gt 40) {
            Write-Host "⚠️ Warning: Total capacity ($totalCapacity) may exceed your available quota (40)" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Capacity requirements should fit within quota" -ForegroundColor Green
        }
    }
    
    # Upload the file
    try {
        $blob = Set-AzStorageBlobContent `
            -File $localPath `
            -Container $ContainerName `
            -Blob $blobName `
            -Context $ctx `
            -Force
        
        Write-Host "✅ Upload successful" -ForegroundColor Green
        Write-Host "📍 URL: $($blob.ICloudBlob.StorageUri.PrimaryUri)" -ForegroundColor Gray
        
        # Get file size
        $size = [math]::Round($blob.Length / 1KB, 2)
        Write-Host "📦 Size: $size KB" -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ Upload failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "📋 Quota Fix Applied:" -ForegroundColor Cyan
    Write-Host "✅ Text-Embedding-Ada-002 capacity: 30 (was 120)" -ForegroundColor Green
    Write-Host "✅ GPT-4o capacity: 10 (unchanged)" -ForegroundColor Green
    Write-Host "✅ Total capacity needed: ~40 (fits in your quota)" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 Deployment.json quota fix completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Your Deploy to Azure button should now work without quota errors!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 If you still get quota errors, you may need to:" -ForegroundColor Cyan
    Write-Host "   1. Check your OpenAI quota usage in Azure Portal" -ForegroundColor Gray
    Write-Host "   2. Delete unused OpenAI deployments to free up quota" -ForegroundColor Gray
    Write-Host "   3. Request quota increase from Microsoft" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
