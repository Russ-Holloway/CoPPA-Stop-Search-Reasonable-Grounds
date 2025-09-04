# Authentication Troubleshooting Guide

This guide helps resolve common Azure AD authentication issues after deployment.

## 🔍 Quick Diagnostics

### 1. Test Authentication Flow

Visit your web app URL: `https://your-app-name.azurewebsites.net`

**Expected behavior:**
1. Redirects to Azure AD login page
2. After login, redirects back to your app
3. Shows the application interface

### 2. Check Authentication Status

Run this PowerShell command to verify your setup:
```powershell
# Check if authentication is enabled
az webapp auth show --name "your-app-name" --resource-group "your-resource-group"
```

---

## ❌ Common Errors & Solutions

### "AADSTS50011: The reply URL specified in the request does not match"

**Cause:** Redirect URI mismatch  
**Solution:**
1. Go to Azure Portal → Azure AD → App registrations → Your app
2. Go to "Authentication" 
3. Verify redirect URIs exactly match:
   - `https://your-app-name.azurewebsites.net/.auth/login/aad/callback`
   - `https://your-app-name.azurewebsites.net/redirect`
4. Check for typos, trailing slashes, or case differences

### "AADSTS65001: User or administrator has not consented"

**Cause:** Admin consent not granted  
**Solution:**
1. Go to Azure Portal → Azure AD → App registrations → Your app
2. Go to "API permissions"
3. Click "Grant admin consent for [Your Organization]"
4. Confirm the action

### Authentication Loop (Keeps Redirecting)

**Cause:** App Service authentication misconfiguration  
**Solutions:**

1. **Check client secret:**
   ```powershell
   # Verify app settings contain the client secret
   az webapp config appsettings list --name "your-app-name" --resource-group "your-resource-group" --query "[?name=='MICROSOFT_PROVIDER_AUTHENTICATION_SECRET']"
   ```

2. **Regenerate client secret:**
   - Go to Azure AD → App registrations → Your app → Certificates & secrets
   - Create new secret, copy value
   - Update App Service app setting `MICROSOFT_PROVIDER_AUTHENTICATION_SECRET`

3. **Re-run authentication script:**
   ```powershell
   .\scripts\setup_azure_ad_auth.ps1 -WebAppName "your-app" -ResourceGroupName "your-rg"
   ```

### "User assignment required" Error

**Cause:** Enterprise Application requires assignment but user is not assigned  
**Solution:**
1. Go to Azure Portal → Azure AD → Enterprise applications → Your app
2. Go to "Users and groups"
3. Click "Add user/group"
4. Select users/groups who should have access
5. Click "Assign"

**Alternative:** Disable assignment requirement:
1. Go to "Properties"
2. Set "Assignment required" to "No"
3. Click "Save"

### "This app can't be accessed" Error

**Cause:** Enterprise Application not properly configured  
**Solutions:**

1. **Check Enterprise Application properties:**
   - Go to Azure AD → Enterprise applications → Your app → Properties
   - Verify: "Enabled for users to sign-in" = Yes
   - Verify: "Visible to users" = Yes

2. **Re-run setup script with Enterprise Application fix:**
   ```powershell
   .\scripts\setup_azure_ad_auth.ps1 -WebAppName "your-app" -ResourceGroupName "your-rg"
   ```

**Cause:** Incorrect Application (client) ID  
**Solution:**
1. Get correct Application ID from Azure AD → App registrations → Your app
2. Update App Service app setting `AZURE_CLIENT_ID`:
   ```powershell
   az webapp config appsettings set --name "your-app-name" --resource-group "your-resource-group" --settings AZURE_CLIENT_ID="correct-client-id"
   ```

### "This site can't be reached" or 500 Errors

**Cause:** App Service configuration issues  
**Solutions:**

1. **Check app is running:**
   ```powershell
   az webapp show --name "your-app-name" --resource-group "your-resource-group" --query "state"
   ```

2. **Check app logs:**
   - Go to Azure Portal → App Service → Log stream
   - Look for authentication or startup errors

