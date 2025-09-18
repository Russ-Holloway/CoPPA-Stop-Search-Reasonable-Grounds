param keyVaultName string
param objectId string
param tenantId string = tenant().tenantId
param permissions object = {
  secrets: ['get']
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: objectId
        permissions: permissions
      }
    ]
  }
}
