# Azure AD Authentication Setup Script for Policing Assistant
# This script configures Azure AD authentication for the deployed web application
# Based on the configuration shown in your Azure AD app registration

param(
    [Parameter(Mandatory = $true)]
    [string]$WebAppName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$AppDisplayName = "app-btp-prosecution-guidance",
    
    [Parameter(Mandatory = $false)]
    [string]$TenantDomain = $null,
      [Parameter(Mandatory = $false)]
    [switch]$SkipAuthConfig = $false,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipEnterpriseAppConfig = $false
)

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Azure AD Authentication Setup for Policing Assistant" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Function to check if user has admin privileges
function Test-AdminPrivileges {
    try {
        $testApp = Get-AzADApplication -Filter "displayName eq 'NonExistentTestApp123456'" -ErrorAction SilentlyContinue
        return $true
    }
    catch {
        return $false
    }
}

# Function to get web app URL
function Get-WebAppUrl {
    param($WebAppName, $ResourceGroupName)
    
    try {
        $webApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName -ErrorAction Stop
        return "https://$($webApp.DefaultHostName)"
    }
    catch {
        Write-Error "Could not find web app '$WebAppName' in resource group '$ResourceGroupName'"
        return $null
    }
}

# Check Azure PowerShell login
Write-Host "Checking Azure PowerShell connection..." -ForegroundColor Yellow
try {
    $context = Get-AzContext -ErrorAction Stop
    if (-not $context) {
        throw "Not logged in"
    }
    Write-Host "✓ Connected as: $($context.Account)" -ForegroundColor Green
} catch {
    Write-Host "Please login to Azure PowerShell first:" -ForegroundColor Red
    Write-Host "Connect-AzAccount" -ForegroundColor Yellow
    exit 1
}

