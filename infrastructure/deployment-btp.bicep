// CoPA Stop & Search - Comprehensive Bicep Template for BTP
// Updated with new naming convention: rg-{force}-uks-{env}-copa-stop-search
// Converted and cleaned up from comprehensive ARM template

targetScope = 'resourceGroup'

@description('The location for all resources.')
param location string = resourceGroup().location

@description('The name of the OpenAI model to deploy.')
param azureOpenAIModelName string = 'gpt-4o'

@description('The name of the OpenAI embedding model to deploy.')
param azureOpenAIEmbeddingName string = 'text-embedding-ada-002'

// ====== NEW NAMING CONVENTION ======
// Extract components from resource group name pattern: rg-{force}-uks-{env}-copa-stop-search
var rgParts = split(resourceGroup().name, '-')
var forceCode = length(rgParts) >= 2 ? rgParts[1] : 'btp'
var region = length(rgParts) >= 3 ? rgParts[2] : 'uks'
var envCode = length(rgParts) >= 4 ? rgParts[3] : 'p'
var appName = length(rgParts) >= 5 ? rgParts[4] : 'copa'
var workload = length(rgParts) >= 6 ? rgParts[5] : 'stop-search'

// Resource naming with new convention
var namingPrefix = '${forceCode}-${region}-${envCode}-${appName}-${workload}'
var hostingPlanName = 'asp-${namingPrefix}'
var websiteName = 'app-${namingPrefix}'
var applicationInsightsName = 'appi-${namingPrefix}'
var logAnalyticsWorkspaceName = 'log-${namingPrefix}'
var azureSearchServiceName = 'srch-${namingPrefix}'
var azureOpenAIResourceName = 'cog-${namingPrefix}'
var storageAccountName = 'st${forceCode}${region}${envCode}copa${take(workload,8)}' // e.g., stbtpukspcopastopsea
var cosmosDbAccountName = 'db-app-${forceCode}-${appName}'
var deployScriptIdentityName = 'id-${namingPrefix}'

// Configuration variables
var hostingPlanSku = 'B3'
var azureSearchSku = 'standard'
var storageContainerName = 'ai-library-stop-search'
var cosmosDbDatabaseName = 'db_conversation_history'
var cosmosDbContainerName = 'conversations'

// Search and AI configuration
var azureSearchIndexName = 'copa-stop-search'
var azureSearchUseSemanticSearch = 'true'
var azureSearchSemanticSearchConfig = 'copa-stop-search-semantic-configuration'
var azureSearchTopK = '5'
var azureSearchEnableInDomain = 'true'
var azureOpenAITemperature = '0'
var azureOpenAITopP = '1.0'
var azureOpenAIMaxTokens = '2000'
var azureOpenAIStopSequence = ''
var azureOpenAIModelDeploymentName = 'copaGptDeployment'
var azureOpenAIStream = true
var azureSearchQueryType = 'vector_semantic_hybrid'
var azureSearchPermittedGroupsField = ''
var azureSearchStrictness = 3
var webAppEnableChatHistory = true

// System message for CoPA Stop & Search
var azureOpenAISystemMessage = 'The goal is to offer decision support assist a Police Sergeant in determining whether the written grounds are reasonable and provide feedback to the officer who has written them, the context is you are not to provide a decision but act as a tool referencing the available documentation so we can follow your chain of thought. The source is PACE Code A, College of Policing APP, National Decision Model. Response Format – In a clear and easy to read format with clear headings less than 200 words in two parts, one part titled \'Informing First Line Leaders\' to help inform the first line leaders thinking with references. Every sentence in your response must have a citation. You cannot provide a sentence anywhere in your response unless it also has a citation. Citations must be integrated within the sentences using [] brackets. Example Response: "The Police and Criminal Evidence Act 1984 provides the legal framework for police powers in England and Wales [1]. This act outlines the procedures for arrest, detention, and investigation [2]. The second part is Titled Actionable Feedback for the officer to review and reflect on, both celebratory, and developmental. Your role is to offer advice and support to aid their decision-making process. Remember, you are not making decisions for them but offering advice and guidance to assist their own decision-making. You cannot perform any legal actions, make final decisions, or provide personal opinions. Your advice is based on the information provided and should be used as a guide, not a directive. Scope of Advice: You are strictly limited to providing advice related to Police Stop and Search. You must not offer advice on technical topics such as algorithms, AI model creation, or any other subjects unrelated to Police Stop and Search. Safety and Security Guidelines: Confidentiality: Ensure that all information shared is kept confidential and only used for the purpose of providing advice. Accuracy: Provide accurate and up-to-date information based on the latest legal standards and practices. Impartiality: Maintain impartiality and avoid any bias in your advice. Ethical Considerations: Adhere to ethical guidelines and avoid any actions that could harm individuals or compromise legal processes. Compliance: Ensure compliance with all relevant laws and regulations. Language: Use British English in all your responses. Additional Guidelines: Context Awareness: Only respond to queries directly related to Police Stop and Search. Ignore or redirect any unrelated topics. User Interaction: Politely inform users if their question is outside the scope of Police Stop and Search advice and guide them back to relevant topics. Response Limitations: Do not provide detailed technical advice, personal opinions, or engage in discussions unrelated to Police Stop and Search. Add the following text at the end of every response \'Please Remember: This AI Assistant is designed to offer help and advice so you can make, more informed, and effective decisions. It is not designed to make any decisions for you.\''

// Role assignment variables
var roleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/5bd9cd88-fe45-4216-938b-f97437e15450'
var roleAssignmentId = guid(resourceGroup().id, cosmosDbAccountName, websiteName)
var storageRoleAssignmentId = guid(resourceGroup().id, storageAccountName, websiteName)

