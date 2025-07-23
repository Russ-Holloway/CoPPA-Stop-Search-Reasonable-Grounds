# Template Hosting Setup for One-Click Deployment

This guide helps you set up your ARM templates for one-click deployment by storing them in Azure Blob Storage with proper CORS configuration.

## Problem Solved

When users click the "Deploy to Azure" button, Azure tries to fetch your ARM templates (deployment.json and createUiDefinition.json) directly from GitHub. However, GitHub's raw content URLs don't have CORS headers enabled, resulting in this error:

```
There was an error downloading the template from URI '...'. Ensure that the template is publicly accessible and that the publisher has enabled CORS policy on the endpoint.
```

These scripts help upload your templates to Azure Blob Storage with CORS properly configured to solve this issue.

## Prerequisites

- Azure CLI installed and logged in, or Azure PowerShell installed and connected
- An existing resource group and storage account (or permission to create them)

## Instructions for PowerShell

1. Open PowerShell and navigate to your project root directory
2. Run the script with your resource group and storage account names:

```powershell
# Install Azure PowerShell if not already installed
# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

# Connect to Azure if not already connected
# Connect-AzAccount

# Run the script
./scripts/setup_template_hosting.ps1 -resourceGroupName "YourResourceGroup" -storageAccountName "yourstorageaccount"
```

## Instructions for Bash

1. Open a terminal and navigate to your project root directory
2. Make the script executable:

```bash
chmod +x ./scripts/setup_template_hosting.sh
```

3. Run the script with your resource group and storage account names:

```bash
# Install Azure CLI if not already installed
# Follow instructions at https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Login to Azure if not already logged in
# az login

# Run the script
./scripts/setup_template_hosting.sh YourResourceGroup yourstorageaccount
```

## Using the Deployment URL

The scripts will output a deployment URL that looks like:

```
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fyourstorageaccount.blob.core.windows.net%2Ftemplates%2Fdeployment.json/createUIDefinitionUri/https%3A%2F%2Fyourstorageaccount.blob.core.windows.net%2Ftemplates%2FcreateUiDefinition.json
```

Use this URL for your "Deploy to Azure" button in your documentation. Users will be directed to the Azure Portal with your template pre-loaded, showing only the options you've defined in your createUiDefinition.json.

## Testing CORS Configuration

To verify that CORS is correctly configured, the scripts provide a test command you can run.

## Troubleshooting

If you still encounter CORS issues:
1. Ensure the storage account has public access enabled for blobs
2. Verify CORS is configured to allow access from portal.azure.com
3. Check that the content type for uploaded files is "application/json"
