# British Transport Police (BTP) - CoPA Stop & Search Deployment Guide

## 🚂 Overview
This guide provides step-by-step instructions for deploying the CoPA Stop & Search application specifically for the British Transport Police (BTP).

## 🏗️ Architecture Overview
The BTP deployment includes:
- **Web Application**: Python Flask app with Azure App Service
- **AI Services**: Azure OpenAI (GPT-4o) for decision support
- **Search**: Azure AI Search with semantic search capabilities
- **Database**: Cosmos DB for conversation history
- **Storage**: Azure Storage for document management
- **Monitoring**: Application Insights with Log Analytics

## 📋 Prerequisites

### 1. Azure Subscription
- BTP Azure subscription with appropriate permissions
- Contributor or Owner role on the target subscription
- Resource group creation permissions

### 2. Required Tools
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Bicep
az bicep install

# Login to Azure
az login
```

## 🎯 Deployment Steps

### Step 1: Create Resource Group
Create the resource group using the BTP naming convention:

```bash
az group create \
  --name "rg-btp-uks-p-copa-stop-search" \
  --location "uksouth" \
  --tags \
    "Environment=Production" \
    "Force=BTP" \
    "Application=CoPA-Stop-Search" \
    "Owner=BTP-IT-Team"
```

### Step 2: Validate Template
Test the template before deployment:

```bash
az deployment group validate \
  --resource-group "rg-btp-uks-p-copa-stop-search" \
  --template-file "infrastructure/deployment-btp.bicep" \
  --parameters "infrastructure/deployment-btp.bicepparam"
```

### Step 3: Deploy Infrastructure
Deploy the complete infrastructure:

```bash
az deployment group create \
  --resource-group "rg-btp-uks-p-copa-stop-search" \
  --template-file "infrastructure/deployment-btp.bicep" \
  --parameters "infrastructure/deployment-btp.bicepparam" \
  --verbose
```

### Step 4: Monitor Deployment
Track deployment progress:

```bash
# List deployments
az deployment group list \
  --resource-group "rg-btp-uks-p-copa-stop-search" \
  --output table

# Get deployment status
az deployment group show \
  --resource-group "rg-btp-uks-p-copa-stop-search" \
  --name "deployment-btp"
```

## 🏷️ Generated Resource Names

When deployed to `rg-btp-uks-p-copa-stop-search`, the following resources will be created:

| Resource Type | Resource Name |
|---------------|---------------|
| **App Service Plan** | `asp-btp-uks-p-copa-stop-search` |
| **Web App** | `app-btp-uks-p-copa-stop-search` |
| **Application Insights** | `appi-btp-uks-p-copa-stop-search` |
| **Log Analytics** | `log-btp-uks-p-copa-stop-search` |
| **Search Service** | `srch-btp-uks-p-copa-stop-search` |
| **OpenAI Service** | `cog-btp-uks-p-copa-stop-search` |
| **Storage Account** | `stbtpukspcopastopsea` |
| **Cosmos DB** | `db-app-btp-copa` |
| **Managed Identity** | `id-btp-uks-p-copa-stop-search` |

## 🔧 Post-Deployment Configuration

### 1. Upload Document Library
Upload BTP-specific policies and procedures:

```bash
# Example: Upload documents to storage
az storage blob upload-batch \
  --destination "ai-library-stop-search" \
  --source "./documents/btp-policies/" \
  --account-name "stbtpukspcopastopsea"
```

### 2. Configure Search Index
The search index is automatically created. To rebuild or update:

```bash
# Reset and rebuild search index
az search admin-key show \
  --resource-group "rg-btp-uks-p-copa-stop-search" \
  --service-name "srch-btp-uks-p-copa-stop-search"
```

### 3. Test Application
Access the application at:
```
https://app-btp-uks-p-copa-stop-search.azurewebsites.net
```

### 4. Configure Custom Domain (Optional)
Set up BTP-specific domain:

```bash
az webapp config hostname add \
  --webapp-name "app-btp-uks-p-copa-stop-search" \
  --resource-group "rg-btp-uks-p-copa-stop-search" \
  --hostname "copa-stop-search.btp.police.uk"
