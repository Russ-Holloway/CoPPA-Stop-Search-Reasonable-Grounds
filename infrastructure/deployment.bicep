@description('The location for all resources.')
param location string = resourceGroup().location

@description('The name of the OpenAI model to deploy.')
param AzureOpenAIModelName string = 'gpt-4o'

@description('The name of the OpenAI embedding model to deploy.')
param AzureOpenAIEmbeddingName string = 'text-embedding-ada-002'

var ForceCode = split(resourceGroup().name, '-')[1]
var EnvironmentSuffix = 'prod'
var ServiceSuffix = 'copa-stop-search'
var HostingPlanName = 'asp-${ForceCode}-${EnvironmentSuffix}-${ServiceSuffix}'
var HostingPlanSku = 'B3'
var WebsiteName = 'app-${ForceCode}-${EnvironmentSuffix}-${ServiceSuffix}'
var ApplicationInsightsName = 'appi-${ForceCode}-${EnvironmentSuffix}-${ServiceSuffix}'
var LogAnalyticsWorkspaceName = 'log-${ForceCode}-${EnvironmentSuffix}-${ServiceSuffix}'
var AzureSearchService_var = 'srch-${ForceCode}-${EnvironmentSuffix}-${ServiceSuffix}'
var AzureOpenAIResource_var = 'cog-${ForceCode}-${EnvironmentSuffix}-${ServiceSuffix}'
var AzureSearchSku = 'standard'
var StorageAccountName = 'st${ForceCode}${EnvironmentSuffix}${ServiceSuffix}'
var StorageContainerName = 'ai-library-stop-search'
var cosmosdb_account_name_var = 'db-app-${ForceCode}-${ServiceSuffix}'
var cosmosdb_database_name = 'db_conversation_history'
var cosmosdb_container_name = 'conversations'
var roleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/5bd9cd88-fe45-4216-938b-f97437e15450'
var roleAssignmentId_var = guid(resourceGroup().id, cosmosdb_account_name_var, WebsiteName)
var storageRoleAssignmentId = guid(resourceGroup().id, StorageAccountName, WebsiteName)
var deployScriptIdentityName = 'id-${ForceCode}-deploy-${EnvironmentSuffix}-${ServiceSuffix}'
var AzureOpenAIEmbeddingName_var = AzureOpenAIEmbeddingName
var AzureSearchDataSourceName = 'copa-stop-search-datasource'
var AzureSearchIndexName = 'copa-stop-search'
var AzureSearchIndexerName = 'copa-stop-search-indexer'
var AzureSearchSkillsetName = 'copa-stop-search-skillset'
var AzureSearchUseSemanticSearch = 'true'
var AzureSearchSemanticSearchConfig = 'copa-stop-search-semantic-configuration'
var AzureSearchTopK = '5'
var AzureSearchEnableInDomain = 'true'
var AzureOpenAITemperature = '0'
var AzureOpenAITopP = '1.0'
var AzureOpenAIMaxTokens = '2000'
var AzureOpenAIStopSequence = ''
var AzureOpenAIModelDeploymentName = 'copaGptDeployment'
var AzureOpenAISystemMessage = 'The goal is to offer decision support assist a Police Sergeant in determining whether the written grounds are reasonable and provide feedback to the officer who has written them, the context is you are not to provide a decision but act as a tool referencing the available documentation so we can follow your chain of thought. The source is PACE Code A, College of Policing APP, National Decision Model. Response Format – In a clear and easy to read format with clear headings less than 200 words in two parts, one part titled \'Informing First Line Leaders\' to help inform the first line leaders thinking with references. Every sentence in your response must have a citation. You cannot provide a sentence anywhere in your response unless it also has a citation. Citations must be integrated within the sentences using [] brackets. Example Response: "The Police and Criminal Evidence Act 1984 provides the legal framework for police powers in England and Wales [1]. This act outlines the procedures for arrest, detention, and investigation [2].  The second part is Titled Actionable Feedback for the officer to review and reflect on, both celebratory,  and developmental. Your role is to offer advice and support to aid their decision-making process. Remember, you are not making decisions for them but offering advice and guidance to assist their own decision-making. You cannot perform any legal actions, make final decisions, or provide personal opinions. Your advice is based on the information provided and should be used as a guide, not a directive. Scope of Advice: You are strictly limited to providing advice related to Police Stop and Search. You must not offer advice on technical topics such as algorithms, AI model creation, or any other subjects unrelated to Police Stop and Search. Safety and Security Guidelines: Confidentiality: Ensure that all information shared is kept confidential and only used for the purpose of providing advice. Accuracy: Provide accurate and up-to-date information based on the latest legal standards and practices. Impartiality: Maintain impartiality and avoid any bias in your advice. Ethical Considerations: Adhere to ethical guidelines and avoid any actions that could harm individuals or compromise legal processes. Compliance: Ensure compliance with all relevant laws and regulations. Language: Use British English in all your responses. Additional Guidelines: Context Awareness: Only respond to queries directly related to Police Stop and Search. Ignore or redirect any unrelated topics. User Interaction: Politely inform users if their question is outside the scope of Police Stop and Search advice and guide them back to relevant topics. Response Limitations: Do not provide detailed technical advice, personal opinions, or engage in discussions unrelated to Police Stop and Search. Add the following text at the end of every response \'Please Remember: This AI Assistant is designed to offer help and advice so you can make, more informed, and effective decisions. It is not designed to make any decisions for you.\''
var AzureOpenAIStream = true
var AzureSearchQueryType = 'vector_semantic_hybrid'
var AzureSearchPermittedGroupsField = ''
var AzureSearchStrictness = 3
var WebAppEnableChatHistory = true

