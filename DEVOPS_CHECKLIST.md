# ✅ CoPA DevOps Setup - Quick Checklist

**Organization:** https://dev.azure.com/uk-police-copa/

---

## **STEP 1: Create Project** ⏱️ 5 minutes
- [ ] Go to https://dev.azure.com/uk-police-copa/
- [ ] Click "+ New project"  
- [ ] Name: `CoPA-Stop-Search`
- [ ] Visibility: Private, Git, Agile
- [ ] Click "Create"

---

## **STEP 2: Import Repository** ⏱️ 5 minutes  
- [ ] Click "Repos" → "Import a repository"
- [ ] Select "Import from GitHub"
- [ ] URL: `https://github.com/Russ-Holloway/CoPA-Stop-Search-Reasonable-Grounds.git`
- [ ] Name: `CoPA-Stop-Search-Reasonable-Grounds`
- [ ] ✅ Check "Requires authentication"
- [ ] Authenticate with GitHub
- [ ] Wait for import to complete

---

## **STEP 3: Service Connections** ⏱️ 10 minutes
- [ ] Project Settings → Service connections
- [ ] Create service connection → Azure Resource Manager → Service principal (automatic)

**Development Connection:**
- [ ] Name: `copa-azure-service-connection-dev`
- [ ] Resource group: `rg-dev-uksouth-copa-stop-search`  
- [ ] ✅ Grant access to all pipelines
- [ ] Save

**Production Connection:**
- [ ] Name: `copa-azure-service-connection-prod`
- [ ] Resource group: `rg-prod-uksouth-copa-stop-search`
- [ ] ❌ Don't grant access to all pipelines
- [ ] Save

---

## **STEP 4: Variable Groups** ⏱️ 15 minutes
- [ ] Pipelines → Library → + Variable group

**Development Group: `copa-dev-variables`**
- [ ] `resourceGroupName` = `rg-dev-uksouth-copa-stop-search`
- [ ] `azureLocation` = `uksouth`
- [ ] `environmentName` = `development`  
- [ ] `openAIModel` = `gpt-4o`
- [ ] `embeddingModel` = `text-embedding-ada-002`
- [ ] `webAppName` = `$(webAppName)`
- [ ] `deploymentSlotName` = `staging`
- [ ] `enableDebugMode` = `true`
- [ ] `azureServiceConnection` = `copa-azure-service-connection-dev`

**Production Group: `copa-prod-variables`**
- [ ] Same variables but with production values:
- [ ] `resourceGroupName` = `rg-prod-uksouth-copa-stop-search`
- [ ] `environmentName` = `production`
- [ ] `deploymentSlotName` = `production`
- [ ] `enableDebugMode` = `false`
- [ ] `azureServiceConnection` = `copa-azure-service-connection-prod`
- [ ] `enableApplicationInsights` = `true`
- [ ] `enableMonitoring` = `true`

---

## **STEP 5: Environments** ⏱️ 10 minutes
- [ ] Pipelines → Environments → Create environment

**Development Environment:**
- [ ] Name: `copa-development`
- [ ] Description: Development environment for CoPA Stop & Search
- [ ] Resource: None
- [ ] Create (no additional config needed)

**Production Environment:**  
- [ ] Name: `copa-production`
- [ ] Description: Production environment for CoPA Stop & Search
- [ ] Resource: None
- [ ] Create
- [ ] After creation: Click environment → "..." → Approvals and checks
- [ ] Add "Approvals" → Add yourself as approver → Create

---

## **STEP 6: Import Pipeline** ⏱️ 10 minutes
- [ ] Pipelines → Pipelines → Create Pipeline
- [ ] Azure Repos Git → Select CoPA-Stop-Search-Reasonable-Grounds
- [ ] Existing Azure Pipelines YAML file
- [ ] Branch: `Dev-Ops-Deployment`
- [ ] Path: `/azure-pipelines.yml`
- [ ] Continue → Save (don't run yet)
- [ ] Rename pipeline to: `CoPA-Stop-Search-Main-Deploy`

**Configure Pipeline Security:**
- [ ] Pipeline → "..." → Security
- [ ] Grant access to variable groups: copa-dev-variables, copa-prod-variables
- [ ] Grant access to environments: copa-development, copa-production  
- [ ] Grant access to service connections: both dev and prod

---

## **STEP 7: Test Pipeline** ⏱️ 10 minutes
- [ ] Pipeline → Run pipeline
- [ ] Branch: `Dev-Ops-Deployment`
- [ ] Click "Run"
- [ ] Monitor execution:
  - [ ] ✅ Validate stage completes
  - [ ] ✅ BuildAndPackage stage completes  
  - [ ] ⚠️ DeployDevelopment may fail (expected without Azure resources)

---

## **✅ SUCCESS CHECKLIST**
- [ ] Project created: CoPA-Stop-Search
- [ ] Repository imported successfully
- [ ] 2 service connections created and working
- [ ] 2 variable groups created with all variables
- [ ] 2 environments created (prod has approvals)
- [ ] Pipeline imported and properly configured
- [ ] Pipeline validation run completed successfully

---

## **🎉 NEXT STEPS**
- [ ] Create Azure resources (run prep scripts or manually)
- [ ] Test development deployment
- [ ] Merge to main branch
- [ ] Test production deployment with approvals

**Total Time:** ~60 minutes
**Status:** Ready for deployment! 🚀