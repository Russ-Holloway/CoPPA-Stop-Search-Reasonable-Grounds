#!/bin/bash

# CoPA Stop & Search - BTP Deployment via Azure CLI
# This script deploys the BTP infrastructure directly using Azure CLI
# Use this while waiting for DevOps parallelism approval

set -e

# Configuration
RESOURCE_GROUP_NAME="rg-btp-p-copa-stop-search"
LOCATION="uksouth"
DEPLOYMENT_NAME="btp-copa-deployment-$(date +%Y%m%d-%H%M%S)"
TEMPLATE_FILE="./infra/main.bicep"
PARAMETERS_FILE="./infra/main.parameters.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if user is logged in
check_azure_login() {
    echo_info "Checking Azure CLI authentication..."
    
    if ! az account show &>/dev/null; then
        echo_warning "Not logged into Azure CLI. Please login..."
        echo_info "If you have Conditional Access policies, use device code flow:"
        echo "az login --use-device-code"
        echo ""
        echo_info "Otherwise, use regular login:"
        echo "az login"
        exit 1
    fi
    
    local account_info=$(az account show --query "{name:name, id:id, tenantId:tenantId}" -o table)
    echo_success "Logged into Azure:"
    echo "$account_info"
}

# Function to set subscription
set_subscription() {
    echo_info "Current subscription details:"
    az account show --query "{name:name, id:id, isDefault:isDefault}" -o table
    
    echo ""
    read -p "Do you want to use this subscription? (y/n): " confirm
    if [[ $confirm != [yY]* ]]; then
        echo_info "Available subscriptions:"
        az account list --query "[].{Name:name, SubscriptionId:id, State:state}" -o table
        echo ""
        read -p "Enter the subscription ID or name you want to use: " subscription
        az account set --subscription "$subscription"
        echo_success "Switched to subscription: $(az account show --query name -o tsv)"
    fi
}

# Function to create resource group
create_resource_group() {
    echo_info "Checking if resource group exists: $RESOURCE_GROUP_NAME"
    
    if az group show --name "$RESOURCE_GROUP_NAME" &>/dev/null; then
        echo_success "Resource group $RESOURCE_GROUP_NAME already exists"
    else
        echo_info "Creating resource group: $RESOURCE_GROUP_NAME in $LOCATION"
        az group create \
            --name "$RESOURCE_GROUP_NAME" \
            --location "$LOCATION" \
            --tags \
                "Environment=Production" \
                "Project=CoPA-Stop-Search" \
                "DeploymentMethod=AzureCLI" \
                "CreatedBy=$(az account show --query user.name -o tsv)" \
                "CreatedDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        
        echo_success "Resource group created successfully"
    fi
}

