# 🎯 CoPA Stop & Search - Complete Azure DevOps Setup Guide
**Step-by-Step Instructions for https://dev.azure.com/uk-police-copa/**

---

## 🚀 **STEP 1: Create Azure DevOps Project**

### 1.1 Navigate to Your Organization
1. **Open browser** and go to: **https://dev.azure.com/uk-police-copa/**
2. **Sign in** with your Microsoft account if prompted
3. You should see the UK Police CoPA organization homepage

### 1.2 Create New Project
1. **Click** the **"+ New project"** button (top right corner)
2. **Fill in the project form:**
   ```
   Project name: CoPA-Stop-Search
   Description: CoPA Stop & Search Reasonable Grounds Application - Secure DevOps Deployment
   Visibility: Private
   Version control: Git
   Work item process: Agile
   ```
3. **Click** **"Create"** button
4. **Wait** for project creation (30-60 seconds)

**✅ Expected Result:** You should see the new project dashboard for "CoPA-Stop-Search"

---

## 📦 **STEP 2: Import Repository from GitHub**

### 2.1 Access Repos Section
1. **In the new project**, click **"Repos"** in the left sidebar
2. You should see a screen saying "Add some code!"

### 2.2 Import from GitHub
1. **Click** **"Import a repository"**
2. **Select** **"Import from GitHub"**
3. **Fill in the import form:**
   ```
   Repository type: Git (should be selected by default)
   Clone URL: https://github.com/Russ-Holloway/CoPA-Stop-Search-Reasonable-Grounds.git
   Repository name: CoPA-Stop-Search-Reasonable-Grounds
   ☑️ Requires authentication: CHECK THIS BOX
   ```
4. **Click** **"Import"**
5. **Authenticate with GitHub** when the popup appears:
   - Enter your GitHub username and password
   - Or use personal access token if you have 2FA enabled
6. **Wait** for import to complete (3-5 minutes)

**✅ Expected Result:** Repository imported successfully, you can see all files including `azure-pipelines.yml`

---

## 🔐 **STEP 3: Create Service Connections**

### 3.1 Navigate to Service Connections
1. **Click** **"Project Settings"** (bottom left corner)
2. **Click** **"Service connections"** (under Pipelines section)
3. You should see an empty list of service connections

### 3.2 Create Development Service Connection
1. **Click** **"Create service connection"**
2. **Select** **"Azure Resource Manager"**
3. **Choose** **"Service principal (automatic)"**
4. **Click** **"Next"**
5. **Fill in the connection form:**
   ```
   Scope level: Subscription (default)
   Subscription: [Select your Azure subscription from dropdown]
   Resource group: rg-dev-uksouth-copa-stop-search
   Service connection name: copa-azure-service-connection-dev
   Description: Development environment service connection for CoPA Stop & Search
   Security: ☑️ Grant access permission to all pipelines
   ```
6. **Click** **"Save"**
7. **Wait** for Azure authentication and service principal creation

### 3.3 Create Production Service Connection
1. **Click** **"Create service connection"** again
2. **Repeat the same process** with these settings:
   ```
   Subscription: [Select your Azure subscription from dropdown]
   Resource group: rg-prod-uksouth-copa-stop-search
   Service connection name: copa-azure-service-connection-prod
   Description: Production environment service connection for CoPA Stop & Search
   Security: ☐ Grant access permission to all pipelines (LEAVE UNCHECKED)
   ```
3. **Click** **"Save"**

**✅ Expected Result:** Two service connections created and showing "Ready" status

---

## 📊 **STEP 4: Create Variable Groups**

### 4.1 Navigate to Library
1. **Click** **"Pipelines"** in the left sidebar
2. **Click** **"Library"** (under Pipelines)
3. You should see the Library page with tabs for Variable groups

### 4.2 Create Development Variable Group
1. **Click** **"+ Variable group"**
2. **Fill in group details:**
   ```
   Variable group name: copa-dev-variables
   Description: Development environment variables for CoPA Stop & Search
   ☐ Link secrets from an Azure key vault (LEAVE UNCHECKED)
   ```
