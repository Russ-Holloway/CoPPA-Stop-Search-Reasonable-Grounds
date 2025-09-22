targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// BTP Naming Convention Parameters
@description('Environment code (e.g., p for production, d for development)')
param environmentCode string = 'p'

@description('Instance number for resources')
param instanceNumber string = '001'

// Network Configuration
param vnetAddressPrefix string = '10.0.0.0/16'
param appServiceSubnetAddressPrefix string = '10.0.1.0/24'
param privateEndpointSubnetAddressPrefix string = '10.0.2.0/24'
param enablePrivateEndpoints bool = true
param enablePrivateDnsZones bool = false

// Security Configuration
param keyVaultName string = ''
param logAnalyticsWorkspaceName string = ''
param restoreKeyVault bool = false

param appServicePlanName string = ''
param backendServiceName string = ''
param resourceGroupName string = ''

param searchServiceName string = ''
// param searchServiceResourceGroupName string = ''
param searchServiceResourceGroupLocation string = location
param searchServiceSkuName string = ''
param searchIndexName string = 'gptkbindex'
param searchUseSemanticSearch bool = false
param searchSemanticSearchConfig string = 'default'
param searchTopK int = 5
param searchEnableInDomain bool = true
param searchContentColumns string = 'content'
param searchFilenameColumn string = 'filepath'
param searchTitleColumn string = 'title'
param searchUrlColumn string = 'url'

param openAiResourceName string = ''
// param openAiResourceGroupName string = ''
param openAiResourceGroupLocation string = location
param openAiSkuName string = ''
param openAIModel string = 'gpt4o'
param openAIModelName string = 'gpt-35-turbo-16k'
param openAITemperature int = 0
param openAITopP int = 1
param openAIMaxTokens int = 1000
param openAIStopSequence string = ''
param openAISystemMessage string = 'The goal is to offer decision support assist a Police Sergeant in determining whether the written grounds are reasonable and provide feedback to the officer who has written them, the context is you are not to provide a decision but act as a tool referencing the available documentation so we can follow your chain of thought. The source is PACE Code A, College of Policing APP, National Decision Model, and the expectation – less than 200 words in two parts, one part to help inform the first line leaders thinking with references and the second part actionable feedback for the officer to review and reflect on, both celebratory and developmental. Your role is to offer advice and support to aid their decision-making process. Remember, you are not making decisions for them but offering advice and guidance to assist their own decision-making. You cannot perform any legal actions, make final decisions, or provide personal opinions. Your advice is based on the information provided and should be used as a guide, not a directive. Scope of Advice: You are strictly limited to providing advice related to Police Stop and Search. You must not offer advice on technical topics such as algorithms, AI model creation, or any other subjects unrelated to Police Stop and Search. Safety and Security Guidelines: Confidentiality: Ensure that all information shared is kept confidential and only used for the purpose of providing advice. Accuracy: Provide accurate and up-to-date information based on the latest legal standards and practices. Impartiality: Maintain impartiality and avoid any bias in your advice. Ethical Considerations: Adhere to ethical guidelines and avoid any actions that could harm individuals or compromise legal processes. Compliance: Ensure compliance with all relevant laws and regulations. Language: Use British English in all your responses. Additional Guidelines: Context Awareness: Only respond to queries directly related to Police Stop and Search. Ignore or redirect any unrelated topics. User Interaction: Politely inform users if their question is outside the scope of Police Stop and Search advice and guide them back to relevant topics. Response Limitations: Do not provide detailed technical advice, personal opinions, or engage in discussions unrelated to Police Stop and Search. Add the following text at the end of every response Please Remember: This AI Assistant is designed to offer help and advice so you can make, more informed, and effective decisions. It is not designed to make any decisions for you.'
param openAIStream bool = true
param embeddingDeploymentName string = 'embedding'
param embeddingModelName string = 'text-embedding-ada-002'
param restoreOpenAi bool = false

// Used by prepdocs.py: Form recognizer
param formRecognizerServiceName string = ''
// param formRecognizerResourceGroupName string = ''
// param formRecognizerResourceGroupLocation string = location
param formRecognizerSkuName string = ''
param restoreFormRecognizer bool = false

// Used for the Azure AD application
param authClientId string = ''
@secure()
param authClientSecret string = ''
param createAppRegistration bool = true  // New parameter to control app registration creation

