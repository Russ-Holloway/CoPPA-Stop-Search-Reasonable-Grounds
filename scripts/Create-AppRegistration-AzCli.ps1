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
            --output json

        # Clean up temp file
        Remove-Item $tempFile -ErrorAction SilentlyContinue

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create app registration"
        }

        $app = $appJson | ConvertFrom-Json
        $appId = $app.appId
        $objectId = $app.id
        Write-Host "Created app registration: $($app.displayName) (ID: $appId)"
    } else {
        $appId = $existingApp.appId
        $objectId = $existingApp.id
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
        $spJson = az ad sp create --id $appId --output json
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create service principal"
        }
        
        $servicePrincipal = $spJson | ConvertFrom-Json
        $spObjectId = $servicePrincipal.id
        Write-Host "Created service principal: $($servicePrincipal.displayName) (ID: $spObjectId)"
    } else {
        $spObjectId = $servicePrincipal.id
    }

    # Create client secret
    Write-Host "Creating client secret..."
    $endDate = (Get-Date).AddYears(2).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $secretJson = az ad app credential reset --id $appId --display-name "$AppName-client-secret-$EnvironmentName" --end-date $endDate --output json
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create client secret"
    }
    
    $secret = $secretJson | ConvertFrom-Json
    Write-Host "Created client secret (expires: $endDate)"
    
    # Get tenant info
    $tenantInfo = az account show --output json | ConvertFrom-Json
    $tenantId = $tenantInfo.tenantId

    # Construct issuer URI
    $issuerUri = "https://login.microsoftonline.com/$tenantId/v2.0"

    # Prepare output
    $output = @{
        ApplicationId = $appId
        ClientId = $appId
        TenantId = $tenantId
        ServicePrincipalId = $spObjectId
        ClientSecret = $secret.password
        IssuerUri = $issuerUri
        RedirectUri = $redirectUri
        IdentifierUri = $identifierUri
        DisplayName = $AppName
        SecretExpiry = $endDate
    }

    if ($OutputFormat -eq "json") {
        Write-Host "App Registration Details (JSON):"
        $jsonOutput = $output | ConvertTo-Json -Depth 3
        Write-Host $jsonOutput
        
        # Also output as pipeline variables
        Write-Host "##vso[task.setvariable variable=AppRegistration.ApplicationId;isOutput=true]$($output.ApplicationId)"
        Write-Host "##vso[task.setvariable variable=AppRegistration.ClientId;isOutput=true]$($output.ClientId)"
        Write-Host "##vso[task.setvariable variable=AppRegistration.TenantId;isOutput=true]$($output.TenantId)"
        Write-Host "##vso[task.setvariable variable=AppRegistration.IssuerUri;isOutput=true]$($output.IssuerUri)"
        Write-Host "##vso[task.setvariable variable=AppRegistration.ClientSecret;issecret=true;isOutput=true]$($output.ClientSecret)"
    } else {
        Write-Host "App Registration Details:"
        Write-Host "Application ID: $($output.ApplicationId)"
        Write-Host "Client ID: $($output.ClientId)"
        Write-Host "Tenant ID: $($output.TenantId)"
        Write-Host "Service Principal ID: $($output.ServicePrincipalId)"
        Write-Host "Issuer URI: $($output.IssuerUri)"
        Write-Host "Redirect URI: $($output.RedirectUri)"
        Write-Host "Identifier URI: $($output.IdentifierUri)"
        Write-Host "Display Name: $($output.DisplayName)"
        Write-Host "Secret Expiry: $($output.SecretExpiry)"
        Write-Host "Client Secret: [MASKED - Available in pipeline variables]"
    }

    Write-Host "SUCCESS: Azure AD App Registration created/updated successfully using Azure CLI"
    exit 0

} catch {
    Write-Error "FAILED: Error creating app registration with Azure CLI: $($_.Exception.Message)"
    Write-Error $_.Exception.ToString()
    exit 1
}

# Security note: The client secret is output as a secure pipeline variable
# and should be stored securely in Key Vault or Azure DevOps variable groups