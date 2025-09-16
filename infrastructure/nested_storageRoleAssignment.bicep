param resourceId_Microsoft_Web_sites_variables_WebsiteName object
param variables_StorageAccountName ? /* TODO: fill in correct type */
param variables_storageRoleAssignmentId ? /* TODO: fill in correct type */

resource variables_StorageAccountName_Microsoft_Authorization_variables_storageRoleAssignmentId 'Microsoft.Storage/storageAccounts/providers/roleAssignments@2022-04-01' = {
  name: '${variables_StorageAccountName}/Microsoft.Authorization/${variables_storageRoleAssignmentId}'
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalId: resourceId_Microsoft_Web_sites_variables_WebsiteName.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