// Used for Cosmos DB
param cosmosAccountName string = ''

// Storage Account Configuration - Always created by pipeline
param storageAccountName string = '' // For naming override only
param createStorageAccount bool = true  // Always create storage account
param aiLibraryContainerName string = 'ai-library-stop-search'
param webAppLogosContainerName string = 'web-app-logos'
param contentContainerName string = 'content'

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Whether to deploy user role assignments (requires elevated service principal permissions)')
param deployUserRoles bool = true

// BTP Required Tags Parameters
@description('Owner tag value for BTP policy compliance')
param ownerTag string = ''
@description('Cost Centre tag value for BTP policy compliance')
param costCentreTag string = ''
@description('Force ID tag value for BTP policy compliance')
param forceIdTag string = ''
@description('Service Name tag value for BTP policy compliance')
param serviceNameTag string = 'CoPA-Stop-Search'
@description('Location ID tag value for BTP policy compliance')
param locationIdTag string = ''
@description('Environment tag value for BTP policy compliance')
param environmentTag string = 'Production'

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 
  'azd-env-name': environmentName
  Owner: ownerTag
  CostCentre: costCentreTag
  ForceID: forceIdTag
  ServiceName: serviceNameTag
  LocationID: locationIdTag
  Environment: environmentTag
}

// BTP naming convention: {service}-btp-{env}-copa-stop-search-{instance}
// Resource Group: rg-btp-{env}-copa-stop-search
// Services: {service}-btp-{env}-copa-stop-search-{instance}
var btpNamingPrefix = 'btp-${environmentCode}-copa-stop-search'
var btpResourceGroupName = 'rg-${btpNamingPrefix}'

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : btpResourceGroupName
  location: location
  tags: tags
}

// Network Security Infrastructure
module nsg 'core/network/network-security-group.bicep' = {
  name: 'nsg'
  scope: resourceGroup
  params: {
    name: 'nsg-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// Virtual Network Infrastructure
module vnet 'core/network/virtual-network.bicep' = {
  name: 'vnet'
  scope: resourceGroup
  params: {
    name: 'vnet-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    addressPrefixes: [vnetAddressPrefix]
    subnets: [
      {
        name: 'app-service-subnet'
        addressPrefix: appServiceSubnetAddressPrefix
        delegations: [
          {
            name: 'delegation'
            properties: {
              serviceName: 'Microsoft.Web/serverFarms'
            }
          }
        ]
        networkSecurityGroupId: nsg.outputs.id
      }
      {
        name: 'private-endpoint-subnet'
        addressPrefix: privateEndpointSubnetAddressPrefix
        privateEndpointNetworkPolicies: 'Disabled'
        networkSecurityGroupId: nsg.outputs.id
      }
    ]
  }
}

// Log Analytics Workspace
module logAnalytics 'core/monitor/log-analytics-workspace.bicep' = {
  name: 'log-analytics'
  scope: resourceGroup
  params: {
    name: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : 'log-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
  }
}

// Key Vault
module keyVault 'core/security/key-vault.bicep' = {
  name: 'key-vault'
  scope: resourceGroup
  params: {
    name: !empty(keyVaultName) ? keyVaultName : 'kv-${environmentCode}-copa-ss-${instanceNumber}'
    location: location
    tags: tags
    publicNetworkAccess: 'Disabled'
    restore: restoreKeyVault
  }
}

// Create helper variables for auth secret logic
var hasAuthSecret = shouldCreateAppRegistration || !empty(authClientSecret)

// Key Vault Secret for AUTH_CLIENT_SECRET - Conditional creation based on scenario
module authClientSecretKvSecret 'core/security/key-vault-secret.bicep' = if (hasAuthSecret) {
  name: 'auth-client-secret'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'auth-client-secret'
    // Use parameter value initially - will be updated by pipeline if app registration is used
    secretValue: authClientSecret
    contentType: 'text/plain'
  }
}

// Private DNS Zones
module storagePrivateDnsZone 'core/network/private-dns-zone.bicep' = if (enablePrivateEndpoints && enablePrivateDnsZones) {
  name: 'storage-private-dns-zone'
  scope: resourceGroup
  params: {
    name: 'privatelink.blob.${environment().suffixes.storage}'
    location: location
    tags: tags
    virtualNetworkId: vnet.outputs.id
  }
}

module cognitiveServicesPrivateDnsZone 'core/network/private-dns-zone.bicep' = if (enablePrivateEndpoints && enablePrivateDnsZones) {
  name: 'cognitive-services-private-dns-zone'
  scope: resourceGroup
  params: {
    name: 'privatelink.cognitiveservices.azure.com'
    location: location
    tags: tags
    virtualNetworkId: vnet.outputs.id
  }
}

module searchPrivateDnsZone 'core/network/private-dns-zone.bicep' = if (enablePrivateEndpoints && enablePrivateDnsZones) {
  name: 'search-private-dns-zone'
  scope: resourceGroup
  params: {
    name: 'privatelink.search.windows.net'
    location: location
    tags: tags
    virtualNetworkId: vnet.outputs.id
  }
}

module keyVaultPrivateDnsZone 'core/network/private-dns-zone.bicep' = if (enablePrivateEndpoints && enablePrivateDnsZones) {
  name: 'key-vault-private-dns-zone'
  scope: resourceGroup
  params: {
    name: 'privatelink.vaultcore.azure.net'
    location: location
    tags: tags
    virtualNetworkId: vnet.outputs.id
  }
}

module cosmosPrivateDnsZone 'core/network/private-dns-zone.bicep' = if (enablePrivateEndpoints && enablePrivateDnsZones) {
  name: 'cosmos-private-dns-zone'
  scope: resourceGroup
  params: {
    name: 'privatelink.documents.azure.com'
    location: location
    tags: tags
    virtualNetworkId: vnet.outputs.id
  }
}


// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: resourceGroup
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : 'asp-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    sku: {
      name: 'B1'
      capacity: 1
    }
    kind: 'linux'
  }
}

