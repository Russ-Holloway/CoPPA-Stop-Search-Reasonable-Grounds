// Placeholder for App Registration - This will be created via Azure CLI/PowerShell script
// Since Azure AD App Registrations cannot be created directly in Bicep templates,
// we use deployment scripts to create the app registration and pass the values back

targetScope = 'resourceGroup'

@description('The display name for the application registration')
param appName string

@description('The App Service URL that will use this app registration')
param appServiceUrl string

@description('Environment name for naming consistency')
param environmentName string

@description('Location for deployment script resources')
param location string = resourceGroup().location

@description('Tags for resources')
param tags object = {}

// User-assigned managed identity for the deployment script
resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-script-${appName}-${environmentName}'
  location: location
  tags: tags
}

// Role assignments for the script identity
module scriptRoles 'script-identity-roles.bicep' = {
  name: 'script-identity-roles'
  params: {
    principalId: scriptIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deployment script to create Azure AD App Registration
resource appRegistrationScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'script-create-app-registration-${environmentName}'
  location: location
  tags: tags
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${scriptIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '11.0'
    retentionInterval: 'PT1H'
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    environmentVariables: [
      {
        name: 'AUTHENTICATION_ENDPOINT'
        value: environment().authentication.loginEndpoint
      }
    ]
    scriptContent: '''
      param(
        [string]$AppName,
        [string]$AppServiceUrl,
        [string]$EnvironmentName
      )
      
      # Install required modules if not present
      if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Applications)) {
        Install-Module -Name Microsoft.Graph.Applications -Force -Scope CurrentUser
      }
      if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module -Name Microsoft.Graph.Authentication -Force -Scope CurrentUser
      }
      
      # Connect to Microsoft Graph
      Connect-MgGraph -Identity
      
      $redirectUri = "$AppServiceUrl/.auth/login/aad/callback"
      $identifierUri = "api://$AppName-$EnvironmentName"
      
      # Check if app registration already exists
      $existingApp = Get-MgApplication -Filter "displayName eq '$AppName'"
      
      if ($existingApp) {
        Write-Output "App registration already exists: $($existingApp.DisplayName)"
        $appRegistration = $existingApp
      } else {
        # Create new app registration
        $appParams = @{
          DisplayName = $AppName
          Description = "Azure AD App Registration for $AppName - Environment: $EnvironmentName"
          SignInAudience = "AzureADMyOrg"
          Web = @{
            RedirectUris = @($redirectUri)
            ImplicitGrantSettings = @{
              EnableIdTokenIssuance = $true
              EnableAccessTokenIssuance = $false
            }
          }
          Api = @{
            AcceptMappedClaims = $true
            RequestedAccessTokenVersion = 2
          }
          RequiredResourceAccess = @(
            @{
              ResourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
              ResourceAccess = @(
                @{
                  Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
                  Type = "Scope"
                }
              )
            }
          )
          IdentifierUris = @($identifierUri)
        }
        
        $appRegistration = New-MgApplication @appParams
        Write-Output "Created app registration: $($appRegistration.DisplayName)"
      }
      
      # Create service principal if it doesn't exist
      $servicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$($appRegistration.AppId)'"
      if (-not $servicePrincipal) {
        $spParams = @{
          AppId = $appRegistration.AppId
          DisplayName = $appRegistration.DisplayName
          Description = "Service Principal for $AppName"
          ServicePrincipalType = "Application"
          AppRoleAssignmentRequired = $false
          Tags = @("CoPA-Stop-Search", $EnvironmentName, "WebApp", "Authentication")
        }
        $servicePrincipal = New-MgServicePrincipal @spParams
        Write-Output "Created service principal: $($servicePrincipal.DisplayName)"
      }
      
      # Create client secret
      $secretParams = @{
        DisplayName = "$AppName-client-secret-$EnvironmentName"
        EndDateTime = (Get-Date).AddYears(2)
      }
      $clientSecret = Add-MgApplicationPassword -ApplicationId $appRegistration.Id -BodyParameter $secretParams
      
      # Set outputs
      $DeploymentScriptOutputs = @{
        applicationId = $appRegistration.AppId
        clientId = $appRegistration.AppId
        tenantId = (Get-MgContext).TenantId
        servicePrincipalId = $servicePrincipal.Id
        clientSecret = $clientSecret.SecretText
        issuerUri = "$env:AUTHENTICATION_ENDPOINT$((Get-MgContext).TenantId)/v2.0"
        redirectUri = $redirectUri
      }
    '''
    arguments: '-AppName "${appName}" -AppServiceUrl "${appServiceUrl}" -EnvironmentName "${environmentName}"'
  }
  dependsOn: [
    scriptRoles
  ]
}

// Outputs from the deployment script
output applicationId string = appRegistrationScript.properties.outputs.applicationId
output clientId string = appRegistrationScript.properties.outputs.clientId
output tenantId string = appRegistrationScript.properties.outputs.tenantId
output servicePrincipalId string = appRegistrationScript.properties.outputs.servicePrincipalId
output clientSecret string = appRegistrationScript.properties.outputs.clientSecret
output issuerUri string = appRegistrationScript.properties.outputs.issuerUri
output redirectUri string = appRegistrationScript.properties.outputs.redirectUri
