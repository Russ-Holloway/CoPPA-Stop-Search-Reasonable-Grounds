# Azure AD Authentication Setup Guide

This guide helps you configure Azure Active Directory (Azure AD) authentication for your deployed CoPA application, replicating the exact configuration shown in the reference Azure AD app registration.

## Quick Setup (Automated)

### Prerequisites

1. **Azure PowerShell installed and logged in:**
   ```powershell
   # Install Azure PowerShell (if not already installed)
   Install-Module -Name Az -AllowClobber -Force
   
   # Login to Azure
   Connect-AzAccount
   ```

2. **Azure AD Admin permissions** (Global Admin or Application Admin role)

### Run the Setup Script

```powershell
# Navigate to the scripts directory
cd scripts

# Run the Azure AD setup script
.\setup_azure_ad_auth.ps1 -WebAppName "your-web-app-name" -ResourceGroupName "your-resource-group"
```

**Example:**
```powershell
.\setup_azure_ad_auth.ps1 -WebAppName "policing-assistant-web" -ResourceGroupName "rg-policing-assistant"
```

### Script Options

- **Basic setup:** Creates app registration and configures authentication
- **App name only:** Creates app registration but skips App Service auth config
  ```powershell
  .\setup_azure_ad_auth.ps1 -WebAppName "your-app" -ResourceGroupName "your-rg" -SkipAuthConfig
  ```
- **Custom app name:**
  ```powershell
  .\setup_azure_ad_auth.ps1 -WebAppName "your-app" -ResourceGroupName "your-rg" -AppDisplayName "My Custom App Name"
  ```

### After Running the Script

