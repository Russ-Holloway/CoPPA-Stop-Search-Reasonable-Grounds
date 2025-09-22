# App Registration URI Reference Guide

## 🔗 Required URIs for CoPA Stop & Search App Registration

When creating the Azure AD App Registration, you need to configure the correct redirect URI for authentication to work properly.

### Redirect URI Format

**Base Pattern:**
```
https://{app-service-name}.azurewebsites.net/.auth/login/aad/callback
```

### Standard Environment Examples

#### Development Environment
- **Environment Code:** `d`
- **Instance Number:** `001` (default)
- **Redirect URI:** 
  ```
  https://app-btp-d-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback
  ```

#### Production Environment  
- **Environment Code:** `p`
- **Instance Number:** `001` (default)
- **Redirect URI:** 
  ```
  https://app-btp-p-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback
  ```

### Custom Configurations

#### Different Instance Numbers
If using instance number `002`, `003`, etc.:
```
https://app-btp-p-copa-stop-search-002.azurewebsites.net/.auth/login/aad/callback
https://app-btp-p-copa-stop-search-003.azurewebsites.net/.auth/login/aad/callback
```

#### Custom App Service Names
If using the `backendServiceName` parameter with a custom name:
```
https://{your-custom-name}.azurewebsites.net/.auth/login/aad/callback
```

### Important Notes

1. **Exact Path Required**: The callback path `/.auth/login/aad/callback` is mandatory and must be exactly as shown
2. **HTTPS Only**: All URIs must use HTTPS protocol
3. **Case Sensitive**: The path is case-sensitive
4. **Single URI**: You only need to add one redirect URI per environment
5. **Preview Domains**: If you're using deployment slots, the format would be:
   ```
   https://{app-service-name}-{slot-name}.azurewebsites.net/.auth/login/aad/callback
   ```

### Where to Add This

**In Azure Portal:**
1. Azure Active Directory → App registrations → Your App
2. Authentication → Platform configurations → Web
3. Add the redirect URI in the "Redirect URIs" field

**In Azure CLI:**
```bash
az ad app create \
  --display-name "CoPA-Stop-Search-Prod-001" \
  --web-redirect-uris "https://app-btp-p-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback"
```

### Troubleshooting

**Common Issues:**
- ❌ Missing `/.auth/login/aad/callback` path
- ❌ Using HTTP instead of HTTPS  
- ❌ Incorrect environment code (`d` vs `p`)
- ❌ Wrong instance number
- ❌ Typos in the domain name

**Validation:**
The final deployed app service URL should match your redirect URI exactly (minus the callback path).