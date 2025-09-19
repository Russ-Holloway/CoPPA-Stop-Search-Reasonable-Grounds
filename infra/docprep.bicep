targetScope = 'subscription'

param resourceGroupName string
param location string
param tags object = {}
param principalId string
param resourceToken string
param namingPrefix string = ''
param deployUserRoles bool = true

param formRecognizerServiceName string = ''
// param formRecognizerResourceGroupName string = ''
// param formRecognizerResourceGroupLocation string = location
param formRecognizerSkuName string = 'S0'

var abbrs = loadJsonContent('abbreviations.json')

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
}

module formRecognizer 'core/ai/cognitiveservices.bicep' = {
  name: 'formrecognizer'
  scope: resourceGroup
  params: {
    name: !empty(formRecognizerServiceName) ? formRecognizerServiceName : !empty(namingPrefix) ? 'doc-${namingPrefix}' : '${abbrs.cognitiveServicesFormRecognizer}${resourceToken}'
    kind: 'FormRecognizer'
    location: location
    tags: tags
    sku: {
      name: formRecognizerSkuName
    }
  }
}

module formRecognizerRoleUser 'core/security/role.bicep' = if (deployUserRoles && !empty(principalId)) {
  scope: resourceGroup
  name: 'formrecognizer-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
    principalType: 'User'
  }
}

// Used by prepdocs
// Form recognizer
output AZURE_FORMRECOGNIZER_SERVICE string = formRecognizer.outputs.name
output AZURE_FORMRECOGNIZER_RESOURCE_GROUP string = resourceGroup.name
output AZURE_FORMRECOGNIZER_SKU_NAME string = formRecognizerSkuName
output AZURE_FORMRECOGNIZER_ID string = formRecognizer.outputs.id
