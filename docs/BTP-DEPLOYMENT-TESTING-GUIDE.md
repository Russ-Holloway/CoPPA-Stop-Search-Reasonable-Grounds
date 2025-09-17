# BTP Deployment Testing Guide

This guide provides multiple approaches to test your CoPA Stop & Search solution deployment to the BTP tenant, including options that work with Conditional Access (CA) policies.

## Overview

Your CoPA Stop & Search solution is now configured with:
- ✅ BTP naming convention (`rg-btp-p-copa-stop-search`, `app-btp-p-copa-stop-search-001`)
- ✅ Comprehensive security (private endpoints, VNET integration, NSGs)
- ✅ UK 14 Cloud Security Principles compliance
- ✅ Microsoft CAF alignment
- ✅ Updated DevOps pipelines

## Testing Options

### Option 1: Validation Without Azure Authentication (CA Policy Safe)

If you can't sign into Azure due to CA policies, start with this validation:

```bash
# Run infrastructure validation (no Azure auth required)
./scripts/validate-btp-infrastructure.sh
```

**What this does:**
- ✅ Validates all Bicep templates compile correctly
- ✅ Runs Bicep linting for best practices
- ✅ Verifies BTP naming convention is properly implemented
- ✅ Analyzes security configuration
- ✅ Generates validation report
- ✅ No Azure authentication required

### Option 2: Full BTP Deployment Test (Requires Azure Auth)

When you can authenticate to Azure, use the full deployment script:

```bash
# Linux/macOS
./scripts/btp-deployment-test.sh

# Windows PowerShell
.\scripts\btp-deployment-test.ps1
```

**What this does:**
- ✅ All validation from Option 1
- ✅ Creates BTP resource group
- ✅ Runs What-If analysis to preview changes
- ✅ Validates deployment template with Azure
- ✅ Deploys all infrastructure with BTP naming
- ✅ Verifies all resources are created correctly
- ✅ Tests application health
- ✅ Generates deployment report

### Option 3: Azure DevOps Pipeline Deployment

Use the updated DevOps pipelines for automated deployment:

1. **BTP-Specific Pipeline:**
   ```bash
   # Trigger the BTP deployment pipeline
   .azure-pipelines/btp-deployment-pipeline.yml
   ```

2. **Main DevOps Pipeline:**
   ```bash
   # Use the updated main pipeline
   azure-pipelines.yml
   ```

### Option 4: Manual Azure CLI Commands (CA Policy Workarounds)

If interactive login fails, try these CA policy workarounds:

```bash
# Device code flow (often works with CA policies)
az login --use-device-code

# Service Principal authentication (if configured)
az login --service-principal --username $APP_ID --password $PASSWORD --tenant $TENANT_ID

# Managed identity (if running on Azure VM)
az login --identity
```

## Step-by-Step Testing Process

### Step 1: Pre-deployment Validation

```bash
# 1. Validate infrastructure templates (no auth needed)
./scripts/validate-btp-infrastructure.sh

# 2. Check for any compilation errors
az bicep build --file infra/main.bicep --stdout > /dev/null
echo "Template compilation: $([[ $? -eq 0 ]] && echo "✅ SUCCESS" || echo "❌ FAILED")"
```

### Step 2: Authentication

Choose the method that works with your CA policies:

```bash
# Try standard login first
az login

# If that fails, try device code
az login --use-device-code

# Verify authentication
az account show
```

### Step 3: Set Subscription Context

```bash
# Set your BTP subscription
az account set --subscription "YOUR-BTP-SUBSCRIPTION-ID"

# Verify current context
az account show --query "{name:name, id:id, tenantId:tenantId}" --output table
```

### Step 4: Run What-If Analysis

```bash
# Preview what will be deployed
az deployment group what-if \
  --resource-group "rg-btp-p-copa-stop-search" \
  --template-file "infra/main.bicep" \
  --parameters "infra/main.parameters.json" \
    environmentCode="p" \
    instanceNumber="001"
```

### Step 5: Deploy Infrastructure

```bash
# Full deployment test
./scripts/btp-deployment-test.sh
```

### Step 6: Verify Deployment

```bash
# Check all resources were created
az resource list --resource-group "rg-btp-p-copa-stop-search" --output table

# Test specific resources
az webapp show --name "app-btp-p-copa-stop-search-001" --resource-group "rg-btp-p-copa-stop-search"
az cosmosdb show --name "cosmos-btp-p-copa-stop-search-001" --resource-group "rg-btp-p-copa-stop-search"
az search service show --name "srch-btp-p-copa-stop-search-001" --resource-group "rg-btp-p-copa-stop-search"
```