resource HostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: HostingPlanName
  location: location
  sku: {
    name: HostingPlanSku
  }
  properties: {
    name: HostingPlanName
    reserved: true
  }
  kind: 'linux'
}

resource Website 'Microsoft.Web/sites@2023-12-01' = {
  name: WebsiteName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: HostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(ApplicationInsights.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'AZURE_SEARCH_SERVICE'
          value: AzureSearchService_var
        }
        {
          name: 'AZURE_SEARCH_INDEX'
          value: AzureSearchIndexName
        }
        {
          name: 'AZURE_SEARCH_KEY'
          value: listAdminKeys(AzureSearchService.id, '2024-06-01-preview').primaryKey
        }
        {
          name: 'AZURE_SEARCH_USE_SEMANTIC_SEARCH'
          value: AzureSearchUseSemanticSearch
        }
        {
          name: 'AZURE_SEARCH_SEMANTIC_SEARCH_CONFIG'
          value: AzureSearchSemanticSearchConfig
        }
        {
          name: 'AZURE_SEARCH_TOP_K'
          value: AzureSearchTopK
        }
        {
          name: 'AZURE_SEARCH_ENABLE_IN_DOMAIN'
          value: AzureSearchEnableInDomain
        }
        {
          name: 'AZURE_OPENAI_RESOURCE'
          value: AzureOpenAIResource_var
        }
        {
          name: 'AZURE_OPENAI_MODEL'
          value: AzureOpenAIModelDeploymentName
        }
        {
          name: 'AZURE_OPENAI_KEY'
          value: listKeys(AzureOpenAIResource.id, '2023-05-01').key1
        }
        {
          name: 'AZURE_OPENAI_MODEL_NAME'
          value: AzureOpenAIModelName
        }
        {
          name: 'AZURE_OPENAI_TEMPERATURE'
          value: AzureOpenAITemperature
        }
        {
          name: 'AZURE_OPENAI_TOP_P'
          value: AzureOpenAITopP
        }
        {
          name: 'AZURE_OPENAI_MAX_TOKENS'
          value: AzureOpenAIMaxTokens
        }
        {
          name: 'AZURE_OPENAI_STOP_SEQUENCE'
          value: AzureOpenAIStopSequence
        }
        {
          name: 'AZURE_OPENAI_SYSTEM_MESSAGE'
          value: AzureOpenAISystemMessage
        }
        {
          name: 'AZURE_OPENAI_STREAM'
          value: AzureOpenAIStream
        }
        {
          name: 'AZURE_SEARCH_QUERY_TYPE'
          value: AzureSearchQueryType
        }
        {
          name: 'AZURE_SEARCH_PERMITTED_GROUPS_COLUMN'
          value: AzureSearchPermittedGroupsField
        }
        {
          name: 'AZURE_SEARCH_STRICTNESS'
          value: AzureSearchStrictness
        }
        {
          name: 'AZURE_SEARCH_DATA_SOURCE'
          value: AzureSearchDataSourceName
        }
        {
          name: 'AZURE_SEARCH_INDEXER'
          value: AzureSearchIndexerName
        }
        {
          name: 'AZURE_OPENAI_EMBEDDING_NAME'
          value: AzureOpenAIEmbeddingName
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'AZURE_COSMOSDB_ACCOUNT'
          value: (WebAppEnableChatHistory ? cosmosdb_account_name_var : '')
        }
        {
          name: 'AZURE_COSMOSDB_URI'
          value: 'https://${cosmosdb_account_name_var}.documents.azure.com:443/'
        }
        {
          name: 'AZURE_COSMOSDB_DATABASE'
          value: cosmosdb_database_name
        }
        {
          name: 'AZURE_COSMOSDB_CONVERSATIONS_CONTAINER'
          value: cosmosdb_container_name
        }
        {
          name: 'UI_CHAT_TITLE'
          value: 'CoPA'
        }
        {
          name: 'UI_TITLE'
          value: 'CoPA (College of Policing Assistant) for Stop Search'
        }
        {
          name: 'UI_FAVICON'
          value: ''
        }
        {
          name: 'UI_LOGO'
          value: ''
        }
        {
          name: 'UI_POLICE_FORCE_LOGO'
          value: ''
        }
        {
          name: 'UI_POLICE_FORCE_TAGLINE'
          value: 'This version of CoPA (College of Policing Assistant) is configured for (Name of Police Force) Stop & Search Reasonable Grounds Review'
        }
        {
          name: 'UI_POLICE_FORCE_TAGLINE_2'
          value: 'Paste the reasonable grounds from a stop search record exactly as they are written and the CoPA Assistant will provide operational guidance and feedback'
        }
        {
          name: 'UI_FEEDBACK_EMAIL'
          value: ''
        }
        {
          name: 'UI_FIND_OUT_MORE_LINK'
          value: ''
        }
        {
          name: 'AZURE_SEARCH_SKILLSET'
          value: AzureSearchSkillsetName
        }
        {
          name: 'AZURE_STORAGE_CONTAINER_NAME'
          value: StorageContainerName
        }
        {
          name: 'DATASOURCE_TYPE'
          value: 'AzureCognitiveSearch'
        }
        {
          name: 'minTlsVersion'
          value: '1.2'
        }
        {
          name: 'PYTHON_VERSION'
          value: '3.11'
        }
        {
          name: 'WEBSITE_AUTH_AAD_ALLOWED_TENANTS'
          value: ''
        }
      ]
      pythonVersion: '3.11'
      linuxFxVersion: 'PYTHON|3.11'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      alwaysOn: true
      http20Enabled: true
      remoteDebuggingEnabled: false
      webSocketsEnabled: false
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
  dependsOn: [
    AzureOpenAIResource_AzureOpenAIModelDeployment
    AzureOpenAIResource_AzureOpenAIEmbedding
  ]
}

