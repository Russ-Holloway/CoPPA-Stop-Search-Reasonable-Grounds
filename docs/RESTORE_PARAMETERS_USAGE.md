# Restore Parameters Usage Guide

## Overview

The Bicep templates now include restore parameters to handle Azure soft-delete scenarios for Cognitive Services and Key Vault resources. These parameters should only be set to `true` when you need to restore a resource that is actually in a soft-deleted state.

## Error Resolution

### "CanNotRestoreAnActiveResource" Error

**Error Message:**
```
"CanNotRestoreAnActiveResource": "Could not restore an active account '/subscriptions/.../providers/Microsoft.CognitiveServices/accounts/resource-name'."
```

**Cause:** The resource exists and is active, but the restore parameter is set to `true`.

**Solution:** Set the restore parameter to `false` (which is now the default).

### "FlagMustBeSetForRestore" Error

**Error Message:**
```
"FlagMustBeSetForRestore": "An existing resource with ID '...' has been soft-deleted. To restore the resource, you must specify 'restore' to be 'true' in the property."
```

**Cause:** The resource is in a soft-deleted state and needs to be restored.

**Solution:** Set the appropriate restore parameter to `true`.

## Current Parameter Defaults

```bicep
param restoreKeyVault bool = false           // Default: false (normal deployment)
param restoreFormRecognizer bool = false     // Default: false (normal deployment)  
param restoreOpenAi bool = false            // Default: false (normal deployment)
```

## When to Override Parameters

### For Normal Deployments (Default)
Use the default values (`false`) when:
- Deploying to a new environment
- Resources have never been created before
- Resources were properly deleted (not soft-deleted)

### For Restoring Soft-Deleted Resources
Set to `true` only when:
- You get a "FlagMustBeSetForRestore" error
- You know the specific resource is in soft-deleted state
- You want to recover a previously deleted resource

## Pipeline Parameter Examples

### Normal Deployment (Recommended)
```powershell
# Use defaults - no override needed
$parameters = @{
    # ... other parameters
}
```

### Restore Specific Resources
```powershell
# Only if you get soft-delete errors
$parameters = @{
    restoreFormRecognizer = $true     # Only if Form Recognizer is soft-deleted
    restoreKeyVault = $true          # Only if Key Vault is soft-deleted
    restoreOpenAi = $true            # Only if OpenAI service is soft-deleted
    # ... other parameters
}
```

## Best Practices

1. **Start with defaults** - Always try deployment with default `false` values first
2. **React to errors** - Only set restore parameters to `true` if you get soft-delete errors
3. **Be specific** - Only set the restore parameter for the specific resource that's soft-deleted
4. **Reset after success** - After successful restoration, change back to `false` for future deployments

## Resource Naming Patterns

The resources follow these naming patterns (useful for identifying which restore parameter to use):

- **Form Recognizer:** `doc-btp-{env}-copa-stop-search` → use `restoreFormRecognizer`
- **Key Vault:** `kv-{env}-copa-ss-{instance}` → use `restoreKeyVault`  
- **OpenAI Service:** `cog-btp-{env}-copa-stop-search-{instance}` → use `restoreOpenAi`

## Troubleshooting

### If deployment still fails after setting restore=false:
1. Check if the resource actually exists in the portal
2. Verify the resource name matches the expected pattern
3. Ensure you have the correct permissions
4. Check for other policy violations (like private DNS zones)

### If you're unsure about resource state:
1. Check Azure portal for the specific resource
2. Look for "deleted" or "soft-deleted" status
3. Use Azure CLI: `az cognitiveservices account list --query "[?name=='resource-name']"`
4. Use Azure CLI: `az keyvault list-deleted --query "[?name=='resource-name']"`