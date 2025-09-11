# Test Deploy to Azure URLs

## Current Issue
The Deploy to Azure button uses SAS tokens from July 23, 2025, which point to cached/old versions of the templates.

## Test URLs (Direct Access)
Open these in your browser to verify your updated files:

**Deployment Template:**
https://stcopadeployment02.blob.core.windows.net/copa-deployment/deployment.json

**UI Definition:**
https://stcopadeployment02.blob.core.windows.net/copa-deployment/createUiDefinition.json

## Expected Results
If your files were uploaded correctly, you should see:
- ✅ **NO AuthClientSecret parameter** in deployment.json
- ✅ **NO AuthClientSecret output** in createUiDefinition.json
- ✅ Only AzureOpenAIModelName and AzureOpenAIEmbeddingName parameters

## If Files Are Correct
If the above URLs show your updated files, then the issue is the cached SAS tokens in the Deploy button URL.

## Solutions

### Solution 1: Generate New SAS Tokens
Run the upload script to generate fresh URLs:
```bash
./upload_template.sh  # Will output new Deploy to Azure URL
```

### Solution 2: Temporary Public Access
If you can make the storage container temporarily public:
1. Storage Account → Containers → copa-deployment → Change access level to "Blob"
2. Use this simple Deploy URL (no SAS needed):

```
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fstcopadeployment02.blob.core.windows.net%2Fcopa-deployment%2Fdeployment.json/createUIDefinitionUri/https%3A%2F%2Fstcopadeployment02.blob.core.windows.net%2Fcopa-deployment%2FcreateUiDefinition.json
```

### Solution 3: Manual SAS Generation
1. Azure Portal → Storage Account → Container → File → Generate SAS
2. Set permissions: Read, Expiry: 1 year from today
3. Copy the full URL with new SAS token
4. Update README.md with new URL
