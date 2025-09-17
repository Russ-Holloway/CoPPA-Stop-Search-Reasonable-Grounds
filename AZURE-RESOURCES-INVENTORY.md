# Azure Resources Created - Security Compliant CoPA Stop & Search Solution

## Resource Inventory and Naming Conventions

This document lists all Azure resources that will be created during deployment with their naming patterns and security configurations for compliance verification.

## BTP Naming Convention

The solution follows the BTP (British Transport Police) naming standard:
- **Pattern**: `{service}-btp-{environment}-copa-stop-search-{instance}`
- **Environment Codes**: `p` (production), `d` (development), `t` (test)
- **Instance Numbers**: `001`, `002`, `003` etc.

## Naming Convention Variables

- `environmentCode`: Environment identifier (e.g., "p" for production)
- `instanceNumber`: Instance identifier (e.g., "001")
- `btpNamingPrefix`: Core naming pattern = `btp-{environmentCode}-copa-stop-search`

## Core Infrastructure Resources

### 1. Resource Group
- **Resource Type**: `Microsoft.Resources/resourceGroups`
- **Name Pattern**: `rg-btp-{environmentCode}-copa-stop-search`
- **Example**: `rg-btp-p-copa-stop-search`
- **Security Features**: Tagged with environment and compliance markers

### 2. Virtual Network (VNET)
- **Resource Type**: `Microsoft.Network/virtualNetworks`
- **Name Pattern**: `vnet-btp-{environmentCode}-copa-stop-search-{instance}`
- **Example**: `vnet-btp-p-copa-stop-search-001`
- **Address Space**: `10.0.0.0/16` (configurable)
- **Security Features**: 
  - Private address space
  - Segmented subnets
  - NSG associations

#### Subnets
1. **App Service Subnet**
   - **Name**: `app-service-subnet`
   - **Address Prefix**: `10.0.1.0/24` (configurable)
   - **Delegation**: `Microsoft.Web/serverFarms`
   - **Security**: NSG attached, service delegation

2. **Private Endpoint Subnet**
   - **Name**: `private-endpoint-subnet`
   - **Address Prefix**: `10.0.2.0/24` (configurable)
   - **Security**: Private endpoint network policies disabled

### 3. Network Security Group (NSG)
- **Resource Type**: `Microsoft.Network/networkSecurityGroups`
- **Name Pattern**: `nsg-btp-{environmentCode}-copa-stop-search-{instance}`
- **Example**: `nsg-btp-p-copa-stop-search-001`
- **Security Rules**:
  - `AllowHTTPS` (Priority 100): Allow HTTPS inbound
  - `AllowHTTP` (Priority 110): Allow HTTP inbound for redirects
  - `DenyAllInbound` (Priority 4096): Default deny all inbound

## Data Services (All with Private Endpoints)

### 4. Storage Account
- **Resource Type**: `Microsoft.Storage/storageAccounts`
- **Name Pattern**: `stbtp{environmentCode}copastopsearch{instance}`
- **Example**: `stbtppcopastopsearch001`
- **Security Configuration**:
  - `publicNetworkAccess: "Disabled"`
  - `supportsHttpsTrafficOnly: true`
  - `defaultToOAuthAuthentication: true`
  - Network ACLs with default deny
- **Containers**:
  - `content` (Private access only)

### 5. Cosmos DB Account
- **Resource Type**: `Microsoft.DocumentDB/databaseAccounts`
- **Name Pattern**: `cosmos-btp-{environmentCode}-copa-stop-search-{instance}`
- **Example**: `cosmos-btp-p-copa-stop-search-001`
- **Security Configuration**:
  - `publicNetworkAccess: "Disabled"`
  - `disableKeyBasedMetadataWriteAccess: true`
  - Network ACL bypass for Azure Services only
- **Database**: `db_conversation_history`
- **Container**: `conversations`

### 6. Cognitive Services (OpenAI)
- **Resource Type**: `Microsoft.CognitiveServices/accounts`
- **Name Pattern**: `cog-btp-{environmentCode}-copa-stop-search-{instance}`
- **Example**: `cog-btp-p-copa-stop-search-001`
- **Security Configuration**:
  - `publicNetworkAccess: "Disabled"`
  - Network ACLs with restrictive policies
- **Deployments**:
  - GPT model deployment
  - Embedding model deployment

### 7. Azure Search Service
- **Resource Type**: `Microsoft.Search/searchServices`
- **Name Pattern**: `srch-btp-{environmentCode}-copa-stop-search-{instance}`
- **Example**: `srch-btp-p-copa-stop-search-001`
- **Security Configuration**:
  - Public network access disabled
  - Authentication via Azure AD or API keys
  - Private endpoint integration
- **SKU**: Standard (configurable)

### 8. Form Recognizer (Document Intelligence)
- **Resource Type**: `Microsoft.CognitiveServices/accounts`
- **Name Pattern**: `doc-btp-{environmentCode}-copa-stop-search-{instance}`
- **Example**: `doc-btp-p-copa-stop-search-001`
- **Kind**: `FormRecognizer`
- **Security Configuration**:
  - Public network access disabled
  - Private endpoint integration

## Security & Management Services

### 9. Key Vault
- **Resource Type**: `Microsoft.KeyVault/vaults`
- **Name Pattern**: `kv-btp{environmentCode}copastopsearch{instance}`
- **Example**: `kv-btppcopastopsearch001`
- **Security Configuration**:
  - `publicNetworkAccess: "Disabled"`
  - RBAC-based access policies
  - Private endpoint integration
- **Purpose**: Secure storage of secrets, keys, and certificates

