#!/bin/bash

# Deployment script for College of Policing Assistant
# This script will deploy all the necessary Azure resources for the College of Policing Assistant

# Default values
RESOURCE_GROUP="college-policing-assistant-rg"
LOCATION="eastus"
DEPLOYMENT_NAME="policing-assistant-deployment"
WEBSITE_NAME="policing-assistant-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)"
OPENAI_NAME="oai-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)"
SEARCH_NAME="search-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║              Policing Assistant Deployment                  ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
echo "Checking Azure login status..."
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo "You are not logged in to Azure. Please login first."
    az login
fi

# Display available subscriptions
echo "Available subscriptions:"
az account list --query "[].{name:name, id:id, isDefault:isDefault}" -o table

# Confirm subscription
read -p "Do you want to use the default subscription? (y/n): " use_default
if [[ "$use_default" != "y" && "$use_default" != "Y" ]]; then
    az account list --query "[].{name:name, id:id}" -o table
    read -p "Enter the subscription ID to use: " SUBSCRIPTION_ID
    az account set --subscription "$SUBSCRIPTION_ID"
fi

# Display current subscription
echo "Using subscription:"
az account show --query "{name:name, id:id}" -o table

# Customize deployment
read -p "Resource Group Name [$RESOURCE_GROUP]: " input
RESOURCE_GROUP=${input:-$RESOURCE_GROUP}

read -p "Location [$LOCATION]: " input
LOCATION=${input:-$LOCATION}

read -p "Web App Name [$WEBSITE_NAME]: " input
WEBSITE_NAME=${input:-$WEBSITE_NAME}

read -p "OpenAI Service Name [$OPENAI_NAME]: " input
OPENAI_NAME=${input:-$OPENAI_NAME}

read -p "Search Service Name [$SEARCH_NAME]: " input
SEARCH_NAME=${input:-$SEARCH_NAME}

read -p "Enable Chat History? (y/n) [n]: " CHAT_HISTORY
if [[ "$CHAT_HISTORY" == "y" || "$CHAT_HISTORY" == "Y" ]]; then
    ENABLE_CHAT_HISTORY="true"
else
    ENABLE_CHAT_HISTORY="false"
fi

# Create resource group if it doesn't exist
echo "Creating resource group if it doesn't exist..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Model deployment settings
read -p "OpenAI Model Name (gpt-4o recommended) [gpt-4o]: " input
MODEL_NAME=${input:-"gpt-4o"}

read -p "OpenAI Model Deployment Name [$MODEL_NAME-deployment]: " input
MODEL_DEPLOYMENT=${input:-"$MODEL_NAME-deployment"}

# Start deployment
echo "Starting deployment..."
echo "This may take up to 15-20 minutes to complete..."

az deployment group create \
  --name "$DEPLOYMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "infrastructure/deployment.json" \
  --parameters \
    WebsiteName="$WEBSITE_NAME" \
    AzureSearchService="$SEARCH_NAME" \
    AzureOpenAIResource="$OPENAI_NAME" \
    AzureOpenAIModel="$MODEL_DEPLOYMENT" \
    AzureOpenAIModelName="$MODEL_NAME" \
    WebAppEnableChatHistory="$ENABLE_CHAT_HISTORY" \
  --verbose

# Check deployment status
if [ $? -eq 0 ]; then
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║             Deployment completed successfully!              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    
    # Get the Web App URL
    WEBAPP_URL="https://$(az webapp show --name $WEBSITE_NAME --resource-group $RESOURCE_GROUP --query defaultHostName -o tsv)"
    
    echo "Your Policing Assistant is now deployed!"
    echo "Web App URL: $WEBAPP_URL"
    echo ""
    echo "Note: It may take a few minutes for the application to be fully deployed and ready to use."
    echo "If you see a 'deployment in progress' message, please wait a few minutes and refresh the page."
else
    echo "Deployment failed. Please check the error messages above."
    exit 1
fi