```

## 🚨 BTP-Specific Configuration

### Environment Variables
Key application settings for BTP:

- **AZURE_OPENAI_SYSTEM_MESSAGE**: Configured for BTP procedures
- **AZURE_SEARCH_INDEX**: Uses BTP document library
- **AZURE_COSMOSDB_DATABASE**: Stores BTP conversation history
- **ENABLE_CHAT_HISTORY**: Enabled for audit compliance

### Security Settings
- **HTTPS Only**: Enforced for all connections
- **TLS 1.2**: Minimum TLS version
- **Managed Identity**: Used for secure resource access
- **Private Access**: Storage and database are not publicly accessible

## 📊 Monitoring and Logging

### Application Insights
Monitor application performance:
- Dashboard: Navigate to `appi-btp-uks-p-copa-stop-search` in Azure Portal
- Alerts: Configured for errors and performance issues
- Custom metrics: Stop & search decision tracking

### Log Analytics
Centralized logging:
- Workspace: `log-btp-uks-p-copa-stop-search`
- Retention: 30 days (configurable)
- Integration: Application Insights data

## 🔄 Azure DevOps Integration

### Variable Group
The BTP production variable group `copa-btp-production` contains:
- `FORCE_CODE`: btp
- `AZURE_LOCATION`: uksouth
- `AZURE_RESOURCE_GROUP`: rg-btp-uks-p-copa-stop-search
- `AZURE_WEBAPP_NAME`: app-btp-uks-p-copa-stop-search

### Pipeline Deployment
Use the configured pipeline for automated deployments:

```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
- group: copa-btp-production

steps:
- task: AzureCLI@2
  displayName: 'Deploy to BTP Production'
  inputs:
    azureSubscription: 'BTP-Production'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az deployment group create \
        --resource-group $(AZURE_RESOURCE_GROUP) \
        --template-file infrastructure/deployment-btp.bicep \
        --parameters infrastructure/deployment-btp.bicepparam
```

## 💰 Cost Estimation

Estimated monthly costs for BTP production deployment:

| Service | SKU | Estimated Cost |
|---------|-----|----------------|
| App Service Plan | B3 | ~£45/month |
| Azure OpenAI | Pay-per-use | ~£50-200/month* |
| Azure Search | Standard | ~£200/month |
| Cosmos DB | Serverless | ~£20-100/month* |
| Storage Account | LRS | ~£5-20/month* |
| Application Insights | Pay-per-GB | ~£10-50/month* |
| **Total** | | **~£330-615/month** |

*Actual costs depend on usage volume

## 🆘 Troubleshooting

### Common Issues

**1. Deployment Fails - Resource Name Conflicts**
```bash
# Check if resources already exist
az resource list --resource-group "rg-btp-uks-p-copa-stop-search" --output table
```

**2. OpenAI Service Not Available**
- Ensure your subscription has access to Azure OpenAI
- Check regional availability for the selected models

**3. Storage Account Name Too Long**
- The template automatically handles name length constraints
- Storage account name: `stbtpukspcopastopsea` (20 characters)

**4. Web App Not Responding**
```bash
# Check app service status
az webapp show \
  --name "app-btp-uks-p-copa-stop-search" \
  --resource-group "rg-btp-uks-p-copa-stop-search" \
  --query "state"
```

### Support Contacts
- **Technical Issues**: BTP IT Support
- **Application Issues**: CoPA Development Team
- **Azure Issues**: BTP Cloud Team

## 📚 Additional Resources

- [BTP Police Stop & Search Procedures](https://www.btp.police.uk)
- [PACE Code A Guidelines](https://www.gov.uk/guidance/police-and-criminal-evidence-act-1984-pace-codes-of-practice)
- [College of Policing APP](https://www.app.college.police.uk/)
- [Azure OpenAI Documentation](https://docs.microsoft.com/azure/cognitive-services/openai/)

## ✅ Deployment Checklist

- [ ] Azure subscription access confirmed
- [ ] Resource group created: `rg-btp-uks-p-copa-stop-search`
- [ ] Template validation successful
- [ ] Infrastructure deployment completed
- [ ] Web application accessible
- [ ] Document library uploaded
- [ ] Search index configured
- [ ] Monitoring configured
- [ ] Custom domain configured (if required)
- [ ] User access testing completed
- [ ] Production readiness review completed

---

**Deployment Date**: _________________  
**Deployed By**: ___________________  
**Reviewed By**: __________________