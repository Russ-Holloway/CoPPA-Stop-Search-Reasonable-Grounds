// CoPA Stop & Search - Bicep Template with PDS Naming Compliance
// Converted from ARM template while preserving all functionality

targetScope = 'resourceGroup'

@description('The location for all resources.')
param location string = resourceGroup().location

@description('The name of the OpenAI model to deploy.')
param azureOpenAIModelName string = 'gpt-4o'

@description('The name of the OpenAI embedding model to deploy.')
param azureOpenAIEmbeddingName string = 'text-embedding-ada-002'

// ====== PDS NAMING CONVENTIONS ======
// Extract force code from resource group name (e.g., rg-btp-prod-01 -> btp)
var forceCode = split(resourceGroup().name, '-')[1]
var environmentSuffix = 'prod'
var serviceSuffix = 'copa-stop-search'

// PDS-compliant resource names
var hostingPlanName = 'asp-${forceCode}-${environmentSuffix}-${serviceSuffix}'
var websiteName = 'app-${forceCode}-${environmentSuffix}-${serviceSuffix}'
var applicationInsightsName = 'appi-${forceCode}-${environmentSuffix}-${serviceSuffix}'
var logAnalyticsWorkspaceName = 'log-${forceCode}-${environmentSuffix}-${serviceSuffix}'
var azureSearchServiceName = 'srch-${forceCode}-${environmentSuffix}-${serviceSuffix}'
var azureOpenAIResourceName = 'cog-${forceCode}-${environmentSuffix}-${serviceSuffix}'
var storageAccountName = 'st${forceCode}${environmentSuffix}${serviceSuffix}'
var cosmosDbAccountName = 'db-app-${forceCode}-${serviceSuffix}'

// Configuration variables
var hostingPlanSku = 'B3'
var azureSearchSku = 'standard'
var storageContainerName = 'ai-library-stop-search'
var cosmosDbDatabaseName = 'db_conversation_history'
var cosmosDbContainerName = 'conversations'

// Search configuration
var azureSearchIndexName = 'copa-stop-search'
var azureSearchUseSemanticSearch = 'true'
var azureSearchSemanticSearchConfig = 'copa-stop-search-semantic-configuration'

// OpenAI configuration
var azureOpenAIModelDeploymentName = 'copaGptDeployment'
var azureOpenAISystemMessage = 'The goal is to offer decision support assist a Police Sergeant in determining whether the written grounds are reasonable and provide feedback to the officer who has written them, the context is you are not to provide a decision but act as a tool referencing the available documentation so we can follow your chain of thought. The source is PACE Code A, College of Policing APP, National Decision Model. Response Format – In a clear and easy to read format with clear headings less than 200 words in two parts, one part titled \'Informing First Line Leaders\' to help inform the first line leaders thinking with references. Every sentence in your response must have a citation. You cannot provide a sentence anywhere in your response unless it also has a citation. Citations must be integrated within the sentences using [] brackets. Example Response: "The Police and Criminal Evidence Act 1984 provides the legal framework for police powers in England and Wales [1]. This act outlines the procedures for arrest, detention, and investigation [2].  The second part is Titled Actionable Feedback for the officer to review and reflect on, both celebratory,  and developmental. Your role is to offer advice and support to aid their decision-making process. Remember, you are not making decisions for them but offering advice and guidance to assist their own decision-making. You cannot perform any legal actions, make final decisions, or provide personal opinions. Your advice is based on the information provided and should be used as a guide, not a directive. Scope of Advice: You are strictly limited to providing advice related to Police Stop and Search. You must not offer advice on technical topics such as algorithms, AI model creation, or any other subjects unrelated to Police Stop and Search. Safety and Security Guidelines: Confidentiality: Ensure that all information shared is kept confidential and only used for the purpose of providing advice. Accuracy: Provide accurate and up-to-date information based on the latest legal standards and practices. Impartiality: Maintain impartiality and avoid any bias in your advice. Ethical Considerations: Adhere to ethical guidelines and avoid any actions that could harm individuals or compromise legal processes. Compliance: Ensure compliance with all relevant laws and regulations. Language: Use British English in all your responses. Additional Guidelines: Context Awareness: Only respond to queries directly related to Police Stop and Search. Ignore or redirect any unrelated topics. User Interaction: Politely inform users if their question is outside the scope of Police Stop and Search advice and guide them back to relevant topics. Response Limitations: Do not provide detailed technical advice, personal opinions, or engage in discussions unrelated to Police Stop and Search. Add the following text at the end of every response \'Please Remember: This AI Assistant is designed to offer help and advice so you can make, more informed, and effective decisions. It is not designed to make any decisions for you.\''

// ====== AZURE RESOURCES ======

// Log Analytics Workspace (needed for Application Insights)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// App Service Plan
resource hostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: hostingPlanSku
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

// Storage Container
resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storageAccount.name}/default/${storageContainerName}'
  properties: {
    publicAccess: 'None'
  }
}

// Cosmos DB Account
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    capabilities: []
    enableFreeTier: false
  }
}

// Cosmos DB Database
resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosDbAccount
  name: cosmosDbDatabaseName
  properties: {
    resource: {
      id: cosmosDbDatabaseName
    }
  }
}

