# PDS Compliant CoPPA Deployment Guide

## Overview
This deployment guide provides instructions for deploying the CoPPA (College of Policing Assistant) solution in compliance with PDS (Police Digital Service) naming standards. The solution is designed to be used by all 44 UK police forces with consistent, policy-compliant resource naming.

## Prerequisites
- Azure subscription with appropriate permissions
- Access to Azure OpenAI services
- Knowledge of your police force's 2-3 letter code
- Understanding of PDS naming conventions

## PDS Naming Compliance
All resources created by this deployment follow the PDS naming strategy:
- **Format**: `{force-code}-{service-type}-{workload}-{environment}-{instance}`
- **Force codes**: 2-3 letter abbreviations (e.g., 'btp', 'met', 'gmp')
- **Environments**: dev, test, prod
- **Instance numbers**: 01, 02, etc.

## Quick Deployment

### Option 1: Azure Portal Deployment
1. Click the "Deploy to Azure" button below
2. Fill in your police force details
3. Review the auto-generated resource names
4. Deploy the solution

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fstcoppadeployment02.blob.core.windows.net%2Fcoppa-deployment%2Fdeployment.json/createUIDefinitionUri/https%3A%2F%2Fstcoppadeployment02.blob.core.windows.net%2Fcoppa-deployment%2FcreateUiDefinition.json)

### Option 2: PowerShell Deployment
```powershell
# Set your deployment parameters
$resourceGroupName = "rg-btp-policing-prod-02"
$forceCode = "btp"  # Change to your force code
$environment = "prod"  # dev, test, or prod
$instanceNumber = "02"

# Deploy the template
New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "infrastructure/deployment.json" `
    -TemplateParameterFile "infrastructure/parameters-pds.json" `
    -ForceCode $forceCode `
    -EnvironmentSuffix $environment `
    -InstanceNumber $instanceNumber
```

### Option 3: Azure CLI Deployment
```bash
# Set your deployment parameters
RESOURCE_GROUP="rg-btp-policing-prod-01"
FORCE_CODE="btp"  # Change to your force code
ENVIRONMENT="prod"  # dev, test, or prod
INSTANCE_NUMBER="01"

# Deploy the template
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file infrastructure/deployment.json \
    --parameters \
        ForceCode=$FORCE_CODE \
        EnvironmentSuffix=$ENVIRONMENT \
        InstanceNumber=$INSTANCE_NUMBER
```

## Force Codes Reference
Here are some common UK police force codes:

| Force | Code | Example Resources |
|-------|------|------------------|
| British Transport Police | btp | btp-app-policing-prod-01 |
| Metropolitan Police | met | met-app-policing-prod-01 |
| Greater Manchester Police | gmp | gmp-app-policing-prod-01 |
| West Midlands Police | wmp | wmp-app-policing-prod-01 |
| Thames Valley Police | tvp | tvp-app-policing-prod-01 |
| Kent Police | kent | kent-app-policing-prod-01 |
| Essex Police | essex | essex-app-policing-prod-01 |
| Avon and Somerset Police | avs | avs-app-policing-prod-01 |
| Devon and Cornwall Police | dcp | dcp-app-policing-prod-01 |
| North Yorkshire Police | nyp | nyp-app-policing-prod-01 |

*Contact your PDS team if your force code is not listed*

## Resource Names Generated
When you deploy with force code "btp", environment "prod", and instance "01", the following resources will be created:

| Resource Type | Generated Name | Purpose |
|---------------|----------------|---------|
| Web App | btp-app-policing-prod-01 | Main application |
| Search Service | btp-srch-policing-prod-01 | Azure AI Search |
| OpenAI Service | btp-ai-policing-prod-01 | Azure OpenAI |
| Storage Account | stbtppolicingprod01 | Document storage |
| Cosmos DB | btp-cosmos-policing-prod-01 | Conversation history |
| App Insights | btp-insights-policing-prod-01 | Monitoring |
| Search Index | btp-policing-index-prod | Search index |
| Search Indexer | btp-policing-indexer-prod | Document indexer |
| Search Data Source | btp-policing-datasource-prod | Data source |

## Post-Deployment Configuration

### 1. Upload Documents
After deployment, upload your policing documents to the storage container:
```powershell
# Connect to your storage account
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name "stbtppolicingprod01"
$ctx = $storageAccount.Context

# Upload documents
Set-AzStorageBlobContent -File "local-document.pdf" -Container "docs" -Blob "document.pdf" -Context $ctx
```

### 2. Configure Search Components
The search components are automatically configured during deployment. To verify:
```powershell
# Run the search setup script manually if needed
.\scripts\setup_search_components.ps1 `
    -SearchServiceName "btp-srch-policing-prod-01" `
    -SearchServiceSku "standard" `
    -SearchIndexName "btp-policing-index-prod" `
    -SearchIndexerName "btp-policing-indexer-prod" `
    -SearchDataSourceName "btp-policing-datasource-prod" `
    -StorageAccountName "stbtppolicingprod01" `
    -StorageContainerName "docs" `
    -ResourceGroupName $resourceGroupName
```

### 3. Test the Application
1. Navigate to your web app URL: `https://btp-app-policing-prod-01.azurewebsites.net`
2. Test document search functionality
3. Verify conversation history is being saved

## Troubleshooting

### Common Issues
1. **Resource name conflicts**: Ensure your force code and instance number combination is unique
2. **Permission errors**: Verify you have Contributor access to the resource group
3. **OpenAI quota**: Check your Azure OpenAI service quotas in the selected region

### Validation
To verify PDS compliance, check that all resource names follow the pattern:
- Web resources: `{force}-{type}-policing-{env}-{instance}`
- Storage: `st{force}policing{env}{instance}`
- Search components: `{force}-policing-{component}-{env}`

### Support
- Review the [Azure Naming Guidelines](docs/azure-naming-guidelines.md)
- Check the [PDS Naming Policy Documentation](link-to-pds-docs)
- Contact your local IT team for force-specific requirements

## Security Considerations
- All resources are deployed with managed identities
- Network access can be restricted using Azure Private Endpoints
- Data is encrypted at rest and in transit
- Access is controlled through Azure RBAC

## Monitoring and Maintenance
- Application Insights provides monitoring and alerting
- Cosmos DB handles conversation history with automatic scaling
- Search indexer runs hourly to process new documents
- Review and update document permissions regularly

## Cost Management
- Use development environments for testing to minimize costs
- Consider scaling down non-production environments outside business hours
- Monitor usage through Azure Cost Management

## Compliance Notes
This deployment template ensures:
- ✅ PDS naming convention compliance
- ✅ UK data residency (resources deployed in UK regions)
- ✅ Government security standards
- ✅ Audit logging enabled
- ✅ Encryption at rest and in transit
