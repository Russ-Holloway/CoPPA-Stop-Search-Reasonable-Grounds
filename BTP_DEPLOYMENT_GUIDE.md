# 🚂 BTP Azure Deployment Guide

## Quick BTP Deployment

### Option 1: Deploy to Azure Button (Recommended)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FRuss-Holloway%2FCoPA-Stop-Search-Reasonable-Grounds%2Fmain%2Finfrastructure%2Fdeployment.json)

**Parameters for BTP:**
- **Force Code**: `btp`
- **Environment**: `prod`
- **Instance Number**: `01`

### Option 2: Azure CLI Deployment
```bash
# Set BTP deployment parameters
RESOURCE_GROUP="rg-btp-prod-01"
FORCE_CODE="btp"
ENVIRONMENT="prod"
INSTANCE_NUMBER="01"

# Create resource group (if needed)
az group create --name $RESOURCE_GROUP --location "UK South"

# Deploy the template
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file infrastructure/deployment.json \
    --parameters \
        ForceCode=$FORCE_CODE \
        EnvironmentSuffix=$ENVIRONMENT \
        InstanceNumber=$INSTANCE_NUMBER
```

### Option 3: PowerShell Deployment
```powershell
# Set BTP deployment parameters
$resourceGroupName = "rg-btp-prod-01"
$forceCode = "btp"
$environment = "prod"
$instanceNumber = "01"

# Create resource group (if needed)
New-AzResourceGroup -Name $resourceGroupName -Location "UK South"

# Deploy the template
New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "infrastructure/deployment.json" `
    -ForceCode $forceCode `
    -EnvironmentSuffix $environment `
    -InstanceNumber $instanceNumber
```

## 🏷️ BTP Resource Names Generated

When deployed with BTP parameters, you'll get:

| Resource Type | Generated Name | Purpose |
|---------------|----------------|---------|
| **Web App** | `app-btp-prod-01` | Main CoPA application |
| **Search Service** | `srch-btp-prod-01` | Azure AI Search |
| **OpenAI Service** | `cog-btp-prod-01` | Azure OpenAI |
| **Storage Account** | `stbtpprod01` | Document storage |
| **Key Vault** | `kv-btp-prod-01` | Secrets management |
| **App Insights** | `appi-btp-prod-01` | Monitoring |
| **Cosmos DB** | `cosmos-btp-prod-01` | Chat history |

## 🔐 BTP Security Features

- ✅ **PDS Compliant Naming** - All resources follow BTP standards
- ✅ **Managed Identity** - No stored credentials needed
- ✅ **Role-Based Access** - Proper RBAC assignments
- ✅ **Key Vault Integration** - Secure secret management
- ✅ **Network Security** - Configured for police environments

## 🚀 Deployment Process

1. **Create Resource Group**: `rg-btp-prod-01` in BTP Azure subscription
2. **Deploy Template**: Using one of the methods above
3. **Post-Deployment**: Automatic authentication setup runs
4. **Upload Documents**: Add BTP policies and procedures
5. **Test Application**: Verify CoPA is working correctly

## 📞 BTP Specific Configuration

The application will automatically:
- Use BTP branding and logos
- Apply BTP-specific search configurations
- Follow BTP data governance policies
- Integrate with BTP Azure AD

## 🛠️ DevOps Integration

If you want to use the DevOps pipeline for BTP:
1. **Update service connections** to point to BTP Azure subscription
2. **Update variable groups** (already configured for BTP)
3. **Run pipeline** → Automatic deployment to BTP environment

## ✅ Ready to Deploy!

Your application is fully prepared for British Transport Police deployment. All naming conventions, security settings, and configurations are already optimized for BTP!