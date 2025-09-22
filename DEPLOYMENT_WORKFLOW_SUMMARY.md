# CoPA Stop & Search Deployment Workflow Summary

## Quick Start Guide

This document provides a concise overview of the updated deployment process using manual prerequisites.

## Deployment Phases

### Phase 1: One-Time Prerequisites Setup (Manual)

**Required Actions:**
1. Create Azure AD App Registration
2. Create Storage Account with containers
3. Upload logo files (optional)
4. Configure pipeline variables

**Time Estimate:** 15-30 minutes per environment

### Phase 2: Automated Pipeline Deployment (Repeatable)

**What the Pipeline Does:**
1. Validates prerequisites configuration
2. Creates resource group with BTP tags
3. Deploys all infrastructure using Bicep
4. Deploys web application
5. Configures automatic logo URLs

**Time Estimate:** 10-15 minutes per deployment

## Key Files Updated

### Pipeline Configuration
- ✅ `azure-pipelines.yml` - Updated to use manual prerequisites
- ✅ `infra/main.prerequisites.parameters.json` - Development parameters
- ✅ `infra/main.prerequisites.production.parameters.json` - Production parameters

### Bicep Templates
- ✅ `infra/main.bicep` - Enhanced with conditional logic and automatic logo URLs

### Documentation
- ✅ `docs/MANUAL_PREREQUISITES_GUIDE.md` - Complete setup instructions

## What Changed from Previous Approach

### ❌ Removed (Problems Solved)
- App registration creation tasks (permission issues)
- Complex PowerShell authentication scripts
- Variable reference mismatches
- Storage account automatic creation

### ✅ Added (New Benefits)
- Manual prerequisite validation
- Automatic logo URL generation
- Simplified pipeline flow
- Better error handling
- Clear documentation

## Deployment Commands

### Prerequisites Setup (One-Time)
```bash
# 1. Create app registration
az ad app create --display-name "CoPA-Stop-Search-Dev-001" \
  --web-redirect-uris "https://app-btp-d-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback"

# 2. Create storage account
az storage account create --name "stbtpdcopasss001" \
  --resource-group "rg-btp-d-copa-stop-search" --location "uksouth"

# 3. Create containers
az storage container create --name "ai-library-stop-search" --account-name "stbtpdcopasss001"
az storage container create --name "web-app-logos" --account-name "stbtpdcopasss001"
az storage container create --name "content" --account-name "stbtpdcopasss001"
```

### Pipeline Deployment (Repeatable)
```bash
# Just push to the Dev-Ops-Deployment branch
git push origin Dev-Ops-Deployment

# Or push to main for production
git push origin main
```

## Verification Checklist

After successful deployment, verify:

- [ ] Web application loads: `https://app-btp-d-copa-stop-search-001.azurewebsites.net`
- [ ] Authentication redirects work
- [ ] Logo images display correctly
- [ ] Storage containers accessible
- [ ] All Azure resources created with BTP naming
- [ ] Tags applied correctly to all resources

## Next Steps for Implementation

1. **Update Parameter Files**
   - Set `authClientId` in both parameter files
   - Set `storageAccountName` in both parameter files

2. **Configure Pipeline Variables**
   - Set `AUTH_CLIENT_SECRET` in development variable group
   - Set `AUTH_CLIENT_SECRET` in production variable group

3. **Create Prerequisites**
   - Follow `docs/MANUAL_PREREQUISITES_GUIDE.md`
   - Complete setup for development environment first

4. **Test Deployment**
   - Run pipeline against dev environment
   - Verify all functionality works
   - Deploy to production

## Support and Troubleshooting

- **Documentation**: `docs/MANUAL_PREREQUISITES_GUIDE.md`
- **Pipeline Logs**: Check Azure DevOps pipeline execution logs
- **Resource Verification**: Use Azure Portal to verify all resources created correctly
- **Authentication Testing**: Test login flow end-to-end

---

## Benefits Summary

✅ **Enhanced Security** - Manual control over critical authentication resources  
✅ **Improved Reliability** - Eliminates permission-related pipeline failures  
✅ **Better Compliance** - Meets organizational oversight requirements  
✅ **Automatic Branding** - Logo URLs configured automatically from storage  
✅ **Simplified Maintenance** - Cleaner pipeline with fewer potential failure points  
✅ **Clear Documentation** - Step-by-step guides for all procedures  

The deployment is now ready for implementation with the manual prerequisites approach!