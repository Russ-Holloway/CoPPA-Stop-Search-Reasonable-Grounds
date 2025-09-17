# BTP Tenant Deployment Guide - Security Compliant Version

## Overview
This guide provides step-by-step instructions for deploying the security-compliant CoPA Stop & Search solution to a BTP (Business Technology Platform) tenant. The deployment includes comprehensive network security, private endpoints, and compliance with UK 14 Cloud Security Principles.

## Prerequisites

### 1. Azure CLI and Tools
```bash
# Install Azure CLI (if not already installed)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Azure Developer CLI
curl -fsSL https://aka.ms/install-azd.sh | bash

# Login to Azure
az login
```

### 2. Required Permissions
- **Subscription Contributor** or **Owner** role
- **Application Administrator** role in Azure AD (for app registration)
- Access to BTP tenant subscription

### 3. Environment Variables
Create a `.env` file in the project root:
```bash
# Core Configuration
AZURE_ENV_NAME=copa-btp-prod
AZURE_LOCATION=uksouth
AZURE_SUBSCRIPTION_ID=<your-subscription-id>
AZURE_TENANT_ID=<your-tenant-id>

# Authentication
AUTH_CLIENT_ID=<your-app-registration-client-id>
AUTH_CLIENT_SECRET=<your-app-registration-secret>

# Network Security Configuration
ENABLE_PRIVATE_ENDPOINTS=true
VNET_ADDRESS_PREFIX=10.0.0.0/16
APP_SERVICE_SUBNET_ADDRESS_PREFIX=10.0.1.0/24
PRIVATE_ENDPOINT_SUBNET_ADDRESS_PREFIX=10.0.2.0/24

# Optional: Custom Resource Names
AZURE_KEYVAULT_NAME=kv-copa-btp-prod
AZURE_LOG_ANALYTICS_WORKSPACE_NAME=log-copa-btp-prod
```

## Deployment Steps

### Step 1: Initialize AZD Environment
```bash
# Navigate to project directory
cd /path/to/CoPA-Stop-Search-Reasonable-Grounds

# Initialize environment
azd env new copa-btp-prod

# Set environment variables
azd env set AZURE_LOCATION uksouth
azd env set ENABLE_PRIVATE_ENDPOINTS true
azd env set VNET_ADDRESS_PREFIX 10.0.0.0/16
azd env set APP_SERVICE_SUBNET_ADDRESS_PREFIX 10.0.1.0/24
azd env set PRIVATE_ENDPOINT_SUBNET_ADDRESS_PREFIX 10.0.2.0/24
```

### Step 2: Validate Configuration
```bash
# Check environment configuration
azd env get-values

# Validate Bicep templates
az deployment sub validate --location uksouth --template-file infra/main.bicep --parameters infra/main.parameters.json
```

### Step 3: Deploy Infrastructure
```bash
# Provision Azure resources with security controls
azd provision

# This will create:
# - Resource Group
# - Virtual Network with secure subnets
# - Network Security Groups
# - Private Endpoints for all services
# - Key Vault with private access
# - Log Analytics Workspace
# - App Service with VNET integration
# - Storage Account (private access only)
# - Cosmos DB (private access only)
# - Cognitive Services (private access only)
# - Azure Search Service (private access only)
```

### Step 4: Deploy Application
```bash
# Deploy the application code
azd deploy

# This will:
# - Build and package the application
# - Deploy to App Service
# - Configure application settings
# - Set up authentication
```

### Step 5: Verify Security Configuration
```bash
# Run the security validation script
./scripts/validate-security-compliance.sh <resource-group-name> <subscription-id>

# Example:
./scripts/validate-security-compliance.sh rg-copa-btp-prod 12345678-1234-1234-1234-123456789012
```

## Post-Deployment Configuration

### 1. Application Registration Setup
If you haven't already created an app registration:

```bash
# Create app registration
az ad app create --display-name "CoPA-StopSearch-BTP" \
  --web-redirect-uris "https://<your-app-service>.azurewebsites.net/.auth/login/aad/callback" \
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
  ]'

# Create client secret
az ad app credential reset --id <app-id>
```

