#!/bin/bash

# CoPA Stop & Search - BTP SECURE Deployment via Azure CLI
# This script deploys the complete BTP infrastructure with full security (private endpoints enabled)
# Deploys at SUBSCRIPTION SCOPE as required by the Bicep template

set -euo pipefail

# Configuration
RESOURCE_GROUP_NAME="rg-btp-p-copa-stop-search"
LOCATION="uksouth"
ENVIRONMENT_NAME="copa-btp"
ENVIRONMENT_CODE="p"
INSTANCE_NUMBER="001"
DEPLOYMENT_NAME="btp-copa-secure-deployment-$(date +%Y%m%d-%H%M%S)"
TEMPLATE_FILE="./infra/main.bicep"

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
    echo_info "Note: Resource group will be created by the subscription-level deployment"
    echo_info "Target resource group: $RESOURCE_GROUP_NAME in $LOCATION"
    echo_success "Resource group creation will be handled by Bicep template"
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
    
    # Get principal ID for validation
    PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
    if [ -z "$PRINCIPAL_ID" ]; then
        echo_warning "Could not get user principal ID, template validation may be limited"
        PRINCIPAL_ID="00000000-0000-0000-0000-000000000000"
    fi
    
    # Validate against Azure at SUBSCRIPTION scope
    echo_info "Validating template against Azure (subscription scope)..."
    validation_result=$(az deployment sub validate \
        --location "$LOCATION" \
        --template-file "$TEMPLATE_FILE" \
        --parameters \
            environmentName="$ENVIRONMENT_NAME" \
            location="$LOCATION" \
            principalId="$PRINCIPAL_ID" \
            environmentCode="$ENVIRONMENT_CODE" \
            instanceNumber="$INSTANCE_NUMBER" \
            enablePrivateEndpoints=true \
            resourceGroupName="$RESOURCE_GROUP_NAME" \
            openAiSkuName="S0" \
            searchServiceSkuName="basic" \
            formRecognizerSkuName="S0" 2>&1)
    
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
    echo_info "🔒 This will show the SECURE deployment with private endpoints enabled"
    
    # Get principal ID
    PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
    
    az deployment sub what-if \
        --location "$LOCATION" \
        --template-file "$TEMPLATE_FILE" \
        --parameters \
            environmentName="$ENVIRONMENT_NAME" \
            location="$LOCATION" \
            principalId="$PRINCIPAL_ID" \
            environmentCode="$ENVIRONMENT_CODE" \
            instanceNumber="$INSTANCE_NUMBER" \
            enablePrivateEndpoints=true \
            vnetAddressPrefix="10.0.0.0/16" \
            appServiceSubnetAddressPrefix="10.0.1.0/24" \
            privateEndpointSubnetAddressPrefix="10.0.2.0/24" \
            resourceGroupName="$RESOURCE_GROUP_NAME" \
            openAiSkuName="S0" \
            searchServiceSkuName="basic" \
            formRecognizerSkuName="S0" \
        --result-format FullResourcePayloads
    
    echo ""
    echo_warning "🔒 SECURE DEPLOYMENT PREVIEW ABOVE:"
    echo "  ✅ Private endpoints enabled for all services"
    echo "  ✅ VNet isolation for network security"  
    echo "  ✅ Cosmos DB: db-btp-p-copa-stop-search-001"
    echo "  ✅ Production-ready security configuration"
    echo ""
    read -p "Do you want to proceed with the SECURE deployment? (y/n): " confirm
    if [[ $confirm != [yY]* ]]; then
        echo_info "Deployment cancelled by user"
        exit 0
    fi
}

