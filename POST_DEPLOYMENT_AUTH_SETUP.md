# Post-Deployment Authentication Configuration

This guide explains how to configure Azure AD authentication after deploying your application to Azure. This approach allows you to deploy the application infrastructure first without requiring authentication secrets upfront.

## Overview

The deployment process has been modified to make authentication configuration a post-deployment step:

1. **Deploy Infrastructure**: Deploy the Azure resources (App Service, OpenAI, Search, etc.) without authentication
2. **Configure Authentication**: Run post-deployment scripts to set up Azure AD authentication
3. **Update App Configuration**: Apply the authentication settings to your deployed app

## Deployment Flow

### Option 1: Using Azure Developer CLI (azd) - Recommended

If you're using `azd up`, authentication will be automatically configured in the post-provisioning hooks:

```bash
# Deploy everything including post-deployment auth configuration
azd up
```

The `azure.yaml` file now runs authentication setup in the `postprovision` hooks, so no manual intervention is needed.

### Option 2: Manual Deployment with "Deploy to Azure" Button

If you're using the "Deploy to Azure" button or manual ARM/Bicep deployment:

1. **Deploy the template** - The auth client secret is now optional, so you can leave it empty or use a placeholder
2. **Run the post-deployment configuration script**:

   **Linux/macOS:**
   ```bash
   ./configure-auth.sh
   ```

   **Windows:**
   ```powershell
   .\configure-auth.ps1
   ```

### Option 3: Azure CLI Manual Deployment

```bash
# 1. Deploy the Bicep template (auth parameters are now optional)
az deployment sub create \
  --location "East US" \
  --template-file ./infra/main.bicep \
  --parameters ./infra/main.parameters.json \
  --parameters environmentName="myapp"

# 2. Configure authentication
./configure-auth.sh
```

## What Changed

### Template Parameters

The following parameters are now **optional** in the Bicep templates:

- `authClientId` - defaults to empty string
- `authClientSecret` - defaults to empty string

### Azure.yaml Hooks

Authentication setup has been moved from `preprovision` to `postprovision`:

```yaml
hooks:
    postprovision:
      posix:
        shell: sh
        run: ./scripts/auth_init.sh;./scripts/auth_update.sh;./scripts/prepdocs.sh;
```

### App Service Configuration

The app service will deploy without authentication initially. Authentication is configured after deployment through:

1. Creating/updating the Azure AD application registration
2. Updating the app service configuration with the new auth values
3. Enabling Azure AD authentication on the app service

## Manual Configuration Steps

If you need to configure authentication manually:

### 1. Create Azure AD Application

```bash
# Set environment variables
export AZURE_ENV_NAME="your-environment-name"
export AZURE_APP_SERVICE_URL="https://your-app.azurewebsites.net"

# Run auth initialization
python ./scripts/auth_init.py
```

### 2. Update App Service Configuration

```bash
# Run auth update to configure the deployed app
python ./scripts/auth_update.py
```

### 3. Verify Configuration

Check that the following app settings are configured in your App Service:

- `AUTH_CLIENT_ID`
- `AUTH_CLIENT_SECRET` 
- `AUTH_ISSUER_URI`

## Environment Variables

The following environment variables are used during configuration:

| Variable | Description | Required |
|----------|-------------|----------|
| `AZURE_ENV_NAME` | Environment name used in deployment | Yes |
| `AZURE_APP_SERVICE_URL` | URL of the deployed app service | Yes* |
| `AUTH_APP_ID` | Existing Azure AD application ID (optional) | No |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | Yes |
| `AZURE_TENANT_ID` | Azure AD tenant ID | Yes |

*Auto-detected if not provided and Azure CLI is available

## Troubleshooting

### Common Issues

1. **"AUTH_CLIENT_SECRET is required"**
   - The deployment template still requires the secret
   - Solution: Ensure you're using the updated Bicep templates where these parameters are optional

2. **"Cannot find app service URL"**
   - The post-deployment script cannot determine the app URL
   - Solution: Set `AZURE_APP_SERVICE_URL` environment variable manually

3. **"Azure AD application not found"**
   - The auth configuration failed to create the AD application
   - Solution: Check Azure CLI is authenticated and has sufficient permissions

### Debug Steps

1. Verify environment variables are set:
   ```bash
   echo $AZURE_ENV_NAME
   echo $AZURE_APP_SERVICE_URL
   ```

2. Check Azure CLI authentication:
   ```bash
   az account show
   ```

3. Verify app service deployment:
   ```bash
   az webapp list --query "[].{name:name,url:defaultHostName}"
   ```

4. Check app service configuration:
   ```bash
   az webapp config appsettings list --name <app-name> --resource-group <resource-group>
   ```

## Security Considerations

- Authentication secrets are now created after deployment, reducing the risk of exposing them during deployment
- The Azure AD application is configured with the minimum required permissions
- Client secrets have appropriate expiration dates set
- All authentication traffic uses HTTPS

## Next Steps

After authentication is configured:

1. Test sign-in functionality at your app URL
2. Verify user roles and permissions are working correctly
3. Review the authentication logs in Azure AD
4. Set up any additional security policies as needed

For more details on the authentication implementation, see the `/scripts/auth_*.py` files.