## Expected Resources

After successful deployment, you should see these resources with BTP naming:

### Core Infrastructure
- **Resource Group**: `rg-btp-p-copa-stop-search`
- **Virtual Network**: `vnet-btp-p-copa-stop-search-001`
- **Network Security Group**: `nsg-btp-p-copa-stop-search-001`

### Compute Services
- **App Service Plan**: `asp-btp-p-copa-stop-search-001`
- **App Service**: `app-btp-p-copa-stop-search-001`

### Data Services
- **Storage Account**: `stbtppcopastopsearch001`
- **Cosmos DB**: `cosmos-btp-p-copa-stop-search-001`
- **Azure Search**: `srch-btp-p-copa-stop-search-001`
- **Cognitive Services**: `cog-btp-p-copa-stop-search-001`

### Security Services
- **Key Vault**: `kv-btppcopastopsearch001`
- **Log Analytics**: `log-btp-p-copa-stop-search-001`

### Private Endpoints (7 total)
- `pe-storage-btp-p-copa-stop-search-001`
- `pe-cosmos-btp-p-copa-stop-search-001`
- `pe-cognitive-btp-p-copa-stop-search-001`
- `pe-search-btp-p-copa-stop-search-001`
- `pe-keyvault-btp-p-copa-stop-search-001`
- `pe-logs-btp-p-copa-stop-search-001`

## Troubleshooting

### CA Policy Issues

**Problem**: Can't sign in with `az login`
**Solutions**:
```bash
# Try device code flow
az login --use-device-code

# Use service principal if configured
az login --service-principal --username $APP_ID --password $PASSWORD --tenant $TENANT_ID
```

### Template Validation Errors

**Problem**: Bicep template doesn't compile
**Solution**:
```bash
# Check syntax
az bicep build --file infra/main.bicep

# Run linting
az bicep lint --file infra/main.bicep

# Check specific module
az bicep build --file infra/core/network/virtual-network.bicep
```

### Deployment Failures

**Problem**: Azure deployment fails
**Solutions**:
```bash
# Check deployment status
az deployment group show --resource-group "rg-btp-p-copa-stop-search" --name "DEPLOYMENT_NAME"

# Get deployment logs
az deployment operation group list --resource-group "rg-btp-p-copa-stop-search" --name "DEPLOYMENT_NAME"

# Run validation first
az deployment group validate --resource-group "rg-btp-p-copa-stop-search" --template-file "infra/main.bicep" --parameters "infra/main.parameters.json"
```

### Naming Convention Issues

**Problem**: Resource names don't follow BTP convention
**Solution**: Check parameters file and ensure:
```json
{
  "environmentCode": {"value": "p"},
  "instanceNumber": {"value": "001"}
}
```

## Security Validation

After deployment, verify security features:

```bash
# Check private endpoints are working
az network private-endpoint list --resource-group "rg-btp-p-copa-stop-search" --output table

# Verify NSG rules
az network nsg rule list --resource-group "rg-btp-p-copa-stop-search" --nsg-name "nsg-btp-p-copa-stop-search-001" --output table

# Test that public access is disabled
az storage account show --name "stbtppcopastopsearch001" --resource-group "rg-btp-p-copa-stop-search" --query "publicNetworkAccess"
```

## Application Testing

Once deployed, test the application:

```bash
# Get application URL
APP_URL=$(az webapp show --name "app-btp-p-copa-stop-search-001" --resource-group "rg-btp-p-copa-stop-search" --query "defaultHostName" --output tsv)

# Test application health
curl -I "https://$APP_URL"

# Test specific endpoints (adjust based on your application)
curl -s "https://$APP_URL/health" || echo "Health endpoint not available"
```

## Next Steps After Successful Deployment

1. **Configure Application Settings**: Update app service configuration with proper connection strings
2. **Set up Monitoring**: Configure alerts and dashboards in Azure Monitor
3. **Deploy Application Code**: Use Azure DevOps pipeline to deploy your application
4. **Security Testing**: Run penetration tests and vulnerability assessments
5. **User Acceptance Testing**: Have end users test the deployed application
6. **Documentation**: Update operational documentation with BTP-specific details

## Support and Resources

- **Azure CLI Authentication**: https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli
- **Conditional Access Troubleshooting**: https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/troubleshoot-conditional-access
- **Bicep Documentation**: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/
- **UK 14 Cloud Security Principles**: https://www.ncsc.gov.uk/collection/cloud-security

---

**Important**: Always test in a development environment first before deploying to production. The BTP tenant deployment should only be done after thorough testing and validation.