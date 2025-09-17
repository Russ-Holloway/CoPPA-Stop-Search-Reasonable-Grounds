param name string
param location string = resourceGroup().location
param tags object = {}

param securityRules array = []

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules: securityRules
  }
}

output id string = networkSecurityGroup.id
output name string = networkSecurityGroup.name
