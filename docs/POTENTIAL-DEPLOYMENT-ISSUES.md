# Potential Deployment Issues and Solutions

Based on analysis of the current pipeline and infrastructure code, here are potential issues you might encounter:

## 🚨 High Probability Issues (Likely Next Failures)

### 1. **Missing Variable Group Variables** ⚠️
**Status**: FIXED PROACTIVELY
**Problem**: Pipeline references undefined variables from variable groups that may not exist
**Variables at risk**:
- `resourceGroupName`
- `azureLocation` 
- `openAIModel`
- `embeddingModel`

**Expected Error**:
```
The variable '$(resourceGroupName)' is not defined
```

**Solution**: Added fallback values in pipeline stages

### 2. **Principal ID Configuration** ⚠️
**Status**: FIXED PROACTIVELY  
**Problem**: Parameters file uses dummy principal ID `00000000-0000-0000-0000-000000000000`
**Expected Error**:
```
Principal 00000000-0000-0000-0000-000000000000 does not exist in tenant
InvalidPrincipalId: Principal id is invalid
```

**Solution**: Pipeline now dynamically gets current user's principal ID

### 3. **Service Connection Validation** ⚠️
**Status**: FIXED PROACTIVELY
**Problem**: Service connections may not exist or have insufficient permissions
**Expected Error**:
```
The service connection 'BTP-Development' could not be found
Insufficient privileges to complete the operation
```

**Solution**: Added validation step to check connection and permissions

### 4. **Azure OpenAI Quota/Regional Availability** ⚠️
**Status**: ADDED CHECK
**Problem**: OpenAI services have limited regional availability and quota
**Expected Error**:
```
The subscription does not have sufficient quota for OpenAI in region uksouth
OpenAI is not available in the requested region
```

**Solution**: Added pre-deployment check for OpenAI availability

### 5. **Storage Account Naming Issues** ⚠️
**Status**: AT RISK - Manual intervention may be needed
**Problem**: Storage account name `stbtpdcopaStopSearch001` is exactly 24 chars (max limit)
**Expected Error**:
```
Storage account name 'stbtpdcopaStopSearch001' is not available
The storage account name is too long or contains invalid characters
```

**Risk Level**: MEDIUM
**Manual Fix**: May need to shorten the naming pattern in Bicep if uniqueness becomes an issue

## 🟡 Medium Probability Issues

### 6. **Private Endpoint DNS Resolution**
**Problem**: Private endpoints may not resolve correctly
**Expected Error**:
```
Private endpoint connections are not ready
DNS resolution failed for private endpoints
```

**Solution**: Wait times are built into deployment, but may need manual verification

### 7. **Key Vault Access Policy Issues**
**Problem**: Managed identity may not have proper Key Vault permissions
**Expected Error**:
```
The user, group or application does not have secrets get permission on key vault
```

**Solution**: Role assignments are in Bicep template, but timing issues may occur

### 8. **Cosmos DB Role Assignments**
**Problem**: Role assignments may take time to propagate
**Expected Error**:
```
The user does not have required access to Cosmos DB
Role assignment not yet effective
```

**Solution**: Add retry logic or wait times in application startup

## 🟢 Low Probability Issues

### 9. **Application Startup Issues**
**Problem**: Python dependencies or configuration issues
**Expected Error**:
```
Application failed to start
Module not found errors
Configuration errors
```

### 10. **Network Security Group Rules**
**Problem**: Too restrictive NSG rules
**Expected Error**:
```
Connection timeout
Access denied from source IP
```

## 🛠️ Quick Recovery Commands

If issues occur, use these commands for faster debugging:

```bash
# Check what was actually created
az resource list --resource-group rg-btp-d-copa-stop-search --output table

# Check web app status
az webapp show --name app-btp-d-copa-stop-search-001 --resource-group rg-btp-d-copa-stop-search

# Check deployment status
az deployment group list --resource-group rg-btp-d-copa-stop-search --output table

# Check role assignments
az role assignment list --scope "/subscriptions/{subscription-id}/resourceGroups/rg-btp-d-copa-stop-search"
```

## 📋 Infrastructure-Only Testing

To avoid the 25-minute build cycle when fixing infrastructure issues:

1. Set pipeline variable: `infrastructureOnly = true`
2. This will skip:
   - Application building
   - Frontend compilation  
   - Application deployment
   - Long validation stages

3. Only run:
   - Infrastructure validation
   - Bicep deployment
   - Basic verification

Use the quick-deploy script:
```bash
./scripts/quick-deploy.sh
```

This reduces deployment time from 25 minutes to ~8-10 minutes for infrastructure-only changes.