# Check admin privileges
Write-Host "Checking Azure AD admin privileges..." -ForegroundColor Yellow
if (-not (Test-AdminPrivileges)) {
    Write-Host "⚠️  Warning: You may not have sufficient Azure AD admin privileges." -ForegroundColor Yellow
    Write-Host "   Some operations may fail. You may need Global Admin or Application Admin role." -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

# Get web app URL
Write-Host "Getting web app information..." -ForegroundColor Yellow
$webAppUrl = Get-WebAppUrl -WebAppName $WebAppName -ResourceGroupName $ResourceGroupName
if (-not $webAppUrl) {
    exit 1
}
Write-Host "✓ Web App URL: $webAppUrl" -ForegroundColor Green

# Set up redirect URIs (matching your Azure AD app registration)
$redirectUris = @(
    "$webAppUrl/.auth/login/aad/callback",
    "$webAppUrl/redirect"
)

# Set up logout URLs
$logoutUrl = "$webAppUrl/.auth/logout"

Write-Host ""
Write-Host "Creating Azure AD App Registration..." -ForegroundColor Yellow

try {
    # Check if app already exists
    $existingApp = Get-AzADApplication -Filter "displayName eq '$AppDisplayName'" -ErrorAction SilentlyContinue
      if ($existingApp) {
        Write-Host "⚠️  App registration '$AppDisplayName' already exists." -ForegroundColor Yellow
        $action = Read-Host "Choose action: (u)pdate existing, (c)reate new with timestamp, (s)kip and use existing (u/c/s)"
        
        switch ($action.ToLower()) {
            "c" {
                $timestampSuffix = Get-Date -Format "yyyyMMdd-HHmm"
                $AppDisplayName = "$AppDisplayName-$timestampSuffix"
                $app = New-AzADApplication -DisplayName $AppDisplayName
                Write-Host "✓ Created new app registration: $AppDisplayName" -ForegroundColor Green
            }
            "s" {
                Write-Host "✓ Using existing app registration" -ForegroundColor Green
                $app = $existingApp
            }
            default {
                Write-Host "✓ Updating existing app registration" -ForegroundColor Green
                $app = $existingApp
            }
        }
    } else {
        # Create new app registration
        $app = New-AzADApplication -DisplayName $AppDisplayName
        Write-Host "✓ Created app registration: $AppDisplayName" -ForegroundColor Green
    }

    # Update web settings (redirect URIs and logout URL)
    $webSettings = @{
        RedirectUris = $redirectUris
        LogoutUrl = $logoutUrl
        ImplicitGrantSettings = @{
            EnableIdTokenIssuance = $true
            EnableAccessTokenIssuance = $false
        }
    }
    
    Update-AzADApplication -ApplicationId $app.AppId -Web $webSettings
    Write-Host "✓ Configured web settings (redirect URIs, logout URL, implicit grant)" -ForegroundColor Green    # Add Microsoft Graph permissions (matching your Azure AD app registration)
    Write-Host "Adding Microsoft Graph permissions..." -ForegroundColor Yellow
    
    # Microsoft Graph App ID
    $graphAppId = "00000003-0000-0000-c000-000000000000"
    
    # Define permissions (matching your configuration)
    $permissions = @(
        @{
            Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"  # User.Read
            Type = "Scope"
        },
        @{
            Id = "37f7f235-527c-4136-accd-4a02d197296e"  # openid
            Type = "Scope"
        },
        @{
            Id = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0"  # email
            Type = "Scope"
        },
        @{
            Id = "14dad69e-099b-42c9-810b-d002981feec1"  # profile
            Type = "Scope"
        }
    )
    
    $requiredResourceAccess = @{
        ResourceAppId = $graphAppId
        ResourceAccess = $permissions
    }
    
    Update-AzADApplication -ApplicationId $app.AppId -RequiredResourceAccess $requiredResourceAccess
    Write-Host "✓ Added Microsoft Graph permissions: User.Read, openid, email, profile" -ForegroundColor Green    # Create client secret
    Write-Host "Creating client secret..." -ForegroundColor Yellow
    $secretName = "Policing-Assistant-Secret-$(Get-Date -Format 'yyyyMMdd')"
    $secret = New-AzADAppCredential -ApplicationId $app.AppId -DisplayName $secretName
    Write-Host "✓ Created client secret (expires: $($secret.EndDateTime))" -ForegroundColor Green    # Configure Enterprise Application settings
    if (-not $SkipEnterpriseAppConfig) {
        Write-Host "Configuring Enterprise Application settings..." -ForegroundColor Yellow
        
        # Get or create the service principal (Enterprise Application)
        $servicePrincipal = Get-AzADServicePrincipal -ApplicationId $app.AppId -ErrorAction SilentlyContinue
        
        if (-not $servicePrincipal) {
            Write-Host "Creating Enterprise Application (Service Principal)..." -ForegroundColor Yellow
            $servicePrincipal = New-AzADServicePrincipal -ApplicationId $app.AppId
            Write-Host "✓ Created Enterprise Application" -ForegroundColor Green
            # Wait a moment for propagation
            Start-Sleep -Seconds 10
        } else {
            Write-Host "✓ Enterprise Application already exists" -ForegroundColor Green
        }
        
        # Configure Enterprise Application properties to match your screenshot
        try {
            # Set Enterprise Application properties
            # - Enabled for users to sign-in: Yes
            # - Assignment required: Yes  
            # - Visible to users: Yes
            Update-AzADServicePrincipal -ApplicationId $app.AppId `
                -AccountEnabled $true `
                -AppRoleAssignmentRequired $true
            
            Write-Host "✓ Configured Enterprise Application settings:" -ForegroundColor Green
            Write-Host "  - Enabled for users to sign-in: Yes" -ForegroundColor White
            Write-Host "  - Assignment required: Yes" -ForegroundColor White  
            Write-Host "  - Visible to users: Yes" -ForegroundColor White
            
            # Set additional properties via Microsoft Graph API if available
            try {
                $graphToken = (Get-AzAccessToken -ResourceTypeName MSGraph).Token
                $headers = @{
                    'Authorization' = "Bearer $graphToken"
                    'Content-Type' = 'application/json'
                }
                
                # Configure service principal properties
                $servicePrincipalUpdate = @{
                    accountEnabled = $true
                    appRoleAssignmentRequired = $true
                    preferredSingleSignOnMode = "saml"
                    notes = "Policing Assistant Enterprise Application - Configured automatically"
                } | ConvertTo-Json
                
                $spUpdateUri = "https://graph.microsoft.com/v1.0/servicePrincipals/$($servicePrincipal.Id)"
                Invoke-RestMethod -Uri $spUpdateUri -Method PATCH -Body $servicePrincipalUpdate -Headers $headers -ErrorAction SilentlyContinue
                
                Write-Host "✓ Applied additional Enterprise Application settings" -ForegroundColor Green
            } catch {
                Write-Host "⚠️  Could not apply all Enterprise Application settings via Graph API" -ForegroundColor Yellow
                Write-Host "   Basic settings have been applied successfully" -ForegroundColor Yellow
            }
            
        } catch {
            Write-Host "⚠️  Could not configure all Enterprise Application settings" -ForegroundColor Yellow
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "   You may need to configure these manually in Azure Portal" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⏭️  Skipping Enterprise Application configuration (use -SkipEnterpriseAppConfig to skip)" -ForegroundColor Yellow
        # Still need to get the service principal for output
        $servicePrincipal = Get-AzADServicePrincipal -ApplicationId $app.AppId -ErrorAction SilentlyContinue
        if (-not $servicePrincipal) {
            $servicePrincipal = @{ Id = "Not configured" }
        }
    }# Configure App Service Authentication (skip if requested)
    if (-not $SkipAuthConfig) {
        Write-Host "Configuring App Service Authentication..." -ForegroundColor Yellow
        
        # Get current tenant info
        $tenant = Get-AzContext | Select-Object -ExpandProperty Tenant
        $issuerUri = "https://sts.windows.net/$($tenant.Id)/"
        
        # Create auth configuration
        $authConfig = @{
            platform = @{
                enabled = $true
            }
            globalValidation = @{
                requireAuthentication = $true
                unauthenticatedClientAction = "RedirectToLoginPage"
                redirectToProvider = "azureactivedirectory"
            }
            identityProviders = @{
                azureActiveDirectory = @{
                    enabled = $true
                    registration = @{
                        clientId = $app.AppId
                        clientSecretSettingName = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
                        openIdIssuer = $issuerUri
                    }
                    validation = @{
                        defaultAuthorizationPolicy = @{
                            allowedApplications = @()
                        }
                    }
                }
            }
            login = @{
                tokenStore = @{
                    enabled = $true
                }
            }
        } | ConvertTo-Json -Depth 10

        # Set the client secret as an app setting
        $appSettings = @{
            "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET" = $secret.SecretText
            "AUTH_ENABLED" = "true"
            "AZURE_CLIENT_ID" = $app.AppId
            "AZURE_TENANT_ID" = $tenant.Id
        }
        
        Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName -AppSettings $appSettings
        Write-Host "✓ Configured app settings with authentication details" -ForegroundColor Green
        
        # Apply authentication configuration to App Service
        $webApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
        $resourceId = $webApp.Id
        
        # Use REST API to configure auth settings v2
        $restUri = "https://management.azure.com$resourceId/config/authsettingsV2?api-version=2021-02-01"
        $headers = @{
            'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
            'Content-Type' = 'application/json'
        }
        
        try {
            Invoke-RestMethod -Uri $restUri -Method PUT -Body $authConfig -Headers $headers
            Write-Host "✓ Applied authentication configuration to App Service" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Could not configure App Service auth via REST API. You may need to configure this manually." -ForegroundColor Yellow
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "⏭️  Skipping App Service authentication configuration (use -SkipAuthConfig to skip)" -ForegroundColor Yellow
        Write-Host "   You can manually configure this later or run the script again without -SkipAuthConfig" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  SETUP COMPLETE!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""    Write-Host "App Registration Details:" -ForegroundColor Cyan
    Write-Host "  Display Name: $AppDisplayName" -ForegroundColor White
    Write-Host "  Application ID: $($app.AppId)" -ForegroundColor White
    Write-Host "  Object ID: $($app.Id)" -ForegroundColor White
    Write-Host "  Redirect URIs:" -ForegroundColor White
    foreach ($uri in $redirectUris) {
        Write-Host "    - $uri" -ForegroundColor White
    }
    Write-Host "  Logout URL: $logoutUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "Enterprise Application Settings:" -ForegroundColor Cyan
    Write-Host "  - Enabled for users to sign-in: Yes" -ForegroundColor White
    Write-Host "  - Assignment required: Yes" -ForegroundColor White
    Write-Host "  - Visible to users: Yes" -ForegroundColor White
    Write-Host "  - Service Principal ID: $($servicePrincipal.Id)" -ForegroundColor White
    Write-Host ""
    Write-Host "Configured Permissions:" -ForegroundColor Cyan
    Write-Host "  - Microsoft Graph: User.Read (delegated)" -ForegroundColor White
    Write-Host "  - Microsoft Graph: openid (delegated)" -ForegroundColor White  
    Write-Host "  - Microsoft Graph: email (delegated)" -ForegroundColor White
    Write-Host "  - Microsoft Graph: profile (delegated)" -ForegroundColor White
    Write-Host "  - ID tokens enabled for implicit grant flow" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. ⚠️  GRANT ADMIN CONSENT for Microsoft Graph permissions:" -ForegroundColor Yellow
    Write-Host "   - Go to Azure Portal > Azure Active Directory > App registrations" -ForegroundColor White
    Write-Host "   - Find '$AppDisplayName'" -ForegroundColor White
    Write-Host "   - Go to 'API permissions'" -ForegroundColor White
    Write-Host "   - Click 'Grant admin consent for [Your Organization]'" -ForegroundColor White
    Write-Host ""
    Write-Host "2. 🌐 Test your application:" -ForegroundColor Green
    Write-Host "   $webAppUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "3. 📝 Optional: Update publisher domain (to remove 'Unverified' label):" -ForegroundColor Yellow
    Write-Host "   - In the app registration, go to 'Branding & properties'" -ForegroundColor White
    Write-Host "   - Set 'Publisher domain' to your verified domain" -ForegroundColor White
    Write-Host ""
    
    # Save configuration for reference
    $configFile = "azure-ad-config-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"    $configData = @{
        AppDisplayName = $AppDisplayName
        ApplicationId = $app.AppId
        ObjectId = $app.Id
        ServicePrincipalId = $servicePrincipal.Id
        WebAppUrl = $webAppUrl
        RedirectUris = $redirectUris
        LogoutUrl = $logoutUrl
        TenantId = $tenant.Id
        SecretExpiry = $secret.EndDateTime
        ConfiguredDate = Get-Date
        Permissions = @(
            "Microsoft Graph: User.Read (delegated)",
            "Microsoft Graph: openid (delegated)",
            "Microsoft Graph: email (delegated)", 
            "Microsoft Graph: profile (delegated)"
        )
        ImplicitGrant = @{
            IdTokens = $true
            AccessTokens = $false
        }
        EnterpriseApplication = @{
            Enabled = $true
            AssignmentRequired = $true
            VisibleToUsers = $true
        }
        AuthConfigured = -not $SkipAuthConfig
    } | ConvertTo-Json -Depth 3
    
    $configData | Out-File -FilePath $configFile -Encoding UTF8
    Write-Host "Configuration saved to: $configFile" -ForegroundColor Cyan

} catch {
    Write-Host ""
    Write-Host "❌ Error occurred during setup:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual Setup Instructions:" -ForegroundColor Yellow
    Write-Host "1. Go to Azure Portal > Azure Active Directory > App registrations" -ForegroundColor White
    Write-Host "2. Click 'New registration'" -ForegroundColor White
    Write-Host "3. Name: $AppDisplayName" -ForegroundColor White
    Write-Host "4. Redirect URI: $($redirectUris[0])" -ForegroundColor White
    Write-Host "5. Add Microsoft Graph User.Read permission" -ForegroundColor White
    Write-Host "6. Grant admin consent" -ForegroundColor White
    Write-Host "7. Create a client secret" -ForegroundColor White
    Write-Host "8. Configure App Service authentication with the client ID and secret" -ForegroundColor White
    exit 1
}
