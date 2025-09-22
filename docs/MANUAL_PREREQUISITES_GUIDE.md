# Manual Prerequisites Setup Guide

This guide provides step-by-step instructions for setting up the required prerequisites before deploying the CoPA Stop & Search application using Azure DevOps pipelines.

## Overview

The manual prerequisites approach provides better security, reliability, and compliance by:
- Eliminating permission issues with automated app registration creation
- Providing full control over authentication configuration  
- Enabling custom branding through pre-uploaded logo files
- Ensuring storage account compliance with organizational policies

## Prerequisites Required

1. **Azure AD App Registration** - For authentication
2. **Azure Storage Account** - For file storage and branding
3. **Pipeline Variables** - To connect prerequisites with deployment

---

## Part 1: Azure AD App Registration Setup

### Option A: Using Azure Portal (Recommended for Production)

1. **Navigate to Azure Portal**
   - Go to [https://portal.azure.com](https://portal.azure.com)
   - Navigate to **Azure Active Directory** > **App registrations**

2. **Create New Registration**
   - Click **"New registration"**
   - Configure as follows:
     - **Name**: `CoPA-Stop-Search-Dev-001` (for development) or `CoPA-Stop-Search-Prod-001` (for production)
     - **Supported account types**: "Accounts in this organizational directory only"
     - **Redirect URI**: 
       - Platform: **Web**
       - URI: See **Redirect URI Format** section below

### 🔗 Redirect URI Format

The redirect URI follows the pattern: `https://{app-service-name}.azurewebsites.net/.auth/login/aad/callback`

**For Development Environment:**
- Format: `https://app-btp-d-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback`
- Replace `001` with your instance number if different

**For Production Environment:**  
- Format: `https://app-btp-p-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback`
- Replace `001` with your instance number if different

**Custom App Service Name:**
If you're using a custom `backendServiceName` parameter, use:
- `https://{your-custom-name}.azurewebsites.net/.auth/login/aad/callback`

**Important:** The callback path `/.auth/login/aad/callback` is required by Azure App Service authentication and must be exact.

3. **Create Client Secret**
   - In the app registration, go to **"Certificates & secrets"**
   - Click **"New client secret"**
   - **Description**: `CoPA Production Secret` (for production) or `CoPA Dev Secret` (for development)
     - Note: This description can be anything - it doesn't need to match environment variable names
   - **Expires**: Select appropriate duration (24 months recommended)
   - **Copy the secret value immediately** - you won't see it again!

4. **Record Required Values**
   - **Application (client) ID**: From the app registration overview page
   - **Client Secret Value**: The actual secret value (not the description)
   - **Directory (tenant) ID**: From the app registration overview page

### Option B: Using Azure CLI

```bash
# Set environment variables
ENVIRONMENT="dev"  # or "prod"
APP_NAME="CoPA-Stop-Search-${ENVIRONMENT^}-001"
REDIRECT_URI="https://app-btp-${ENVIRONMENT:0:1}-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback"

# Create app registration
az ad app create \
  --display-name "$APP_NAME" \
  --web-redirect-uris "$REDIRECT_URI" \
  --required-resource-accesses '[
    {
      "resourceAppId": "00000003-0000-0000-c000-000000000000",
      "resourceAccess": [
        {
          "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d",
          "type": "Scope"
        }
      ]
    }
  ]' \
  --query "appId" -o tsv

# Store the returned Application ID for later use
APP_ID="<APPLICATION_ID_FROM_ABOVE>"

# Create client secret
az ad app credential reset \
  --id "$APP_ID" \
  --append \
  --display-name "CoPA Application Secret" \
  --query "password" -o tsv
```

---

## Part 2: Azure Storage Account Setup

### Option A: Using Azure Portal

1. **Create Storage Account**
   - Navigate to **Storage accounts** > **Create**
   - Configure as follows:
     - **Resource group**: `rg-btp-d-copa-stop-search` (dev) or `rg-btp-p-copa-stop-search` (prod)
     - **Storage account name**: Follow BTP naming: `stbtpdcopasss001` (dev) or `stbtppcopasss001` (prod)
     - **Region**: UK South
     - **Performance**: Standard
     - **Redundancy**: LRS (or as per organizational requirements)

2. **Create Required Containers**
   - In the storage account, navigate to **Data storage** > **Containers**
   - Create the following containers (all with **Private** access level):
     - `ai-library-stop-search`
     - `web-app-logos` 
     - `content`

### Option B: Using Azure CLI

```bash
# Set variables
ENVIRONMENT="dev"  # or "prod" 
RESOURCE_GROUP="rg-btp-${ENVIRONMENT:0:1}-copa-stop-search"
STORAGE_ACCOUNT="stbtp${ENVIRONMENT:0:1}copasss001"
LOCATION="uksouth"

# Create resource group if it doesn't exist
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags \
    Owner="DevOps-Pipeline" \
    CostCentre="IT-001" \
    ForceID="BTP" \
    ServiceName="CoPA-Stop-Search" \
    LocationID="UK-South" \
    Environment="${ENVIRONMENT^}"

# Create storage account
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku "Standard_LRS" \
  --kind "StorageV2" \
  --access-tier "Hot" \
  --https-only true \
  --allow-blob-public-access false

# Create required containers
az storage container create --name "ai-library-stop-search" --account-name "$STORAGE_ACCOUNT"
az storage container create --name "web-app-logos" --account-name "$STORAGE_ACCOUNT"  
az storage container create --name "content" --account-name "$STORAGE_ACCOUNT"

echo "Storage account created: $STORAGE_ACCOUNT"
```

---

## Part 3: Logo Files Setup (Optional but Recommended)

Upload custom branding files to enable automatic logo configuration:

### Required Logo Files

1. **copa-logo.png**
   - Recommended size: 200x50 pixels
   - Format: PNG with transparent background
   - Usage: Main application logo

2. **police-force-logo.png**
   - Recommended size: 100x100 pixels  
   - Format: PNG with transparent background
   - Usage: Police force specific branding

3. **favicon.ico**
   - Size: 32x32 pixels (or multi-size ICO)
   - Format: ICO file
   - Usage: Browser favicon

### Upload via Azure Portal

1. Navigate to your storage account
2. Go to **Data storage** > **Containers** > **web-app-logos**
3. Click **Upload** and select each logo file
4. Ensure **Access tier** is set to **Hot**

### Upload via Azure CLI

```bash
# Upload logo files (adjust paths to your files)
az storage blob upload \
  --file "./logos/copa-logo.png" \
  --container "web-app-logos" \
  --name "copa-logo.png" \
  --account-name "$STORAGE_ACCOUNT"

az storage blob upload \
  --file "./logos/police-force-logo.png" \
  --container "web-app-logos" \
  --name "police-force-logo.png" \
  --account-name "$STORAGE_ACCOUNT"

az storage blob upload \
  --file "./logos/favicon.ico" \
  --container "web-app-logos" \
  --name "favicon.ico" \
  --account-name "$STORAGE_ACCOUNT"
```

### Automatic Logo URL Generation

The Bicep template automatically generates logo URLs using this pattern:
```
https://{storageAccountName}.blob.core.windows.net/web-app-logos/{filename}
```

These URLs are automatically configured in the web application environment variables:
- `UI_LOGO` -> copa-logo.png
- `UI_POLICE_FORCE_LOGO` -> police-force-logo.png  
- `UI_FAVICON` -> favicon.ico

---

## Part 4: Pipeline Configuration

### Update Parameter Files

1. **Development Environment**
   - File: `infra/main.prerequisites.parameters.json`
   - Update these values:
     ```json
     {
       "authClientId": { "value": "YOUR_APP_REGISTRATION_CLIENT_ID" },
       "storageAccountName": { "value": "stbtpdcopasss001" }
     }
     ```

2. **Production Environment**  
   - File: `infra/main.prerequisites.production.parameters.json`
   - Update these values:
     ```json
     {
       "authClientId": { "value": "YOUR_PROD_APP_REGISTRATION_CLIENT_ID" },
       "storageAccountName": { "value": "stbtppcopasss001" }
     }
     ```

### Configure Pipeline Variables

Set these variables in your Azure DevOps pipeline variable groups:

#### Development Variables (`copa-stop-search-dev-variables`)
- `AUTH_CLIENT_ID`: Application ID from app registration
- `AUTH_CLIENT_SECRET`: Client secret value (mark as **Secret**)
- `STORAGE_ACCOUNT_NAME`: `stbtpdcopasss001` (optional - can be in parameters file)

#### Production Variables (`copa-stop-search-prod-variables`)  
- `AUTH_CLIENT_ID`: Production application ID from app registration
- `AUTH_CLIENT_SECRET`: Production client secret value (mark as **Secret**)
- `STORAGE_ACCOUNT_NAME`: `stbtppcopasss001` (optional - can be in parameters file)

---

## Part 5: Deployment Process

### Run the Pipeline

1. **Commit Changes**
   - Ensure parameter files are updated with correct values
   - Commit and push to your repository

2. **Execute Pipeline**
   - The pipeline will now use the manual prerequisites
   - No app registration creation tasks will run
   - Storage account creation will be skipped
   - Logo URLs will be automatically configured

3. **Monitor Deployment**
   - Check pipeline logs for authentication warnings
   - Verify web application starts successfully  
   - Test login functionality

### Verification Steps

After deployment, verify the setup:

```bash
# Check app registration redirect URI
az ad app show --id "YOUR_APP_ID" --query "web.redirectUris"

# Check storage containers exist
az storage container list --account-name "YOUR_STORAGE_ACCOUNT" --query "[].name"

# Check logo files exist
az storage blob list --container "web-app-logos" --account-name "YOUR_STORAGE_ACCOUNT" --query "[].name"

# Test web application
curl -I https://app-btp-d-copa-stop-search-001.azurewebsites.net
```

---

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify `AUTH_CLIENT_ID` and `AUTH_CLIENT_SECRET` are correctly set
   - Check redirect URI matches exactly (including trailing slash)
   - Ensure app registration has correct API permissions

2. **Storage Access Issues**  
   - Verify storage account name matches parameter file
   - Check containers were created with correct names
   - Ensure storage account allows required access patterns

3. **Logo Display Issues**
   - Verify logo files exist in `web-app-logos` container
   - Check file names match exactly (case-sensitive)
   - Confirm storage account blob access is configured

### Pipeline Variable Troubleshooting

If authentication issues persist:

```bash
# Check current pipeline variables (in Azure DevOps)
echo "AUTH_CLIENT_ID: $(AUTH_CLIENT_ID)"
echo "AUTH_CLIENT_SECRET: ***" # Never log the actual secret
echo "STORAGE_ACCOUNT_NAME: $(STORAGE_ACCOUNT_NAME)"
```

### Getting Help

- Check Azure DevOps pipeline logs for detailed error messages
- Review Azure Portal app registration and storage account settings
- Verify all prerequisite steps were completed in order
- Test prerequisites independently before running full deployment

---

## Security Best Practices

1. **Secrets Management**
   - Always mark `AUTH_CLIENT_SECRET` as **Secret** in pipeline variables
   - Use different app registrations for development and production
   - Rotate client secrets regularly (every 12-24 months)

2. **Storage Security**
   - Use private containers only
   - Enable storage account firewall if required by organization
   - Consider using managed identities for storage access

3. **Access Control**
   - Limit app registration permissions to minimum required
   - Use separate Azure subscriptions for dev/prod if possible
   - Implement proper RBAC on storage accounts

4. **Monitoring**
   - Enable logging on app registrations
   - Monitor storage account access patterns
   - Set up alerts for authentication failures

---

This completes the manual prerequisites setup. Once all prerequisites are in place, the Azure DevOps pipeline will deploy the infrastructure and application using your pre-created authentication and storage resources.

#### **Development Environment**
1. **Create Storage Account**:
   - Go to [Azure Portal](https://portal.azure.com) → Storage accounts
   - Click **"Create"**
   - **Subscription**: Select appropriate subscription
   - **Resource Group**: `rg-btp-d-copa-stop-search` (create if it doesn't exist)
   - **Storage account name**: `stbtpdcopastopsearch001` (must be globally unique)
   - **Region**: UK South
   - **Performance**: Standard
   - **Redundancy**: LRS (Locally-redundant storage) for dev
   - **Access tier**: Hot

2. **Configure Required Tags**:
   - **Owner**: `DevOps-Pipeline`
   - **CostCentre**: `IT-001`
   - **ForceID**: `BTP`
   - **ServiceName**: `CoPA-Stop-Search`
   - **LocationID**: `UK-South`
   - **Environment**: `Development`

3. **Create Required Containers**:
   Navigate to your storage account → Containers, then create:
   
   | Container Name | Public Access Level | Purpose |
   |---|---|---|
   | `ai-library-stop-search` | Private | AI training documents and knowledge base |
   | `web-app-logos` | Private | Police force logos and branding assets |
   | `content` | Private | General application content and uploads |

4. **Upload Logo Assets** (to `web-app-logos` container):
   - `copa-logo.png` - Main application logo
   - `police-force-logo.png` - Your police force logo/badge  
   - `favicon.ico` - Browser favicon
   - **Note**: The deployment will automatically configure these URLs in the web app

5. **Set Container Properties**:
   - All containers should be **Private** (no anonymous read access)
   - Enable **Container-level public access** = **Disabled**

---

## Logo and Branding Setup

### **Required Logo Files**
Upload these files to the `web-app-logos` container in your storage account:

| File Name | Purpose | Recommended Size | Format |
|---|---|---|---|
| `copa-logo.png` | Main application logo | 200x60px | PNG with transparency |
| `police-force-logo.png` | Police force badge/logo | 100x100px | PNG with transparency |
| `favicon.ico` | Browser tab icon | 32x32px | ICO format |

### **Logo File Guidelines**
- **Format**: PNG for logos (supports transparency), ICO for favicon
- **Quality**: High resolution for crisp display on all devices
- **Background**: Transparent background recommended for logos
- **Naming**: Use exact filenames as shown - case sensitive
- **Access**: Files should be uploaded to private container (deployment handles access)

### **Automatic Configuration**
The deployment will automatically configure these environment variables:
- `UI_LOGO`: Points to `copa-logo.png` in your storage
- `UI_POLICE_FORCE_LOGO`: Points to `police-force-logo.png`  
- `UI_FAVICON`: Points to `favicon.ico`

**No manual URL configuration needed** - the Bicep template builds the URLs automatically.

---

#### **Production Environment**
1. **Create Storage Account**:
   - **Storage account name**: `stbtppcopastopsearch001`
   - **Resource Group**: `rg-btp-p-copa-stop-search`
   - **Redundancy**: ZRS (Zone-redundant storage) for production
   - Same containers as development
   - **Environment** tag: `Production`

### ✅ **Prerequisite 3: Pipeline Variables Configuration**

#### **Development Variables** (Variable Group: `copa-stop-search-dev-variables`)
Set these variables in Azure DevOps Library:

| Variable Name | Value | Secret | Description |
|---|---|---|---|
| `AUTH_CLIENT_ID` | `[App Registration Client ID]` | No | From Step 1 - Development App Registration |
| `AUTH_CLIENT_SECRET` | `[Client Secret Value]` | **Yes** | From Step 1 - Mark as secret |
| `STORAGE_ACCOUNT_NAME` | `stbtpdcopastopsearch001` | No | From Step 2 - Development Storage |
| `STORAGE_ACCOUNT_RESOURCE_GROUP` | `rg-btp-d-copa-stop-search` | No | Resource group containing storage |

#### **Production Variables** (Variable Group: `copa-stop-search-prod-variables`)  
| Variable Name | Value | Secret | Description |
|---|---|---|---|
| `AUTH_CLIENT_ID` | `[Prod App Registration Client ID]` | No | From Step 1 - Production App Registration |
| `AUTH_CLIENT_SECRET` | `[Prod Client Secret Value]` | **Yes** | From Step 1 - Mark as secret |
| `STORAGE_ACCOUNT_NAME` | `stbtppcopastopsearch001` | No | From Step 2 - Production Storage |
| `STORAGE_ACCOUNT_RESOURCE_GROUP` | `rg-btp-p-copa-stop-search` | No | Resource group containing storage |

---

## Parameter Files Configuration

### **Step 4: Update Parameter Files**

#### **Development Parameters** (`infra/main.devops.parameters.json`)
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "development"
    },
    "location": {
      "value": "uksouth"
    },
    "environmentCode": {
      "value": "d"
    },
    "createAppRegistration": {
      "value": false
    },
    "createStorageAccount": {
      "value": false
    },
    "authClientId": {
      "value": "$(AUTH_CLIENT_ID)"
    },
    "authClientSecret": {
      "value": "$(AUTH_CLIENT_SECRET)"
    },
    "storageAccountName": {
      "value": "$(STORAGE_ACCOUNT_NAME)"
    },
    "ownerTag": {
      "value": "DevOps-Pipeline"
    },
    "costCentreTag": {
      "value": "IT-001"
    },
    "forceIdTag": {
      "value": "BTP"
    },
    "locationIdTag": {
      "value": "UK-South"
    },
    "environmentTag": {
      "value": "Development"
    }
  }
}
```

#### **Production Parameters** (`infra/main.production.parameters.json`)
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "production"
    },
    "location": {
      "value": "uksouth"
    },
    "environmentCode": {
      "value": "p"
    },
    "createAppRegistration": {
      "value": false
    },
    "createStorageAccount": {
      "value": false
    },
    "authClientId": {
      "value": "$(AUTH_CLIENT_ID)"
    },
    "authClientSecret": {
      "value": "$(AUTH_CLIENT_SECRET)"
    },
    "storageAccountName": {
      "value": "$(STORAGE_ACCOUNT_NAME)"
    },
    "ownerTag": {
      "value": "Production-Team"
    },
    "costCentreTag": {
      "value": "IT-001"
    },
    "forceIdTag": {
      "value": "BTP"
    },
    "locationIdTag": {
      "value": "UK-South"
    },
    "environmentTag": {
      "value": "Production"
    }
  }
}
```