// Cosmos DB Container
resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: cosmosDbDatabase
  name: cosmosDbContainerName
  properties: {
    resource: {
      id: cosmosDbContainerName
      partitionKey: {
        paths: ['/userId']
        kind: 'Hash'
      }
    }
  }
}

// Azure Search Service
resource azureSearchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: azureSearchServiceName
  location: location
  sku: {
    name: azureSearchSku
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

// Azure OpenAI Service
resource azureOpenAIResource 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: azureOpenAIResourceName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: azureOpenAIResourceName
    publicNetworkAccess: 'Enabled'
  }
}

// OpenAI Model Deployment
resource openAIModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: azureOpenAIResource
  name: azureOpenAIModelDeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: azureOpenAIModelName
      version: '2024-05-13'
    }
  }
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
}

// OpenAI Embedding Deployment
resource openAIEmbeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: azureOpenAIResource
  name: 'embedding'
  properties: {
    model: {
      format: 'OpenAI'
      name: azureOpenAIEmbeddingName
      version: azureOpenAIEmbeddingName == 'text-embedding-3-small' ? '1' : '2'
    }
  }
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  dependsOn: [
    openAIModelDeployment
  ]
}

// App Service with managed identity
resource website 'Microsoft.Web/sites@2023-12-01' = {
  name: websiteName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AZURE_SEARCH_SERVICE'
          value: azureSearchService.name
        }
        {
          name: 'AZURE_SEARCH_INDEX'
          value: azureSearchIndexName
        }
        {
          name: 'AZURE_SEARCH_KEY'
          value: azureSearchService.listAdminKeys().primaryKey
        }
        {
          name: 'AZURE_SEARCH_USE_SEMANTIC_SEARCH'
          value: azureSearchUseSemanticSearch
        }
        {
          name: 'AZURE_SEARCH_SEMANTIC_SEARCH_CONFIG'
          value: azureSearchSemanticSearchConfig
        }
        {
          name: 'AZURE_OPENAI_RESOURCE'
          value: azureOpenAIResource.name
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: azureOpenAIResource.properties.endpoint
        }
        {
          name: 'AZURE_OPENAI_KEY'
          value: azureOpenAIResource.listKeys().key1
        }
        {
          name: 'AZURE_OPENAI_MODEL'
          value: azureOpenAIModelName
        }
        {
          name: 'AZURE_OPENAI_MODEL_NAME'
          value: azureOpenAIModelDeploymentName
        }
        {
          name: 'AZURE_OPENAI_EMBEDDING_NAME'
          value: 'embedding'
        }
        {
          name: 'AZURE_OPENAI_SYSTEM_MESSAGE'
          value: azureOpenAISystemMessage
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT'
          value: storageAccount.name
        }
        {
          name: 'AZURE_STORAGE_CONTAINER'
          value: storageContainerName
        }
        {
          name: 'AZURE_STORAGE_KEY'
          value: storageAccount.listKeys().keys[0].value
        }
        {
          name: 'AZURE_COSMOSDB_ACCOUNT'
          value: cosmosDbAccount.name
        }
        {
          name: 'AZURE_COSMOSDB_DATABASE'
          value: cosmosDbDatabaseName
        }
        {
          name: 'AZURE_COSMOSDB_CONVERSATIONS_CONTAINER'
          value: cosmosDbContainerName
        }
        {
          name: 'AZURE_COSMOSDB_ACCOUNT_KEY'
          value: cosmosDbAccount.listKeys().primaryMasterKey
        }
        {
          name: 'UI_TITLE'
          value: 'CoPA (College of Policing Assistant) for Stop Search'
        }
        {
          name: 'UI_CHAT_TITLE'
          value: 'CoPA for Stop Search'
        }
        {
          name: 'UI_POLICE_FORCE_TAGLINE'
          value: 'This version of CoPPA is configured for ${toUpper(forceCode)} Stop & Search Reasonable Grounds Review'
        }
        {
          name: 'UI_POLICE_FORCE_TAGLINE_2'
          value: 'Paste the reasonable grounds from a stop search record exactly as they are written and the CoPPA Assistant will provide operational guidance and feedback'
        }
      ]
    }
  }
}

// Role assignments for managed identity access to Cosmos DB
resource cosmosDbRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, cosmosDbAccount.name, website.name, 'cosmos')
  scope: cosmosDbAccount
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/5bd9cd88-fe45-4216-938b-f97437e15450'
    principalId: website.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role assignments for managed identity access to Storage
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, storageAccount.name, website.name, 'storage')
  scope: storageAccount
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalId: website.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ====== OUTPUTS ======
output websiteName string = website.name
output websiteUrl string = 'https://${website.properties.defaultHostName}'
output azureOpenAIEndpoint string = azureOpenAIResource.properties.endpoint
output azureSearchServiceName string = azureSearchService.name
output storageAccountName string = storageAccount.name
output cosmosDbAccountName string = cosmosDbAccount.name
output forceCode string = forceCode
output resourceNames object = {
  hostingPlan: hostingPlanName
  website: websiteName
  applicationInsights: applicationInsightsName
  logAnalyticsWorkspace: logAnalyticsWorkspaceName
  azureSearch: azureSearchServiceName
  azureOpenAI: azureOpenAIResourceName
  storageAccount: storageAccountName
  cosmosDb: cosmosDbAccountName
}