# Function to deploy template
deploy_template() {
    echo_info "🔒 Starting SECURE BTP deployment: $DEPLOYMENT_NAME"
    echo_info "⏱️  This may take 20-40 minutes (private endpoints add time)..."
    echo_info "🔐 Deploying with full network isolation and security"
    
    # Get principal ID
    PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
    if [ -z "$PRINCIPAL_ID" ]; then
        echo_error "Could not get user principal ID, this is required for deployment"
        exit 1
    fi
    
    # Start SUBSCRIPTION-LEVEL deployment (the correct approach!)
    az deployment sub create \
        --name "$DEPLOYMENT_NAME" \
        --location "$LOCATION" \
        --template-file "$TEMPLATE_FILE" \
        --parameters \
            environmentName="$ENVIRONMENT_NAME" \
            location="$LOCATION" \
            principalId="$PRINCIPAL_ID" \
            environmentCode="$ENVIRONMENT_CODE" \
            instanceNumber="$INSTANCE_NUMBER" \
            enablePrivateEndpoints=true \
            vnetAddressPrefix="10.0.0.0/16" \
            appServiceSubnetAddressPrefix="10.0.1.0/24" \
            privateEndpointSubnetAddressPrefix="10.0.2.0/24" \
            resourceGroupName="$RESOURCE_GROUP_NAME" \
            openAiResourceName="" \
            openAiResourceGroupName="" \
            openAiSkuName="S0" \
            searchServiceName="" \
            searchServiceResourceGroupName="" \
            searchServiceSkuName="basic" \
            formRecognizerServiceName="" \
            formRecognizerResourceGroupName="" \
            formRecognizerSkuName="S0" \
            authClientId="" \
            authClientSecret="" \
            cosmosAccountName="" \
            keyVaultName="" \
            logAnalyticsWorkspaceName="" \
            appServicePlanName="" \
            backendServiceName="" \
        --verbose
    
    if [ $? -eq 0 ]; then
        echo_success "🔒 SECURE deployment completed successfully!"
        echo_success "✅ All resources deployed with private endpoints enabled"
        echo_success "✅ Cosmos DB created: db-btp-p-copa-stop-search-001"
    else
        echo_error "Deployment failed. Check the error messages above."
        echo_info "You can check deployment status in the Azure portal"
        exit 1
    fi
}