### 10. Log Analytics Workspace
- **Resource Type**: `Microsoft.OperationalInsights/workspaces`
- **Name Pattern**: `log-btp-{environmentCode}-copa-stop-search-{instance}`
- **Example**: `log-btp-p-copa-stop-search-001`
- **Security Configuration**:
  - `publicNetworkAccessForIngestion: "Disabled"`
  - `publicNetworkAccessForQuery: "Disabled"`
  - Centralized logging for all services

## Compute Services

### 11. App Service Plan
- **Resource Type**: `Microsoft.Web/serverfarms`
- **Name Pattern**: `asp-btp-{environmentCode}-copa-stop-search-{instance}`
- **Example**: `asp-btp-p-copa-stop-search-001`
- **Configuration**:
  - SKU: B1 (Linux)
  - Capacity: 1 instance
- **Security**: Supports VNET integration

### 12. App Service (Web App)
- **Resource Type**: `Microsoft.Web/sites`
- **Name Pattern**: `app-btp-{environmentCode}-copa-stop-search-{instance}`
- **Example**: `app-btp-p-copa-stop-search-001`
- **Security Configuration**:
  - VNET integration enabled
  - HTTPS only enforcement
  - Managed identity enabled
  - EasyAuth with Azure AD
- **Runtime**: Python 3.10

## Private Network Components

### 13-26. Private Endpoints
Each data service has a dedicated private endpoint following the pattern:
- **Resource Type**: `Microsoft.Network/privateEndpoints`
- **Name Pattern**: `pe-{service}-btp-{environmentCode}-copa-stop-search-{instance}`
- **Examples**:
  - Storage Account: `pe-storage-btp-p-copa-stop-search-001`
  - Cosmos DB: `pe-cosmos-btp-p-copa-stop-search-001`
  - Cognitive Services: `pe-cognitive-btp-p-copa-stop-search-001`
  - Search Service: `pe-search-btp-p-copa-stop-search-001`
  - Form Recognizer: `pe-form-btp-p-copa-stop-search-001`
  - Key Vault: `pe-keyvault-btp-p-copa-stop-search-001`
  - Log Analytics: `pe-logs-btp-p-copa-stop-search-001`

Each private endpoint includes:
- **Private DNS Zone Groups** for proper name resolution
- **Network Interface** for private connectivity
- **Connection to respective service's private link resources**

### 14. Private DNS Zones
All private DNS zones are created when `enablePrivateEndpoints: true`:

1. **Storage DNS Zone**
   - **Name**: `privatelink.blob.{environment.suffixes.storage}`
   - **Example**: `privatelink.blob.core.windows.net`

2. **Cognitive Services DNS Zone**
   - **Name**: `privatelink.cognitiveservices.azure.com`

3. **Search DNS Zone**
   - **Name**: `privatelink.search.windows.net`

4. **Key Vault DNS Zone**
   - **Name**: `privatelink.vaultcore.azure.net`

5. **Cosmos DB DNS Zone**
   - **Name**: `privatelink.documents.azure.com`

## Security & Compliance Features Summary

### Network Security
- ✅ All data services have public network access disabled
- ✅ Private endpoints for all external communications
- ✅ VNET integration for compute services
- ✅ NSG rules following least privilege principle
- ✅ Private DNS zones for proper name resolution

### Data Protection
- ✅ Encryption in transit (HTTPS/TLS)
- ✅ Encryption at rest (Azure-managed keys)
- ✅ Secure key management via Key Vault
- ✅ OAuth authentication for storage
- ✅ RBAC for service access

### Monitoring & Auditing
- ✅ Centralized logging via Log Analytics
- ✅ Security event monitoring
- ✅ Audit trails for all operations
- ✅ Diagnostic settings enabled

### Identity & Access Management
- ✅ Managed identities for service authentication
- ✅ Azure AD integration for user authentication
- ✅ RBAC assignments for appropriate permissions
- ✅ Principle of least privilege

## Compliance Verification Commands

Use these Azure CLI commands to verify resource compliance:

```bash
# List all resources in resource group
az resource list --resource-group <resource-group> --output table

# Verify private endpoints
az network private-endpoint list --resource-group <resource-group> --output table

# Check NSG rules
az network nsg rule list --resource-group <resource-group> --nsg-name <nsg-name> --output table

# Verify storage account security
az storage account show --name <storage-account> --resource-group <resource-group> --query '{publicNetworkAccess:publicNetworkAccess, httpsOnly:enableHttpsTrafficOnly}'

# Check Cosmos DB security
az cosmosdb show --name <cosmos-account> --resource-group <resource-group> --query '{publicNetworkAccess:publicNetworkAccess}'

# Verify Key Vault security
az keyvault show --name <keyvault-name> --resource-group <resource-group> --query '{publicNetworkAccess:properties.publicNetworkAccess}'
```

## Resource Tags

All resources are tagged with:
- `Environment`: Environment name (e.g., "copa-btp-prod")
- `ForceCode`: Police force identifier
- `Service`: Service component identifier
- `ManagedBy`: "azd" for Azure Developer CLI
- `Project`: "CoPA-Stop-Search"

## Total Resource Count

**Expected Resource Count: ~25-30 resources**
- 1 Resource Group
- 1 Virtual Network + 2 Subnets
- 1 Network Security Group
- 6 Data/Compute Services
- 2 Security/Management Services
- 5 Private Endpoints
- 5 Private DNS Zones
- Various role assignments and configurations

---
*Document Version: 1.0*  
*Last Updated: September 2025*  
*Use this list to verify all resources are created and properly secured during deployment*