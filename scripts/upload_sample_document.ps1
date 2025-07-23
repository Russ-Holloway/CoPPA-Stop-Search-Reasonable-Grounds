# Upload Sample Document and Copy Script to Azure Storage
# This script uploads the pre-created sample document and copy script to your deployment storage

param(
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = "stbtpukssandopenai",
    
    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "policing-assistant-azure-deployment-template"
)

Write-Host "🚀 Uploading Sample Document and Copy Script" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Target Storage: $StorageAccountName" -ForegroundColor Yellow
Write-Host "Target Container: $ContainerName" -ForegroundColor Yellow
Write-Host ""

# Files to upload
$filesToUpload = @(
    @{
        LocalPath = ".\sample-police-procedures.txt"
        BlobName = "sample-police-procedures.txt"
        Description = "Sample police procedures document"
    },
    @{
        LocalPath = ".\scripts\copy_sample_document.ps1"
        BlobName = "copy_sample_document.ps1"
        Description = "Sample document copy script"
    }
)

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
    
    # Upload each file
    foreach ($file in $filesToUpload) {
        Write-Host "📤 Uploading: $($file.Description)" -ForegroundColor Yellow
        Write-Host "   Local: $($file.LocalPath)" -ForegroundColor Gray
        Write-Host "   Blob: $($file.BlobName)" -ForegroundColor Gray
        
        if (-not (Test-Path $file.LocalPath)) {
            Write-Host "   ⚠️ File not found: $($file.LocalPath)" -ForegroundColor Yellow
            continue
        }
        
        try {
            $blob = Set-AzStorageBlobContent `
                -File $file.LocalPath `
                -Container $ContainerName `
                -Blob $file.BlobName `
                -Context $ctx `
                -Force
            
            Write-Host "   ✅ Upload successful" -ForegroundColor Green
            Write-Host "   📍 URL: $($blob.ICloudBlob.StorageUri.PrimaryUri)" -ForegroundColor Gray
        }
        catch {
            Write-Host "   ❌ Upload failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    # Verify uploads
    Write-Host "🔍 Verifying uploads..." -ForegroundColor Cyan
    foreach ($file in $filesToUpload) {
        try {
            $blob = Get-AzStorageBlob -Container $ContainerName -Blob $file.BlobName -Context $ctx
            $size = [math]::Round($blob.Length / 1KB, 2)
            Write-Host "✅ $($file.BlobName) - $size KB" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ $($file.BlobName) - Not found" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. The sample document is now available at:" -ForegroundColor Gray
    Write-Host "   https://$StorageAccountName.blob.core.windows.net/$ContainerName/sample-police-procedures.txt" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "2. The copy script is now available at:" -ForegroundColor Gray
    Write-Host "   https://$StorageAccountName.blob.core.windows.net/$ContainerName/copy_sample_document.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "3. Test the Deploy to Azure button - it should now:" -ForegroundColor Gray
    Write-Host "   - Copy the sample document (instead of creating it)" -ForegroundColor Gray
    Write-Host "   - Set up search components" -ForegroundColor Gray
    Write-Host "   - Work without PowerShell parameter errors" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎉 Upload completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
