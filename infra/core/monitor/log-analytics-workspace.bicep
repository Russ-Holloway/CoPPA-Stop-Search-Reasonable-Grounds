param name string
param location string = resourceGroup().location
param tags object = {}

@allowed(['PerGB2018', 'PerNode', 'Premium', 'Standalone', 'Standard', 'CapacityReservation'])
param skuName string = 'PerGB2018'

@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@allowed(['Enabled', 'Disabled'])
param publicNetworkAccessForIngestion string = 'Disabled'

@allowed(['Enabled', 'Disabled'])
param publicNetworkAccessForQuery string = 'Disabled'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
  }
}

output id string = logAnalyticsWorkspace.id
output name string = logAnalyticsWorkspace.name
output customerId string = logAnalyticsWorkspace.properties.customerId