// The application frontend
var appServiceName = !empty(backendServiceName) ? backendServiceName : 'app-${btpNamingPrefix}-${instanceNumber}'
var authIssuerUri = '${environment().authentication.loginEndpoint}${tenant().tenantId}/v2.0'

// Create Azure AD App Registration if needed
var shouldCreateAppRegistration = createAppRegistration && (empty(authClientId) || empty(authClientSecret))

// Variables for auth configuration that handle conditional app registration
var finalAuthClientId = empty(authClientId) ? '' : authClientId
var finalAuthIssuerUri = authIssuerUri

module appRegistration 'core/security/app-registration.bicep' = if (shouldCreateAppRegistration) {
  name: 'app-registration'
  scope: resourceGroup
  params: {
    appName: 'CoPA-Stop-Search-${environmentCode}-${instanceNumber}'
    appServiceUrl: 'https://${appServiceName}.azurewebsites.net'
    environmentName: environmentName
    location: location
    tags: tags
  }
}

// Use provided values or values from app registration
var authClientSecretKeyVaultRef = hasAuthSecret ? '@Microsoft.KeyVault(VaultName=${keyVault.outputs.name};SecretName=auth-client-secret)' : ''
module backend 'core/host/appservice.bicep' = {
  name: 'web'
  scope: resourceGroup
  params: {
    name: appServiceName
    location: location
    tags: union(tags, { 'azd-service-name': 'backend' })
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.10'
    appCommandLine: 'python -m gunicorn app:app'
    scmDoBuildDuringDeployment: true
    managedIdentity: true
    authClientSecret: authClientSecretKeyVaultRef
    authClientId: finalAuthClientId
    authIssuerUri: finalAuthIssuerUri
    subnetIdForIntegration: '${vnet.outputs.id}/subnets/app-service-subnet'
    appSettings: {
      // search - using managed identity authentication
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE: searchService.outputs.name
      AZURE_SEARCH_USE_SEMANTIC_SEARCH: searchUseSemanticSearch
      AZURE_SEARCH_SEMANTIC_SEARCH_CONFIG: searchSemanticSearchConfig
      AZURE_SEARCH_TOP_K: searchTopK
      AZURE_SEARCH_ENABLE_IN_DOMAIN: searchEnableInDomain
      AZURE_SEARCH_CONTENT_COLUMNS: searchContentColumns
      AZURE_SEARCH_FILENAME_COLUMN: searchFilenameColumn
      AZURE_SEARCH_TITLE_COLUMN: searchTitleColumn
      AZURE_SEARCH_URL_COLUMN: searchUrlColumn
      // Additional search configuration from working version
      AZURE_SEARCH_DATA_SOURCE: 'copa-stop-search-datasource'
      AZURE_SEARCH_INDEXER: 'copa-stop-search-indexer'
      AZURE_SEARCH_SKILLSET: 'copa-stop-search-skillset'
      AZURE_SEARCH_STRICTNESS: '3'
      AZURE_SEARCH_PERMITTED_GROUPS_COLUMN: ''
      AZURE_SEARCH_QUERY_TYPE: 'vector_semantic_hybrid'
      // openai - using managed identity authentication
      AZURE_OPENAI_RESOURCE: openAi.outputs.name
      AZURE_OPENAI_ENDPOINT: openAi.outputs.endpoint
      AZURE_OPENAI_MODEL: openAIModel
      AZURE_OPENAI_MODEL_NAME: openAIModelName
      AZURE_OPENAI_TEMPERATURE: openAITemperature
      AZURE_OPENAI_TOP_P: openAITopP
      AZURE_OPENAI_MAX_TOKENS: openAIMaxTokens
      AZURE_OPENAI_STOP_SEQUENCE: openAIStopSequence
      AZURE_OPENAI_SYSTEM_MESSAGE: openAISystemMessage
      AZURE_OPENAI_STREAM: openAIStream
      AZURE_OPENAI_EMBEDDING_NAME: embeddingModelName
      // CosmosDB configuration
      AZURE_COSMOSDB_ACCOUNT: !empty(cosmosAccountName) ? cosmosAccountName : 'db-${btpNamingPrefix}-${instanceNumber}'
      AZURE_COSMOSDB_URI: 'https://${(!empty(cosmosAccountName) ? cosmosAccountName : 'db-${btpNamingPrefix}-${instanceNumber}')}.documents.azure.com:443/'
      AZURE_COSMOSDB_DATABASE: 'db_conversation_history'
      AZURE_COSMOSDB_CONVERSATIONS_CONTAINER: 'conversations'
      // Storage configuration
      AZURE_STORAGE_ACCOUNT_NAME: !empty(storageAccountName) ? storageAccountName : 'st${replace(btpNamingPrefix, '-', '')}${instanceNumber}'
      AZURE_STORAGE_CONTAINER_NAME: aiLibraryContainerName
      AZURE_STORAGE_WEBAPP_LOGOS_CONTAINER: webAppLogosContainerName
      AZURE_STORAGE_CONTENT_CONTAINER: contentContainerName
      // Data source type
      DATASOURCE_TYPE: 'AzureCognitiveSearch'
      // UI Configuration with automatic logo URLs from storage
      UI_TITLE: 'CoPA for Stop Search'
      UI_CHAT_TITLE: 'CoPA for Stop Search'
      UI_POLICE_FORCE_TAGLINE: 'This version of CoPA is configured for British Transport Police Stop & Search Reasonable Grounds Review'
      UI_POLICE_FORCE_TAGLINE_2: 'Paste the reasonable grounds from a stop search record exactly as they are written and the CoPA Assistant will provide operational guidance and feedback'
      UI_FAVICON: 'https://${!empty(storageAccountName) ? storageAccountName : 'st${replace(btpNamingPrefix, '-', '')}${instanceNumber}'}.blob.${environment().suffixes.storage}/${webAppLogosContainerName}/favicon.ico'
      UI_FEEDBACK_EMAIL: ''
      UI_FIND_OUT_MORE_LINK: ''
      UI_POLICE_FORCE_LOGO: 'https://${!empty(storageAccountName) ? storageAccountName : 'st${replace(btpNamingPrefix, '-', '')}${instanceNumber}'}.blob.${environment().suffixes.storage}/${webAppLogosContainerName}/police-force-logo.png'
      UI_LOGO: 'https://${!empty(storageAccountName) ? storageAccountName : 'st${replace(btpNamingPrefix, '-', '')}${instanceNumber}'}.blob.${environment().suffixes.storage}/${webAppLogosContainerName}/copa-logo.png'
    }
  }
}

