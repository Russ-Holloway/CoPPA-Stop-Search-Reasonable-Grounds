# CoPA Stop & Search - New Naming Convention Guide

## 🔄 Updated Naming Convention (v2.0)

The CoPA Stop & Search application has been updated to use a new, more descriptive naming convention that better reflects the application's purpose and deployment structure.

## 📋 Naming Pattern Changes

### Previous Convention (v1.0)
- **Resource Group**: `rg-{force}-{env}-{instance}`
- **Resources**: `{type}-{force}-{env}-{instance}`
- **Environment**: `dev`, `test`, `prod`

### New Convention (v2.0)
- **Resource Group**: `rg-{force}-uks-{env}-copa-stop-search`
- **Resources**: `{type}-{force}-uks-{env}-copa-stop-search`
- **Environment**: `d` (development), `t` (test), `p` (production)

## 🎯 Benefits of New Convention

1. **More Descriptive**: Clearly identifies the application and workload
2. **Region Aware**: Includes `uks` for UK South region identification
3. **Shorter Environment Codes**: Single-character environment codes save space
4. **Azure Compliance**: Designed to work within Azure naming constraints

## 🔧 Resource Naming Examples

### Standard Resources
| Resource Type | Old Format | New Format |
|---------------|------------|------------|
| Resource Group | `rg-der-prod-01` | `rg-der-uks-p-copa-stop-search` |
| App Service | `app-der-prod-01` | `app-der-uks-p-copa-stop-search` |
| App Service Plan | `asp-der-prod-01` | `asp-der-uks-p-copa-stop-search` |
| Search Service | `srch-der-prod-01` | `srch-der-uks-p-copa-stop-search` |
| OpenAI Service | `cog-der-prod-01` | `cog-der-uks-p-copa-stop-search` |
| Form Recognizer | `doc-der-prod-01` | `doc-der-uks-p-copa-stop-search` |
| Cosmos DB | `cosmos-der-prod-01` | `db-app-der-copa` |

### Length-Constrained Resources
For resources with strict naming length limits, a simplified format is used:

| Resource Type | Max Length | New Format |
|---------------|------------|------------|
| Cosmos DB | 44 chars | `db-app-der-copa` |
| Storage Account | 24 chars | `storageaccountname` (if needed) |
| Key Vault | 24 chars | `kv-shortname` (if needed) |

## 🚀 Migration Guide

### For Development Teams

1. **Update Variable Groups**: Azure DevOps variable groups have been automatically updated
2. **Update Documentation**: Reference this new naming convention in deployment docs
3. **New Deployments**: Use the new naming convention for all future deployments

### For Existing Deployments

**Option 1: Keep Existing (Recommended)**
- Existing deployments can continue using the old naming convention
- No action required - resources will continue to work normally

**Option 2: Migrate to New Convention**
- Deploy new resources with new naming convention
- Migrate data from old to new resources
- Decommission old resources (requires careful planning)

## 📝 Deployment Commands

### Development Environment (Derbyshire)
```bash
az deployment sub create \
  --template-file infra/main.bicep \
  --parameters environmentName=copa-dev \
              location=uksouth \
              resourceGroupName=rg-der-uks-d-copa-stop-search
```

### Production Environment (Metropolitan Police)
```bash
az deployment sub create \
  --template-file infra/main.bicep \
  --parameters environmentName=copa-prod \
              location=uksouth \
              resourceGroupName=rg-met-uks-p-copa-stop-search
```

### Test Environment (British Transport Police)
```bash
az deployment sub create \
  --template-file infra/main.bicep \
  --parameters environmentName=copa-test \
              location=uksouth \
              resourceGroupName=rg-btp-uks-t-copa-stop-search
```

## 🔧 Azure DevOps Integration

The Azure DevOps project has been updated with the new naming convention:

### Variable Groups Updated
- **copa-development**: Uses `rg-der-uks-d-copa-stop-search`
- **copa-production**: Uses `rg-met-uks-p-copa-stop-search`

### Pipeline Compatibility
- All existing pipelines work with the new naming convention
- No pipeline changes required

## 📊 Name Length Analysis

| Component | Length | Azure Limit | Status |
|-----------|--------|-------------|---------|
| Resource Group | 35 chars | 90 chars | ✅ Well within limit |
| App Service | 35 chars | 60 chars | ✅ Well within limit |
| Search Service | 37 chars | 60 chars | ✅ Well within limit |
| OpenAI Service | 35 chars | 64 chars | ✅ Well within limit |
| Cosmos DB | 15 chars | 44 chars | ✅ Well within limit |
| Storage Account | TBD | 24 chars | ⚠️ Will use shortened format if needed |

## 🎯 Force-Specific Examples

### England & Wales Examples
- **Derbyshire**: `rg-der-uks-p-copa-stop-search`
- **Metropolitan**: `rg-met-uks-p-copa-stop-search`
- **Greater Manchester**: `rg-gmp-uks-p-copa-stop-search`
- **West Midlands**: `rg-wmp-uks-p-copa-stop-search`

### Scotland Examples
- **Police Scotland**: `rg-sct-uks-p-copa-stop-search`

### Northern Ireland Examples
- **PSNI**: `rg-psn-uks-p-copa-stop-search`

### National Examples
- **British Transport Police**: `rg-btp-uks-p-copa-stop-search`

## 🛠️ Technical Implementation

The Bicep templates have been updated to automatically parse the new naming convention:

```bicep
// Extract force code and environment from resource group name
var rgParts = split(resourceGroupName, '-')
var forceCode = rgParts[1]    // e.g., 'der'
var region = rgParts[2]       // e.g., 'uks'  
var envCode = rgParts[3]      // e.g., 'p'
var appName = rgParts[4]      // e.g., 'copa'
var workload = rgParts[5]     // e.g., 'stop-search'

// Example resource names:
// App Service: app-der-uks-p-copa-stop-search
// Cosmos DB: db-app-der-copa
```

## 🔄 Backwards Compatibility

- **Existing Infrastructure**: Continues to work with old naming convention
- **ARM Templates**: Support both old and new patterns
- **Migration Path**: Deploy new resources alongside old ones if needed

## 📞 Support

For questions about the new naming convention:
1. Check this documentation first
2. Review the UK_POLICE_FORCE_CODES.md for your force code
3. Test deployments in development environment first
4. Contact the development team for migration assistance

---

*Last Updated: December 2024*  
*Version: 2.0*