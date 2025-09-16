# 🚀 Azure DevOps Project Creation - Step-by-Step Guide
# Organization: https://dev.azure.com/uk-police-copa/

## 📋 Step 1: Create New Project

### Actions to take:
1. **Navigate to:** https://dev.azure.com/uk-police-copa/
2. **Click:** `+ New project` (top right)
3. **Fill in the form:**

```
Project name: CoPA-Stop-Search
Description: CoPA Stop & Search Reasonable Grounds Application - Secure DevOps Deployment
Visibility: Private (recommended for police data)
Version control: Git 
Work item process: Agile
```

4. **Click:** `Create`

⏱️ **Expected time:** 2 minutes

---

## 📦 Step 2: Import Repository

### Actions to take:
1. **In the new project, navigate to:** `Repos` (left sidebar)
2. **Click:** `Import a repository` 
3. **Select:** `Import from GitHub`
4. **Fill in the import form:**

```
Repository type: Git
Clone URL: https://github.com/Russ-Holloway/CoPA-Stop-Search-Reasonable-Grounds.git
Repository name: CoPA-Stop-Search-Reasonable-Grounds
Requires authentication: ✅ Check this box
```

5. **Authenticate with GitHub** when prompted
6. **Click:** `Import`

⏱️ **Expected time:** 3-5 minutes (depending on repository size)

---

## 🔐 Step 3: Create Service Connections

### Development Service Connection:
1. **Navigate to:** `Project Settings` (bottom left) → `Service connections`
2. **Click:** `Create service connection`
3. **Select:** `Azure Resource Manager`
4. **Choose:** `Service principal (automatic)`
5. **Fill in the connection details:**

```
Connection name: copa-azure-service-connection-dev
Subscription: [Select your Azure subscription]
Resource group: rg-dev-uksouth-copa-stop-search
Service connection name: copa-azure-service-connection-dev
Description: Development environment service connection for CoPA Stop & Search
Grant access permission to all pipelines: ✅ Check this
```

6. **Click:** `Save`

### Production Service Connection:
1. **Repeat the above process** with these settings:

```
Connection name: copa-azure-service-connection-prod  
Subscription: [Select your Azure subscription]
Resource group: rg-prod-uksouth-copa-stop-search
Service connection name: copa-azure-service-connection-prod
Description: Production environment service connection for CoPA Stop & Search
Grant access permission to all pipelines: ❌ Leave unchecked (security)
```

⏱️ **Expected time:** 5-10 minutes

---

## 📊 Step 4: Create Variable Groups

### Development Variable Group:
1. **Navigate to:** `Pipelines` (left sidebar) → `Library`
2. **Click:** `+ Variable group`
3. **Fill in the group details:**

```
Variable group name: copa-dev-variables
Description: Development environment variables for CoPA Stop & Search
Link secrets from an Azure key vault: ❌ Leave unchecked for now
```

4. **Add these variables one by one:**

| Variable Name | Value | Keep this secret |
|---------------|-------|------------------|
| `resourceGroupName` | `rg-dev-uksouth-copa-stop-search` | ❌ |
| `azureLocation` | `uksouth` | ❌ |
| `environmentName` | `development` | ❌ |
| `openAIModel` | `gpt-4o` | ❌ |
| `embeddingModel` | `text-embedding-ada-002` | ❌ |
| `webAppName` | `$(webAppName)` | ❌ |
| `deploymentSlotName` | `staging` | ❌ |
| `enableDebugMode` | `true` | ❌ |
| `azureServiceConnection` | `copa-azure-service-connection-dev` | ❌ |

5. **Click:** `Save`

### Production Variable Group:
1. **Create another variable group:** `copa-prod-variables`
2. **Add these variables:**

| Variable Name | Value | Keep this secret |
|---------------|-------|------------------|
| `resourceGroupName` | `rg-prod-uksouth-copa-stop-search` | ❌ |
| `azureLocation` | `uksouth` | ❌ |
| `environmentName` | `production` | ❌ |
| `openAIModel` | `gpt-4o` | ❌ |
| `embeddingModel` | `text-embedding-ada-002` | ❌ |
| `webAppName` | `$(webAppName)` | ❌ |
| `deploymentSlotName` | `production` | ❌ |
| `enableDebugMode` | `false` | ❌ |
| `azureServiceConnection` | `copa-azure-service-connection-prod` | ❌ |
| `enableApplicationInsights` | `true` | ❌ |
| `enableMonitoring` | `true` | ❌ |

