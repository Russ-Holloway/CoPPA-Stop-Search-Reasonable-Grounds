// Role assignments for deployment script managed identity
// This module assigns the necessary permissions for creating Azure AD app registrations

param principalId string
param principalType string = 'ServicePrincipal'

// Application Administrator role - needed to create and manage app registrations
resource appAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, 'Application Administrator')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3') // Application Administrator
    principalId: principalId
    principalType: principalType
    description: 'Allows deployment script to create and manage Azure AD app registrations'
  }
}

// User Access Administrator role - needed for role assignments during app registration setup
resource userAccessAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, 'User Access Administrator')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9') // User Access Administrator  
    principalId: principalId
    principalType: principalType
    description: 'Allows deployment script to manage role assignments for app registration'
  }
}

output appAdminRoleAssignmentId string = appAdminRole.name
output userAccessAdminRoleAssignmentId string = userAccessAdminRole.name