// Add Key Vault access policy for App Service managed identity
module keyVaultAccessPolicy 'core/security/key-vault-access-policy.bicep' = {
  name: 'key-vault-access-policy'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    objectId: backend.outputs.identityPrincipalId
    permissions: {
      secrets: ['get']
    }
  }
}


module openAi 'core/ai/cognitiveservices.bicep' = {
  name: 'openai'
  scope: resourceGroup
  params: {
    name: !empty(openAiResourceName) ? openAiResourceName : 'cog-${btpNamingPrefix}-${instanceNumber}'
    location: openAiResourceGroupLocation
    tags: tags
    sku: {
      name: !empty(openAiSkuName) ? openAiSkuName : 'S0'
    }
    restore: restoreOpenAi
    deployments: [
      {
        name: openAIModel
        model: {
          format: 'OpenAI'
          name: openAIModelName
          version: '2024-11-20'
        }
        capacity: 100
      }
      {
        name: embeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: embeddingModelName
          version: embeddingModelName == 'text-embedding-3-small' ? '1' : '2'
        }
        capacity: 100
      }
    ]
  }
}

module searchService 'core/search/search-services.bicep' = {
  name: 'search-service'
  scope: resourceGroup
  params: {
    name: !empty(searchServiceName) ? searchServiceName : 'srch-${btpNamingPrefix}-${instanceNumber}'
    location: searchServiceResourceGroupLocation
    tags: tags
    sku: {
      name: !empty(searchServiceSkuName) ? searchServiceSkuName : 'standard'
    }
    semanticSearch: 'free'
  }
}

