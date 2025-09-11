# Infrastructure Files

This folder contains the Azure deployment templates for the CoPA Stop & Search application.

## Files

### 📋 `deployment.json` (32KB)
**Main ARM template** for Azure deployment
- Contains all Azure resource definitions
- **NO AuthClientSecret parameter** - authentication configured post-deployment only
- Used by the "Deploy to Azure" button
- **Upload to storage as:** `deployment.json`

### 🖥️ `createUiDefinition.json` (7.6KB)
**UI definition** for Azure Portal deployment experience
- PDS-compliant deployment interface for UK Police Forces
- Includes model selection (GPT-4o, embeddings)
- Contains post-deployment authentication info
- **Upload to storage as:** `createUiDefinition.json`

### 🧪 `test_search_only.json` (7.8KB)
**Test template** (optional)
- Used for testing search service deployment only
- Can be ignored for main deployments

## Usage

### For Deploy to Azure Button
Both `deployment.json` and `createUiDefinition.json` must be uploaded to:
- **Storage Account:** `stcopadeployment02`
- **Container:** `copa-deployment`
- **Names:** Keep the same names when uploading

### Upload Methods
1. **Automated:** Run `./upload_template.sh` or `.\upload_template.ps1`
2. **Manual:** Upload via Azure Portal → Storage Account → Container

## Key Features
- ✅ **Post-deployment authentication** - No client secrets needed during deployment
- ✅ **PDS naming compliance** - Automatic naming for UK police forces
- ✅ **Model selection** - Choose GPT and embedding models during deployment
- ✅ **Clean, single-source** - Only the files you need, no duplicates

## Matching Guarantee
The files in this folder are exactly what should be uploaded to the storage account. No more confusion about which version to use!