3. **Verify required app settings:**
   ```powershell
   az webapp config appsettings list --name "your-app-name" --resource-group "your-resource-group"
   ```
   Required settings:
   - `AZURE_CLIENT_ID`
   - `MICROSOFT_PROVIDER_AUTHENTICATION_SECRET`
   - `AUTH_ENABLED=true`

---

## 🔧 Manual Verification Steps

### 1. Test Azure AD App Registration

Use this URL to test your app registration directly:
```
https://login.microsoftonline.com/[tenant-id]/oauth2/v2.0/authorize?client_id=[client-id]&response_type=code&scope=openid%20profile%20email%20User.Read&redirect_uri=https://[your-app].azurewebsites.net/.auth/login/aad/callback
```

Replace:
- `[tenant-id]` with your Azure AD tenant ID
- `[client-id]` with your Application (client) ID  
- `[your-app]` with your App Service name

### 2. Check App Service Authentication

1. Go to Azure Portal → App Service → Authentication
2. Verify configuration:
   - Provider: Microsoft
   - Status: Enabled
   - Client ID: Matches your Azure AD app
   - Unauthenticated action: HTTP 302 Found redirect

### 3. Verify Permissions

1. Go to Azure Portal → Azure AD → Enterprise applications
2. Find your app
3. Go to "Permissions" tab
4. Confirm admin consent granted for all permissions

---

## 🚨 Emergency Fixes

### Option 1: Re-run Setup Script

```powershell
# This will update existing configuration
.\scripts\setup_azure_ad_auth.ps1 -WebAppName "your-app" -ResourceGroupName "your-rg"
```

### Option 2: Reset Authentication

```powershell
# Disable authentication temporarily
az webapp auth update --name "your-app-name" --resource-group "your-resource-group" --enabled false

# Re-enable with fresh configuration
.\scripts\setup_azure_ad_auth.ps1 -WebAppName "your-app" -ResourceGroupName "your-rg"
```

### Option 3: Create New App Registration

```powershell
# Create with timestamp to avoid conflicts
.\scripts\setup_azure_ad_auth.ps1 -WebAppName "your-app" -ResourceGroupName "your-rg" -AppDisplayName "app-btp-prosecution-guidance-new"
```

---

## 📊 Diagnostic Commands

### Get App Registration Details
```powershell
# List all app registrations containing your app name
az ad app list --display-name "app-btp-prosecution-guidance" --query "[].{DisplayName:displayName, AppId:appId, ObjectId:id}"
```

### Get Enterprise Application Details
```powershell
# Get Enterprise Application (Service Principal) details
az ad sp list --display-name "app-btp-prosecution-guidance" --query "[].{DisplayName:displayName, AppId:appId, ObjectId:id, AccountEnabled:accountEnabled, AppRoleAssignmentRequired:appRoleAssignmentRequired}"
```  
```powershell
# Check authentication configuration
az webapp auth show --name "your-app-name" --resource-group "your-resource-group" --query "{enabled:enabled, defaultProvider:defaultProvider}"
```

### Get App Settings
```powershell
# List authentication-related app settings
az webapp config appsettings list --name "your-app-name" --resource-group "your-resource-group" --query "[?contains(name, 'AUTH') || contains(name, 'AZURE') || contains(name, 'MICROSOFT')]"
```

### Check App Service Logs
```powershell
# Stream logs in real-time
az webapp log tail --name "your-app-name" --resource-group "your-resource-group"
```

---

## 🆘 Still Having Issues?

1. **Review setup guide:** [Azure AD Setup Guide](AZURE_AD_SETUP_GUIDE.md)
2. **Check quick reference:** [Azure AD Quick Reference](AZURE_AD_QUICK_REFERENCE.md)
3. **Microsoft documentation:** [Azure App Service Authentication](https://learn.microsoft.com/en-us/azure/app-service/scenario-secure-app-authentication-app-service)

### Common Resolution Order

1. Grant admin consent (if not done)
2. Verify redirect URIs exactly match
3. Check/regenerate client secret
4. Re-run setup script
5. Create new app registration if all else fails

Most authentication issues are resolved by ensuring admin consent is granted and redirect URIs match exactly.
