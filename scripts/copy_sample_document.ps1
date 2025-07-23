# Copy Pre-existing Sample Document for Policing Assistant Search
# This script copies a pre-uploaded sample document from the deployment storage to the data storage

param(
    [Parameter(Mandatory = $true)]
    [string]$storageAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$storageAccountKey,
    
    [Parameter(Mandatory = $true)]
    [string]$containerName
)

Write-Output "=== Copying Sample Document ==="
Write-Output "Target Storage Account: $storageAccountName"
Write-Output "Target Container: $containerName"
Write-Output ""

try {
    # Source details (where the sample document is pre-uploaded)
    $sourceStorageAccount = "stbtpukssandopenai"
    $sourceContainer = "policing-assistant-azure-deployment-template"
    $sourceBlobName = "sample-police-procedures.txt"
    $targetBlobName = "sample-police-procedures.txt"
    
    # Public URL of the pre-uploaded sample document
    $sourceUrl = "https://$sourceStorageAccount.blob.core.windows.net/$sourceContainer/$sourceBlobName"
    
    Write-Output "Source URL: $sourceUrl"
    Write-Output "Target Blob: $targetBlobName"
    Write-Output ""
    
    # Create storage context for target
    Write-Output "Connecting to target storage account..."
    $targetCtx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    
    # Copy blob from source to target using Start-AzStorageBlobCopy
    Write-Output "Copying sample document..."
    $copyJob = Start-AzStorageBlobCopy -SrcUri $sourceUrl -DestContainer $containerName -DestBlob $targetBlobName -DestContext $targetCtx -Force
    
    Write-Output "Copy operation initiated. Blob copy ID: $($copyJob.CopyId)"
    
    # Wait for copy to complete (with timeout)
    $timeout = 30 # seconds
    $elapsed = 0
    do {
        Start-Sleep -Seconds 2
        $elapsed += 2
        $blob = Get-AzStorageBlob -Container $containerName -Blob $targetBlobName -Context $targetCtx -ErrorAction SilentlyContinue
        if ($blob -and $blob.ICloudBlob.CopyState.Status -eq "Success") {
            break
        }
    } while ($elapsed -lt $timeout)
    
    # Verify the copy
    $blob = Get-AzStorageBlob -Container $containerName -Blob $targetBlobName -Context $targetCtx -ErrorAction SilentlyContinue
    
    if ($blob) {
        Write-Output "✅ Sample document copied successfully!"
        Write-Output "Blob name: $targetBlobName"
        Write-Output "Blob size: $($blob.Length) bytes"
        Write-Output "Blob URL: $($blob.ICloudBlob.StorageUri.PrimaryUri)"
        
        # Check copy status
        if ($blob.ICloudBlob.CopyState.Status -eq "Success") {
            Write-Output "✅ Copy status: Success"
        } else {
            Write-Output "⚠️ Copy status: $($blob.ICloudBlob.CopyState.Status)"
        }
    } else {
        Write-Output "⚠️ Could not verify the copied blob"
    }
    
    Write-Output ""
    Write-Output "🎉 Sample document setup completed successfully!"
    
}
catch {
    Write-Output "❌ Error copying sample document: $($_.Exception.Message)"
    Write-Output "Full error details:"
    Write-Output "Exception Type: $($_.Exception.GetType().FullName)"
    
    # Don't fail the entire deployment for sample document issues
    Write-Output ""
    Write-Output "Sample document copy failed, but this is not critical for the main deployment."
    Write-Output "You can upload documents manually to the storage container after deployment."
    Write-Output "Make sure the source document exists at: https://$sourceStorageAccount.blob.core.windows.net/$sourceContainer/$sourceBlobName"
}

Write-Output "Sample document script completed."
