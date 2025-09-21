# PowerShell script to create Azure AD App Registration using Azure CLI
# This script uses Azure CLI instead of Microsoft Graph PowerShell to avoid authentication issues in Azure DevOps

param(
    [Parameter(Mandatory=$true)]
    [string]$AppName,
    
    [Parameter(Mandatory=$true)]
    [string]$AppServiceUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory=$false)]
    [string]$TenantId = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "json"
)

# Set error handling
$ErrorActionPreference = "Stop"

Write-Host "Creating Azure AD App Registration using Azure CLI for CoPA Stop Search Application"
Write-Host "App Name: $AppName"
Write-Host "App Service URL: $AppServiceUrl" 
Write-Host "Environment: $EnvironmentName"

try {
    # Check if Azure CLI is logged in
    Write-Host "Checking Azure CLI authentication status..."
    $accountInfo = az account show --output json 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI is not authenticated. This script must run within an Azure PowerShell task."
    }
    
    $account = $accountInfo | ConvertFrom-Json
    Write-Host "Authenticated as: $($account.user.name) in tenant: $($account.tenantId)"

    $redirectUri = "$AppServiceUrl/.auth/login/aad/callback"
    $identifierUri = "api://$AppName-$EnvironmentName"
    
    Write-Host "Redirect URI: $redirectUri"
    Write-Host "Identifier URI: $identifierUri"

    # Check if app registration already exists
    Write-Host "Checking for existing app registration..."
    $existingAppJson = az ad app list --display-name "$AppName" --output json 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $existingAppJson) {
        $existingApps = $existingAppJson | ConvertFrom-Json
        if ($existingApps.Count -gt 0) {
            $existingApp = $existingApps[0]
            Write-Host "App registration already exists: $($existingApp.displayName) (ID: $($existingApp.appId))"
            
            # Update redirect URI if needed
            $webConfig = $existingApp.web
            if ($webConfig.redirectUris -notcontains $redirectUri) {
                Write-Host "Adding redirect URI to existing app registration..."
                $redirectUris = $webConfig.redirectUris + @($redirectUri)
                $redirectUrisJson = $redirectUris | ConvertTo-Json -Compress
                az ad app update --id $existingApp.appId --web-redirect-uris $redirectUrisJson
                Write-Host "Updated app registration with new redirect URI"
            }
            
            $appId = $existingApp.appId
            $objectId = $existingApp.id
        } else {
            $existingApp = $null
        }
    } else {
        $existingApp = $null
    }

    if (-not $existingApp) {
        Write-Host "Creating new app registration..."
        
        try {
            # Create a temporary JSON file for the required resource access
            $requiredResourceAccess = @(
                @{
                    resourceAppId = "00000003-0000-0000-c000-000000000000"
                    resourceAccess = @(
                        @{
                            id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
                            type = "Scope"
                        }
                    )
                }
            )
            
            $tempFile = [System.IO.Path]::GetTempFileName() + ".json"
            $requiredResourceAccess | ConvertTo-Json -Depth 5 | Out-File -FilePath $tempFile -Encoding UTF8
            
            # Create the app registration using Azure CLI
            $appJson = az ad app create `
                --display-name "$AppName" `
                --web-redirect-uris "$redirectUri" `
                --identifier-uris "$identifierUri" `
                --required-resource-accesses "@$tempFile" `
                --output json 2>&1

            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue

            if ($LASTEXITCODE -ne 0) {
                # Check if the error is due to insufficient privileges
                if ($appJson -like "*Insufficient privileges*" -or $appJson -like "*insufficient*privileges*") {
                    Write-Warning "=========================================================================="
                    Write-Warning "PERMISSION ISSUE: The service principal lacks permissions to create Azure AD app registrations."
                    Write-Warning ""
                    Write-Warning "REQUIRED PERMISSIONS:"
                    Write-Warning "The service principal used by Azure DevOps needs the following Microsoft Graph API permissions:"
                    Write-Warning "- Application.ReadWrite.All (Application permissions)"
                    Write-Warning "- Directory.Read.All (Application permissions)"
                    Write-Warning ""
                    Write-Warning "SOLUTION OPTIONS:"
                    Write-Warning "1. RECOMMENDED: Have an Azure AD administrator grant these permissions to the service principal"
                    Write-Warning "2. ALTERNATIVE: Create the app registration manually and provide the Client ID and Secret"
                    Write-Warning ""
                    Write-Warning "MANUAL APP REGISTRATION STEPS:"
                    Write-Warning "1. Go to Azure Portal > Azure Active Directory > App registrations"
                    Write-Warning "2. Click 'New registration'"
                    Write-Warning "3. Name: $AppName"
                    Write-Warning "4. Redirect URI: $redirectUri"
                    Write-Warning "5. Create a client secret"
                    Write-Warning "6. Set pipeline variables: AUTH_CLIENT_ID and AUTH_CLIENT_SECRET"
                    Write-Warning ""
                    Write-Warning "CONTINUING DEPLOYMENT WITHOUT APP REGISTRATION..."
                    Write-Warning "The infrastructure will be deployed but authentication will need to be configured manually."
                    Write-Warning "=========================================================================="
                    
                    # Set flag to indicate manual configuration is needed
                    Write-Host "##vso[task.setvariable variable=AppRegistration.ManualConfigRequired;isOutput=true]true"
                    Write-Host "##vso[task.setvariable variable=AppRegistration.RedirectUri;isOutput=true]$redirectUri"
                    Write-Host "##vso[task.setvariable variable=AppRegistration.AppName;isOutput=true]$AppName"
                    
                    # Return without error to allow deployment to continue
                    exit 0
                } else {
                    throw "Failed to create app registration: $appJson"
                }
            }

            $app = $appJson | ConvertFrom-Json
            $appId = $app.appId
            $objectId = $app.id
            Write-Host "Created app registration: $($app.displayName) (ID: $appId)"
            
        } catch {
            # Handle any other unexpected errors
            Write-Warning "Unexpected error during app registration creation: $($_.Exception.Message)"
            Write-Warning "Continuing deployment - manual app registration configuration will be required."
            
            # Set flag to indicate manual configuration is needed
            Write-Host "##vso[task.setvariable variable=AppRegistration.ManualConfigRequired;isOutput=true]true"
            Write-Host "##vso[task.setvariable variable=AppRegistration.RedirectUri;isOutput=true]$redirectUri"
            Write-Host "##vso[task.setvariable variable=AppRegistration.AppName;isOutput=true]$AppName"
            
            exit 0
        }
    } else {
        $appId = $existingApp.appId
        $objectId = $existingApp.id
    }

    # Check if we have an app registration to work with
    if (-not $appId) {
        Write-Warning "No app registration available (either existing or newly created)."
        Write-Warning "Skipping service principal and secret creation."
        Write-Warning "Manual app registration setup is required."
        exit 0
    }

    # Check for service principal
    Write-Host "Checking for service principal..."
    $spJson = az ad sp list --filter "appId eq '$appId'" --output json
    
    if ($LASTEXITCODE -eq 0 -and $spJson) {
        $servicePrincipals = $spJson | ConvertFrom-Json
        if ($servicePrincipals.Count -gt 0) {
            $servicePrincipal = $servicePrincipals[0]
            Write-Host "Service principal already exists: $($servicePrincipal.displayName) (ID: $($servicePrincipal.id))"
            $spObjectId = $servicePrincipal.id
        } else {
            $servicePrincipal = $null
        }
    } else {
        $servicePrincipal = $null
    }
    
    if (-not $servicePrincipal) {
        Write-Host "Creating service principal..."
        $spJson = az ad sp create --id $appId --output json 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            if ($spJson -like "*Insufficient privileges*" -or $spJson -like "*insufficient*privileges*") {
                Write-Warning "Insufficient privileges to create service principal. This may require manual creation."
                Write-Host "##vso[task.setvariable variable=AppRegistration.ServicePrincipalManualRequired;isOutput=true]true"
            } else {
                Write-Warning "Failed to create service principal: $spJson"
            }
            $spObjectId = ""
        } else {
            $servicePrincipal = $spJson | ConvertFrom-Json
            $spObjectId = $servicePrincipal.id
            Write-Host "Created service principal: $($servicePrincipal.displayName) (ID: $spObjectId)"
        }
    } else {
        $spObjectId = $servicePrincipal.id
    }

    # Create client secret
    Write-Host "Creating client secret..."
    $endDate = (Get-Date).AddYears(2).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $secretJson = az ad app credential reset --id $appId --display-name "$AppName-client-secret-$EnvironmentName" --end-date $endDate --output json 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        if ($secretJson -like "*Insufficient privileges*" -or $secretJson -like "*insufficient*privileges*") {
            Write-Warning "Insufficient privileges to create client secret. This will require manual creation."
            Write-Host "##vso[task.setvariable variable=AppRegistration.SecretManualRequired;isOutput=true]true"
            $clientSecret = ""
        } else {
            Write-Warning "Failed to create client secret: $secretJson"
            $clientSecret = ""
        }
    } else {
        $secret = $secretJson | ConvertFrom-Json
        $clientSecret = $secret.password
        Write-Host "Created client secret (expires: $endDate)"
    }
    
    # Get tenant info
    $tenantInfo = az account show --output json | ConvertFrom-Json
    $tenantId = $tenantInfo.tenantId

    # Construct issuer URI
    $issuerUri = "https://login.microsoftonline.com/$tenantId/v2.0"

    # Prepare output - handle cases where some values might not be available
    $output = @{
        ApplicationId = if ($appId) { $appId } else { "" }
        ClientId = if ($appId) { $appId } else { "" }
        TenantId = $tenantId
        ServicePrincipalId = if ($spObjectId) { $spObjectId } else { "" }
        ClientSecret = if ($clientSecret) { $clientSecret } else { "" }
        IssuerUri = $issuerUri
        RedirectUri = $redirectUri
        IdentifierUri = $identifierUri
        DisplayName = $AppName
        SecretExpiry = if ($endDate) { $endDate } else { "" }
        ManualConfigRequired = if (-not $appId -or -not $clientSecret) { $true } else { $false }
    }

    if ($OutputFormat -eq "json") {
        Write-Host "App Registration Details (JSON):"
        $jsonOutput = $output | ConvertTo-Json -Depth 3
        Write-Host $jsonOutput
        
        # Output as pipeline variables - only set if we have values
        if ($output.ApplicationId) {
            Write-Host "##vso[task.setvariable variable=AppRegistration.ApplicationId;isOutput=true]$($output.ApplicationId)"
            Write-Host "##vso[task.setvariable variable=AppRegistration.ClientId;isOutput=true]$($output.ClientId)"
        }
        Write-Host "##vso[task.setvariable variable=AppRegistration.TenantId;isOutput=true]$($output.TenantId)"
        Write-Host "##vso[task.setvariable variable=AppRegistration.IssuerUri;isOutput=true]$($output.IssuerUri)"
        if ($output.ClientSecret) {
            Write-Host "##vso[task.setvariable variable=AppRegistration.ClientSecret;issecret=true;isOutput=true]$($output.ClientSecret)"
        }
        Write-Host "##vso[task.setvariable variable=AppRegistration.ManualConfigRequired;isOutput=true]$($output.ManualConfigRequired)"
    } else {
        Write-Host "App Registration Details:"
        if ($output.ApplicationId) {
            Write-Host "Application ID: $($output.ApplicationId)"
            Write-Host "Client ID: $($output.ClientId)"
        } else {
            Write-Host "Application ID: [MANUAL CREATION REQUIRED]"
            Write-Host "Client ID: [MANUAL CREATION REQUIRED]"
        }
        Write-Host "Tenant ID: $($output.TenantId)"
        if ($output.ServicePrincipalId) {
            Write-Host "Service Principal ID: $($output.ServicePrincipalId)"
        }
        Write-Host "Issuer URI: $($output.IssuerUri)"
        Write-Host "Redirect URI: $($output.RedirectUri)"
        Write-Host "Identifier URI: $($output.IdentifierUri)"
        Write-Host "Display Name: $($output.DisplayName)"
        if ($output.SecretExpiry) {
            Write-Host "Secret Expiry: $($output.SecretExpiry)"
        }
        if ($output.ClientSecret) {
            Write-Host "Client Secret: [MASKED - Available in pipeline variables]"
        } else {
            Write-Host "Client Secret: [MANUAL CREATION REQUIRED]"
        }
        Write-Host "Manual Configuration Required: $($output.ManualConfigRequired)"
    }

    if ($output.ManualConfigRequired) {
        Write-Host "WARNING: App registration setup incomplete due to insufficient permissions."
        Write-Host "Please review the warnings above for manual setup instructions."
        Write-Host "SUCCESS: Script completed - manual configuration required for authentication."
    } else {
        Write-Host "SUCCESS: Azure AD App Registration created/updated successfully using Azure CLI"
    }
    exit 0

} catch {
    Write-Error "FAILED: Error creating app registration with Azure CLI: $($_.Exception.Message)"
    Write-Error $_.Exception.ToString()
    exit 1
}

# Security note: The client secret is output as a secure pipeline variable
# and should be stored securely in Key Vault or Azure DevOps variable groups