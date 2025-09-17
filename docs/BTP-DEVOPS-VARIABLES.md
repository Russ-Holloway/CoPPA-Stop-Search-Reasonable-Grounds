# BTP DevOps Pipeline Variable Configuration

## Required Variables for BTP Deployment

### Variable Groups Configuration

Update your Azure DevOps Variable Groups with the following variables:

#### Copa Production Variables (`copa-prod-variables`)
```yaml
# Core Environment Settings
resourceGroupName: rg-btp-p-copa-stop-search
azureLocation: uksouth
environmentName: production
environmentCode: p
instanceNumber: '001'

# Model Configuration
openAIModel: gpt-4o
embeddingModel: text-embedding-ada-002

# Resource Names (BTP Convention)
webAppName: app-btp-p-copa-stop-search-001

# Security (Mark as Secret Variables)
prod-app-client-id: [YOUR_PRODUCTION_CLIENT_ID]
prod-app-client-secret: [YOUR_PRODUCTION_CLIENT_SECRET]

# Service Connection
azureServiceConnection: copa-azure-service-connection-prod
```

#### Copa Development Variables (`copa-dev-variables`)
```yaml
# Core Environment Settings
resourceGroupName: rg-btp-d-copa-stop-search
azureLocation: uksouth
environmentName: development
environmentCode: d
instanceNumber: '001'

# Model Configuration
openAIModel: gpt-4o
embeddingModel: text-embedding-ada-002

# Resource Names (BTP Convention)
webAppName: app-btp-d-copa-stop-search-001

# Development Settings
deploymentSlotName: staging
enableDebugMode: true

# Security (Mark as Secret Variables)
dev-app-client-id: [YOUR_DEVELOPMENT_CLIENT_ID]
dev-app-client-secret: [YOUR_DEVELOPMENT_CLIENT_SECRET]

# Service Connection
azureServiceConnection: copa-azure-service-connection-dev
```

#### BTP Production Variables (`copa-btp-production`)
```yaml
# BTP Specific Variables
AZURE_RESOURCE_GROUP: rg-btp-p-copa-stop-search
AZURE_LOCATION: uksouth
FORCE_CODE: btp
ENVIRONMENT_CODE: p
INSTANCE_NUMBER: '001'

# Application Settings
AZURE_WEBAPP_NAME: app-btp-p-copa-stop-search-001

# Security (Mark as Secret Variables)
btp-app-client-id: [YOUR_BTP_CLIENT_ID]
btp-app-client-secret: [YOUR_BTP_CLIENT_SECRET]
```

### Environment Code Standards
- **Production**: `p`
- **Development**: `d`
- **Test**: `t`
- **Staging**: `s`

### Instance Number Format
- Always use 3-digit format: `001`, `002`, etc.
- Start with `001` for first deployment
- Increment for multiple instances in same environment

### Resource Naming Pattern
All resources follow: `{service}-btp-{environmentCode}-copa-stop-search-{instance}`

**Examples:**
- Resource Group: `rg-btp-p-copa-stop-search`
- App Service: `app-btp-p-copa-stop-search-001`
- Storage Account: `stbtppcopastopsearch001`
- Key Vault: `kv-btppcopastopsearch001`

### Required Azure DevOps Service Connections
1. **copa-azure-service-connection** - Main service connection
2. **copa-azure-service-connection-prod** - Production specific
3. **copa-azure-service-connection-dev** - Development specific
4. **BTP-Production** - BTP tenant connection

### Required Azure DevOps Environments
1. **copa-development** - Development environment
2. **copa-production** - Production environment  
3. **BTP-Production** - BTP production environment (requires approval)

## Pipeline File Updates Summary

### ✅ Updated Files:
1. `azure-pipelines.yml` - Main deployment pipeline
2. `azure-pipelines-infra.yml` - Infrastructure-only pipeline
3. `.azure-pipelines/btp-deployment-pipeline.yml` - BTP deployment pipeline
4. `.azure-devops/copa-prod-variables.yml` - Production variables
5. `.azure-devops/copa-dev-variables.yml` - Development variables

### Key Changes Made:
- Updated Bicep template path from `main-pds-converted.bicep` to `main.bicep`
- Added `environmentCode` and `instanceNumber` parameters
- Updated resource group names to BTP convention
- Fixed resource name references in verification scripts
- Added BTP-specific variable configurations

### Next Steps:
1. Update Azure DevOps Variable Groups with new values
2. Test pipeline with development environment first
3. Deploy to BTP production environment
4. Verify all resources are created with correct naming