# Function to validate Bicep template
validate_template() {
    echo_info "Validating Bicep template..."
    
    # First compile the Bicep to check for syntax errors
    echo_info "Compiling Bicep template..."
    az bicep build --file "$TEMPLATE_FILE"
    
    if [ $? -eq 0 ]; then
        echo_success "Bicep template compiled successfully"
    else
        echo_error "Bicep template compilation failed"
        exit 1
    fi
    
    # Validate against Azure
    echo_info "Validating template against Azure..."
    validation_result=$(az deployment group validate \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$PARAMETERS_FILE" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo_success "Template validation passed"
    else
        echo_error "Template validation failed:"
        echo "$validation_result"
        exit 1
    fi
}

# Function to run what-if analysis
run_whatif() {
    echo_info "Running What-If analysis to preview changes..."
    
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$PARAMETERS_FILE" \
        --result-format FullResourcePayloads
    
    echo ""
    echo_warning "Please review the What-If results above carefully."
    read -p "Do you want to proceed with the deployment? (y/n): " confirm
    if [[ $confirm != [yY]* ]]; then
        echo_info "Deployment cancelled by user"
        exit 0
    fi
}

# Function to deploy template
deploy_template() {
    echo_info "Starting deployment: $DEPLOYMENT_NAME"
    echo_info "This may take 15-30 minutes..."
    
    # Start deployment
    az deployment group create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$PARAMETERS_FILE" \
        --verbose
    
    if [ $? -eq 0 ]; then
        echo_success "Deployment completed successfully!"
    else
        echo_error "Deployment failed. Check the error messages above."
        echo_info "You can check deployment status in the Azure portal:"
        echo "https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/deployments"
        exit 1
    fi
}

# Function to get deployment outputs
get_deployment_outputs() {
    echo_info "Retrieving deployment outputs..."
    
    outputs=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs" \
        --output json)
    
    if [ "$outputs" != "null" ] && [ "$outputs" != "{}" ]; then
        echo_success "Deployment outputs:"
        echo "$outputs" | jq '.'
        
        # Save outputs to file
        echo "$outputs" | jq '.' > "./deployment-outputs-$(date +%Y%m%d-%H%M%S).json"
        echo_info "Outputs saved to deployment-outputs-$(date +%Y%m%d-%H%M%S).json"
    else
        echo_warning "No deployment outputs available"
    fi
}

# Function to verify deployment
verify_deployment() {
    echo_info "Verifying deployment..."
    
    # Check key resources
    echo_info "Checking deployed resources..."
    
    # App Service
    app_service_name="app-btp-p-copa-stop-search-001"
    if az webapp show --name "$app_service_name" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        echo_success "App Service: $app_service_name"
        app_url="https://$app_service_name.azurewebsites.net"
        echo_info "App URL: $app_url"
    else
        echo_warning "App Service not found: $app_service_name"
    fi
    
    # Cosmos DB
    cosmos_name="db-btp-p-copa-stop-search-001"
    if az cosmosdb show --name "$cosmos_name" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        echo_success "Cosmos DB: $cosmos_name"
    else
        echo_warning "Cosmos DB not found: $cosmos_name"
    fi
    
    # Key Vault
    kv_name="kvbtppcopastopsearch001"
    if az keyvault show --name "$kv_name" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        echo_success "Key Vault: $kv_name"
    else
        echo_warning "Key Vault not found: $kv_name"
    fi
    
    # OpenAI
    openai_name="cog-btp-p-copa-stop-search-001"
    if az cognitiveservices account show --name "$openai_name" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        echo_success "OpenAI Service: $openai_name"
    else
        echo_warning "OpenAI Service not found: $openai_name"
    fi
}

# Function to display next steps
show_next_steps() {
    echo ""
    echo_success "=== DEPLOYMENT SUMMARY ==="
    echo_info "Resource Group: $RESOURCE_GROUP_NAME"
    echo_info "Deployment Name: $DEPLOYMENT_NAME"
    echo_info "Location: $LOCATION"
    
    echo ""
    echo_info "=== NEXT STEPS ==="
    echo "1. 🌐 Access the Azure Portal to verify resources:"
    echo "   https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME"
    
    echo ""
    echo "2. 🔑 Configure application settings in the App Service"
    echo "3. 📊 Set up monitoring and alerts"
    echo "4. 🔒 Review security settings and private endpoints"
    echo "5. 🧪 Test the application functionality"
    
    echo ""
    echo_info "=== USEFUL COMMANDS ==="
    echo "• View deployment details:"
    echo "  az deployment group show --resource-group $RESOURCE_GROUP_NAME --name $DEPLOYMENT_NAME"
    
    echo ""
    echo "• Monitor deployment progress:"
    echo "  az deployment group list --resource-group $RESOURCE_GROUP_NAME --output table"
    
    echo ""
    echo "• Delete all resources (when no longer needed):"
    echo "  az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait"
}

# Main execution
main() {
    echo_info "=== CoPA Stop & Search - BTP Azure CLI Deployment ==="
    echo_info "Starting deployment process..."
    echo ""
    
    # Pre-deployment checks
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo_error "Template file not found: $TEMPLATE_FILE"
        echo_info "Please run this script from the project root directory"
        exit 1
    fi
    
    if [ ! -f "$PARAMETERS_FILE" ]; then
        echo_error "Parameters file not found: $PARAMETERS_FILE"
        exit 1
    fi
    
    # Execute deployment steps
    check_azure_login
    set_subscription
    create_resource_group
    validate_template
    run_whatif
    deploy_template
    get_deployment_outputs
    verify_deployment
    show_next_steps
    
    echo ""
    echo_success "🎉 BTP deployment completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "CoPA Stop & Search - BTP Azure CLI Deployment"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --validate     Only validate the template (no deployment)"
        echo "  --whatif       Only run what-if analysis (no deployment)"
        echo ""
        echo "Environment Variables:"
        echo "  RESOURCE_GROUP_NAME    Override resource group name"
        echo "  LOCATION              Override deployment location"
        echo ""
        exit 0
        ;;
    --validate)
        check_azure_login
        set_subscription
        create_resource_group
        validate_template
        echo_success "Template validation completed successfully!"
        exit 0
        ;;
    --whatif)
        check_azure_login
        set_subscription
        create_resource_group
        validate_template
        run_whatif
        echo_success "What-If analysis completed!"
        exit 0
        ;;
    *)
        main
        ;;
esac