# Automated Search Component Setup

CoPPA (College of Policing Assistant) includes fully automated setup for Azure Cognitive Search components. This document explains how this automation works and what happens during deployment.

## True One-Click Deployment

The system provides a true "one-click" deployment experience with search components automatically configured through two mechanisms:

### 1. ARM Template Deployment Script (Primary Method)
During ARM template deployment, a PowerShell script (`setup_search_components.ps1`) runs to:
- Create and configure the search index with vector capabilities
- Set up data sources connected to blob storage
- Configure skillsets for document processing
- Create and run indexers
- Upload sample documents

This script is defined in the ARM template as a `Microsoft.Resources/deploymentScripts` resource and runs automatically after all dependent resources are deployed.

### 2. Application Startup Automation (Backup Method)
As a fallback mechanism, the web application also includes automation that runs during startup:
- The `backend/search_setup.py` script checks if search components exist
- If components are missing, it creates and configures them
- This ensures search functionality even if the ARM deployment script encounters issues

## What The Automation Does

Both automation approaches perform the same core setup tasks:

1. Creates a search index with vector search capabilities
2. Sets up a data source connected to blob storage
3. Configures two skillsets for document processing:
   - Text processing skillset for document splitting and language detection
   - AI enrichment skillset using Azure OpenAI for embeddings and categorization
4. Creates an indexer to connect everything together
5. Uploads sample policing documents to provide immediate value

## How It Works

The automation is implemented through these components:

1. **ARM Template Deployment Script**: A PowerShell script that runs as part of the ARM template deployment
2. **Storage Account**: Automatically created to store documents
3. **Python Setup Script**: Runs during web app startup as a backup method
4. **Sample Documents**: Automatically uploaded to provide immediate value

## Technical Implementation

### ARM Template Deployment Script
The primary method is the PowerShell script that runs during ARM template deployment:
- Located at: `https://stbtpukssandopenai.blob.core.windows.net/policing-assistant-azure-deployment-template/setup_search_components.ps1`
- Identical to the `scripts/setup-search-components.ps1` script in the repository
- Uses a managed identity to access Azure resources
- Creates and configures all search components

### Application Startup Implementation (Backup Method)
The `backend/search_setup.py` script runs automatically when the web app starts up as a backup method:

1. Checks if search components already exist
2. Creates or connects to the blob storage container if needed
3. Uploads sample policing documents from the data directory
4. Creates the search index with vector search configuration if missing
5. Sets up data sources, skillsets, and the indexer if needed
6. Configures the proper search query type in application settings

## Verification

You can verify the automated setup worked by:

1. Navigating to your Azure Cognitive Search service in the Azure Portal
2. Checking that the index, indexer, data sources, and skillsets exist
3. Viewing the indexer execution history to confirm documents were indexed
4. Testing the search functionality in the CoPPA application

## Troubleshooting

### ARM Deployment Script Issues
If the deployment script failed:
1. Check the deployment details in the Azure Portal
2. Look for errors in the deployment script output
3. Verify resource dependencies were created correctly
4. Run the script manually using `.\scripts\setup-search-components.ps1`

### Application Startup Issues
If the app startup automation failed:

1. Check the web app logs for any error messages
2. Verify that the storage account and container were created successfully
3. Check that the search service has the correct permissions
4. Ensure the Azure OpenAI models are deployed correctly

## Adding More Documents

You can add more documents to the system at any time:

1. Navigate to the storage account in the Azure Portal
2. Open the "documents" container
3. Upload additional policing-related documents
4. The indexer will process these documents on its scheduled run, or you can manually run the indexer in the Azure Portal