// Storage Account for document processing and file uploads
// Always created by pipeline to ensure proper integration with Key Vault and private endpoints
module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: resourceGroup
  params: {
    name: !empty(storageAccountName) ? storageAccountName : 'st${replace(btpNamingPrefix, '-', '')}${instanceNumber}'
    location: location
    tags: tags
    publicNetworkAccess: 'Disabled'
    containers: [
      {
        name: contentContainerName
        publicAccess: 'None'
      }
      {
        name: aiLibraryContainerName
        publicAccess: 'None'
      }
      {
        name: webAppLogosContainerName
        publicAccess: 'None'
      }
    ]
  }
}

// The application database
module cosmos 'db.bicep' = {
  name: 'cosmos'
  scope: resourceGroup
  params: {
    accountName: !empty(cosmosAccountName) ? cosmosAccountName : 'db-${btpNamingPrefix}-${instanceNumber}'
    location: resourceGroup.location
    tags: tags
    principalIds: [principalId, backend.outputs.identityPrincipalId]
  }
}

// Private Endpoints for secure network access
module storagePrivateEndpoint 'core/network/private-endpoint.bicep' = if (enablePrivateEndpoints) {
  name: 'storage-private-endpoint'
  scope: resourceGroup
  params: {
    name: 'pe-storage-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    privateLinkServiceId: storage.outputs.id
    groupIds: ['blob']
    subnetId: '${vnet.outputs.id}/subnets/private-endpoint-subnet'
    privateDnsZoneId: (enablePrivateEndpoints && enablePrivateDnsZones && storagePrivateDnsZone != null) ? storagePrivateDnsZone!.outputs.id : ''
  }
}

module cognitiveServicesPrivateEndpoint 'core/network/private-endpoint.bicep' = if (enablePrivateEndpoints) {
  name: 'cognitive-services-private-endpoint'
  scope: resourceGroup
  params: {
    name: 'pe-openai-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    privateLinkServiceId: openAi.outputs.id
    groupIds: ['account']
    subnetId: '${vnet.outputs.id}/subnets/private-endpoint-subnet'
    privateDnsZoneId: (enablePrivateEndpoints && enablePrivateDnsZones && cognitiveServicesPrivateDnsZone != null) ? cognitiveServicesPrivateDnsZone!.outputs.id : ''
  }
}

module searchPrivateEndpoint 'core/network/private-endpoint.bicep' = if (enablePrivateEndpoints) {
  name: 'search-private-endpoint'
  scope: resourceGroup
  params: {
    name: 'pe-search-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    privateLinkServiceId: searchService.outputs.id
    groupIds: ['searchService']
    subnetId: '${vnet.outputs.id}/subnets/private-endpoint-subnet'
    privateDnsZoneId: (enablePrivateEndpoints && enablePrivateDnsZones && searchPrivateDnsZone != null) ? searchPrivateDnsZone!.outputs.id : ''
  }
}

