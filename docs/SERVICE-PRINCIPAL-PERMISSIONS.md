# Service Principal Permissions for Azure AD App Registration

This document describes the permissions required for the Azure DevOps service principal to automatically create Azure AD app registrations during deployment.

## Issue Description

When running the deployment pipeline, you may encounter the following error:
```
ERROR: Insufficient privileges to complete the operation.
```

This occurs because the service principal used by Azure DevOps lacks the necessary permissions to create and manage Azure AD app registrations.

## Required Microsoft Graph API Permissions

The Azure DevOps service principal needs the following **Application Permissions** in Microsoft Graph API:

### Essential Permissions
1. **Application.ReadWrite.All**
   - Allows creating, reading, updating, and deleting applications
   - Required for creating the Azure AD app registration

2. **Directory.Read.All**
   - Allows reading directory data
   - Required for checking existing app registrations and tenant information

### Additional Recommended Permissions (Optional)
3. **Application.ReadWrite.OwnedBy**
   - Alternative to Application.ReadWrite.All with more restricted scope
   - Only allows managing applications owned by the service principal

## How to Grant Permissions

### Option 1: Using Azure Portal (Recommended)

1. **Navigate to Azure Active Directory**
   - Go to [Azure Portal](https://portal.azure.com)
   - Select "Azure Active Directory"

2. **Find the Service Principal**
   - Go to "Enterprise applications"
   - Search for your Azure DevOps service connection name (e.g., "BTP-Development" or "BTP-Production")
   - Click on the application

3. **Request API Permissions**
   - Go to "API permissions"
   - Click "Add a permission"
   - Select "Microsoft Graph"
   - Choose "Application permissions"
   - Search for and add:
     - `Application.ReadWrite.All`
     - `Directory.Read.All`
   - Click "Add permissions"

4. **Grant Admin Consent**
   - Click "Grant admin consent for [Your Organization]"
   - Confirm the consent

### Option 2: Using Azure CLI

```bash
# Get the service principal object ID
SERVICE_PRINCIPAL_NAME="BTP-Development"  # Or your service connection name
SP_OBJECT_ID=$(az ad sp list --display-name "$SERVICE_PRINCIPAL_NAME" --query "[0].id" -o tsv)

# Get Microsoft Graph App ID
GRAPH_APP_ID="00000003-0000-0000-c000-000000000000"

# Get the required permission IDs
APP_READWRITE_ALL_ID="1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"
DIRECTORY_READ_ALL_ID="7ab1d382-f21e-4acd-a863-ba3e13f7da61"

# Assign the permissions
az rest --method POST --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" \
  --body "{\"principalId\":\"$SP_OBJECT_ID\",\"resourceId\":\"$(az ad sp list --filter "appId eq '$GRAPH_APP_ID'" --query "[0].id" -o tsv)\",\"appRoleId\":\"$APP_READWRITE_ALL_ID\"}"

az rest --method POST --url "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignments" \
  --body "{\"principalId\":\"$SP_OBJECT_ID\",\"resourceId\":\"$(az ad sp list --filter "appId eq '$GRAPH_APP_ID'" --query "[0].id" -o tsv)\",\"appRoleId\":\"$DIRECTORY_READ_ALL_ID\"}"
```

### Option 3: Using PowerShell with Microsoft Graph

```powershell
# Connect to Microsoft Graph (requires admin privileges)
Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.Read.All"

# Get the service principal
$servicePrincipal = Get-MgServicePrincipal -Filter "displayName eq 'BTP-Development'"

# Get Microsoft Graph service principal
$graphServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Define required app roles
$appRoles = @(
    @{
        Id = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"  # Application.ReadWrite.All
        DisplayName = "Application.ReadWrite.All"
    },
    @{
        Id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"  # Directory.Read.All
        DisplayName = "Directory.Read.All"
    }
)

# Assign app roles
foreach ($appRole in $appRoles) {
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipal.Id -PrincipalId $servicePrincipal.Id -ResourceId $graphServicePrincipal.Id -AppRoleId $appRole.Id
}
```

## Alternative Solutions

If you cannot grant the required permissions, you have these alternatives:

### Option A: Manual App Registration Creation

1. **Create App Registration Manually**
   - Go to Azure Portal > Azure Active Directory > App registrations
   - Click "New registration"
   - Name: `CoPA-Stop-Search-[Environment]-001` (e.g., `CoPA-Stop-Search-Dev-001`)
   - Redirect URI: `https://[your-app-service-name].azurewebsites.net/.auth/login/aad/callback`

2. **Create Client Secret**
   - In the app registration, go to "Certificates & secrets"
   - Click "New client secret"
   - Add description and expiration
   - Copy the secret value

3. **Configure Pipeline Variables**
   Set these variables in your Azure DevOps pipeline:
   ```
   AUTH_CLIENT_ID: [Application ID from step 1]
   AUTH_CLIENT_SECRET: [Secret value from step 2] (mark as secret)
   ```

### Option B: Update Pipeline to Skip App Registration

You can modify the pipeline to skip automatic app registration creation by setting:
```yaml
variables:
  createAppRegistration: false
```

## Verification

To verify that permissions have been granted correctly:

1. **Using Azure Portal**
   - Navigate to Azure Active Directory > Enterprise applications
   - Find your service principal
   - Go to "Permissions" and verify the granted permissions

2. **Using Azure CLI**
   ```bash
   # List granted permissions
   az ad sp list --display-name "BTP-Development" --query "[0].appRoleAssignments"
   ```

## Security Considerations

- **Principle of Least Privilege**: Only grant the minimum permissions required
- **Regular Review**: Periodically review and audit service principal permissions
- **Rotation**: Regularly rotate service principal credentials
- **Monitoring**: Monitor service principal usage and access patterns

## Troubleshooting

### Common Issues

1. **"Insufficient privileges" Error**
   - Verify permissions are granted as Application permissions (not Delegated)
   - Ensure admin consent has been granted
   - Check that the correct service principal is being used

2. **"Permission not found" Error**
   - Verify the permission IDs are correct
   - Ensure you're using the Microsoft Graph API (not Azure AD Graph)

3. **Pipeline Still Failing After Permission Grant**
   - Permissions may take a few minutes to propagate
   - Restart the pipeline after waiting 5-10 minutes
   - Verify the service connection is using the correct service principal

### Support Contacts

For assistance with granting these permissions, contact:
- Your Azure AD Administrator
- Cloud Platform Team
- DevOps Support Team

## References

- [Microsoft Graph permissions reference](https://docs.microsoft.com/en-us/graph/permissions-reference)
- [Azure AD application permissions](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent)
- [Azure DevOps service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)