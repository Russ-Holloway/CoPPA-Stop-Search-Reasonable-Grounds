#!/bin/bash

# BTP Deployment Test Script for CoPA Stop & Search
# This script performs a complete deployment test to the BTP tenant
# with proper error handling and validation

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Update these values for your BTP tenant
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-}"
RESOURCE_GROUP_NAME="rg-btp-p-copa-stop-search"
LOCATION="uksouth"
ENVIRONMENT_CODE="p"
INSTANCE_NUMBER="001"

# Derived values
DEPLOYMENT_NAME="copa-btp-deployment-$(date +%Y%m%d-%H%M%S)"
BICEP_TEMPLATE_PATH="./infra/main.bicep"
PARAMETERS_FILE_PATH="./infra/main.parameters.json"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is signed in
    if ! az account show &> /dev/null; then
        print_error "You are not signed in to Azure CLI."
        print_status "Please sign in using: az login"
        print_status "If you have CA policies, try: az login --use-device-code"
        exit 1
    fi
    
    # Check if Bicep CLI is available
    if ! az bicep version &> /dev/null; then
        print_status "Installing Bicep CLI..."
        az bicep install
    fi
    
    # Check if files exist
    if [[ ! -f "$BICEP_TEMPLATE_PATH" ]]; then
        print_error "Bicep template not found at $BICEP_TEMPLATE_PATH"
        exit 1
    fi
    
    if [[ ! -f "$PARAMETERS_FILE_PATH" ]]; then
        print_error "Parameters file not found at $PARAMETERS_FILE_PATH"
        exit 1
    fi
    
    print_success "All prerequisites checked"
}

# Function to validate Bicep template
validate_bicep_template() {
    print_status "Validating Bicep template..."
    
    # Build the template to check for syntax errors
    if ! az bicep build --file "$BICEP_TEMPLATE_PATH" --outdir ./temp/; then
        print_error "Bicep template build failed"
        exit 1
    fi
    
    # Lint the template
    print_status "Running Bicep linting..."
    az bicep lint --file "$BICEP_TEMPLATE_PATH" || print_warning "Bicep linting found issues (non-fatal)"
    
    print_success "Bicep template validation completed"
}

# Function to set subscription context
set_subscription_context() {
    if [[ -n "$SUBSCRIPTION_ID" ]]; then
        print_status "Setting subscription context to $SUBSCRIPTION_ID"
        az account set --subscription "$SUBSCRIPTION_ID"
    else
        print_status "Using current subscription context"
        SUBSCRIPTION_ID=$(az account show --query id --output tsv)
        print_status "Current subscription: $SUBSCRIPTION_ID"
    fi
}

# Function to create resource group
create_resource_group() {
    print_status "Creating resource group: $RESOURCE_GROUP_NAME"
    
    if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_warning "Resource group $RESOURCE_GROUP_NAME already exists"
    else
        az group create \
            --name "$RESOURCE_GROUP_NAME" \
            --location "$LOCATION" \
            --tags \
                "Environment=Production" \
                "Force=BTP" \
                "Application=CoPA-Stop-Search" \
                "DeployedBy=$(az account show --query user.name --output tsv)" \
                "DeployedAt=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        print_success "Resource group created successfully"
    fi
}

# Function to run What-If analysis
run_whatif_analysis() {
    print_status "Running What-If analysis..."
    
    local whatif_output_file="./temp/whatif-analysis-$(date +%Y%m%d-%H%M%S).json"
    
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$BICEP_TEMPLATE_PATH" \
        --parameters "$PARAMETERS_FILE_PATH" \
            environmentCode="$ENVIRONMENT_CODE" \
            instanceNumber="$INSTANCE_NUMBER" \
        --result-format FullResourcePayloads \
        --no-pretty-print > "$whatif_output_file"
    
    print_success "What-If analysis completed. Results saved to $whatif_output_file"
    
    # Display summary
    echo ""
    print_status "What-If Analysis Summary:"
    echo "----------------------------------------"
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$BICEP_TEMPLATE_PATH" \
        --parameters "$PARAMETERS_FILE_PATH" \
            environmentCode="$ENVIRONMENT_CODE" \
            instanceNumber="$INSTANCE_NUMBER"
    echo "----------------------------------------"
    echo ""
}

# Function to validate deployment
validate_deployment() {
    print_status "Validating deployment template..."
    
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$BICEP_TEMPLATE_PATH" \
        --parameters "$PARAMETERS_FILE_PATH" \
            environmentCode="$ENVIRONMENT_CODE" \
            instanceNumber="$INSTANCE_NUMBER"
    
    print_success "Deployment validation completed successfully"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Starting infrastructure deployment..."
    print_status "Deployment Name: $DEPLOYMENT_NAME"
    print_status "Resource Group: $RESOURCE_GROUP_NAME"
    print_status "Location: $LOCATION"
    print_status "Environment Code: $ENVIRONMENT_CODE"
    print_status "Instance Number: $INSTANCE_NUMBER"
    
    # Create deployment with detailed output
    az deployment group create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --template-file "$BICEP_TEMPLATE_PATH" \
        --parameters "$PARAMETERS_FILE_PATH" \
            environmentCode="$ENVIRONMENT_CODE" \
            instanceNumber="$INSTANCE_NUMBER" \
        --verbose \
        --output table
    
    print_success "Infrastructure deployment completed!"
    
    # Get deployment outputs
    print_status "Retrieving deployment outputs..."
    az deployment group show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs \
        --output table
}

