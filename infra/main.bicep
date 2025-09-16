targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param appServicePlanName string = ''
param backendServiceName string = ''
param resourceGroupName string = ''

param searchServiceName string = ''
param searchServiceResourceGroupName string = ''
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
param openAiResourceGroupName string = ''
param openAiResourceGroupLocation string = location
param openAiSkuName string = ''
param openAIModel string = 'turbo16k'
param openAIModelName string = 'gpt-35-turbo-16k'
param openAITemperature int = 0
param openAITopP int = 1
param openAIMaxTokens int = 1000
param openAIStopSequence string = ''
param openAISystemMessage string = 'The goal is to offer decision support assist a Police Sergeant in determining whether the written grounds are reasonable and provide feedback to the officer who has written them, the context is you are not to provide a decision but act as a tool referencing the available documentation so we can follow your chain of thought. The source is PACE Code A, College of Policing APP, National Decision Model, and the expectation – less than 200 words in two parts, one part to help inform the first line leaders thinking with references and the second part actionable feedback for the officer to review and reflect on, both celebratory and developmental. Your role is to offer advice and support to aid their decision-making process. Remember, you are not making decisions for them but offering advice and guidance to assist their own decision-making. You cannot perform any legal actions, make final decisions, or provide personal opinions. Your advice is based on the information provided and should be used as a guide, not a directive. Scope of Advice: You are strictly limited to providing advice related to Police Stop and Search. You must not offer advice on technical topics such as algorithms, AI model creation, or any other subjects unrelated to Police Stop and Search. Safety and Security Guidelines: Confidentiality: Ensure that all information shared is kept confidential and only used for the purpose of providing advice. Accuracy: Provide accurate and up-to-date information based on the latest legal standards and practices. Impartiality: Maintain impartiality and avoid any bias in your advice. Ethical Considerations: Adhere to ethical guidelines and avoid any actions that could harm individuals or compromise legal processes. Compliance: Ensure compliance with all relevant laws and regulations. Language: Use British English in all your responses. Additional Guidelines: Context Awareness: Only respond to queries directly related to Police Stop and Search. Ignore or redirect any unrelated topics. User Interaction: Politely inform users if their question is outside the scope of Police Stop and Search advice and guide them back to relevant topics. Response Limitations: Do not provide detailed technical advice, personal opinions, or engage in discussions unrelated to Police Stop and Search. Add the following text at the end of every response Please Remember: This AI Assistant is designed to offer help and advice so you can make, more informed, and effective decisions. It is not designed to make any decisions for you.'
param openAIStream bool = true
param embeddingDeploymentName string = 'embedding'
param embeddingModelName string = 'text-embedding-ada-002'

// Used by prepdocs.py: Form recognizer
param formRecognizerServiceName string = ''
param formRecognizerResourceGroupName string = ''
param formRecognizerResourceGroupLocation string = location
param formRecognizerSkuName string = ''

// Used for the Azure AD application - now optional for post-deployment configuration
param authClientId string = ''
@secure()
param authClientSecret string = ''

// Used for Cosmos DB
param cosmosAccountName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Extract force code and environment from resource group name for custom naming convention
// Expected pattern: rg-{force}-uks-{env}-copa-stop-search
var rgParts = !empty(resourceGroupName) ? split(resourceGroupName, '-') : split('rg-${environmentName}-uks-d-copa-stop-search', '-')
var forceCode = length(rgParts) >= 2 ? rgParts[1] : 'def'
var region = length(rgParts) >= 3 ? rgParts[2] : 'uks'
var envCode = length(rgParts) >= 4 ? rgParts[3] : 'd'
var appName = length(rgParts) >= 5 ? rgParts[4] : 'copa'
var workload = length(rgParts) >= 6 ? rgParts[5] : 'stop-search'

// Custom naming pattern: {type}-{force}-{region}-{env}-{app}-{workload}
var namingPrefix = '${forceCode}-${region}-${envCode}-${appName}-${workload}'

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

resource openAiResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(openAiResourceGroupName)) {
  name: !empty(openAiResourceGroupName) ? openAiResourceGroupName : resourceGroup.name
}

resource searchServiceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(searchServiceResourceGroupName)) {
  name: !empty(searchServiceResourceGroupName) ? searchServiceResourceGroupName : resourceGroup.name
}


// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: resourceGroup
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : 'asp-${namingPrefix}'
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
var appServiceName = !empty(backendServiceName) ? backendServiceName : 'app-${namingPrefix}'
var authIssuerUri = '${environment().authentication.loginEndpoint}${tenant().tenantId}/v2.0'
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
    scmDoBuildDuringDeployment: true
    managedIdentity: true
    authClientSecret: authClientSecret
    authClientId: authClientId
    authIssuerUri: authIssuerUri
    appSettings: {
      // search
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE: searchService.outputs.name
      AZURE_SEARCH_KEY: searchService.outputs.adminKey
      AZURE_SEARCH_USE_SEMANTIC_SEARCH: searchUseSemanticSearch
      AZURE_SEARCH_SEMANTIC_SEARCH_CONFIG: searchSemanticSearchConfig
      AZURE_SEARCH_TOP_K: searchTopK
      AZURE_SEARCH_ENABLE_IN_DOMAIN: searchEnableInDomain
      AZURE_SEARCH_CONTENT_COLUMNS: searchContentColumns
      AZURE_SEARCH_FILENAME_COLUMN: searchFilenameColumn
      AZURE_SEARCH_TITLE_COLUMN: searchTitleColumn
      AZURE_SEARCH_URL_COLUMN: searchUrlColumn
      // openai
      AZURE_OPENAI_RESOURCE: openAi.outputs.name
      AZURE_OPENAI_MODEL: openAIModel
      AZURE_OPENAI_MODEL_NAME: openAIModelName
      AZURE_OPENAI_KEY: openAi.outputs.key
      AZURE_OPENAI_TEMPERATURE: openAITemperature
      AZURE_OPENAI_TOP_P: openAITopP
      AZURE_OPENAI_MAX_TOKENS: openAIMaxTokens
      AZURE_OPENAI_STOP_SEQUENCE: openAIStopSequence
      AZURE_OPENAI_SYSTEM_MESSAGE: openAISystemMessage
      AZURE_OPENAI_STREAM: openAIStream
    }
  }
}


module openAi 'core/ai/cognitiveservices.bicep' = {
  name: 'openai'
  scope: openAiResourceGroup
  params: {
    name: !empty(openAiResourceName) ? openAiResourceName : 'cog-${namingPrefix}'
    location: openAiResourceGroupLocation
    tags: tags
    sku: {
      name: !empty(openAiSkuName) ? openAiSkuName : 'S0'
    }
    deployments: [
      {
        name: openAIModel
        model: {
          format: 'OpenAI'
          name: openAIModelName
          version: '0613'
        }
        capacity: 30
      }
      {
        name: embeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: embeddingModelName
          version: '2'
        }
        capacity: 30
      }
    ]
  }
}

module searchService 'core/search/search-services.bicep' = {
  name: 'search-service'
  scope: searchServiceResourceGroup
  params: {
    name: !empty(searchServiceName) ? searchServiceName : 'srch-${namingPrefix}'
    location: searchServiceResourceGroupLocation
    tags: tags
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    sku: {
      name: !empty(searchServiceSkuName) ? searchServiceSkuName : 'standard'
    }
    semanticSearch: 'free'
  }
}

// The application database
module cosmos 'db.bicep' = {
  name: 'cosmos'
  scope: resourceGroup
  params: {
    accountName: !empty(cosmosAccountName) ? cosmosAccountName : 'db-app-${forceCode}-copa'
    location: resourceGroup.location
    tags: tags
    principalIds: [principalId, backend.outputs.identityPrincipalId]
  }
}


// USER ROLES
module openAiRoleUser 'core/security/role.bicep' = {
  scope: openAiResourceGroup
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'User'
  }
}

module searchRoleUser 'core/security/role.bicep' = {
  scope: searchServiceResourceGroup
  name: 'search-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'User'
  }
}

module searchIndexDataContribRoleUser 'core/security/role.bicep' = {
  scope: searchServiceResourceGroup
  name: 'search-index-data-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: 'User'
  }
}

module searchServiceContribRoleUser 'core/security/role.bicep' = {
  scope: searchServiceResourceGroup
  name: 'search-service-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    principalType: 'User'
  }
}

// SYSTEM IDENTITIES
module openAiRoleBackend 'core/security/role.bicep' = {
  scope: openAiResourceGroup
  name: 'openai-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module searchRoleBackend 'core/security/role.bicep' = {
  scope: searchServiceResourceGroup
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
    namingPrefix: namingPrefix
    tags: tags
    principalId: principalId
    resourceGroupName: resourceGroup.name
    formRecognizerServiceName: formRecognizerServiceName
    formRecognizerResourceGroupName: formRecognizerResourceGroupName
    formRecognizerResourceGroupLocation: formRecognizerResourceGroupLocation
    formRecognizerSkuName: !empty(formRecognizerSkuName) ? formRecognizerSkuName : 'S0'
  }
}
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name

output BACKEND_URI string = backend.outputs.uri

// search
output AZURE_SEARCH_INDEX string = searchIndexName
output AZURE_SEARCH_SERVICE string = searchService.outputs.name
output AZURE_SEARCH_SERVICE_RESOURCE_GROUP string = searchServiceResourceGroup.name
output AZURE_SEARCH_SKU_NAME string = searchService.outputs.skuName
output AZURE_SEARCH_KEY string = searchService.outputs.adminKey
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
output AZURE_OPENAI_RESOURCE_GROUP string = openAiResourceGroup.name
output AZURE_OPENAI_ENDPOINT string = openAi.outputs.endpoint
output AZURE_OPENAI_MODEL string = openAIModel
output AZURE_OPENAI_MODEL_NAME string = openAIModelName
output AZURE_OPENAI_SKU_NAME string = openAi.outputs.skuName
output AZURE_OPENAI_KEY string = openAi.outputs.key
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
