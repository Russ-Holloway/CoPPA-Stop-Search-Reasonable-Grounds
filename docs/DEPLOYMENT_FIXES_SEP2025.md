# Azure Deployment Fixes - September 2025

## Issues Resolved

### 1. Key Vault Soft-Delete Issue
**Error**: `A vault with the same name already exists in deleted state. You need to either recover or purge existing key vault.`

**Solution**: Added Key Vault restore parameter support
- Added `restore` parameter to `infra/core/security/key-vault.bicep`
- Added `restoreKeyVault` parameter to `infra/main.bicep` (default: `true`)
- Key Vault uses `createMode: 'recover'` when `restore = true`

### 2. Form Recognizer Soft-Delete Issue
**Error**: `FlagMustBeSetForRestore` for Cognitive Services resource

**Solution**: Added Cognitive Services restore parameter support
- Added `restore` parameter to `infra/core/ai/cognitiveservices.bicep`
- Added `restoreFormRecognizer` parameter to `infra/docprep.bicep` and `infra/main.bicep`
- Added `restoreOpenAi` parameter for future flexibility

### 3. Private DNS Zone Policy Violations
**Error**: `Resource 'privatelink.blob.core.windows.net' was disallowed by policy` due to PDS Network Security policy

**Solution**: Made private DNS zones optional
- Added `enablePrivateDnsZones` parameter to `infra/main.bicep` (default: `false`)
- Updated all private DNS zone modules to use `enablePrivateEndpoints && enablePrivateDnsZones`
- Updated all private endpoint modules to handle missing DNS zones

## Template Changes Summary

### Parameters Added
```bicep
// Key Vault restore support
param restoreKeyVault bool = true

// Cognitive Services restore support  
param restoreFormRecognizer bool = true
param restoreOpenAi bool = false

// Private DNS zone control
param enablePrivateDnsZones bool = false
```

### Key Configuration Changes
1. **Private DNS Zones**: Disabled by default to comply with organizational policy
2. **Key Vault Restore**: Enabled by default to handle soft-deleted vault
3. **Form Recognizer Restore**: Enabled by default to handle soft-deleted service
4. **OpenAI Restore**: Available but disabled by default for future use

## Deployment Behavior

### Current Settings (for fixing immediate issues):
- `restoreKeyVault = true` - Will restore the soft-deleted Key Vault
- `restoreFormRecognizer = true` - Will restore the soft-deleted Form Recognizer
- `enablePrivateDnsZones = false` - Will skip DNS zone creation (policy compliant)
- Private endpoints will still be created but without DNS integration

### Future Deployments:
After successful deployment, you can optionally change:
- `restoreKeyVault = false`
- `restoreFormRecognizer = false` 
- `enablePrivateDnsZones = true` (if policy allows or is exempted)

## Files Modified
1. `infra/core/security/key-vault.bicep` - Added restore parameter
2. `infra/core/ai/cognitiveservices.bicep` - Added restore parameter  
3. `infra/docprep.bicep` - Added Form Recognizer restore parameter
4. `infra/main.bicep` - Added all restore and DNS control parameters
5. Updated all private DNS zone and private endpoint references

## Testing
Template compiles successfully with `az bicep build --file infra/main.bicep`

## Policy Compliance Notes
- The template now respects the PDS Network Security policy by not creating private DNS zones
- Private endpoints are still created for security but will require manual DNS configuration
- This is a common pattern in enterprise environments with strict networking policies

## Recovery Instructions
If deployment still fails:
1. **For Key Vault issues**: Verify the Key Vault name and purge any existing soft-deleted vault if restore fails
2. **For DNS policy issues**: Ensure `enablePrivateDnsZones = false` in deployment parameters
3. **For other soft-delete issues**: Check Azure portal for soft-deleted resources and either restore or purge them