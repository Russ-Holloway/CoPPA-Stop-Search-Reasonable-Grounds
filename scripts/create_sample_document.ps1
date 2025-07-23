# Create Sample Document for Policing Assistant Search
# This script uploads a sample police procedures document to the storage container

param(
    [Parameter(Mandatory = $true)]
    [string]$storageAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$storageAccountKey,
    
    [Parameter(Mandatory = $true)]
    [string]$containerName
)

Write-Output "=== Creating Sample Document ==="
Write-Output "Storage Account: $storageAccountName"
Write-Output "Container: $containerName"
Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Output ""

# Check if Az.Storage module is available
Write-Output "Checking Azure PowerShell modules..."
try {
    Import-Module Az.Storage -Force
    Write-Output "✅ Az.Storage module imported successfully"
}
catch {
    Write-Output "⚠️ Az.Storage module import failed: $($_.Exception.Message)"
    Write-Output "Attempting to use built-in Azure PowerShell..."
}

try {
    # Create sample content
    $sampleContent = @"
# Police Investigation Procedures

## General Guidelines
- Follow all departmental protocols
- Document all evidence thoroughly
- Maintain chain of custody
- Interview witnesses promptly
- Collaborate with other agencies when appropriate

### Emergency Response
- Assess scene safety first
- Request backup when needed
- Provide medical aid if qualified
- Secure the scene

### Investigation Best Practices
- Preserve crime scene integrity
- Collect and catalog evidence systematically
- Interview witnesses separately
- Maintain detailed case notes
- Follow proper evidence chain of custody
- Coordinate with forensic teams when necessary

### Community Policing
- Build positive relationships with community members
- Engage in proactive problem-solving
- Participate in community outreach programs
- Maintain professional demeanor at all times

### Report Writing
- Use clear, concise language
- Include all relevant facts
- Maintain objectivity
- Follow department formatting standards
- Submit reports in a timely manner

This document serves as a sample for the Policing Assistant search functionality.
"@

    Write-Output "Creating temporary file with sample content..."
    
    # Create temporary file with specific path
    $tempDir = [System.IO.Path]::GetTempPath()
    $tempFile = Join-Path $tempDir "sample-police-procedures-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    
    # Write content to file using Set-Content
    Set-Content -Path $tempFile -Value $sampleContent -Encoding UTF8
    
    Write-Output "Temporary file created at: $tempFile"
    Write-Output "File size: $((Get-Item $tempFile).Length) bytes"
    
    Write-Output "Connecting to storage account..."
    
    # Create storage context
    $ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    
    Write-Output "Uploading sample document to container..."
    
    # Upload the file to blob storage using -File parameter
    $blob = Set-AzStorageBlobContent -File $tempFile -Container $containerName -Blob 'sample-police-procedures.txt' -Context $ctx -Force -Verbose
    
    Write-Output "Cleaning up temporary file..."
    
    # Clean up temporary file
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
    }
    
    Write-Output "✅ Sample document created successfully!"
    Write-Output "Blob name: sample-police-procedures.txt"
    Write-Output "Blob URI: $($blob.ICloudBlob.StorageUri.PrimaryUri)"
    Write-Output ""
    
    # Verify the upload
    Write-Output "Verifying upload..."
    $uploadedBlob = Get-AzStorageBlob -Container $containerName -Blob 'sample-police-procedures.txt' -Context $ctx
    Write-Output "✅ Verification successful - Blob size: $($uploadedBlob.Length) bytes"
    
    Write-Output ""
    Write-Output "🎉 Sample document setup completed successfully!"
    
}
catch {
    Write-Output "❌ Error creating sample document: $($_.Exception.Message)"
    Write-Output "Full error details:"
    Write-Output "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Output "Stack trace: $($_.ScriptStackTrace)"
    
    # Specific check for Content parameter error
    if ($_.Exception.Message -like "*parameter name 'Content'*") {
        Write-Output ""
        Write-Output "⚠️ DETECTED: Parameter binding error with 'Content'"
        Write-Output "This usually indicates an issue with the Set-AzStorageBlobContent cmdlet"
        Write-Output "or a conflict with PowerShell parameters."
    }
    
    # Clean up temp file if it exists
    if ($tempFile -and (Test-Path $tempFile)) {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
    
    # Don't fail the entire deployment for sample document issues
    Write-Output ""
    Write-Output "Sample document creation failed, but this is not critical for the main deployment."
    Write-Output "You can upload documents manually to the storage container after deployment."
}

Write-Output "Sample document script completed."
