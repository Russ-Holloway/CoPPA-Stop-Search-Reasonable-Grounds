param(
    [Parameter(Mandatory = $true)]
    [string]$resourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$storageAccountName,
    
    [Parameter(Mandatory = $false)]
    [string]$containerName = "templates"
)

# Check if Azure PowerShell is installed, install if missing
if (-not (Get-Module -ListAvailable -Name Az)) {
    Write-Host "Azure PowerShell module not found. Installing..."
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
}

# Check if logged in to Azure
try {
    $context = Get-AzContext -ErrorAction Stop
    if (-not $context) { throw }
} catch {
    Write-Host "Not logged in to Azure. Please login..."
    Connect-AzAccount
}

# Add System.Web assembly for URL encoding
Add-Type -AssemblyName System.Web

# Function to validate JSON files
function Test-JsonValid {
    param(
        [string]$FilePath,
        [string]$FileDescription
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw
        $null = ConvertFrom-Json -InputObject $content
        Write-Host "$FileDescription is valid JSON." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "$FileDescription is NOT valid JSON. Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Get storage account context
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction SilentlyContinue
if (-not $storageAccount) {
    Write-Error "Storage account '$storageAccountName' not found in resource group '$resourceGroupName'. Please check the account name and resource group."
    exit 1
}
$ctx = $storageAccount.Context

# Verify the container exists and has proper permissions
$container = Get-AzStorageContainer -Name $containerName -Context $ctx -ErrorAction SilentlyContinue
if (!$container) {
    Write-Host "Container '$containerName' not found. Creating new container with Blob access."
    New-AzStorageContainer -Name $containerName -Context $ctx -Permission Blob
}
else {
    # Ensure container has Blob (public) access
    if ($container.PublicAccess -ne "Blob") {
        Write-Host "Setting container access policy to 'Blob' (public read access for blobs)"
        Set-AzStorageContainerAcl -Name $containerName -Context $ctx -Permission Blob
        
        # Double-check the permission was set correctly
        $container = Get-AzStorageContainer -Name $containerName -Context $ctx
        if ($container.PublicAccess -ne "Blob") {
            Write-Warning "Failed to set container access policy to 'Blob'. This may cause deployment issues."
            Write-Host "Please manually set the container access level to 'Blob' in the Azure Portal."
        }
        else {
            Write-Host "Container access policy successfully set to 'Blob'."
        }
    }
    else {
        Write-Host "Container '$containerName' already exists with proper Blob access."
    }
}

# Verify CORS is set properly for Azure Portal
Write-Host "Configuring CORS settings for Azure Portal deployment..."
$corsRules = @(
    @{
        AllowedOrigins = @("https://portal.azure.com", "https://ms.portal.azure.com", "https://*.portal.azure.com", 
                          "https://portal.azure.us", "https://*.portal.azure.us", 
                          "https://portal.azure.cn", "https://*.portal.azure.cn");
        AllowedMethods = @("GET", "HEAD", "OPTIONS", "PUT", "POST");
        AllowedHeaders = @("*");
        ExposedHeaders = @("*");
        MaxAgeInSeconds = 3600;
    },
    @{
        AllowedOrigins = @("https://afd.hosting.portal.azure.net", "https://afd.hosting-ms.portal.azure.com", 
                          "https://*.afd.hosting.portal.azure.net", "https://management.azure.com");
        AllowedMethods = @("GET", "HEAD", "OPTIONS", "PUT", "POST");
        AllowedHeaders = @("*");
        ExposedHeaders = @("*");
        MaxAgeInSeconds = 3600;
    },
    @{
        AllowedOrigins = @("*");
        AllowedMethods = @("GET", "HEAD", "OPTIONS");
        AllowedHeaders = @("*");
        ExposedHeaders = @("*");
        MaxAgeInSeconds = 3600;
    }
)
Set-AzStorageCORSRule -ServiceType Blob -CorsRules $corsRules -Context $ctx

# Path to createUiDefinition-pds.json file
$createUiDefinitionJsonPath = Join-Path (Get-Location).Path "infrastructure/createUiDefinition-pds.json"
$deploymentJsonPath = Join-Path (Get-Location).Path "infrastructure/deployment.json"

# Validate JSON files before uploading
$createUiDefinitionValid = Test-JsonValid -FilePath $createUiDefinitionJsonPath -FileDescription "createUiDefinition-pds.json"
$deploymentJsonValid = Test-JsonValid -FilePath $deploymentJsonPath -FileDescription "deployment.json"

if (-not ($createUiDefinitionValid -and $deploymentJsonValid)) {
    Write-Warning "JSON validation failed for one or more files. The deployment may not work correctly."
    $continue = Read-Host "Do you want to continue anyway? (Y/N)"
    if ($continue -ne "Y" -and $continue -ne "y") {
        Write-Host "Operation cancelled by user. Please fix the JSON files and try again."
        exit
    }
}

# Function to test CORS for a blob
function Test-BlobCORS {
    param (
        [string]$BlobName,
        [string]$Origin = "https://portal.azure.com"
    )
    
    $testUrl = $ctx.BlobEndPoint + "$containerName/$BlobName"
    Write-Host "Testing CORS for: $testUrl from origin: $Origin"
    
    # Create a temporary HTML file to test CORS
    $tempHtmlPath = [System.IO.Path]::GetTempFileName() + ".html"
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>CORS Test for $BlobName</title>
    <script>
        function testCORS() {
            const url = '$testUrl';
            // Simulate a request from Azure Portal
            fetch(url, {
                method: 'GET',
                headers: {
                    'Origin': '$Origin'
                }
            })
            .then(response => {
                document.getElementById('response-headers').textContent = 
                    JSON.stringify(Array.from(response.headers.entries()).reduce((obj, [key, value]) => {
                        obj[key] = value;
                        return obj;
                    }, {}), null, 2);
                
                if (response.ok) {
                    document.getElementById('result').innerHTML = 
                        '<span style="color:green">SUCCESS: CORS is properly configured for $BlobName</span>';
                    return response.text();
                }
                throw new Error('Network response was not ok.');
            })
            .then(data => {
                const previewLength = Math.min(data.length, 300);
                document.getElementById('content-preview').textContent = 
                    data.substring(0, previewLength) + (data.length > previewLength ? '...' : '');
            })
            .catch(error => {
                document.getElementById('result').innerHTML = 
                    '<span style="color:red">ERROR: CORS is not properly configured. ' + error.message + '</span>';
            });
        }
    </script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .container { margin-bottom: 20px; }
        pre { background-color: #f5f5f5; padding: 10px; border-radius: 5px; overflow-x: auto; }
        .success { color: green; }
        .error { color: red; }
    </style>
</head>
<body onload="testCORS()">
    <h1>Advanced CORS Test for $BlobName</h1>
    <div class="container">
        <p><strong>URL being tested:</strong> <code>$testUrl</code></p>
        <p><strong>Simulated Origin:</strong> <code>$Origin</code></p>
    </div>
    
    <div class="container">
        <h2>Test Result:</h2>
        <div id="result">Testing...</div>
    </div>
    
    <div class="container">
        <h2>Response Headers:</h2>
        <pre id="response-headers">Waiting for response...</pre>
    </div>
    
    <div class="container">
        <h2>Content Preview:</h2>
        <pre id="content-preview">Waiting for content...</pre>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $tempHtmlPath -Encoding utf8
    Write-Host "Opening CORS test page in your browser for $BlobName..."
    Start-Process $tempHtmlPath
}

# Upload createUiDefinition-pds.json to the container
Write-Host "Uploading createUiDefinition-pds.json to the container"
Set-AzStorageBlobContent -File $createUiDefinitionJsonPath `
    -Container $containerName `
    -Blob "createUiDefinition-pds.json" `
    -Context $ctx `
    -Properties @{"ContentType" = "application/json"} `
    -Force

# Verify content type was set correctly
$blob = Get-AzStorageBlob -Container $containerName -Blob "createUiDefinition-pds.json" -Context $ctx
if ($blob.Properties.ContentType -ne "application/json") {
    Write-Host "Setting content type for createUiDefinition-pds.json to application/json"
    $blob.ICloudBlob.Properties.ContentType = "application/json"
    $blob.ICloudBlob.SetProperties()
}

# Check if deployment.json exists in the container
$deploymentBlob = Get-AzStorageBlob -Container $containerName -Blob "deployment.json" -Context $ctx -ErrorAction SilentlyContinue
if (!$deploymentBlob) {
    Write-Host "deployment.json not found in container. Uploading..."
    $deploymentJsonPath = Join-Path (Get-Location).Path "infrastructure/deployment.json"
    Set-AzStorageBlobContent -File $deploymentJsonPath `
        -Container $containerName `
        -Blob "deployment.json" `
        -Context $ctx `
        -Properties @{"ContentType" = "application/json"} `
        -Force
}

# Verify content type was set correctly for deployment.json
$blob = Get-AzStorageBlob -Container $containerName -Blob "deployment.json" -Context $ctx
if ($blob.Properties.ContentType -ne "application/json") {
    Write-Host "Setting content type for deployment.json to application/json"
    $blob.ICloudBlob.Properties.ContentType = "application/json"
    $blob.ICloudBlob.SetProperties()
}

# Function to generate a comprehensive HTML report
function Generate-DeploymentReport {
    param (
        [string]$OutputPath = "$env:TEMP\deployment_report.html",
        [hashtable]$TestResults
    )

    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $storageUrl = $ctx.BlobEndPoint + $containerName
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure Deployment Configuration Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #0078d4;
        }
        .report-header {
            border-bottom: 2px solid #0078d4;
            padding-bottom: 10px;
            margin-bottom: 30px;
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            background-color: #f9f9f9;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .config-item {
            margin-bottom: 15px;
        }
        .config-title {
            font-weight: bold;
        }
        .config-value {
            font-family: Consolas, monospace;
            background-color: #f0f0f0;
            padding: 5px;
            border-radius: 3px;
            display: block;
            overflow-x: auto;
            margin-top: 5px;
        }
        .success {
            color: #107c10;
        }
        .warning {
            color: #ff8c00;
        }
        .error {
            color: #d13438;
        }
        .status-icon {
            font-weight: bold;
            margin-right: 5px;
        }
        .check-list {
            list-style-type: none;
            padding-left: 10px;
        }
        .check-list li {
            margin-bottom: 10px;
            padding-left: 25px;
            position: relative;
        }
        .check-list li:before {
            content: '✓';
            position: absolute;
            left: 0;
            color: #107c10;
        }
        .check-list li.error:before {
            content: '✗';
            color: #d13438;
        }
        .check-list li.warning:before {
            content: '⚠';
            color: #ff8c00;
        }
        .troubleshooting {
            background-color: #e6f3ff;
        }
        code {
            background-color: #f0f0f0;
            padding: 2px 5px;
            border-radius: 3px;
            font-family: Consolas, monospace;
        }
        .deployment-url {
            padding: 15px;
            background-color: #dff6dd;
            border-left: 4px solid #107c10;
            margin: 20px 0;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <div class="report-header">
        <h1>Azure Deployment Configuration Report</h1>
        <p>Generated on: $reportDate</p>
    </div>

    <div class="section">
        <h2>Storage Account Configuration</h2>
        
        <div class="config-item">
            <div class="config-title">Resource Group:</div>
            <div class="config-value">$resourceGroupName</div>
        </div>
        
        <div class="config-item">
            <div class="config-title">Storage Account:</div>
            <div class="config-value">$storageAccountName</div>
        </div>
        
        <div class="config-item">
            <div class="config-title">Container:</div>
            <div class="config-value">$containerName</div>
        </div>
        
        <div class="config-item">
            <div class="config-title">Storage URL:</div>
            <div class="config-value">$storageUrl</div>
        </div>
    </div>

    <div class="section">
        <h2>Template Files</h2>
        
        <div class="config-item">
            <div class="config-title">Deployment Template:</div>
            <div class="config-value">$deploymentUrl</div>
        </div>
        
        <div class="config-item">
            <div class="config-title">UI Definition:</div>
            <div class="config-value">$createUiDefinitionUrl</div>
        </div>
    </div>

    <div class="section">
        <h2>CORS Configuration</h2>
        <p>The following origins are configured for CORS access:</p>
        <ul>
            <li><code>https://portal.azure.com</code></li>
            <li><code>https://ms.portal.azure.com</code></li>
            <li><code>https://*.portal.azure.com</code></li>
            <li><code>https://portal.azure.us</code></li>
            <li><code>https://*.portal.azure.us</code></li>
            <li><code>https://portal.azure.cn</code></li>
            <li><code>https://*.portal.azure.cn</code></li>
            <li><code>https://afd.hosting.portal.azure.net</code></li>
            <li><code>https://afd.hosting-ms.portal.azure.com</code></li>
            <li><code>https://*.afd.hosting.portal.azure.net</code></li>
            <li><code>https://management.azure.com</code></li>
            <li><code>*</code> (all origins)</li>
        </ul>
    </div>

    <div class="section troubleshooting">
        <h2>Troubleshooting Guide</h2>
        
        <h3>Common Issues and Solutions</h3>
        <ol>
            <li>
                <strong>CORS errors when deploying:</strong>
                <ul class="check-list">
                    <li>Verify CORS settings include Azure Portal domains</li>
                    <li>Check that blob container has public access level set to 'Blob'</li>
                    <li>Ensure JSON files have 'application/json' content type</li>
                    <li>Try clearing browser cache or using incognito mode</li>
                </ul>
            </li>
            
            <li>
                <strong>Template not loading:</strong>
                <ul class="check-list">
                    <li>Check direct access to template URLs in browser</li>
                    <li>Verify JSON syntax is valid</li>
                    <li>Ensure storage account firewall settings allow public access</li>
                </ul>
            </li>
            
            <li>
                <strong>Alternative deployment methods:</strong>
                <ul class="check-list">
                    <li>Azure CLI: <code>az deployment group create --resource-group &lt;group&gt; --template-uri $deploymentUrl</code></li>
                    <li>PowerShell: <code>New-AzResourceGroupDeployment -ResourceGroupName &lt;group&gt; -TemplateUri $deploymentUrl</code></li>
                    <li>Manual upload in Portal: Create a resource > Template deployment > Build your own template</li>
                </ul>
            </li>
        </ol>
        
        <h3>Testing Commands</h3>
        <p>PowerShell CORS test:</p>
        <div class="config-value">Invoke-WebRequest -Uri $deploymentUrl -Method OPTIONS -Headers @{'Origin'='https://portal.azure.com'; 'Access-Control-Request-Method'='GET'}</div>
        
        <p>cURL CORS test:</p>
        <div class="config-value">curl -I -X OPTIONS $deploymentUrl -H 'Origin: https://portal.azure.com' -H 'Access-Control-Request-Method: GET'</div>
    </div>

    <div class="deployment-url">
        <h2>Deployment URL</h2>
        <p>Use this URL for the "Deploy to Azure" button:</p>
        <div class="config-value">$portalUrl</div>
    </div>
    
    <div class="section">
        <h2>How to Run This Script Again</h2>
        <p>To rerun this configuration script, use:</p>
        <div class="config-value">.\scripts\setup_template_hosting.ps1 -resourceGroupName "$resourceGroupName" -storageAccountName "$storageAccountName" -containerName "$containerName"</div>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding utf8
    
    Write-Host "Report generated at: $OutputPath" -ForegroundColor Green
    # Open the report in the default browser
    Start-Process $OutputPath
}

# Output template URLs
$deploymentUrl = $ctx.BlobEndPoint + "$containerName/deployment.json"
$createUiDefinitionUrl = $ctx.BlobEndPoint + "$containerName/createUiDefinition-pds.json"

# Output the Azure Portal deployment link
$encodedCreateUiDefinitionUrl = [System.Web.HttpUtility]::UrlEncode($createUiDefinitionUrl)
$encodedDeploymentUrl = [System.Web.HttpUtility]::UrlEncode($deploymentUrl)
$portalUrl = "https://portal.azure.com/#create/Microsoft.Template/uri/$encodedDeploymentUrl/createUIDefinitionUri/$encodedCreateUiDefinitionUrl"

Write-Host "-----------------------------------------------------------"
Write-Host "Azure Portal Deployment URL (Copy this for one-click deployment):"
Write-Host $portalUrl

# Test CORS for both files
Write-Host "-----------------------------------------------------------"
Write-Host "Would you like to test CORS configuration for the deployment files? (Y/N)"
$testCors = Read-Host
if ($testCors -eq "Y" -or $testCors -eq "y") {
    # Create a results collection for the report
    $corsTestResults = @{}
    
    # Test with multiple origins to be thorough
    Write-Host "Testing CORS with multiple origins that Azure Portal uses..."
    
    # Define all the origins we want to test
    $originsToTest = @(
        "https://portal.azure.com",
        "https://ms.portal.azure.com",
        "https://afd.hosting.portal.azure.net"
    )
    
    # Test primary Azure Portal domain first
    Test-BlobCORS -BlobName "deployment.json" -Origin $originsToTest[0]
    Start-Sleep -Seconds 2  # Add delay between browser openings
    Test-BlobCORS -BlobName "createUiDefinition-pds.json" -Origin $originsToTest[0]
    
    # Offer to test with additional origins
    Write-Host "Would you like to test with additional Azure Portal domains? (Y/N)"
    $additionalTests = Read-Host
    if ($additionalTests -eq "Y" -or $additionalTests -eq "y") {
        for ($i = 1; $i -lt $originsToTest.Count; $i++) {
            Start-Sleep -Seconds 2
            Test-BlobCORS -BlobName "deployment.json" -Origin $originsToTest[$i]
        }
    }
    
    # Direct PowerShell CORS check
    Write-Host "-----------------------------------------------------------"
    Write-Host "Performing direct CORS headers check with PowerShell..."
    
    $deploymentUrlToCurl = $ctx.BlobEndPoint + "$containerName/deployment.json"
    $createUiDefinitionUrlToCurl = $ctx.BlobEndPoint + "$containerName/createUiDefinition-pds.json"
    
    foreach ($origin in $originsToTest) {
        try {
            # Test with an OPTIONS request from a domain that would simulate Azure Portal
            $headers = @{
                "Origin" = $origin
                "Access-Control-Request-Method" = "GET"
                "Access-Control-Request-Headers" = "content-type"
            }
            
            Write-Host "Testing CORS with origin: $origin..." -NoNewline
            $response = Invoke-WebRequest -Uri $deploymentUrlToCurl -Method OPTIONS -Headers $headers -ErrorAction Stop
            
            if ($response.Headers.ContainsKey("Access-Control-Allow-Origin")) {
                $allowOrigin = $response.Headers["Access-Control-Allow-Origin"]
                $allowMethods = $response.Headers["Access-Control-Allow-Methods"]
                $allowHeaders = $response.Headers["Access-Control-Allow-Headers"]
                
                $corsTestResults[$origin] = @{
                    "Status" = "Success"
                    "AllowOrigin" = $allowOrigin
                    "AllowMethods" = $allowMethods
                    "AllowHeaders" = $allowHeaders
                }
                
                if ($allowOrigin -contains $origin -or $allowOrigin -contains "*") {
                    Write-Host "SUCCESS!" -ForegroundColor Green
                    Write-Host "  - Access-Control-Allow-Origin: $allowOrigin" -ForegroundColor Green
                    Write-Host "  - Access-Control-Allow-Methods: $allowMethods" -ForegroundColor Green
                    Write-Host "  - Access-Control-Allow-Headers: $allowHeaders" -ForegroundColor Green
                } else {
                    Write-Host "FAILED - Header exists but origin not allowed" -ForegroundColor Red
                    $corsTestResults[$origin]["Status"] = "Failed - Origin not allowed"
                }
            } else {
                Write-Host "FAILED - No Access-Control-Allow-Origin header" -ForegroundColor Red
                $corsTestResults[$origin] = @{
                    "Status" = "Failed - Missing CORS headers"
                }
            }
        } catch {
            Write-Host "FAILED with error: $($_.Exception.Message)" -ForegroundColor Red
            $corsTestResults[$origin] = @{
                "Status" = "Failed - Error: $($_.Exception.Message)"
            }
        }
    }
    
    # Verify the deployment URL is directly accessible
    try {
        Write-Host "-----------------------------------------------------------"
        Write-Host "Verifying direct template access..." -NoNewline
        $response = Invoke-WebRequest -Uri $deploymentUrl -Method GET -ErrorAction Stop
        Write-Host "SUCCESS! Templates are directly accessible." -ForegroundColor Green
    } catch {
        Write-Host "FAILED. Templates may not be publicly accessible: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "This could indicate container permissions issues or network restrictions." -ForegroundColor Yellow
    }
    
    Write-Host "-----------------------------------------------------------"
    Write-Host "CORS test summary:"
    foreach ($key in $corsTestResults.Keys) {
        $result = $corsTestResults[$key]
        if ($result.Status -like "Success*") {
            Write-Host "$key : $($result.Status)" -ForegroundColor Green
        } else {
            Write-Host "$key : $($result.Status)" -ForegroundColor Red
        }
    }
    
    Write-Host "-----------------------------------------------------------"
    Write-Host "CORS test pages have been opened in your browser."
    Write-Host "If you see green success messages, your deployment should work."
    Write-Host "If you see red error messages, there may still be CORS configuration issues."
}

# Provide additional troubleshooting help
Write-Host "-----------------------------------------------------------"
Write-Host "Troubleshooting Tips:" -ForegroundColor Cyan
Write-Host "1. If deployment still fails, ensure your GitHub repository is public"
Write-Host "2. Try accessing the template URLs directly in your browser to verify they load correctly:"
Write-Host "   - $deploymentUrl"
Write-Host "   - $createUiDefinitionUrl"
Write-Host "3. Verify container access policy is set to 'Blob' (anonymous read access for blobs only)"
Write-Host "4. Check that the files have the correct content type (application/json)"
Write-Host "5. Make sure CORS settings include all required Azure portal domains"
Write-Host "6. Try clearing your browser cache or using a private/incognito window"
Write-Host "7. The Azure Portal deployment page sometimes has issues with CORS. Try these alternatives:"
Write-Host "   a. Use a different browser"
Write-Host "   b. Use the Azure CLI to deploy directly: az deployment group create --resource-group <group> --template-uri $deploymentUrl"
Write-Host "   c. Use Azure PowerShell: New-AzResourceGroupDeployment -ResourceGroupName <group> -TemplateUri $deploymentUrl"
Write-Host "8. If issues persist, you can use the Azure Portal to manually create the deployment by:"
Write-Host "   a. Go to Portal > Create a resource > Template deployment"
Write-Host "   b. Click 'Build your own template in the editor'"
Write-Host "   c. Load the template JSON file manually by copying its contents"
Write-Host "9. To run a quick manual CORS test with PowerShell:"
Write-Host "   Invoke-WebRequest -Uri $deploymentUrl -Method OPTIONS -Headers @{'Origin'='https://portal.azure.com'; 'Access-Control-Request-Method'='GET'}"
Write-Host "10. To test with curl (if installed):"
Write-Host "    curl -I -X OPTIONS $deploymentUrl -H 'Origin: https://portal.azure.com' -H 'Access-Control-Request-Method: GET'"
Write-Host "11. Remember that CORS changes can take several minutes to propagate"
Write-Host "12. As a last resort, you can host the templates on a static hosting service with guaranteed CORS support"
Write-Host "-----------------------------------------------------------"
Write-Host "Your deployment URL is ready to use:" -ForegroundColor Green
Write-Host $portalUrl -ForegroundColor Green
Write-Host "-----------------------------------------------------------"
Write-Host "Need to troubleshoot later? Run the test script again with:"
Write-Host ".\scripts\setup_template_hosting.ps1 -resourceGroupName '$resourceGroupName' -storageAccountName '$storageAccountName' -containerName '$containerName'" -ForegroundColor Yellow

# Generate a comprehensive HTML report
Write-Host "-----------------------------------------------------------"
Write-Host "Would you like to generate a comprehensive HTML report for this deployment setup? (Y/N)"
$generateReport = Read-Host
if ($generateReport -eq "Y" -or $generateReport -eq "y") {
    $reportPath = "$env:USERPROFILE\Desktop\azure_deployment_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    Generate-DeploymentReport -OutputPath $reportPath
    Write-Host "Report generated and opened in your browser. A copy is saved to:"
    Write-Host $reportPath -ForegroundColor Green
    Write-Host "You can share this report with team members to help them understand the deployment setup."
}

# Generate the deployment report
Generate-DeploymentReport -OutputPath "$env:TEMP\Azure_Deployment_Report.html"