3. **Add variables one by one** (click "+ Add" for each):

   | Variable name | Value | Keep this secret |
   |---------------|-------|------------------|
   | `resourceGroupName` | `rg-dev-uksouth-copa-stop-search` | ☐ No |
   | `azureLocation` | `uksouth` | ☐ No |
   | `environmentName` | `development` | ☐ No |
   | `openAIModel` | `gpt-4o` | ☐ No |
   | `embeddingModel` | `text-embedding-ada-002` | ☐ No |
   | `webAppName` | `$(webAppName)` | ☐ No |
   | `deploymentSlotName` | `staging` | ☐ No |
   | `enableDebugMode` | `true` | ☐ No |
   | `azureServiceConnection` | `copa-azure-service-connection-dev` | ☐ No |

4. **Click** **"Save"**

### 4.3 Create Production Variable Group
1. **Click** **"+ Variable group"** again
2. **Fill in group details:**
   ```
   Variable group name: copa-prod-variables
   Description: Production environment variables for CoPA Stop & Search
   ```
3. **Add these variables:**

   | Variable name | Value | Keep this secret |
   |---------------|-------|------------------|
   | `resourceGroupName` | `rg-prod-uksouth-copa-stop-search` | ☐ No |
   | `azureLocation` | `uksouth` | ☐ No |
   | `environmentName` | `production` | ☐ No |
   | `openAIModel` | `gpt-4o` | ☐ No |
   | `embeddingModel` | `text-embedding-ada-002` | ☐ No |
   | `webAppName` | `$(webAppName)` | ☐ No |
   | `deploymentSlotName` | `production` | ☐ No |
   | `enableDebugMode` | `false` | ☐ No |
   | `azureServiceConnection` | `copa-azure-service-connection-prod` | ☐ No |
   | `enableApplicationInsights` | `true` | ☐ No |
   | `enableMonitoring` | `true` | ☐ No |

4. **Click** **"Save"**

**✅ Expected Result:** Two variable groups created with all variables configured

---

## 🏗️ **STEP 5: Create Environments**

### 5.1 Navigate to Environments
1. **Still in Pipelines section**, click **"Environments"**
2. You should see an empty environments list

### 5.2 Create Development Environment
1. **Click** **"Create environment"**
2. **Fill in environment details:**
   ```
   Name: copa-development
   Description: Development environment for CoPA Stop & Search
   Resource: None (leave default)
   ```
3. **Click** **"Create"**
4. **No additional configuration needed** for development (auto-deploy)

### 5.3 Create Production Environment
1. **Click** **"Create environment"** again
2. **Fill in environment details:**
   ```
   Name: copa-production
   Description: Production environment for CoPA Stop & Search
   Resource: None (leave default)
   ```
3. **Click** **"Create"**
4. **Configure production security:**
   - **Click** on the **"copa-production"** environment
   - **Click** the **"..."** (three dots menu) in top right
   - **Select** **"Approvals and checks"**
   - **Click** **"+"** and select **"Approvals"**
   - **Add yourself** (and other stakeholders) as approvers
   - **Set** "Number of approvers required" to **1** (or more)
   - **Click** **"Create"**

**✅ Expected Result:** Two environments created, production has approval requirements

---

## 🔄 **STEP 6: Import and Configure Pipeline**

### 6.1 Navigate to Pipelines
1. **Click** **"Pipelines"** → **"Pipelines"** (main pipelines page)
2. You should see "Create your first pipeline"

### 6.2 Create Pipeline from Repository
1. **Click** **"Create Pipeline"**
2. **Select** **"Azure Repos Git"**
3. **Select** **"CoPA-Stop-Search-Reasonable-Grounds"** repository
4. **Choose** **"Existing Azure Pipelines YAML file"**
5. **Select branch and path:**
   ```
   Branch: Dev-Ops-Deployment
   Path: /azure-pipelines.yml
   ```
6. **Click** **"Continue"**
7. **Review the YAML** (you should see the complete pipeline configuration)
8. **Click** the **dropdown arrow** next to "Run" and select **"Save"**

### 6.3 Rename Pipeline
1. **Click** **"..."** (three dots) next to the pipeline name
2. **Select** **"Rename/move"**
3. **Change name to:** `CoPA-Stop-Search-Main-Deploy`
4. **Click** **"Save"**