module keyVaultPrivateEndpoint 'core/network/private-endpoint.bicep' = if (enablePrivateEndpoints) {
  name: 'key-vault-private-endpoint'
  scope: resourceGroup
  params: {
    name: 'pe-keyvault-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    privateLinkServiceId: keyVault.outputs.id
    groupIds: ['vault']
    subnetId: '${vnet.outputs.id}/subnets/private-endpoint-subnet'
    privateDnsZoneId: (enablePrivateEndpoints && enablePrivateDnsZones && keyVaultPrivateDnsZone != null) ? keyVaultPrivateDnsZone!.outputs.id : ''
  }
}

module cosmosPrivateEndpoint 'core/network/private-endpoint.bicep' = if (enablePrivateEndpoints) {
  name: 'cosmos-private-endpoint'
  scope: resourceGroup
  params: {
    name: 'pe-db-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    privateLinkServiceId: cosmos.outputs.id
    groupIds: ['Sql']
    subnetId: '${vnet.outputs.id}/subnets/private-endpoint-subnet'
    privateDnsZoneId: (enablePrivateEndpoints && enablePrivateDnsZones && cosmosPrivateDnsZone != null) ? cosmosPrivateDnsZone!.outputs.id : ''
  }
}

// USER ROLES - Only deploy if explicitly enabled and principalId is provided
// Skip user roles for service principal-only deployments (DevOps scenarios)
module openAiRoleUser 'core/security/role.bicep' = if (deployUserRoles && !empty(principalId)) {
  scope: resourceGroup
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'User'
  }
}

module searchRoleUser 'core/security/role.bicep' = if (deployUserRoles && !empty(principalId)) {
  scope: resourceGroup
  name: 'search-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'User'
  }
}

module searchIndexDataContribRoleUser 'core/security/role.bicep' = if (deployUserRoles && !empty(principalId)) {
  scope: resourceGroup
  name: 'search-index-data-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: 'User'
  }
}

module searchServiceContribRoleUser 'core/security/role.bicep' = if (deployUserRoles && !empty(principalId)) {
  scope: resourceGroup
  name: 'search-service-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    principalType: 'User'
  }
}

// SYSTEM IDENTITIES
module openAiRoleBackend 'core/security/role.bicep' = if (deployUserRoles) {
  scope: resourceGroup
  name: 'openai-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module searchRoleBackend 'core/security/role.bicep' = if (deployUserRoles) {
  scope: resourceGroup
  name: 'search-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'ServicePrincipal'
  }
}

// For doc prep
module docPrepResources 'docprep.bicep' = {
  name: 'docprep-resources${resourceToken}'
  params: {
    location: location
    resourceToken: resourceToken
    namingPrefix: btpNamingPrefix
    tags: tags
    principalId: principalId
    resourceGroupName: resourceGroup.name
    formRecognizerServiceName: formRecognizerServiceName
    // formRecognizerResourceGroupName: formRecognizerResourceGroupName
    // formRecognizerResourceGroupLocation: formRecognizerResourceGroupLocation
    formRecognizerSkuName: !empty(formRecognizerSkuName) ? formRecognizerSkuName : 'S0'
    deployUserRoles: deployUserRoles
    restoreFormRecognizer: restoreFormRecognizer
  }
}