⏱️ **Expected time:** 10-15 minutes

---

## 🏗️ Step 5: Create Environments

### Development Environment:
1. **Navigate to:** `Pipelines` → `Environments`
2. **Click:** `Create environment`
3. **Fill in the details:**

```
Name: copa-development
Description: Development environment for CoPA Stop & Search
Resource: None
```

4. **Click:** `Create`
5. **No additional security settings needed** (auto-deploy)

### Production Environment:
1. **Create another environment:** `copa-production`
2. **After creation, click on the environment**
3. **Click:** `...` (three dots) → `Security`
4. **Add approval checks:**
   - **Click:** `+` → `Approvals`
   - **Add yourself and other stakeholders as approvers**
   - **Set:** `Number of approvers` = 1 (or more as needed)

⏱️ **Expected time:** 5-10 minutes

---

## 🔄 Step 6: Import Main Pipeline

### Import the Pipeline:
1. **Navigate to:** `Pipelines` → `Pipelines`
2. **Click:** `Create Pipeline`
3. **Choose:** `Azure Repos Git`
4. **Select:** `CoPA-Stop-Search-Reasonable-Grounds`
5. **Choose:** `Existing Azure Pipelines YAML file`
6. **Select:**
   - **Branch:** `Dev-Ops-Deployment`
   - **Path:** `/azure-pipelines.yml`
7. **Click:** `Continue`
8. **Review the YAML** (don't run yet)
9. **Click:** `Save` (dropdown arrow) → `Save`
10. **Rename pipeline to:** `CoPA-Stop-Search-Main-Deploy`

### Configure Pipeline Permissions:
1. **In the pipeline, click:** `...` → `Security`
2. **Grant access to:**
   - Variable groups: `copa-dev-variables`, `copa-prod-variables`
   - Environments: `copa-development`, `copa-production`
   - Service connections: Both dev and prod connections

⏱️ **Expected time:** 10-15 minutes

---

## 🎯 Step 7: Test Pipeline (Validation Only)

### Run Pipeline Validation:
1. **In the main pipeline, click:** `Run pipeline`
2. **Configure the run:**
   - **Branch:** `Dev-Ops-Deployment`
   - **Variables:** Leave default
3. **Click:** `Run`

### What should happen:
- ✅ **Validate stage** should complete successfully
- ✅ **Build & Package stage** should complete
- ⏸️ **Deploy Development stage** might fail (expected if Azure resources aren't created yet)

This validates that:
- Service connections work
- Variable groups are accessible
- Bicep template is valid
- Security scanning passes

⏱️ **Expected time:** 15-20 minutes

---

## ✅ Completion Checklist

After completing all steps, you should have:

- [x] Azure DevOps project: `CoPA-Stop-Search`
- [x] Repository imported with all files
- [x] Service connections: `copa-azure-service-connection-dev` and `copa-azure-service-connection-prod`
- [x] Variable groups: `copa-dev-variables` and `copa-prod-variables`
- [x] Environments: `copa-development` and `copa-production`
- [x] Pipeline: `CoPA-Stop-Search-Main-Deploy`
- [x] Pipeline validation run completed

---

## 🎉 Success! What's Next?

Your Azure DevOps project is now configured! The next steps would be:

1. **Create Azure resources** (if not already done)
2. **Test development deployment**
3. **Setup production approval workflow**
4. **Deploy to production**

---

## 🚨 Troubleshooting

### Common Issues:

**Service Connection Fails:**
- Check Azure subscription permissions
- Verify resource group exists
- Try recreating the service connection

**Pipeline Validation Fails:**
- Check Bicep template syntax
- Verify variable group values
- Ensure service connection has proper permissions

**Import Repository Fails:**
- Check GitHub authentication
- Verify repository URL
- Try using personal access token if needed