# 🚔 Derbyshire Police CoPA Deployment Guide

## Overview
Complete deployment guide for deploying CoPA (College of Policing Assistant) to **Derbyshire Constabulary** with force code `DER`.

## 🎯 Quick Deployment for Derbyshire Police

### Option 1: Deploy to Azure Button (Recommended)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FRuss-Holloway%2FCoPA-Stop-Search-Reasonable-Grounds%2Fmain%2Finfrastructure%2Fdeployment.json)

**Derbyshire Parameters:**
- **Force Code**: `der`
- **Environment**: `prod`
- **Instance Number**: `01`
- **Location**: `UK South` (recommended)

### Option 2: Azure CLI Deployment
```bash
# Derbyshire Police deployment parameters
RESOURCE_GROUP="rg-der-prod-01"
FORCE_CODE="der"
ENVIRONMENT="prod"
INSTANCE_NUMBER="01"
LOCATION="uksouth"

# Create resource group
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Deploy CoPA for Derbyshire
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
# Derbyshire Police deployment parameters
$resourceGroupName = "rg-der-prod-01"
$forceCode = "der"
$environment = "prod"
$instanceNumber = "01"
$location = "UK South"

# Create resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Deploy CoPA for Derbyshire
New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "infrastructure/deployment.json" `
    -ForceCode $forceCode `
    -EnvironmentSuffix $environment `
    -InstanceNumber $instanceNumber
```

## 🏷️ Derbyshire Resource Names

All resources will be automatically named with PDS-compliant conventions:

| Resource Type | Generated Name | Purpose |
|---------------|----------------|---------|
| **Web App** | `app-der-prod-01` | Main CoPA application |
| **Search Service** | `srch-der-prod-01` | Azure AI Search |
| **OpenAI Service** | `cog-der-prod-01` | Azure OpenAI GPT models |
| **Storage Account** | `stderprod01` | Document storage |
| **Key Vault** | `kv-der-prod-01` | Secrets management |
| **App Insights** | `appi-der-prod-01` | Application monitoring |
| **Cosmos DB** | `cosmos-der-prod-01` | Conversation history |
| **Managed Identity** | `id-der-deploy-prod-01` | Secure authentication |

## 🚀 DevOps Deployment (Alternative)

If using Azure DevOps pipelines, update your variable groups:

### Development Environment
```yaml
Variable Group: copa-development
- FORCE_CODE: "der"
- AZURE_RESOURCE_GROUP: "rg-der-dev-01"
- AZURE_WEBAPP_NAME: "app-der-dev-01"
- AZURE_LOCATION: "uksouth"
```

### Production Environment
```yaml
Variable Group: copa-production  
- FORCE_CODE: "der"
- AZURE_RESOURCE_GROUP: "rg-der-prod-01"
- AZURE_WEBAPP_NAME: "app-der-prod-01"
- AZURE_LOCATION: "uksouth"
```

Then run your DevOps pipeline for automatic deployment.

## 🎨 Derbyshire Customization

After deployment, customize for Derbyshire Police:

### Set Force Branding (Optional)
```bash
# In Azure App Service → Configuration → Application Settings
UI_POLICE_FORCE_LOGO="https://your-storage.blob.core.windows.net/logos/derbyshire-logo.png"
UI_POLICE_FORCE_TAGLINE="Derbyshire Constabulary - Keeping Derbyshire Safe"
```

### Upload Derbyshire-Specific Documents
1. **Go to:** Storage Account `stderprod01`
2. **Upload:** Derbyshire policies, procedures, local guidance
3. **Index:** Documents will be automatically processed

## 🔒 Security & Compliance

✅ **PDS Compliant**: All naming follows Police Digital Service standards  
✅ **GDPR Ready**: Built-in data protection and privacy controls  
✅ **Audit Trail**: Complete logging and monitoring  
✅ **Role-Based Access**: Integrated with Azure AD  
✅ **Encrypted**: Data encrypted at rest and in transit  

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] Azure subscription with OpenAI access
- [ ] Resource group `rg-der-prod-01` created
- [ ] Deployment template uploaded
- [ ] Force code confirmed as `DER`

### During Deployment
- [ ] Select correct Azure region (UK South recommended)
- [ ] Choose appropriate OpenAI models
- [ ] Verify resource naming preview
- [ ] Confirm deployment parameters

### Post-Deployment
- [ ] Verify application loads correctly
- [ ] Upload Derbyshire-specific documents
- [ ] Test search functionality
- [ ] Configure user access
- [ ] Set up monitoring alerts

## 🛠️ Testing Your Deployment

1. **Access Application**: `https://app-der-prod-01.azurewebsites.net`
2. **Test Search**: Ask about stop and search procedures
3. **Upload Test Document**: Add a Derbyshire policy document
4. **Verify AI Response**: Ensure responses reference uploaded content

## 📞 Support

For Derbyshire-specific deployment issues:
- **Technical**: Reference this deployment guide
- **Azure Issues**: Check Azure portal diagnostics
- **App Issues**: Review Application Insights logs
- **Force-Specific**: Contact Derbyshire IT team

## 🔄 Updates & Maintenance

- **Application Updates**: Automatic via DevOps pipeline
- **Model Updates**: Via Azure OpenAI service
- **Document Updates**: Upload new documents to storage
- **Configuration**: Via Azure App Service settings

---

**Derbyshire Police is now ready for CoPA deployment!** 🚔  
All resources will be automatically named and configured for Derbyshire Constabulary compliance.