// Form Recognizer Private Endpoint (must be after docPrepResources)
module formRecognizerPrivateEndpoint 'core/network/private-endpoint.bicep' = if (enablePrivateEndpoints) {
  name: 'form-recognizer-private-endpoint'
  scope: resourceGroup
  params: {
    name: 'pe-formrec-${btpNamingPrefix}-${instanceNumber}'
    location: location
    tags: tags
    privateLinkServiceId: docPrepResources.outputs.AZURE_FORMRECOGNIZER_ID
    groupIds: ['account']
    subnetId: '${vnet.outputs.id}/subnets/private-endpoint-subnet'
    privateDnsZoneId: (enablePrivateEndpoints && enablePrivateDnsZones && cognitiveServicesPrivateDnsZone != null) ? cognitiveServicesPrivateDnsZone!.outputs.id : ''
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name

output BACKEND_URI string = backend.outputs.uri

// search
output AZURE_SEARCH_INDEX string = searchIndexName
output AZURE_SEARCH_SERVICE string = searchService.outputs.name
output AZURE_SEARCH_SERVICE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_SEARCH_SKU_NAME string = searchService.outputs.skuName
output AZURE_SEARCH_USE_SEMANTIC_SEARCH bool = searchUseSemanticSearch
output AZURE_SEARCH_SEMANTIC_SEARCH_CONFIG string = searchSemanticSearchConfig
output AZURE_SEARCH_TOP_K int = searchTopK
output AZURE_SEARCH_ENABLE_IN_DOMAIN bool = searchEnableInDomain
output AZURE_SEARCH_CONTENT_COLUMNS string = searchContentColumns
output AZURE_SEARCH_FILENAME_COLUMN string = searchFilenameColumn
output AZURE_SEARCH_TITLE_COLUMN string = searchTitleColumn
output AZURE_SEARCH_URL_COLUMN string = searchUrlColumn

// openai
output AZURE_OPENAI_RESOURCE string = openAi.outputs.name
output AZURE_OPENAI_RESOURCE_GROUP string = resourceGroup.name
output AZURE_OPENAI_ENDPOINT string = openAi.outputs.endpoint
output AZURE_OPENAI_MODEL string = openAIModel
output AZURE_OPENAI_MODEL_NAME string = openAIModelName
output AZURE_OPENAI_SKU_NAME string = openAi.outputs.skuName
output AZURE_OPENAI_EMBEDDING_NAME string = embeddingDeploymentName
output AZURE_OPENAI_TEMPERATURE int = openAITemperature
output AZURE_OPENAI_TOP_P int = openAITopP
output AZURE_OPENAI_MAX_TOKENS int = openAIMaxTokens
output AZURE_OPENAI_STOP_SEQUENCE string = openAIStopSequence
output AZURE_OPENAI_SYSTEM_MESSAGE string = openAISystemMessage
output AZURE_OPENAI_STREAM bool = openAIStream

// Used by prepdocs.py:
output AZURE_FORMRECOGNIZER_SERVICE string = docPrepResources.outputs.AZURE_FORMRECOGNIZER_SERVICE
output AZURE_FORMRECOGNIZER_RESOURCE_GROUP string = docPrepResources.outputs.AZURE_FORMRECOGNIZER_RESOURCE_GROUP
output AZURE_FORMRECOGNIZER_SKU_NAME string = docPrepResources.outputs.AZURE_FORMRECOGNIZER_SKU_NAME

// cosmos
output AZURE_COSMOSDB_ACCOUNT string = cosmos.outputs.accountName
output AZURE_COSMOSDB_DATABASE string = cosmos.outputs.databaseName
output AZURE_COSMOSDB_CONVERSATIONS_CONTAINER string = cosmos.outputs.containerName

output AUTH_ISSUER_URI string = authIssuerUri
output AUTH_CLIENT_ID string = finalAuthClientId
output APP_REGISTRATION_CREATED bool = shouldCreateAppRegistration

// Network Security Infrastructure
output AZURE_VNET_NAME string = vnet.outputs.name
output AZURE_VNET_ID string = vnet.outputs.id
output AZURE_NSG_NAME string = nsg.outputs.name
output AZURE_NSG_ID string = nsg.outputs.id

// Storage Account - handle both created and existing storage
output AZURE_STORAGE_ACCOUNT_NAME string = createStorageAccount ? storage!.outputs.name : storageAccountName
output AZURE_STORAGE_PRIMARY_ENDPOINTS object = createStorageAccount ? storage!.outputs.primaryEndpoints : {
  blob: 'https://${storageAccountName}.blob.${environment().suffixes.storage}/'
  file: 'https://${storageAccountName}.file.${environment().suffixes.storage}/'
}
output AZURE_STORAGE_CONTAINER_NAMES object = {
  aiLibrary: aiLibraryContainerName
  webAppLogos: webAppLogosContainerName
  content: contentContainerName
}

// Key Vault
output AZURE_KEYVAULT_NAME string = keyVault.outputs.name
output AZURE_KEYVAULT_URI string = keyVault.outputs.vaultUri

// Log Analytics
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = logAnalytics.outputs.name
output AZURE_LOG_ANALYTICS_WORKSPACE_ID string = logAnalytics.outputs.id

// Security Configuration
output PRIVATE_ENDPOINTS_ENABLED bool = enablePrivateEndpoints
