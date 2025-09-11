# Setting Up Automated Deployment Template Publishing

This guide explains how to set up the infrastructure and pipeline for publishing your deployment.json template to a public Azure Storage container with CORS enabled, allowing users to deploy your solution with a single click.

## Prerequisites

1. Azure subscription
2. Azure DevOps project with your code repository
3. Permissions to create Azure resources and configure Azure DevOps pipelines

## Step 1: Set Up Azure Storage with CORS

Run the provided PowerShell script to create a public Azure Blob Storage container with CORS enabled:

```powershell
./scripts/setup_public_storage.ps1 -ResourceGroupName "rg-policing-assistant-public" -StorageAccountName "sapolassistdeployment" -ContainerName "templates" -Location "uksouth"
```

> **Note:** Choose a globally unique storage account name and an appropriate Azure region.

## Step 2: Configure the Azure DevOps Pipeline

1. In your Azure DevOps project, go to **Pipelines** > **New Pipeline**
2. Select your repository
3. Select **Existing Azure Pipelines YAML file**
4. Choose the `azure-pipelines-deployment.yml` file
5. Update the variables in the YAML file with your own values:
   - `resourceGroupName`: The resource group created in Step 1
   - `storageAccountName`: The storage account created in Step 1
   - `containerName`: The container created in Step 1
   - `Your-Azure-Service-Connection`: Your Azure service connection name
6. Save and run the pipeline

## Step 3: Obtain the Deployment URL

After the pipeline runs successfully:

1. Go to the completed pipeline run
2. Click on **Artifacts** 
3. Download the **DeploymentURL** artifact
4. Open the `deployment_url.txt` file to get the URL with SAS token
5. Use this URL in your "Deploy to Azure" button in the README.md file

## Step 4: Update the README.md with the Deploy Button

Update your README.md file with the following markdown, replacing `YOUR_URL_HERE` with the URL from Step 3:

```markdown
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FRuss-Holloway%2FCoPA%2Fmain%2Finfrastructure%2Fdeployment.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FRuss-Holloway%2FCoPA%2Fmain%2Finfrastructure%2FcreateUiDefinition-pds.json)
```

## Troubleshooting

- **CORS Issues**: Verify the CORS settings with: `az storage account cors show --account-name <storage-account-name>`
- **Pipeline Failures**: Check service connection permissions and ensure the agent has access to Azure
- **SAS Token Expiration**: The pipeline generates a SAS token valid for 1 year. Schedule a pipeline run before expiration to refresh it

## Security Considerations

- The deployment template is publicly accessible (though obscured by the SAS token)
- Do not include secrets in your deployment template
- Consider regenerating the SAS token periodically for better security
