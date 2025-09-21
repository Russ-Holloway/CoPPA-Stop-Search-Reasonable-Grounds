# Azure AD App Registration Solution for CoPA Stop Search

## Problem Solved

The CoPA Stop Search application was experiencing application errors because it requires Azure AD authentication through Azure App Service's Easy Auth feature, but no Azure AD app registration was being created during deployment.

## Root Cause

1. **Authentication Requirement**: The application code (`app.py`) expects authentication headers like `X-Ms-Client-Principal-Id` from Easy Auth
2. **Missing App Registration**: The Bicep template had placeholders for `authClientId` and `authClientSecret` but they were empty
3. **Easy Auth Configuration**: Without app registration credentials, the Easy Auth configuration fails to initialize properly

## Solution Overview

The solution automatically creates an Azure AD app registration during the deployment pipeline and configures it for use with Azure App Service Easy Auth:

### 1. PowerShell Script (`scripts/Create-AppRegistration.ps1`)

- **Purpose**: Creates Azure AD app registration with proper configuration for App Service
- **Features**:
  - Creates app registration if it doesn't exist
  - Configures proper redirect URIs for Easy Auth callback
  - Sets up service principal
  - Creates client secret with 2-year expiration
  - Outputs values as pipeline variables for use in infrastructure deployment

### 2. Updated Bicep Templates

#### Main Template (`infra/main.bicep`)
- Added `createAppRegistration` parameter to control app registration creation
- Added conditional logic to use either provided credentials or auto-created ones
- Updated app service configuration to use the correct authentication parameters

#### App Registration Template (`infra/core/security/app-registration.bicep`)
- Alternative Bicep-based approach using deployment scripts
- Includes managed identity setup with required permissions
- Currently not used in favor of the PowerShell approach for simplicity

### 3. Updated Azure Pipeline (`azure-pipelines.yml`)

#### For Development:
- Installs Microsoft Graph PowerShell modules
- Runs app registration script before infrastructure deployment
- Passes app registration values to Bicep deployment
- Sets `createAppRegistration` to false to avoid conflicts

#### For Production:
- Same process but with production-specific naming and URLs

## App Registration Configuration

The created app registration includes:

### Basic Settings
- **Display Name**: CoPA-Stop-Search-{Environment}-001
- **Sign-in Audience**: Azure AD (single tenant)
- **Identifier URI**: api://CoPA-Stop-Search-{Environment}-001

### Web Platform Configuration
- **Redirect URI**: `https://{webapp}.azurewebsites.net/.auth/login/aad/callback`
- **ID Token Issuance**: Enabled (required for Easy Auth)
- **Access Token Issuance**: Disabled

### API Permissions
- **Microsoft Graph**: User.Read (delegated permission)

### Authentication Flow
1. User accesses the web application
2. Easy Auth redirects to Azure AD login
3. After successful authentication, Azure AD redirects back to the callback URL
4. Easy Auth validates the token and sets authentication headers
5. Application receives user context via headers like `X-Ms-Client-Principal-Id`

## Security Considerations

### Client Secret Management
- Client secrets are created with 2-year expiration
- Stored securely in Azure Key Vault during deployment
- Referenced via Key Vault reference in App Service configuration
- Marked as secure pipeline variables

### Permissions Required
The Azure DevOps service connection needs:
- **Application Administrator** role in Azure AD (to create app registrations)
- **Contributor** role on the subscription (for infrastructure deployment)

### Network Security
- App Service is configured with HTTPS only
- TLS 1.2 minimum version enforced
- Proper Content Security Policy headers

## Pipeline Integration

### Variables Created
The app registration script creates these pipeline variables:
- `AppRegistration.ApplicationId`
- `AppRegistration.ClientId` 
- `AppRegistration.TenantId`
- `AppRegistration.IssuerUri`
- `AppRegistration.ClientSecret` (secure)

### Infrastructure Parameters
These values are automatically passed to the Bicep deployment:
- `authClientId`: From app registration
- `authClientSecret`: From app registration (secure)
- `createAppRegistration`: Set to false

## Verification Steps

After deployment, verify the solution works by:

1. **Check App Registration**: 
   - Go to Azure AD > App registrations
   - Find "CoPA-Stop-Search-{Environment}-001"
   - Verify redirect URI and settings

2. **Check App Service Configuration**:
   - Go to App Service > Authentication
   - Verify Azure AD provider is configured
   - Check that client ID matches app registration

3. **Test Authentication**:
   - Navigate to the web application
   - Should redirect to Azure AD login
   - After login, should access the application successfully

4. **Check Application Logs**:
   - Verify no authentication-related errors
   - Confirm user context headers are present

## Troubleshooting

### Common Issues

1. **Permission Denied Creating App Registration**:
   - Service connection needs Application Administrator role
   - Verify the service principal has proper Azure AD permissions

2. **App Registration Already Exists**:
   - Script handles existing registrations gracefully
   - Will update redirect URIs if needed

3. **Client Secret Expiration**:
   - Secrets expire after 2 years
   - Monitor expiration and rotate as needed
   - Consider using certificates for longer validity

4. **Easy Auth Not Working**:
   - Verify client ID and secret are correctly configured
   - Check issuer URI matches tenant
   - Ensure redirect URI is exactly: `https://{webapp}.azurewebsites.net/.auth/login/aad/callback`

## Benefits

### Automated Setup
- No manual app registration required
- Consistent configuration across environments
- Reduces deployment complexity and human error

### Security
- Client secrets stored in Key Vault
- Proper permission scoping
- Secure credential handling in pipeline

### Maintainability
- Infrastructure as Code approach
- Documented configuration
- Easy to replicate across environments

## Future Enhancements

1. **Certificate Authentication**: Replace client secrets with certificates for better security
2. **Conditional Access**: Add conditional access policies for enhanced security
3. **Multi-Tenant Support**: Modify for multi-tenant scenarios if needed
4. **Automated Renewal**: Add automated client secret rotation

This solution ensures that the CoPA Stop Search application has proper Azure AD authentication configured automatically during deployment, resolving the application errors caused by missing authentication configuration.