resource LogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: LogAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
      legacy: 0
    }
  }
}

resource ApplicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: ApplicationInsightsName
  location: location
  tags: {
    'hidden-link:${Website.id}': 'Resource'
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: LogAnalyticsWorkspace.id
  }
  kind: 'web'
}

resource cosmosdb_account_name 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = if (WebAppEnableChatHistory) {
  name: cosmosdb_account_name_var
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
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource cosmosdb_account_name_cosmosdb_database_name 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = if (WebAppEnableChatHistory) {
  parent: cosmosdb_account_name
  name: '${cosmosdb_database_name}'
  properties: {
    resource: {
      id: cosmosdb_database_name
    }
  }
}

resource cosmosdb_account_name_cosmosdb_database_name_cosmosdb_container_name 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = if (WebAppEnableChatHistory) {
  parent: cosmosdb_account_name_cosmosdb_database_name
  name: cosmosdb_container_name
  properties: {
    resource: {
      id: cosmosdb_container_name
      partitionKey: {
        paths: [
          '/userId'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
  dependsOn: [
    cosmosdb_account_name
  ]
}

resource roleAssignmentId 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (WebAppEnableChatHistory) {
  name: roleAssignmentId_var
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: reference(Website.id, '2023-12-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    cosmosdb_account_name
    cosmosdb_account_name_cosmosdb_database_name
    cosmosdb_account_name_cosmosdb_database_name_cosmosdb_container_name
  ]
}

resource AzureSearchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: AzureSearchService_var
  location: location
  sku: {
    name: AzureSearchSku
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

resource AzureOpenAIResource 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: AzureOpenAIResource_var
  location: location
  kind: 'OpenAI'
  properties: {
    customSubDomainName: AzureOpenAIResource_var
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'S0'
  }
}

resource AzureOpenAIResource_AzureOpenAIModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: AzureOpenAIResource
  name: '${AzureOpenAIModelDeploymentName}'
  properties: {
    model: {
      format: 'OpenAI'
      name: AzureOpenAIModelName
      version: '2024-08-06'
    }
  }
  sku: {
    name: 'GlobalStandard'
    capacity: 1000
  }
}

resource AzureOpenAIResource_AzureOpenAIEmbedding 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: AzureOpenAIResource
  name: '${AzureOpenAIEmbeddingName_var}'
  properties: {
    model: {
      format: 'OpenAI'
      name: AzureOpenAIEmbeddingName
      version: '2'
    }
  }
  sku: {
    name: 'GlobalStandard'
    capacity: 1000
  }
  dependsOn: [
    AzureOpenAIResource_AzureOpenAIModelDeployment
  ]
}

resource StorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: StorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource StorageAccountName_default 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: StorageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    changeFeed: {
      enabled: false
    }
    cors: {
      corsRules: [
        {
          allowedOrigins: [
            'https://portal.azure.com'
            'https://ms.portal.azure.com'
            'https://preview.portal.azure.com'
            'https://rc.portal.azure.com'
            'https://canary.portal.azure.com'
          ]
          allowedMethods: [
            'GET'
            'HEAD'
            'OPTIONS'
          ]
          maxAgeInSeconds: 200
          exposedHeaders: [
            '*'
          ]
          allowedHeaders: [
            '*'
          ]
        }
      ]
    }
  }
}

module storageRoleAssignment './nested_storageRoleAssignment.bicep' = {
  name: 'storageRoleAssignment'
  params: {
    resourceId_Microsoft_Web_sites_variables_WebsiteName: reference(Website.id, '2023-12-01', 'Full')
    variables_StorageAccountName: StorageAccountName
    variables_storageRoleAssignmentId: storageRoleAssignmentId
  }
  dependsOn: [
    StorageAccount
  ]
}

module managedIdentityDeployment './nested_managedIdentityDeployment.bicep' = {
  name: 'managedIdentityDeployment'
  params: {
    variables_deployScriptIdentityName: deployScriptIdentityName
    location: location
  }
}