# Function to verify deployed resources
verify_deployment() {
    print_status "Verifying deployed resources..."
    
    # List all resources in the resource group
    echo ""
    print_status "Deployed Resources:"
    echo "==================="
    az resource list \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --output table
    echo ""
    
    # Check specific critical resources
    print_status "Verifying critical resources..."
    
    # Check App Service
    local app_service_name="app-btp-${ENVIRONMENT_CODE}-copa-stop-search-${INSTANCE_NUMBER}"
    if az webapp show --name "$app_service_name" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_success "✅ App Service ($app_service_name) deployed successfully"
        
        # Get the URL
        local app_url=$(az webapp show \
            --name "$app_service_name" \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --query "defaultHostName" \
            --output tsv)
        print_status "🌐 Application URL: https://$app_url"
    else
        print_error "❌ App Service not found"
    fi
    
    # Check Cosmos DB
    local cosmos_name="cosmos-btp-${ENVIRONMENT_CODE}-copa-stop-search-${INSTANCE_NUMBER}"
    if az cosmosdb show --name "$cosmos_name" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_success "✅ Cosmos DB ($cosmos_name) deployed successfully"
    else
        print_error "❌ Cosmos DB not found"
    fi
    
    # Check Azure Search
    local search_name="srch-btp-${ENVIRONMENT_CODE}-copa-stop-search-${INSTANCE_NUMBER}"
    if az search service show --name "$search_name" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_success "✅ Azure Search ($search_name) deployed successfully"
    else
        print_error "❌ Azure Search not found"
    fi
    
    # Check Cognitive Services
    local cognitive_name="cog-btp-${ENVIRONMENT_CODE}-copa-stop-search-${INSTANCE_NUMBER}"
    if az cognitiveservices account show --name "$cognitive_name" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_success "✅ Cognitive Services ($cognitive_name) deployed successfully"
    else
        print_error "❌ Cognitive Services not found"
    fi
    
    # Check VNET
    local vnet_name="vnet-btp-${ENVIRONMENT_CODE}-copa-stop-search-${INSTANCE_NUMBER}"
    if az network vnet show --name "$vnet_name" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_success "✅ Virtual Network ($vnet_name) deployed successfully"
    else
        print_error "❌ Virtual Network not found"
    fi
    
    # Check private endpoints
    print_status "Checking private endpoints..."
    local pe_count=$(az network private-endpoint list --resource-group "$RESOURCE_GROUP_NAME" --query "length([])" --output tsv)
    print_success "✅ Found $pe_count private endpoints deployed"
}

# Function to test application health
test_application_health() {
    print_status "Testing application health..."
    
    local app_service_name="app-btp-${ENVIRONMENT_CODE}-copa-stop-search-${INSTANCE_NUMBER}"
    local app_url=$(az webapp show \
        --name "$app_service_name" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "defaultHostName" \
        --output tsv 2>/dev/null || echo "")
    
    if [[ -n "$app_url" ]]; then
        print_status "Testing application endpoint: https://$app_url"
        
        # Test basic connectivity
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$app_url" || echo "000")
        
        if [[ "$status_code" == "200" ]]; then
            print_success "✅ Application is responding (HTTP $status_code)"
        elif [[ "$status_code" == "000" ]]; then
            print_warning "⚠️ Unable to connect to application (may still be starting)"
        else
            print_warning "⚠️ Application responded with HTTP $status_code"
        fi
    else
        print_error "❌ Could not determine application URL"
    fi
}

# Function to generate deployment report
generate_deployment_report() {
    print_status "Generating deployment report..."
    
    local report_file="./deployment-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# BTP Deployment Report

**Deployment Date:** $(date)
**Deployment Name:** $DEPLOYMENT_NAME
**Resource Group:** $RESOURCE_GROUP_NAME
**Location:** $LOCATION
**Environment Code:** $ENVIRONMENT_CODE
**Instance Number:** $INSTANCE_NUMBER

## Deployment Summary

EOF

    # Add resource list to report
    echo "## Deployed Resources" >> "$report_file"
    echo "" >> "$report_file"
    az resource list --resource-group "$RESOURCE_GROUP_NAME" --output table >> "$report_file"
    echo "" >> "$report_file"
    
    # Add deployment outputs
    echo "## Deployment Outputs" >> "$report_file"
    echo "" >> "$report_file"
    az deployment group show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs \
        --output table >> "$report_file" 2>/dev/null || echo "No outputs available" >> "$report_file"
    
    print_success "Deployment report generated: $report_file"
}

# Function to cleanup on error
cleanup_on_error() {
    print_error "Deployment failed. Cleaning up temporary files..."
    rm -rf ./temp/
}

# Main execution
main() {
    print_status "Starting BTP Deployment Test for CoPA Stop & Search"
    print_status "=================================================="
    
    # Create temp directory
    mkdir -p ./temp
    
    # Trap errors for cleanup
    trap cleanup_on_error ERR
    
    # Execute deployment steps
    check_prerequisites
    set_subscription_context
    validate_bicep_template
    create_resource_group
    run_whatif_analysis
    validate_deployment
    
    # Ask for confirmation before actual deployment
    echo ""
    print_warning "Ready to deploy to BTP tenant. This will create real Azure resources."
    read -p "Do you want to continue with the deployment? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_infrastructure
        verify_deployment
        test_application_health
        generate_deployment_report
        
        print_success "🎉 BTP deployment test completed successfully!"
        print_status "Your CoPA Stop & Search solution is now deployed with BTP naming convention."
    else
        print_status "Deployment cancelled by user."
        exit 0
    fi
    
    # Cleanup temp files
    rm -rf ./temp/
}

# Execute main function
main "$@"