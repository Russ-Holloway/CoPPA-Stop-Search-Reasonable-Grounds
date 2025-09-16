#!/bin/bash

# Bash script to prepare Azure resources for CoPA DevOps deployment
# Run this script to set up initial Azure resources before DevOps deployment

set -e  # Exit on any error

# Default values
LOCATION="uksouth"
FORCE_CODE="met"  # Change this to your force code
ENVIRONMENT="dev"  # dev or prod

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    case $color in
        "red") echo -e "\033[31m❌ $message\033[0m" ;;
        "green") echo -e "\033[32m✅ $message\033[0m" ;;
        "yellow") echo -e "\033[33m⚠️  $message\033[0m" ;;
        "blue") echo -e "\033[34m🔍 $message\033[0m" ;;
        "gray") echo -e "\033[37m   $message\033[0m" ;;
        *) echo "$message" ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -f|--force-code)
            FORCE_CODE="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 -s <subscription-id> [options]"
            echo "Options:"
            echo "  -s, --subscription    Azure subscription ID (required)"
            echo "  -l, --location       Azure location (default: uksouth)"
            echo "  -f, --force-code     Police force code (default: met)"
            echo "  -e, --environment    Environment (dev/prod, default: dev)"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Check required parameters
if [ -z "$SUBSCRIPTION_ID" ]; then
    print_status "red" "Subscription ID is required. Use -s <subscription-id>"
    exit 1
fi

print_status "blue" "Starting Azure DevOps preparation for CoPA Stop & Search"
print_status "gray" "Subscription: $SUBSCRIPTION_ID"
print_status "gray" "Location: $LOCATION"
print_status "gray" "Force Code: $FORCE_CODE"
print_status "gray" "Environment: $ENVIRONMENT"

# Check Azure CLI login
print_status "blue" "Checking Azure login status..."
if ! az account show > /dev/null 2>&1; then
    print_status "red" "Please login to Azure first: az login"
    exit 1
fi

CURRENT_USER=$(az account show --query "user.name" --output tsv)
CURRENT_SUBSCRIPTION=$(az account show --query "name" --output tsv)
print_status "green" "Logged in as: $CURRENT_USER"
print_status "green" "Current subscription: $CURRENT_SUBSCRIPTION"

# Set subscription
print_status "blue" "Setting subscription to: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

# Define resource group name following PDS convention
RESOURCE_GROUP_NAME="rg-$ENVIRONMENT-$LOCATION-$FORCE_CODE-copa-stop-search"

print_status "blue" "Creating resource group: $RESOURCE_GROUP_NAME"

# Create resource group
if az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" > /dev/null; then
    print_status "green" "Resource group created successfully!"
    print_status "gray" "Name: $RESOURCE_GROUP_NAME"
    print_status "gray" "Location: $LOCATION"
else
    print_status "red" "Failed to create resource group"
    exit 1
fi

# Check Azure service provider registrations
print_status "blue" "Checking required Azure providers..."

REQUIRED_PROVIDERS=(
    "Microsoft.CognitiveServices"
    "Microsoft.Search"
    "Microsoft.DocumentDB" 
    "Microsoft.Web"
    "Microsoft.Storage"
    "Microsoft.Insights"
    "Microsoft.KeyVault"
    "Microsoft.Authorization"
)

for PROVIDER in "${REQUIRED_PROVIDERS[@]}"; do
    STATUS=$(az provider show --namespace "$PROVIDER" --query "registrationState" --output tsv)
    if [ "$STATUS" != "Registered" ]; then
        print_status "yellow" "Registering provider: $PROVIDER"
        az provider register --namespace "$PROVIDER" > /dev/null
    else
        print_status "green" "Provider registered: $PROVIDER"
    fi
done

# Check quotas for key services
print_status "blue" "Checking Azure quotas..."

print_status "gray" "Checking OpenAI quota in $LOCATION..."
if az cognitiveservices usage list --location "$LOCATION" --query "[?name.value=='OpenAI.Standard.Tokens']" > /dev/null 2>&1; then
    print_status "green" "OpenAI quota available in $LOCATION"
else
    print_status "yellow" "OpenAI might not be available in $LOCATION - check manually"
fi

# Validate Bicep template
print_status "blue" "Validating Bicep template..."

BICEP_PATH="infra/main-pds-converted.bicep"
if [ -f "$BICEP_PATH" ]; then
    print_status "gray" "Found Bicep template: $BICEP_PATH"
    
    # Build Bicep template
    if az bicep build --file "$BICEP_PATH" > /dev/null 2>&1; then
        print_status "green" "Bicep template is valid"
    else
        print_status "red" "Bicep template has errors"
        az bicep build --file "$BICEP_PATH"
        exit 1
    fi
    
    # Run what-if analysis
    print_status "blue" "Running deployment what-if analysis..."
    if az deployment group what-if \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$BICEP_PATH" \
        --parameters location="$LOCATION" azureOpenAIModelName="gpt-4o" azureOpenAIEmbeddingName="text-embedding-ada-002" \
        > /dev/null 2>&1; then
        print_status "green" "What-if analysis completed successfully"
        print_status "gray" "Resources will be created/updated based on Bicep template"
    else
        print_status "yellow" "What-if analysis had issues (this might be normal)"
    fi
else
    print_status "red" "Bicep template not found at: $BICEP_PATH"
    print_status "yellow" "Make sure you're running this from the repository root"
    exit 1
fi

print_status "green" "🎉 Azure preparation completed!"
echo
print_status "gray" "Next steps:"
print_status "gray" "1. Use resource group name in DevOps variable groups: $RESOURCE_GROUP_NAME"
print_status "gray" "2. Continue with Azure DevOps setup using the checklist"
print_status "gray" "3. Test deployment using the DevOps pipeline"

# Output summary for use in DevOps
cat > azure-setup-summary.json << EOF
{
    "subscriptionId": "$SUBSCRIPTION_ID",
    "resourceGroupName": "$RESOURCE_GROUP_NAME", 
    "location": "$LOCATION",
    "forceCode": "$FORCE_CODE",
    "environment": "$ENVIRONMENT",
    "timestamp": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
}
EOF

print_status "gray" "Setup summary saved to: azure-setup-summary.json"