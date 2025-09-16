#!/bin/bash

# Azure DevOps Automation Script
# This script automates the creation of service connections, variable groups, and environments
# Prerequisites: Azure DevOps project created and repository imported

set -e

# Configuration Variables
ORG_URL="https://dev.azure.com/uk-police-copa/"
PROJECT_NAME="CoPA-Stop-Search-Secure-Deployment"
REPO_NAME="CoPA-Stop-Search-Reasonable-Grounds"
SUBSCRIPTION_ID=""
LOCATION="uksouth"
FORCE_CODE="met"  # Change this to your force code

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    case $color in
        "red") echo -e "${RED}❌ $message${NC}" ;;
        "green") echo -e "${GREEN}✅ $message${NC}" ;;
        "yellow") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "blue") echo -e "${BLUE}🔍 $message${NC}" ;;
        *) echo "$message" ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_status "blue" "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_status "red" "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        print_status "red" "Please login to Azure: az login"
        exit 1
    fi
    
    # Check Azure DevOps extension
    if ! az extension list --query "[?name=='azure-devops']" --output tsv | grep -q azure-devops; then
        print_status "yellow" "Installing Azure DevOps extension..."
        az extension add --name azure-devops
    fi
    
    print_status "green" "Prerequisites check completed"
}

# Function to get subscription ID interactively
get_subscription_id() {
    if [ -z "$SUBSCRIPTION_ID" ]; then
        print_status "blue" "Available Azure subscriptions:"
        az account list --output table --query "[].{Name:name, SubscriptionId:id, State:state}"
        
        echo
        read -p "Enter your Azure Subscription ID: " SUBSCRIPTION_ID
        
        if [ -z "$SUBSCRIPTION_ID" ]; then
            print_status "red" "Subscription ID is required"
            exit 1
        fi
    fi
    
    # Set the subscription
    az account set --subscription "$SUBSCRIPTION_ID"
    print_status "green" "Using subscription: $SUBSCRIPTION_ID"
}

# Function to configure Azure DevOps
configure_devops() {
    print_status "blue" "Configuring Azure DevOps CLI..."
    
    # Configure defaults
    az devops configure --defaults organization="$ORG_URL" project="$PROJECT_NAME"
    
    # Login to Azure DevOps (will prompt for PAT if needed)
    print_status "yellow" "You may be prompted to authenticate with Azure DevOps..."
    if ! az devops project show --project "$PROJECT_NAME" &> /dev/null; then
        print_status "red" "Cannot access project '$PROJECT_NAME'. Please ensure:"
        print_status "red" "1. The project exists at $ORG_URL"
        print_status "red" "2. You have access to the project"
        print_status "red" "3. You've authenticated with Azure DevOps (PAT token)"
        exit 1
    fi
    
    print_status "green" "Azure DevOps access confirmed"
}

# Function to create service connections
create_service_connections() {
    print_status "blue" "Creating service connections..."
    
    local dev_rg="rg-dev-$LOCATION-$FORCE_CODE-copa-stop-search"
    local prod_rg="rg-prod-$LOCATION-$FORCE_CODE-copa-stop-search"
    
    # Create development service connection
    print_status "yellow" "Creating development service connection..."
    az devops service-endpoint azurerm create \
        --azure-rm-service-principal-id "" \
        --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
        --azure-rm-subscription-name "$(az account show --query name -o tsv)" \
        --azure-rm-tenant-id "$(az account show --query tenantId -o tsv)" \
        --name "copa-azure-service-connection-dev" \
        --project "$PROJECT_NAME" \
        --org "$ORG_URL" || print_status "yellow" "Dev service connection might already exist"
    
    # Create production service connection  
    print_status "yellow" "Creating production service connection..."
    az devops service-endpoint azurerm create \
        --azure-rm-service-principal-id "" \
        --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
        --azure-rm-subscription-name "$(az account show --query name -o tsv)" \
        --azure-rm-tenant-id "$(az account show --query tenantId -o tsv)" \
        --name "copa-azure-service-connection-prod" \
        --project "$PROJECT_NAME" \
        --org "$ORG_URL" || print_status "yellow" "Prod service connection might already exist"
    
    print_status "green" "Service connections created"
}

