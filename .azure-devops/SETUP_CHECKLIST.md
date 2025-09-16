# CoPA Stop & Search - Azure DevOps Setup Checklist
# Organization: https://dev.azure.com/uk-police-copa/

## 📋 Pre-Setup Information

**Repository:** CoPA-Stop-Search-Reasonable-Grounds
**Owner:** Russ-Holloway
**Current Branch:** Dev-Ops-Deployment
**Azure DevOps Org:** https://dev.azure.com/uk-police-copa/

## ✅ Step 1: Create New Project

### 1.1 Create Project
- [ ] Go to https://dev.azure.com/uk-police-copa/
- [ ] Click **+ New project**
- [ ] Configure:
  - **Project name:** `CoPA-Stop-Search`
  - **Description:** `CoPA Stop & Search Reasonable Grounds Application - Secure DevOps Deployment`
  - **Visibility:** Private
  - **Version control:** Git
  - **Work item process:** Agile
- [ ] Click **Create**

### 1.2 Import Repository
- [ ] In the new project, go to **Repos** → **Import a repository**
- [ ] Choose **Import from GitHub**
- [ ] Configure:
  - **Clone URL:** `https://github.com/Russ-Holloway/CoPA-Stop-Search-Reasonable-Grounds.git`
  - **Repository name:** `CoPA-Stop-Search-Reasonable-Grounds`
  - **Requires authentication:** Yes (use your GitHub credentials)
- [ ] Click **Import**

## ✅ Step 2: Configure Service Connections

### 2.1 Create Development Service Connection
- [ ] Go to **Project Settings** → **Service connections**
- [ ] Click **Create service connection** → **Azure Resource Manager**
- [ ] Choose **Service principal (automatic)**
- [ ] Configure:
  - **Connection name:** `copa-azure-service-connection-dev`
  - **Subscription:** Select your Azure subscription
  - **Resource group:** `rg-dev-uksouth-copa-stop-search` (create if needed)
  - **Grant access permission to all pipelines:** ✅ Checked
- [ ] Click **Save**

### 2.2 Create Production Service Connection  
- [ ] Repeat above process with:
  - **Connection name:** `copa-azure-service-connection-prod`
  - **Resource group:** `rg-prod-uksouth-copa-stop-search` (or your prod RG)
  - **Grant access permission to all pipelines:** ❌ Unchecked (for security)
- [ ] Click **Save**

## ✅ Step 3: Create Variable Groups

### 3.1 Development Variable Group
- [ ] Go to **Pipelines** → **Library**
- [ ] Click **+ Variable group**
- [ ] Configure:
  - **Variable group name:** `copa-dev-variables`
  - **Description:** `Development environment variables for CoPA Stop & Search`
  - **Link secrets from an Azure key vault:** ❌ Unchecked (for now)

**Add these variables:**

| Variable Name | Value | Secret |
|---------------|-------|---------|
| `resourceGroupName` | `rg-dev-uksouth-copa-stop-search` | ❌ |
| `azureLocation` | `uksouth` | ❌ |
| `environmentName` | `development` | ❌ |
| `openAIModel` | `gpt-4o` | ❌ |
| `embeddingModel` | `text-embedding-ada-002` | ❌ |
| `webAppName` | `$(webAppName)` | ❌ |
| `deploymentSlotName` | `staging` | ❌ |
| `enableDebugMode` | `true` | ❌ |
| `appClientId` | `your-dev-app-client-id` | ✅ |
| `appClientSecret` | `your-dev-app-client-secret` | ✅ |
| `azureServiceConnection` | `copa-azure-service-connection-dev` | ❌ |

- [ ] Click **Save**

### 3.2 Production Variable Group
- [ ] Create another variable group: `copa-prod-variables`
- [ ] Add production-specific variables (similar structure, different values)

**Add these variables:**

| Variable Name | Value | Secret |
|---------------|-------|---------|
| `resourceGroupName` | `rg-prod-uksouth-copa-stop-search` | ❌ |
| `azureLocation` | `uksouth` | ❌ |
| `environmentName` | `production` | ❌ |
| `openAIModel` | `gpt-4o` | ❌ |
| `embeddingModel` | `text-embedding-ada-002` | ❌ |
| `webAppName` | `$(webAppName)` | ❌ |
| `deploymentSlotName` | `production` | ❌ |
| `enableDebugMode` | `false` | ❌ |
| `appClientId` | `your-prod-app-client-id` | ✅ |
| `appClientSecret` | `your-prod-app-client-secret` | ✅ |
| `azureServiceConnection` | `copa-azure-service-connection-prod` | ❌ |
| `enableApplicationInsights` | `true` | ❌ |
| `enableMonitoring` | `true` | ❌ |

## ✅ Step 4: Create Environments