### 6.4 Configure Pipeline Security
1. **In the pipeline page**, click **"..."** → **"Security"**
2. **Grant permissions** to required resources:
   - **Variable Groups:** Add `copa-dev-variables` and `copa-prod-variables`
   - **Environments:** Add `copa-development` and `copa-production`
   - **Service Connections:** Add both dev and prod service connections

**✅ Expected Result:** Pipeline created and properly configured with all permissions

---

## 🧪 **STEP 7: Test Pipeline (Validation Run)**

### 7.1 Run Pipeline for Validation
1. **In the main pipeline page**, click **"Run pipeline"**
2. **Configure the run:**
   ```
   Branch/tag: Dev-Ops-Deployment
   Variables: (leave default)
   Stages to run: (leave default - all stages)
   ```
3. **Click** **"Run"**

### 7.2 Monitor Pipeline Execution
1. **Watch the pipeline stages:**
   - **✅ Validate** - Should complete successfully (Bicep validation, security scans)
   - **✅ BuildAndPackage** - Should complete successfully (build application)
   - **⚠️ DeployDevelopment** - Might fail if Azure resources don't exist yet (this is expected)

### 7.3 Review Results
1. **Click** on each stage to see detailed logs
2. **Key things to verify:**
   - Bicep template validates successfully
   - Security scans complete (may show warnings, that's OK)
   - Service connections work properly
   - Variable groups are accessible

**✅ Expected Result:** Validation and Build stages pass, deployment may fail (expected without Azure resources)

---

## ✅ **STEP 8: Verification Checklist**

After completing all steps, verify you have:

### In Azure DevOps:
- [x] **Project:** CoPA-Stop-Search created
- [x] **Repository:** CoPA-Stop-Search-Reasonable-Grounds imported
- [x] **Service Connections:** 
  - copa-azure-service-connection-dev ✅
  - copa-azure-service-connection-prod ✅
- [x] **Variable Groups:**
  - copa-dev-variables ✅
  - copa-prod-variables ✅
- [x] **Environments:**
  - copa-development ✅
  - copa-production (with approvals) ✅
- [x] **Pipeline:** CoPA-Stop-Search-Main-Deploy ✅
- [x] **Pipeline Test:** Validation run completed ✅

---

## 🎉 **SUCCESS! What's Next?**

Your Azure DevOps project is fully configured! Now you can:

### **Immediate Next Steps:**
1. **Create Azure Resources** (if not done already):
   - Run the Azure prep script from earlier
   - Or manually create resource groups in Azure Portal

2. **Test Development Deployment:**
   - Ensure Azure resources exist
   - Re-run the pipeline
   - Verify successful deployment to development

3. **Setup Production Workflow:**
   - Merge changes to main branch
   - Test production deployment with approvals
   - Verify production environment

### **Pipeline Workflow:**
- **Dev-Ops-Deployment branch** → Auto-deploy to development
- **main branch** → Deploy to production (with approvals)

### **Troubleshooting Resources:**
- Check `.azure-devops/SETUP_CHECKLIST.md` for detailed troubleshooting
- Run `./scripts/verify-devops-setup.sh` to verify local configuration
- Review pipeline logs for specific error messages

---

## 🚨 **Common Issues & Solutions**

### **Pipeline Fails at Validation:**
- Check service connection permissions in Azure
- Verify Bicep template syntax with `az bicep build`
- Ensure all variable groups have correct values

### **Service Connection Issues:**
- Verify Azure subscription permissions
- Try recreating service connection
- Check if Azure resource groups exist

### **Variable Group Access:**
- Ensure pipeline has permissions to variable groups
- Check variable names match exactly (case sensitive)
- Verify service connection names in variables

### **Environment Permissions:**
- Grant pipeline access to environments
- Check approval settings for production
- Verify environment names match pipeline YAML

---

## 📞 **Need Help?**

If you encounter issues:
1. **Check pipeline logs** for specific error messages
2. **Verify each component** using the verification checklist
3. **Review Azure DevOps documentation** for specific errors
4. **Check Azure resource quotas** and permissions

**🎯 Your secure, PDS-compliant DevOps deployment is ready to go!** 🚀