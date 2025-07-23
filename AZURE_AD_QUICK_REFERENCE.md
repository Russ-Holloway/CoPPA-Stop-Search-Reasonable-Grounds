# Azure AD Quick Setup Reference

## 🚀 One-Command Setup

After your Azure deployment completes, run this in PowerShell:

```powershell
# Replace with your actual values
.\scripts\setup_azure_ad_auth.ps1 -WebAppName "your-web-app-name" -ResourceGroupName "your-resource-group-name"
```

**Example:**
```powershell
.\scripts\setup_azure_ad_auth.ps1 -WebAppName "policing-assistant-20241217" -ResourceGroupName "rg-policing-assistant"
```

## ✅ Required Steps After Script

1. **Grant Admin Consent** (⚠️ Required):
   - Go to [Azure Portal](https://portal.azure.com) → Azure AD → App registrations  
   - Find "app-btp-prosecution-guidance"
   - Go to "API permissions" → Click "Grant admin consent"

2. **Test**: Visit your web app URL - should redirect to Azure login

## 📋 What Gets Configured

### App Registration
- ✅ App name: `app-btp-prosecution-guidance`
- ✅ Redirect URIs: `/.auth/login/aad/callback` + `/redirect`
- ✅ Logout URL: `/.auth/logout`
- ✅ ID tokens enabled for implicit grant
- ✅ Client secret created (24-month expiry)

### Permissions (Delegated)
- ✅ Microsoft Graph: User.Read
- ✅ Microsoft Graph: openid, email, profile
- ⚠️ **Admin consent required** (manual step)

### Enterprise Application Settings
- ✅ Enabled for users to sign-in: Yes
- ✅ Assignment required: Yes
- ✅ Visible to users: Yes

### App Service Authentication  
- ✅ Azure AD provider configured
- ✅ Client secret stored securely
- ✅ Authentication required for all requests

## 🔧 Script Options

| Option | Description | Example |
|--------|-------------|---------|
| Basic | Full setup with auth | `.\setup_azure_ad_auth.ps1 -WebAppName "myapp" -ResourceGroupName "myrg"` |
| App Only | Create app registration only | Add `-SkipAuthConfig` flag |
| Custom Name | Use different app name | Add `-AppDisplayName "My Custom App"` |

## ⚠️ Prerequisites

1. **Azure PowerShell logged in:**
   ```powershell
   Connect-AzAccount
   ```

2. **Admin permissions:** Global Admin or Application Admin role

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "Reply URL mismatch" | Check redirect URIs match exactly |
| "User consent required" | Grant admin consent in Azure Portal |
| Authentication loop | Verify client secret in App Service settings |
| "Application not found" | Check Application ID in app settings |

## 📱 Mobile Quick Reference

**Azure Portal Path:**
Azure AD → App registrations → [Your App] → API permissions → Grant admin consent

**Test URL Pattern:**
`https://your-app-name.azurewebsites.net`

---

**Need help?** 
- 📖 [Azure AD Setup Guide](AZURE_AD_SETUP_GUIDE.md) - Complete setup instructions
- 🔧 [Azure AD Troubleshooting](AZURE_AD_TROUBLESHOOTING.md) - Fix common issues