### 4.1 Development Environment
- [ ] Go to **Pipelines** → **Environments**
- [ ] Click **Create environment**
- [ ] Configure:
  - **Name:** `copa-development`
  - **Description:** `Development environment for CoPA Stop & Search`
  - **Resource:** None
- [ ] Click **Create**
- [ ] **Security settings:**
  - **Approvers:** None (auto-deploy)
  - **Branch control:** Allow any branch
  - **Required template:** None

### 4.2 Production Environment
- [ ] Create another environment: `copa-production`
- [ ] Configure security settings:
  - **Approvers:** Add yourself and other stakeholders
  - **Branch control:** Restrict to `main` branch only
  - **Required template:** None (optional: add if needed)
- [ ] **Additional settings:**
  - **Checks:** Add approval checks
  - **Security:** Restrict access to production service connection

## ✅ Step 5: Import Pipelines

### 5.1 Import Main Deployment Pipeline
- [ ] Go to **Pipelines** → **Pipelines**
- [ ] Click **Create Pipeline**
- [ ] Choose **Azure Repos Git**
- [ ] Select **CoPA-Stop-Search-Reasonable-Grounds** repository
- [ ] Choose **Existing Azure Pipelines YAML file**
- [ ] Select:
  - **Branch:** `Dev-Ops-Deployment`
  - **Path:** `/azure-pipelines.yml`
- [ ] Click **Continue**
- [ ] Review the pipeline YAML
- [ ] Click **Save** (don't run yet)
- [ ] **Rename pipeline:** `CoPA-Stop-Search-Main-Deploy`

### 5.2 Import Infrastructure Pipeline (Optional)
- [ ] Repeat above process for infrastructure-only pipeline:
  - **Path:** `/azure-pipelines-infra.yml`
  - **Name:** `CoPA-Stop-Search-Infrastructure`

## ✅ Step 6: Configure Pipeline Permissions

### 6.1 Main Pipeline Permissions
- [ ] Go to the main pipeline settings
- [ ] **Security** tab:
  - Grant access to variable groups:
    - `copa-dev-variables`
    - `copa-prod-variables`
  - Grant access to environments:
    - `copa-development`
    - `copa-production`
  - Grant access to service connections:
    - `copa-azure-service-connection-dev`
    - `copa-azure-service-connection-prod`

## ✅ Step 7: Test Development Deployment

### 7.1 Prepare for First Run
- [ ] Verify all prerequisites are complete
- [ ] Check Azure subscription has sufficient quota:
  - OpenAI services (GPT-4 and embeddings)
  - App Service
  - Search Service
  - Cosmos DB

### 7.2 Run Development Deployment
- [ ] Go to **Pipelines** → **CoPA-Stop-Search-Main-Deploy**
- [ ] Click **Run pipeline**
- [ ] Configure run:
  - **Branch:** `Dev-Ops-Deployment`
  - **Advanced options:** Leave defaults
- [ ] Click **Run**
- [ ] Monitor the pipeline execution:
  - ✅ Validate stage should pass
  - ✅ Build & Package stage should complete
  - ✅ Deploy Development stage should deploy resources

### 7.3 Verify Development Deployment
After successful deployment:
- [ ] Check Azure portal for created resources in `rg-dev-uksouth-copa-stop-search`
- [ ] Verify web app is running
- [ ] Test basic application functionality
- [ ] Check Application Insights for telemetry

## ✅ Step 8: Configure Production Deployment

### 8.1 Setup Production Approvals
- [ ] Go to **Pipelines** → **Environments** → **copa-production**
- [ ] Add approval checks:
  - **Pre-deployment approvals:** Add required approvers
  - **Post-deployment approvals:** Optional
- [ ] Configure additional security:
  - **Branch protection:** Ensure only `main` branch can deploy
  - **Required reviewers:** Add stakeholders

### 8.2 Test Production Pipeline
- [ ] Create a Pull Request to merge `Dev-Ops-Deployment` to `main`
- [ ] After merge, pipeline should trigger for production
- [ ] Approve the production deployment
- [ ] Monitor successful deployment to production environment

## ✅ Step 9: Post-Setup Validation

### 9.1 Verify Complete Setup
- [ ] Both environments are working
- [ ] Security scans are passing
- [ ] All Azure resources are properly named with PDS conventions
- [ ] Application is functional in both environments
- [ ] Monitoring and alerts are working

### 9.2 Document Setup
- [ ] Document any custom configurations
- [ ] Share access with team members
- [ ] Set up monitoring and alerting
- [ ] Plan regular maintenance and updates

## 🎉 Setup Complete!

Your secure DevOps deployment for CoPA Stop & Search is now ready!

**Next Steps:**
1. Regular monitoring of pipeline success
2. Security scan review and remediation
3. Performance optimization
4. Team training on the new deployment process