### 2. Update App Service Authentication
```bash
# Configure authentication
az webapp auth update --name <app-service-name> \
  --resource-group <resource-group> \
  --enabled true \
  --action LoginWithAzureActiveDirectory \
  --aad-client-id <client-id> \
  --aad-client-secret <client-secret> \
  --aad-token-issuer-url "https://login.microsoftonline.com/<tenant-id>/v2.0"
```

### 3. Configure Network Access
```bash
# Verify private endpoints are working
az network private-endpoint list --resource-group <resource-group>

# Test connectivity from App Service to private services
az webapp ssh --name <app-service-name> --resource-group <resource-group>
# In the SSH session:
curl -I https://<storage-account>.blob.core.windows.net/
```

## Security Verification Checklist

After deployment, verify the following security controls:

### ✅ Network Security
- [ ] All services have public network access disabled
- [ ] Private endpoints are created and connected
- [ ] VNET integration is working for App Service
- [ ] NSG rules are correctly configured
- [ ] Private DNS zones are resolving correctly

### ✅ Service Security
- [ ] Storage Account: `publicNetworkAccess = "Disabled"`
- [ ] Cosmos DB: `publicNetworkAccess = "Disabled"`
- [ ] Cognitive Services: Public access disabled
- [ ] Key Vault: Public access disabled
- [ ] Search Service: Public access disabled

### ✅ Authentication & Authorization
- [ ] App Service authentication is configured
- [ ] Managed identities are assigned
- [ ] RBAC roles are properly configured
- [ ] Key Vault access policies are set

### ✅ Monitoring & Logging
- [ ] Log Analytics workspace is configured
- [ ] Application Insights is connected
- [ ] Diagnostic settings are enabled
- [ ] Security logs are being collected

## Testing the Deployment

### 1. Application Functionality Test
```bash
# Get the app URL
APP_URL=$(az webapp show --name <app-service-name> --resource-group <resource-group> --query defaultHostName -o tsv)

# Test the application
curl -I https://$APP_URL
```

### 2. Authentication Test
1. Open the application in a browser
2. Verify you're redirected to Microsoft login
3. Complete authentication
4. Ensure you can access the application

### 3. Network Security Test
```bash
# Try to access services directly (should fail)
curl -I https://<storage-account>.blob.core.windows.net/
# Expected: Connection timeout or access denied

# Verify private endpoint connectivity works from App Service
az webapp ssh --name <app-service-name> --resource-group <resource-group>
```

## Troubleshooting

### Common Issues

#### 1. Private Endpoint DNS Resolution
```bash
# Check DNS resolution
nslookup <storage-account>.blob.core.windows.net

# Should resolve to private IP (10.0.x.x)
```

#### 2. VNET Integration Issues
```bash
# Check VNET integration status
az webapp vnet-integration list --name <app-service> --resource-group <resource-group>

# Re-enable if needed
az webapp vnet-integration add --name <app-service> --resource-group <resource-group> --vnet <vnet-name> --subnet app-service-subnet
```

#### 3. Authentication Issues
```bash
# Check authentication configuration
az webapp auth show --name <app-service> --resource-group <resource-group>

# Update redirect URI in app registration
az ad app update --id <app-id> --web-redirect-uris "https://<app-service>.azurewebsites.net/.auth/login/aad/callback"
```

## Monitoring and Maintenance

### 1. Security Monitoring
```bash
# Check security center recommendations
az security assessment list

# Review Key Vault access logs
az monitor activity-log list --resource-group <resource-group> --resource-type "Microsoft.KeyVault/vaults"
```

### 2. Performance Monitoring
- Monitor application performance through Application Insights
- Review Log Analytics queries for performance issues
- Set up alerts for service availability

### 3. Regular Security Reviews
- Run the validation script monthly
- Review access logs weekly
- Update security configurations as needed

## Support and Documentation

- **Security Implementation**: See `SECURITY-COMPLIANCE-IMPLEMENTATION.md`
- **Validation Script**: Use `scripts/validate-security-compliance.sh`
- **Azure Documentation**: [Azure Private Link Documentation](https://docs.microsoft.com/azure/private-link/)

## Rollback Procedure

If deployment fails or issues arise:

```bash
# Get deployment history
az deployment group list --resource-group <resource-group>

# Rollback to previous version
azd down --force --purge

# Redeploy previous version
git checkout <previous-commit>
azd up
```

---
*Document Version: 1.0*  
*Last Updated: September 2025*  
*Classification: Official*