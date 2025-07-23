# Create Sample Document for Policing Assistant Search (REST API Version)
# This script uploads a sample police procedures document using Azure REST API

param(
    [Parameter(Mandatory = $true)]
    [string]$storageAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$storageAccountKey,
    
    [Parameter(Mandatory = $true)]
    [string]$containerName
)

Write-Output "=== Creating Sample Document (REST API Method) ==="
Write-Output "Storage Account: $storageAccountName"
Write-Output "Container: $containerName"
Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Output ""

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

    Write-Output "Preparing blob upload using REST API..."
    
    # Convert content to bytes
    $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($sampleContent)
    
    # Blob details
    $blobName = "sample-police-procedures.txt"
    $contentType = "text/plain"
    
    # Generate authorization header
    $date = [DateTime]::UtcNow.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture)
    $contentLength = $contentBytes.Length
    
    # Create signature for authorization
    $stringToSign = "PUT`n`n`n$contentLength`n`n$contentType`n`n`n`n`n`n`nx-ms-blob-type:BlockBlob`nx-ms-date:$date`nx-ms-version:2020-04-08`n/$storageAccountName/$containerName/$blobName"
    
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.Key = [Convert]::FromBase64String($storageAccountKey)
    $signature = [Convert]::ToBase64String($hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign)))
    $authorization = "SharedKey $storageAccountName`:$signature"
    
    # Create headers
    $headers = @{
        'x-ms-date' = $date
        'x-ms-version' = '2020-04-08'
        'x-ms-blob-type' = 'BlockBlob'
        'Content-Type' = $contentType
        'Content-Length' = $contentLength
        'Authorization' = $authorization
    }
    
    # Blob URL
    $blobUrl = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName"
    
    Write-Output "Uploading to: $blobUrl"
    Write-Output "Content length: $contentLength bytes"
    
    # Upload blob using REST API
    $response = Invoke-RestMethod -Uri $blobUrl -Method PUT -Headers $headers -Body $contentBytes -Verbose
    
    Write-Output "✅ Sample document created successfully!"
    Write-Output "Blob name: $blobName"
    Write-Output "Blob URL: $blobUrl"
    Write-Output ""
    
    # Verify the upload by getting blob properties
    Write-Output "Verifying upload..."
    $verifyHeaders = @{
        'x-ms-date' = [DateTime]::UtcNow.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture)
        'x-ms-version' = '2020-04-08'
        'Authorization' = $authorization
    }
    
    try {
        $verifyResponse = Invoke-RestMethod -Uri $blobUrl -Method HEAD -Headers $verifyHeaders
        Write-Output "✅ Verification successful - Blob exists"
    }
    catch {
        Write-Output "⚠️ Verification failed, but upload may have succeeded: $($_.Exception.Message)"
    }
    
    Write-Output ""
    Write-Output "🎉 Sample document setup completed successfully!"
    
}
catch {
    Write-Output "❌ Error creating sample document: $($_.Exception.Message)"
    Write-Output "Full error details:"
    Write-Output "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Output "Stack trace: $($_.ScriptStackTrace)"
    
    # Don't fail the entire deployment for sample document issues
    Write-Output ""
    Write-Output "Sample document creation failed, but this is not critical for the main deployment."
    Write-Output "You can upload documents manually to the storage container after deployment."
}

Write-Output "Sample document script completed."