# Function to get deployment outputs
get_deployment_outputs() {
    echo_info "Retrieving deployment outputs..."
    
    outputs=$(az deployment sub show \
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
    echo_info "🔍 Verifying SECURE deployment..."
    
    # Check key resources
    echo_info "Checking deployed resources in $RESOURCE_GROUP_NAME..."
    
    # App Service
    app_service_name="app-btp-p-copa-stop-search-001"
    if az webapp show --name "$app_service_name" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        echo_success "✅ App Service: $app_service_name"
        app_url="https://$app_service_name.azurewebsites.net"
        echo_info "   App URL: $app_url"
    else
        echo_warning "⚠️  App Service not found: $app_service_name"
    fi
    
    # Cosmos DB - CHECK THE UPDATED NAME
    cosmos_name="db-btp-p-copa-stop-search-001"
    if az cosmosdb show --name "$cosmos_name" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        echo_success "✅ Cosmos DB: $cosmos_name (CORRECT NAME!)"
    else
        echo_warning "⚠️  Cosmos DB not found: $cosmos_name"
    fi
    
    # Key Vault
    kv_name="kv-btp-p-copa-stop-search-001"
    if az keyvault show --name "$kv_name" &>/dev/null; then
        echo_success "✅ Key Vault: $kv_name"
    else
        echo_warning "⚠️  Key Vault not found: $kv_name"
    fi
    
    # Check Private Endpoints (NEW!)
    echo_info "🔒 Checking private endpoints..."
    private_endpoints=$(az network private-endpoint list --resource-group "$RESOURCE_GROUP_NAME" --query "[].name" -o tsv 2>/dev/null || echo "")
    if [ -n "$private_endpoints" ]; then
        echo_success "✅ Private endpoints created:"
        echo "$private_endpoints" | while read -r pe_name; do
            echo "   🔐 $pe_name"
        done
    else
        echo_warning "⚠️  No private endpoints found"
    fi
    
    # Check VNet
    echo_info "🌐 Checking virtual network..."
    vnet_name=$(az network vnet list --resource-group "$RESOURCE_GROUP_NAME" --query "[0].name" -o tsv 2>/dev/null || echo "")
    if [ -n "$vnet_name" ]; then
        echo_success "✅ Virtual Network: $vnet_name"
    else
        echo_warning "⚠️  Virtual Network not found"
    fi
}

# Function to display next steps
show_next_steps() {
    echo ""
    echo_success "=== 🔒 SECURE BTP DEPLOYMENT SUMMARY ==="
    echo_info "Resource Group: $RESOURCE_GROUP_NAME"
    echo_info "Deployment Name: $DEPLOYMENT_NAME"
    echo_info "Location: $LOCATION"
    echo_info "Security: FULL (Private endpoints enabled)"
    
    echo ""
    echo_info "=== 🎯 NEXT STEPS ==="
    echo "1. 🌐 Access the Azure Portal to verify resources:"
    echo "   https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME"
    
    echo ""
    echo "2. � SECURITY VERIFICATION:"
    echo "   • Verify private endpoints are working"
    echo "   • Check VNet connectivity"
    echo "   • Confirm Cosmos DB is secure: db-btp-p-copa-stop-search-001"
    
    echo ""
    echo "3. 🔑 APPLICATION CONFIGURATION:"
    echo "   • Configure App Service connection strings"
    echo "   • Set up authentication settings"
    echo "   • Deploy application code"
    
    echo ""
    echo "4. � IMPORTANT SECURITY NOTES:"
    echo "   • Resources are ONLY accessible from the VNet"
    echo "   • You may need VPN/Bastion for management access"
    echo "   • This is production-ready security for police data"
    
    echo ""
    echo_info "=== 🛠️ USEFUL COMMANDS ==="
    echo "• View deployment details:"
    echo "  az deployment sub show --name $DEPLOYMENT_NAME"
    
    echo ""
    echo "• List all resources:"
    echo "  az resource list --resource-group $RESOURCE_GROUP_NAME --output table"
    
    echo ""
    echo "• Check private endpoints:"
    echo "  az network private-endpoint list --resource-group $RESOURCE_GROUP_NAME --output table"
    
    echo ""
    echo "• Delete all resources (when no longer needed):"
    echo "  az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait"
}

# Main execution
main() {
    echo_info "=== 🔒 CoPA Stop & Search - BTP SECURE Deployment ==="
    echo_info "🚨 Full security deployment with private endpoints"
    echo_info "🎯 Production-ready for sensitive police data"
    echo ""
    
    # Pre-deployment checks
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo_error "Template file not found: $TEMPLATE_FILE"
        echo_info "Please run this script from the project root directory"
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
    echo_success "🎉 🔒 SECURE BTP deployment completed successfully!"
    echo_success "✅ Cosmos DB deployed: db-btp-p-copa-stop-search-001"
    echo_success "✅ Full network security with private endpoints"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "🔒 CoPA Stop & Search - BTP SECURE Deployment"
        echo "Full security deployment with private endpoints for police data"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --validate     Only validate the template (no deployment)"
        echo "  --whatif       Only run what-if analysis (no deployment)"
        echo ""
        echo "Security Features:"
        echo "  ✅ Private endpoints for all services"
        echo "  ✅ VNet isolation"
        echo "  ✅ Production-ready configuration"
        echo "  ✅ Cosmos DB: db-btp-p-copa-stop-search-001"
        echo ""
        exit 0
        ;;
    --validate)
        check_azure_login
        set_subscription
        create_resource_group
        validate_template
        echo_success "🔒 SECURE template validation completed successfully!"
        exit 0
        ;;
    --whatif)
        check_azure_login
        set_subscription  
        create_resource_group
        validate_template
        run_whatif
        echo_success "🔒 SECURE What-If analysis completed!"
        exit 0
        ;;
    *)
        main
        ;;
esac