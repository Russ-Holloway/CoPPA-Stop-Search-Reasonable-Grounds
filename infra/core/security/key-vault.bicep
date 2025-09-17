param name string
param location string = resourceGroup().location
param tags object = {}

@description('SKU for the Key Vault')
@allowed(['standard', 'premium'])
param skuName string = 'standard'

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed(['A', 'B'])
param skuFamily string = 'A'

param enabledForDeployment bool = false
param enabledForTemplateDeployment bool = false
param enabledForDiskEncryption bool = false
param enableSoftDelete bool = true
param softDeleteRetentionInDays int = 90
param enablePurgeProtection bool = true

@description('The access policies for the Key Vault')
param accessPolicies array = []

@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Disabled'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: skuFamily
      name: skuName
    }
    accessPolicies: accessPolicies
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

output id string = keyVault.id
output name string = keyVault.name
output vaultUri string = keyVault.properties.vaultUri
