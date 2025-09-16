#!/bin/bash

# Set your Azure DevOps Personal Access Token here
# Replace 'YOUR_PAT_TOKEN_HERE' with your actual PAT token

export AZURE_DEVOPS_EXT_PAT='6f7zCPRbQO5pBPihUZQdICO4gjgIEQ9LQL6yFIhMclxNRS4LYlDEJQQJ99BIACAAAAA5z9H3AAASAZDO4BMW'

echo "Azure DevOps PAT has been set!"
echo "You can now run Azure DevOps CLI commands."

# Test the connection
az devops project show --project "CoPA-Stop-Search-Secure-Deployment" --organization "https://dev.azure.com/uk-police-copa/"