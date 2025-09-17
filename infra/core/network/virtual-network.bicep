param name string
param location string = resourceGroup().location
param tags object = {}

param addressPrefixes array = ['10.0.0.0/16']
param subnets array = []

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: contains(subnet, 'networkSecurityGroupId') ? {
          id: subnet.networkSecurityGroupId
        } : null
        delegations: contains(subnet, 'delegations') ? subnet.delegations : []
        privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies') ? subnet.privateEndpointNetworkPolicies : 'Disabled'
        privateLinkServiceNetworkPolicies: contains(subnet, 'privateLinkServiceNetworkPolicies') ? subnet.privateLinkServiceNetworkPolicies : 'Enabled'
        serviceEndpoints: contains(subnet, 'serviceEndpoints') ? subnet.serviceEndpoints : []
      }
    }]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = [for (subnet, index) in subnets: {
  parent: virtualNetwork
  name: subnet.name
}]

output id string = virtualNetwork.id
output name string = virtualNetwork.name
output subnets array = [for (subnet, index) in subnets: {
  id: virtualNetwork.properties.subnets[index].id
  name: subnet.name
  addressPrefix: subnet.addressPrefix
}]