# Function to create variable groups
create_variable_groups() {
    print_status "blue" "Creating variable groups..."
    
    local dev_rg="rg-dev-$LOCATION-$FORCE_CODE-copa-stop-search"
    local prod_rg="rg-prod-$LOCATION-$FORCE_CODE-copa-stop-search"
    
    # Create development variable group
    print_status "yellow" "Creating development variable group..."
    cat > dev-variables.json << EOF
{
    "resourceGroupName": "$dev_rg",
    "azureLocation": "$LOCATION",
    "environmentName": "development",
    "openAIModel": "gpt-4o",
    "embeddingModel": "text-embedding-ada-002",
    "webAppName": "\$(webAppName)",
    "deploymentSlotName": "staging",
    "enableDebugMode": "true",
    "azureServiceConnection": "copa-azure-service-connection-dev"
}
EOF
    
    az pipelines variable-group create \
        --name "copa-dev-variables" \
        --variables @dev-variables.json \
        --description "Development environment variables for CoPA Stop & Search" \
        --project "$PROJECT_NAME" \
        --org "$ORG_URL" || print_status "yellow" "Dev variable group might already exist"
    
    # Create production variable group
    print_status "yellow" "Creating production variable group..."
    cat > prod-variables.json << EOF
{
    "resourceGroupName": "$prod_rg",
    "azureLocation": "$LOCATION",
    "environmentName": "production",
    "openAIModel": "gpt-4o",
    "embeddingModel": "text-embedding-ada-002",
    "webAppName": "\$(webAppName)",
    "deploymentSlotName": "production",
    "enableDebugMode": "false",
    "azureServiceConnection": "copa-azure-service-connection-prod",
    "enableApplicationInsights": "true",
    "enableMonitoring": "true"
}
EOF
    
    az pipelines variable-group create \
        --name "copa-prod-variables" \
        --variables @prod-variables.json \
        --description "Production environment variables for CoPA Stop & Search" \
        --project "$PROJECT_NAME" \
        --org "$ORG_URL" || print_status "yellow" "Prod variable group might already exist"
    
    # Clean up temporary files
    rm -f dev-variables.json prod-variables.json
    
    print_status "green" "Variable groups created"
}

# Function to create environments
create_environments() {
    print_status "blue" "Creating environments..."
    
    # Create development environment
    print_status "yellow" "Creating development environment..."
    az devops invoke \
        --area distributedtask \
        --resource environments \
        --route-parameters project="$PROJECT_NAME" \
        --http-method POST \
        --in-file /dev/stdin \
        --org "$ORG_URL" << EOF || print_status "yellow" "Dev environment might already exist"
{
    "name": "copa-development",
    "description": "Development environment for CoPA Stop & Search"
}
EOF
    
    # Create production environment
    print_status "yellow" "Creating production environment..."
    az devops invoke \
        --area distributedtask \
        --resource environments \
        --route-parameters project="$PROJECT_NAME" \
        --http-method POST \
        --in-file /dev/stdin \
        --org "$ORG_URL" << EOF || print_status "yellow" "Prod environment might already exist"
{
    "name": "copa-production", 
    "description": "Production environment for CoPA Stop & Search"
}
EOF
    
    print_status "green" "Environments created"
    print_status "yellow" "Note: Production approvals need to be configured manually in the Azure DevOps web interface"
}

# Function to create pipeline
create_pipeline() {
    print_status "blue" "Creating pipeline..."
    
    # Check if repository exists
    local repo_id=$(az repos list --query "[?name=='CoPA-Stop-Search-Reasonable-Grounds'].id" -o tsv)
    if [ -z "$repo_id" ]; then
        print_status "red" "Repository 'CoPA-Stop-Search-Reasonable-Grounds' not found"
        print_status "red" "Please import the repository first"
        return 1
    fi
    
    # Create pipeline
    print_status "yellow" "Creating main deployment pipeline..."
    az pipelines create \
        --name "CoPA-Stop-Search-Main-Deploy" \
        --description "Main deployment pipeline for CoPA Stop & Search" \
        --repository "$repo_id" \
        --repository-type tfsgit \
        --branch "Dev-Ops-Deployment" \
        --yml-path "/azure-pipelines.yml" \
        --project "$PROJECT_NAME" \
        --org "$ORG_URL" || print_status "yellow" "Pipeline might already exist"
    
    print_status "green" "Pipeline created"
}

# Function to create Azure resource groups
create_azure_resources() {
    print_status "blue" "Creating Azure resource groups..."
    
    local dev_rg="rg-dev-$LOCATION-$FORCE_CODE-copa-stop-search"
    local prod_rg="rg-prod-$LOCATION-$FORCE_CODE-copa-stop-search"
    
    # Create development resource group
    print_status "yellow" "Creating development resource group: $dev_rg"
    az group create --name "$dev_rg" --location "$LOCATION" || print_status "yellow" "Resource group might already exist"
    
    # Create production resource group  
    print_status "yellow" "Creating production resource group: $prod_rg"
    az group create --name "$prod_rg" --location "$LOCATION" || print_status "yellow" "Resource group might already exist"
    
    print_status "green" "Azure resource groups created"
}

# Main execution
main() {
    print_status "blue" "🚀 Starting Azure DevOps automation for CoPA Stop & Search"
    echo
    
    # Get configuration from user
    if [ -z "$FORCE_CODE" ] || [ "$FORCE_CODE" = "met" ]; then
        read -p "Enter your police force code (e.g., met, gmp, west-midlands): " FORCE_CODE
        if [ -z "$FORCE_CODE" ]; then
            FORCE_CODE="met"
        fi
    fi
    
    check_prerequisites
    get_subscription_id
    configure_devops
    
    echo
    print_status "blue" "Creating Azure DevOps components..."
    
    create_service_connections
    create_variable_groups  
    create_environments
    create_pipeline
    
    echo
    print_status "blue" "Creating Azure resources..."
    create_azure_resources
    
    echo
    print_status "green" "🎉 Automation completed!"
    
    print_status "yellow" "Manual steps still required:"
    echo "1. Configure production environment approvals in Azure DevOps web interface"
    echo "2. Grant pipeline permissions to service connections and environments"
    echo "3. Test pipeline run"
    
    print_status "blue" "Next: Run the pipeline to test deployment!"
}

# Run main function
main "$@"