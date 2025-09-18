param keyVaultName string
param secretName string
@secure()
param secretValue string
param contentType string = ''
param enabled bool = true

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: secretName
  properties: {
    value: secretValue
    contentType: contentType
    attributes: {
      enabled: enabled
    }
  }
}

output secretUri string = secret.properties.secretUri
output secretName string = secret.name
output secretId string = secret.id