---

## Validation Steps

### **Before Running Pipeline**
1. ✅ **App Registration Created**: Verify Client ID and Secret are available
2. ✅ **Storage Account Accessible**: Check containers exist and are private
3. ✅ **Pipeline Variables Set**: Confirm all variables are configured in Azure DevOps
4. ✅ **Parameter Files Updated**: Check createAppRegistration and createStorageAccount are false

### **After Deployment**
1. **Test Authentication**: Verify the web app redirects to Azure AD login
2. **Check Storage Integration**: Confirm the app can access storage containers
3. **Validate Logos**: Test custom police force logo functionality
4. **Verify AI Library**: Check document upload and AI responses work

---

## Troubleshooting

### **Common Issues**

#### **Authentication Not Working**
- Check AUTH_CLIENT_ID matches the Application ID in Azure AD
- Verify AUTH_CLIENT_SECRET is not expired
- Confirm redirect URI matches exactly (including trailing slash)

#### **Storage Access Errors**  
- Verify storage account name is correct and accessible
- Check all three containers exist: `ai-library-stop-search`, `web-app-logos`, `content`
- Confirm App Service managed identity has Storage Blob Data Contributor role

#### **Pipeline Variables Not Found**
- Check variable group names match exactly: `copa-stop-search-dev-variables`
- Verify variables are not marked as secret when they should be accessible
- Confirm AUTH_CLIENT_SECRET is marked as secret

---

## Security Considerations

1. **Secrets Management**: 
   - Client secrets should only be stored in Azure DevOps variable groups
   - Mark sensitive values as secret
   - Rotate client secrets every 24 months

2. **Storage Security**:
   - All containers must remain private
   - Enable audit logging on storage accounts
   - Consider enabling encryption at rest

3. **Access Control**:
   - Limit who can modify app registrations
   - Use separate resource groups for dev/prod
   - Implement proper RBAC on storage accounts

---

## Migration from Automated Approach

If you're currently using automated app registration creation:

1. **Create manual prerequisites** following this guide
2. **Update parameter files** to disable creation (`createAppRegistration: false`)
3. **Set pipeline variables** with existing app registration details  
4. **Test deployment** in development environment first
5. **Remove app registration tasks** from pipeline (optional)

---

## Support

For issues with this deployment approach:
- Check Azure DevOps pipeline logs for specific error messages
- Review parameter files for typos or incorrect references
- Verify all prerequisites were completed as documented
- Test resource access using Azure CLI or PowerShell before deployment

Remember: This approach prioritizes security and reliability over automation. The extra manual steps ensure production-ready, compliant deployments.