1. **Grant Admin Consent** (Required):
   - Go to [Azure Portal](https://portal.azure.com) > Azure Active Directory > App registrations
   - Find your app (default: "app-btp-prosecution-guidance")
   - Go to "API permissions"
   - Click "Grant admin consent for [Your Organization]"

2. **Test Your Application:**
   - Navigate to your web app URL
   - You should be redirected to Azure AD login
   - After login, you should be redirected back to your app

---

## Manual Setup (Alternative)

If the automated script doesn't work or you prefer manual setup:

### Step 1: Create Azure AD App Registration

1. Go to [Azure Portal](https://portal.azure.com) > Azure Active Directory > App registrations
2. Click "New registration"
3. Fill in the details:
   - **Name:** `app-btp-prosecution-guidance` (or your preferred name)
   - **Supported account types:** Accounts in this organizational directory only
   - **Redirect URI:** 
     - Type: Web
     - URL: `https://your-app-name.azurewebsites.net/.auth/login/aad/callback`

### Step 2: Configure Authentication

1. In your app registration, go to "Authentication"
2. Under "Redirect URIs", add:
   - `https://your-app-name.azurewebsites.net/.auth/login/aad/callback`
   - `https://your-app-name.azurewebsites.net/redirect`
3. Under "Front-channel logout URL":
   - `https://your-app-name.azurewebsites.net/.auth/logout`
4. Under "Implicit grant and hybrid flows":
   - ✅ Check "ID tokens (used for implicit and hybrid flows)"
   - ❌ Leave "Access tokens" unchecked

### Step 3: Configure API Permissions

1. Go to "API permissions"
2. Click "Add a permission" > Microsoft Graph > Delegated permissions
3. Add these permissions:
   - ✅ **User.Read** - Sign in and read user profile
   - ✅ **openid** - Sign users in (automatically added)
   - ✅ **email** - View users' email address (automatically added)
   - ✅ **profile** - View users' basic profile (automatically added)
4. Click "Grant admin consent for [Your Organization]"

### Step 4: Configure Enterprise Application

1. Go to Azure Active Directory > Enterprise applications
2. Find your app (same name as app registration)
3. Go to "Properties"
4. Configure the following settings:
   - ✅ **Enabled for users to sign-in:** Yes
   - ✅ **Assignment required:** Yes
   - ✅ **Visible to users:** Yes
5. Click "Save"

### Step 5: Create Client Secret

1. Go to "Certificates & secrets"
2. Click "New client secret"
3. Add description: "Policing-Assistant-Secret"
4. Set expiration: 24 months (recommended)
5. Click "Add"
6. **Copy the secret value immediately** (you won't see it again)

### Step 6: Configure App Service Authentication

1. Go to your App Service in Azure Portal
2. Go to "Authentication" in the left menu
3. Click "Add identity provider"
4. Choose "Microsoft"
5. Fill in:
   - **App registration type:** Provide the details of an existing app registration
   - **Application (client) ID:** [Your app's Application ID]
   - **Client secret:** [The secret you created]
   - **Issuer URL:** `https://sts.windows.net/[your-tenant-id]/`
6. Under "App Service authentication settings":
   - **Restrict access:** Require authentication
   - **Unauthenticated requests:** HTTP 302 Found redirect (recommended for websites)
   - **Token store:** ✅ Enabled

---

## Configuration Reference

Your Azure AD app registration should match this configuration:

### Application Details
- **Application (client) ID:** Generated UUID
- **Directory (tenant) ID:** Your Azure AD tenant ID
- **Object ID:** Generated UUID

### Authentication Settings
- **Redirect URIs:**
  - `https://[your-app].azurewebsites.net/.auth/login/aad/callback`
  - `https://[your-app].azurewebsites.net/redirect`
- **Logout URL:** `https://[your-app].azurewebsites.net/.auth/logout`
- **Implicit grant:** ID tokens enabled, Access tokens disabled

### API Permissions (Delegated)
- **Microsoft Graph:**
  - User.Read
  - openid  
  - email
  - profile

### Enterprise Application Settings
- **Enabled for users to sign-in:** Yes
- **Assignment required:** Yes
- **Visible to users:** Yes
- **Notes:** "CoPA Enterprise Application - Configured automatically"

### Certificates & Secrets
- **Client secret:** Active secret for App Service authentication

---

## Troubleshooting

### Common Issues

1. **"AADSTS50011: The reply URL specified in the request does not match"**
   - Check that redirect URIs exactly match your app URL
   - Ensure no trailing slashes or typos

2. **"User consent required"**
   - Admin consent hasn't been granted
   - Go to API permissions and click "Grant admin consent"

3. **Authentication loop (keeps redirecting)**
   - Check App Service authentication configuration
   - Verify client secret is correct and not expired

4. **"AADSTS700016: Application not found"**
   - Client ID is incorrect
   - Check App Service app settings for `AZURE_CLIENT_ID`

### Verification Steps

1. **Test app registration:**
   ```
   https://login.microsoftonline.com/[tenant-id]/oauth2/v2.0/authorize?client_id=[client-id]&response_type=code&scope=openid%20profile%20email%20User.Read&redirect_uri=https://[your-app].azurewebsites.net/.auth/login/aad/callback
   ```

2. **Check App Service logs:**
   - Go to App Service > Log stream
   - Look for authentication-related errors

3. **Verify permissions:**
   - Go to Azure AD > Enterprise applications
   - Find your app and check "Permissions"

---

## Security Notes

- **Client secrets expire:** Set calendar reminders to renew before expiration
- **Least privilege:** Only request necessary Microsoft Graph permissions
- **Monitor access:** Regularly review sign-in logs in Azure AD
- **Publisher domain:** Consider setting a verified publisher domain to remove "Unverified" labels

---

## Next Steps

After successful authentication setup:

1. **Test thoroughly:** Verify login/logout functionality
2. **Monitor usage:** Check Azure AD sign-in logs
3. **Plan maintenance:** Calendar client secret renewal
4. **Document configuration:** Save the generated config file for reference

For support, refer to the troubleshooting section above or check the Azure AD documentation.
