# PowerShell script to create Azure AD App Registration for CoPA Stop Search
# This script can be run from Azure DevOps Pipeline with appropriate permissions

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

Write-Host "Creating Azure AD App Registration for CoPA Stop Search Application"
Write-Host "App Name: $AppName"
Write-Host "App Service URL: $AppServiceUrl" 
Write-Host "Environment: $EnvironmentName"

try {
    # Install required modules if not already installed
    Write-Host "Checking for Microsoft Graph PowerShell modules..."
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Applications)) {
        Write-Host "Installing Microsoft.Graph.Applications module..."
        Install-Module -Name Microsoft.Graph.Applications -Force -Scope CurrentUser -AllowClobber
    } else {
        Write-Host "Microsoft.Graph.Applications module is already installed"
    }
    
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Host "Installing Microsoft.Graph.Authentication module..."
        Install-Module -Name Microsoft.Graph.Authentication -Force -Scope CurrentUser -AllowClobber
    } else {
        Write-Host "Microsoft.Graph.Authentication module is already installed"
    }
    
    # Import modules
    Write-Host "Importing Microsoft Graph PowerShell modules..."
    Import-Module Microsoft.Graph.Authentication -Force
    Import-Module Microsoft.Graph.Applications -Force
    # Check if we're already connected to Microsoft Graph
    $context = Get-MgContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-Host "Connecting to Microsoft Graph using Azure PowerShell service principal..."
        
        # Get the current Azure PowerShell context
        $azContext = Get-AzContext
        if (-not $azContext) {
            throw "No Azure PowerShell context found. This script must run within an Azure PowerShell task."
        }
        
        Write-Host "Azure context: Account=$($azContext.Account.Id), Tenant=$($azContext.Tenant.Id)"
        
        # Connect to Microsoft Graph using the same service principal credentials
        # The Azure PowerShell task provides the authentication context
        try {
            # Try connecting with the tenant ID from Azure context
            Connect-MgGraph -TenantId $azContext.Tenant.Id -NoWelcome
            $context = Get-MgContext
            Write-Host "Connected to Microsoft Graph in tenant: $($context.TenantId)"
        } catch {
            Write-Host "Failed to connect with tenant-only method, trying alternative approach..."
            
            # Alternative: Use device code or interactive if available (fallback)
            # This should not be needed in Azure DevOps but provides a fallback
            Write-Host "Attempting to connect using service principal identity inheritance..."
            Connect-MgGraph -Identity -NoWelcome
            $context = Get-MgContext
            Write-Host "Connected to Microsoft Graph using identity: $($context.TenantId)"
        }
    } else {
        Write-Host "Already connected to Microsoft Graph in tenant: $($context.TenantId)"
    }

    $redirectUri = "$AppServiceUrl/.auth/login/aad/callback"
    $identifierUri = "api://$AppName-$EnvironmentName"
    
    Write-Host "Redirect URI: $redirectUri"
    Write-Host "Identifier URI: $identifierUri"

    # Check if app registration already exists
    Write-Host "Checking for existing app registration..."
    $existingApp = Get-MgApplication -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue

    if ($existingApp) {
        Write-Host "App registration already exists: $($existingApp.DisplayName) (ID: $($existingApp.AppId))"
        $appRegistration = $existingApp
        
        # Update redirect URI if needed
        $webApp = $existingApp.Web
        if ($webApp.RedirectUris -notcontains $redirectUri) {
            Write-Host "Adding redirect URI to existing app registration..."
            $webApp.RedirectUris += $redirectUri
            Update-MgApplication -ApplicationId $existingApp.Id -Web $webApp
            Write-Host "Updated app registration with new redirect URI"
        }
    } else {
        Write-Host "Creating new app registration..."
        
        # Define required resource access for Microsoft Graph
        $requiredResourceAccess = @(
            @{
                ResourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
                ResourceAccess = @(
                    @{
                        Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
                        Type = "Scope"
                    }
                )
            }
        )

        # Create app registration parameters
        $appParams = @{
            DisplayName = $AppName
            Description = "Azure AD App Registration for $AppName - Environment: $EnvironmentName"
            SignInAudience = "AzureADMyOrg"
            Web = @{
                RedirectUris = @($redirectUri)
                ImplicitGrantSettings = @{
                    EnableIdTokenIssuance = $true
                    EnableAccessTokenIssuance = $false
                }
            }
            Api = @{
                AcceptMappedClaims = $true
                RequestedAccessTokenVersion = 2
            }
            RequiredResourceAccess = $requiredResourceAccess
            IdentifierUris = @($identifierUri)
        }

        $appRegistration = New-MgApplication -BodyParameter $appParams
        Write-Host "Created app registration: $($appRegistration.DisplayName) (ID: $($appRegistration.AppId))"
    }

    # Check for service principal
    Write-Host "Checking for service principal..."
    $servicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$($appRegistration.AppId)'" -ErrorAction SilentlyContinue
    
    if (-not $servicePrincipal) {
        Write-Host "Creating service principal..."
        $spParams = @{
            AppId = $appRegistration.AppId
            DisplayName = $appRegistration.DisplayName  
            Description = "Service Principal for $AppName"
            ServicePrincipalType = "Application"
            AppRoleAssignmentRequired = $false
            Tags = @("CoPA-Stop-Search", $EnvironmentName, "WebApp", "Authentication")
        }
        $servicePrincipal = New-MgServicePrincipal -BodyParameter $spParams
        Write-Host "Created service principal: $($servicePrincipal.DisplayName) (ID: $($servicePrincipal.Id))"
    } else {
        Write-Host "Service principal already exists: $($servicePrincipal.DisplayName) (ID: $($servicePrincipal.Id))"
    }

    # Create client secret
    Write-Host "Creating client secret..."
    $secretParams = @{
        DisplayName = "$AppName-client-secret-$EnvironmentName"
        EndDateTime = (Get-Date).AddYears(2)
    }
    
    $clientSecret = Add-MgApplicationPassword -ApplicationId $appRegistration.Id -BodyParameter $secretParams
    Write-Host "Created client secret (expires: $($clientSecret.EndDateTime))"
    
    # Get tenant info
    $tenantInfo = Get-MgContext
    $tenantId = $tenantInfo.TenantId

    # Construct issuer URI using proper endpoint
    $issuerUri = "https://login.microsoftonline.com/$tenantId/v2.0"

    # Prepare output
    $output = @{
        ApplicationId = $appRegistration.AppId
        ClientId = $appRegistration.AppId
        TenantId = $tenantId
        ServicePrincipalId = $servicePrincipal.Id
        ClientSecret = $clientSecret.SecretText
        IssuerUri = $issuerUri
        RedirectUri = $redirectUri
        IdentifierUri = $identifierUri
        DisplayName = $appRegistration.DisplayName
        SecretExpiry = $clientSecret.EndDateTime
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

    Write-Host "SUCCESS: Azure AD App Registration created/updated successfully"
    exit 0

} catch {
    Write-Error "FAILED: Error creating app registration: $($_.Exception.Message)"
    Write-Error $_.Exception.ToString()
    exit 1
}

# Security note: The client secret is output as a secure pipeline variable
# and should be stored securely in Key Vault or Azure DevOps variable groups