targetScope = 'resourceGroup'

param resourceName string
param logAnalyticsWorkspaceId string
param logs array = []
param metrics array = []

var diagnosticSettingsName = 'diagnostic-settings'

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingsName
  scope: resourceId('Microsoft.Search/searchServices', resourceName)
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: logs
    metrics: metrics
  }
}
