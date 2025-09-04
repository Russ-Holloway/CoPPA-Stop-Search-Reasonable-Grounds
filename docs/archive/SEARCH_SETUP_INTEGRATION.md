# Search Setup Integration

This document explains how search components are automatically set up during deployment and how to maintain the script.

## How Search Setup Works in One-Click Deployment

When a user clicks the "Deploy to Azure" button:

1. The ARM template (`infrastructure/deployment.json`) is deployed, which:
   - Creates all Azure resources (Web App, OpenAI, Search, Storage)
   - Runs a PowerShell deployment script (`setup_search_components.ps1`) that:
     - Creates search index, data sources, skillsets, and indexers
     - Configures vector search capabilities
     - Sets up proper connections between components

2. As a backup, when the web app first starts up:
   - The Python script (`backend/search_setup.py`) checks if search components exist
   - If missing, it creates them automatically

**No manual setup is required** after deployment.

## How to Update the ARM Template's Script

The ARM template references a PowerShell script stored in Azure Blob Storage:
```
https://stbtpukssandopenai.blob.core.windows.net/policing-assistant-azure-deployment-template/setup_search_components.ps1
```

To update the script used by the ARM template:

1. Make changes to `scripts/setup-search-components.ps1`
2. Test the script locally
3. Upload the script to replace the one in Azure Blob Storage:

```powershell
.\scripts\upload_search_script.ps1 -StorageAccountName "stbtpukssandopenai" -ContainerName "policing-assistant-azure-deployment-template" -SasToken "?sp=racwdl&st=..."
```

4. Test the one-click deployment to verify the changes

## Keeping Scripts in Sync

To ensure the local script and ARM template script stay in sync:

1. Always make changes to `scripts/setup-search-components.ps1` first
2. Use the upload script to update the ARM template's script
3. Document any significant changes

## Troubleshooting Automatic Setup

If search components aren't configured properly after deployment:

1. Check the deployment logs in the Azure Portal
2. Verify if the ARM template's deployment script ran successfully
3. Check the web app logs to see if the backup script ran
4. If both failed, manually run the script:

```powershell
.\scripts\setup-search-components.ps1 -ResourceGroupName "your-resource-group-name" -SearchServiceName "your-search-service-name" -StorageAccountName "your-storage-account-name" -OpenAIServiceName "your-openai-service-name"
```
