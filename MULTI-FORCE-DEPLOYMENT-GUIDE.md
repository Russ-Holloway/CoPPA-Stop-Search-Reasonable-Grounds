# Multi-Force Deployment Guide for CoPA Stop & Search

## 🏛️ Overview
This guide explains how to deploy the CoPA Stop & Search application for multiple UK Police Forces using a single Azure DevOps project with force-specific configurations.

## 🎯 Current Setup

### Configured Forces:
- ✅ **British Transport Police (BTP)** - Ready for deployment
- ✅ **Derbyshire Police** - Configuration created, needs service connection

### Force-Specific Configurations:

| Force | Variable Group | Service Connection | Environment | Resource Group |
|-------|----------------|-------------------|-------------|----------------|
| **BTP** | `copa-btp-production` | `BTP-Production` | `BTP-Production` | `rg-btp-uks-p-copa-stop-search` |
| **Derbyshire** | `copa-derbyshire-production` | `Derbyshire-Production` | `Derbyshire-Production` | `rg-derbyshire-uks-p-copa-stop-search` |

## 🚀 Adding a New Police Force

### Step 1: Create Variable Group
```bash
az pipelines variable-group create \
  --name "copa-{force}-production" \
  --variables \
    AZURE_RESOURCE_GROUP="rg-{force}-uks-p-copa-stop-search" \
    AZURE_LOCATION="uksouth" \
    FORCE_CODE="{force}" \
    AZURE_WEBAPP_NAME="app-{force}-uks-p-copa-stop-search" \
    OPENAI_MODEL_NAME="gpt-4o" \
    OPENAI_EMBEDDING_NAME="text-embedding-3-small" \
  --project "CoPA-Stop-Search-Secure-Deployment" \
  --organization "https://dev.azure.com/uk-police-copa/"
```

### Step 2: Create Service Connection
1. Go to Azure DevOps Service Connections
2. Create new Azure Resource Manager connection
3. Name: `{Force}-Production` (e.g., `Derbyshire-Production`)
4. Connect to the force's Azure subscription
5. Ensure Contributor permissions

### Step 3: Create Environment
1. Go to Azure DevOps Environments
2. Create new environment: `{Force}-Production`
3. Add manual approval gates for production safety
4. Configure appropriate approvers from that force

### Step 4: Create Force-Specific Pipeline
Copy `.azure-pipelines/btp-deployment-pipeline.yml` and customize:
- Update pipeline title and descriptions
- Change variable group reference
- Update service connection name
- Update environment name

### Step 5: Deploy
1. Create new pipeline pointing to force-specific YAML file
2. Run pipeline
3. Approve deployment when prompted
4. Verify deployment success

## 🏛️ Police Force Naming Convention

### Current UK Police Force Codes:
- `btp` - British Transport Police
- `derbyshire` - Derbyshire Constabulary
- `met` - Metropolitan Police Service
- `wmp` - West Midlands Police
- `gmp` - Greater Manchester Police
- `northumbria` - Northumbria Police
- `devon-cornwall` - Devon and Cornwall Police
- `thames-valley` - Thames Valley Police
- `west-yorkshire` - West Yorkshire Police
- `south-yorkshire` - South Yorkshire Police

### Resource Naming Examples:
```
BTP:
- Resource Group: rg-btp-uks-p-copa-stop-search
- Web App: app-btp-uks-p-copa-stop-search
- URL: https://app-btp-uks-p-copa-stop-search.azurewebsites.net

Derbyshire:
- Resource Group: rg-derbyshire-uks-p-copa-stop-search  
- Web App: app-derbyshire-uks-p-copa-stop-search
- URL: https://app-derbyshire-uks-p-copa-stop-search.azurewebsites.net
```

## 🔐 Security Considerations

### Force Isolation:
- ✅ Separate Azure subscriptions per force
- ✅ Force-specific service connections
- ✅ Separate variable groups with force-specific secrets
- ✅ Independent environments with force-specific approvers

### Access Control:
- ✅ Force representatives can only access their own deployments
- ✅ Manual approval required for all production deployments
- ✅ Audit trail maintained for all deployments
- ✅ No cross-force data access

## 🛠️ Derbyshire Police Setup

To enable Derbyshire Police deployment, they need:

### 1. Azure Subscription Access
- Provide Derbyshire's Azure subscription details
- Ensure they have Contributor access to their subscription

### 2. Create Service Connection
```
Name: Derbyshire-Production
Type: Azure Resource Manager
Subscription: [Derbyshire's subscription]
Resource Group: (Leave empty or specify rg-derbyshire-uks-p-copa-stop-search)
```

### 3. Create Environment
```
Name: Derbyshire-Production
Approvers: [Derbyshire personnel]
```

### 4. Run Deployment
- Use pipeline: `.azure-pipelines/derbyshire-deployment-pipeline.yml`
- Variable group: `copa-derbyshire-production` (✅ Already created)
- Manual approval required before deployment

## 📋 Deployment Resources Created

Each force gets their own complete set of Azure resources:

### Derbyshire Resources (Example):
```
📦 Resource Group: rg-derbyshire-uks-p-copa-stop-search
├── 🌐 Web App: app-derbyshire-uks-p-copa-stop-search
├── 📊 App Insights: appi-derbyshire-uks-p-copa-stop-search  
├── 🔍 Search Service: srch-derbyshire-uks-p-copa-stop-search
├── 🤖 OpenAI Service: cog-derbyshire-uks-p-copa-stop-search
├── 🗄️ Cosmos DB: db-app-derbyshire-copa
├── 💾 Storage Account: stderbyshireuksp...
├── 📋 App Service Plan: asp-derbyshire-uks-p-copa-stop-search
└── 📝 Log Analytics: log-derbyshire-uks-p-copa-stop-search
```

## 🎉 Benefits of This Approach

- ✅ **Centralized Management**: Single Azure DevOps project for all forces
- ✅ **Force Isolation**: Complete separation of resources and data
- ✅ **Standardized Deployment**: Consistent infrastructure across all forces
- ✅ **Security**: Force-specific access controls and approvals
- ✅ **Scalable**: Easy to add new forces with minimal setup
- ✅ **Cost Effective**: Shared development and deployment infrastructure
- ✅ **Audit Trail**: Complete deployment history for all forces

## 🚀 Next Steps for Derbyshire

1. **Provide Azure subscription details**
2. **Create service connection** (Derbyshire-Production)
3. **Create environment** with Derbyshire approvers
4. **Run the deployment pipeline**
5. **Test the deployed application**

The infrastructure is ready - they just need to complete the Azure subscription integration!