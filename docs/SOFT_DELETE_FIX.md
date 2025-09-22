# Soft-Delete Fix for Cognitive Services Deployment

## Issue Description

The deployment was failing with the error:
```
"FlagMustBeSetForRestore": "An existing resource with ID '/subscriptions/5f58859e-6569-413a-a7f1-540a887d8728/resourceGroups/rg-btp-d-copa-stop-search/providers/Microsoft.CognitiveServices/accounts/doc-btp-d-copa-stop-search' has been soft-deleted. To restore the resource, you must specify 'restore' to be 'true' in the property."
```

## Root Cause

Azure Cognitive Services have a soft-delete feature. When a Cognitive Services resource is deleted, it's not permanently removed but placed in a "soft-deleted" state for a recovery period (typically 7-30 days). During this period, attempts to create a new resource with the same name in the same subscription and region will fail unless the `restore` flag is explicitly set to `true`.

The specific resource causing the issue was the Form Recognizer service: `doc-btp-d-copa-stop-search`, which follows the naming pattern `doc-${btpNamingPrefix}` where `btpNamingPrefix` is `btp-d-copa-stop-search` for development environments.

## Solution Implemented

### 1. Updated Cognitive Services Bicep Template
File: `infra/core/ai/cognitiveservices.bicep`
- Added `param restore bool = false` parameter
- Added `restore: restore` property to the cognitive services resource

### 2. Updated Document Preparation Template
File: `infra/docprep.bicep`
- Added `param restoreFormRecognizer bool = false` parameter
- Passed the restore parameter to the Form Recognizer module

### 3. Updated Main Infrastructure Template
File: `infra/main.bicep`
- Added `param restoreFormRecognizer bool = true` parameter (defaulting to `true` for the specific issue)
- Added `param restoreOpenAi bool = false` parameter (for future flexibility)
- Passed these parameters to the respective modules

## Usage

### For the Current Issue
The deployment should now work because `restoreFormRecognizer` defaults to `true`, which will restore the soft-deleted Form Recognizer resource.

### For Future Deployments
- **New environments**: Use default values (`restoreFormRecognizer = false`, `restoreOpenAi = false`)
- **Restoring from soft-delete**: Set the appropriate restore parameter to `true`

### Pipeline Parameter Examples
To override these parameters in the Azure DevOps pipeline, add to the parameter object:
```powershell
restoreFormRecognizer = $true   # To restore soft-deleted Form Recognizer
restoreOpenAi = $true          # To restore soft-deleted OpenAI service
```

## Files Modified
1. `infra/core/ai/cognitiveservices.bicep` - Added restore parameter support
2. `infra/docprep.bicep` - Added Form Recognizer restore parameter
3. `infra/main.bicep` - Added restore parameters for both services

## Testing
The Bicep template compiles successfully with `az bicep build --file infra/main.bicep`.

## Notes
- The `restoreFormRecognizer` parameter defaults to `true` specifically to fix the current deployment issue
- The `restoreOpenAi` parameter defaults to `false` as it's not currently needed but provides flexibility
- After the deployment succeeds, future deployments can use the default `false` values unless dealing with soft-deleted resources again