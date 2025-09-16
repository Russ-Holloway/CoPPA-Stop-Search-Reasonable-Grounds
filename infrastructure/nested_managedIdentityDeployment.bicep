param variables_deployScriptIdentityName ? /* TODO: fill in correct type */

@description('The location for all resources.')
param location string

resource variables_deployScriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: variables_deployScriptIdentityName
  location: location
}