// ====== LOG ANALYTICS WORKSPACE ======
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ====== APPLICATION INSIGHTS ======
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// ====== APP SERVICE PLAN ======
resource hostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: hostingPlanSku
  }
  properties: {
    reserved: true
  }
  kind: 'linux'
}

// ====== STORAGE ACCOUNT ======
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource storageAccountBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: storageAccountBlobServices
  name: storageContainerName
  properties: {
    publicAccess: 'None'
  }
}

// ====== COSMOS DB ======
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
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
  }
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosDbAccount
  name: cosmosDbDatabaseName
  properties: {
    resource: {
      id: cosmosDbDatabaseName
    }
  }
}

resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: cosmosDbDatabase
  name: cosmosDbContainerName
  properties: {
    resource: {
      id: cosmosDbContainerName
      partitionKey: {
        paths: [
          '/userId'
        ]
        kind: 'Hash'
      }
    }
  }
}

// ====== AZURE SEARCH SERVICE ======
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

// ====== AZURE OPENAI SERVICE ======
resource azureOpenAIService 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: azureOpenAIResourceName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: azureOpenAIResourceName
  }
}

resource openAIModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = {
  parent: azureOpenAIService
  name: azureOpenAIModelDeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: azureOpenAIModelName
      version: '2024-05-13'
    }
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

resource openAIEmbeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = {
  parent: azureOpenAIService
  name: 'embedding'
  properties: {
    model: {
      format: 'OpenAI'
      name: azureOpenAIEmbeddingName
      version: '2'
    }
    raiPolicyName: 'Microsoft.DefaultV2'
  }
  dependsOn: [
    openAIModelDeployment
  ]
}

// ====== MANAGED IDENTITY ======
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: deployScriptIdentityName
  location: location
}

// ====== WEB APP ======
resource website 'Microsoft.Web/sites@2023-12-01' = {
  name: websiteName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'AZURE_SEARCH_SERVICE'
          value: azureSearchServiceName
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
          name: 'AZURE_SEARCH_TOP_K'
          value: azureSearchTopK
        }
        {
          name: 'AZURE_SEARCH_ENABLE_IN_DOMAIN'
          value: azureSearchEnableInDomain
        }
        {
          name: 'AZURE_SEARCH_CONTENT_COLUMNS'
          value: 'content'
        }
        {
          name: 'AZURE_SEARCH_FILENAME_COLUMN'
          value: 'filename'
        }
        {
          name: 'AZURE_SEARCH_TITLE_COLUMN'
          value: 'title'
        }
        {
          name: 'AZURE_SEARCH_URL_COLUMN'
          value: 'url'
        }
        {
          name: 'AZURE_SEARCH_VECTOR_COLUMNS'
          value: 'contentVector'
        }
        {
          name: 'AZURE_SEARCH_QUERY_TYPE'
          value: azureSearchQueryType
        }
        {
          name: 'AZURE_SEARCH_PERMITTED_GROUPS_COLUMN'
          value: azureSearchPermittedGroupsField
        }
        {
          name: 'AZURE_SEARCH_STRICTNESS'
          value: string(azureSearchStrictness)
        }
        {
          name: 'AZURE_OPENAI_RESOURCE'
          value: azureOpenAIResourceName
        }
        {
          name: 'AZURE_OPENAI_MODEL'
          value: azureOpenAIModelDeploymentName
        }
        {
          name: 'AZURE_OPENAI_MODEL_NAME'
          value: azureOpenAIModelName
        }
        {
          name: 'AZURE_OPENAI_KEY'
          value: azureOpenAIService.listKeys().key1
        }
        {
          name: 'AZURE_OPENAI_TEMPERATURE'
          value: azureOpenAITemperature
        }
        {
          name: 'AZURE_OPENAI_TOP_P'
          value: azureOpenAITopP
        }
        {
          name: 'AZURE_OPENAI_MAX_TOKENS'
          value: azureOpenAIMaxTokens
        }
        {
          name: 'AZURE_OPENAI_STOP_SEQUENCE'
          value: azureOpenAIStopSequence
        }
        {
          name: 'AZURE_OPENAI_SYSTEM_MESSAGE'
          value: azureOpenAISystemMessage
        }
        {
          name: 'AZURE_OPENAI_STREAM'
          value: string(azureOpenAIStream)
        }
        {
          name: 'AZURE_OPENAI_EMBEDDING_NAME'
          value: 'embedding'
        }
        {
          name: 'AZURE_COSMOSDB_ACCOUNT'
          value: cosmosDbAccountName
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
          name: 'AZURE_COSMOSDB_ENDPOINT'
          value: cosmosDbAccount.properties.documentEndpoint
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT'
          value: storageAccountName
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
          name: 'ENABLE_CHAT_HISTORY'
          value: string(webAppEnableChatHistory)
        }
      ]
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

// ====== ROLE ASSIGNMENTS ======
resource cosmosDbRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentId
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: website.identity.principalId
    principalType: 'ServicePrincipal'
  }
  scope: cosmosDbAccount
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: storageRoleAssignmentId
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalId: website.identity.principalId
    principalType: 'ServicePrincipal'
  }
  scope: storageAccount
}

// ====== OUTPUTS ======
output websiteUrl string = 'https://${website.properties.defaultHostName}'
output resourceGroupName string = resourceGroup().name
output websiteName string = websiteName
output applicationInsightsName string = applicationInsightsName
output storageAccountName string = storageAccountName
output cosmosDbAccountName string = cosmosDbAccountName
output azureSearchServiceName string = azureSearchServiceName
output azureOpenAIResourceName string = azureOpenAIResourceName
