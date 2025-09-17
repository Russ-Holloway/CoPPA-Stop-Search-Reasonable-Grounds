#!/bin/bash

# Security Compliance Validation Script
# This script validates that the CoPA Stop & Search solution meets security requirements

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
RESOURCE_GROUP=""
SUBSCRIPTION_ID=""
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TESTS=0

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}[✓] ${message}${NC}"
            ((PASSED_TESTS++))
            ;;
        "FAIL")
            echo -e "${RED}[✗] ${message}${NC}"
            ((FAILED_TESTS++))
            ;;
        "WARN")
            echo -e "${YELLOW}[!] ${message}${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}[i] ${message}${NC}"
            ;;
    esac
    ((TOTAL_TESTS++))
}

# Function to get resource name by type
get_resource_name() {
    local resource_type=$1
    az resource list --resource-group "$RESOURCE_GROUP" --resource-type "$resource_type" --query "[0].name" -o tsv
}

# Function to check if resource exists
resource_exists() {
    local resource_type=$1
    local count=$(az resource list --resource-group "$RESOURCE_GROUP" --resource-type "$resource_type" --query "length(@)")
    [ "$count" -gt 0 ]
}

# Function to validate network security groups
validate_nsg() {
    echo -e "\n${BLUE}=== Network Security Group Validation ===${NC}"
    
    if resource_exists "Microsoft.Network/networkSecurityGroups"; then
        local nsg_name=$(get_resource_name "Microsoft.Network/networkSecurityGroups")
        print_status "PASS" "Network Security Group '$nsg_name' exists"
        
        # Check for HTTPS rule
        local https_rule=$(az network nsg rule show --resource-group "$RESOURCE_GROUP" --nsg-name "$nsg_name" --name "AllowHTTPS" --query "access" -o tsv 2>/dev/null || echo "")
        if [ "$https_rule" = "Allow" ]; then
            print_status "PASS" "HTTPS inbound rule is configured"
        else
            print_status "FAIL" "HTTPS inbound rule is missing or misconfigured"
        fi
        
        # Check for deny all rule
        local deny_rule=$(az network nsg rule list --resource-group "$RESOURCE_GROUP" --nsg-name "$nsg_name" --query "[?access=='Deny' && direction=='Inbound'].priority | max(@)" -o tsv 2>/dev/null || echo "")
        if [ -n "$deny_rule" ]; then
            print_status "PASS" "Default deny inbound rule is configured"
        else
            print_status "FAIL" "Default deny inbound rule is missing"
        fi
    else
        print_status "FAIL" "Network Security Group not found"
    fi
}

# Function to validate virtual network
validate_vnet() {
    echo -e "\n${BLUE}=== Virtual Network Validation ===${NC}"
    
    if resource_exists "Microsoft.Network/virtualNetworks"; then
        local vnet_name=$(get_resource_name "Microsoft.Network/virtualNetworks")
        print_status "PASS" "Virtual Network '$vnet_name' exists"
        
        # Check subnets
        local subnets=$(az network vnet subnet list --resource-group "$RESOURCE_GROUP" --vnet-name "$vnet_name" --query "[].name" -o tsv)
        
        if echo "$subnets" | grep -q "app-service-subnet"; then
            print_status "PASS" "App Service subnet exists"
        else
            print_status "FAIL" "App Service subnet not found"
        fi
        
        if echo "$subnets" | grep -q "private-endpoint-subnet"; then
            print_status "PASS" "Private endpoint subnet exists"
        else
            print_status "FAIL" "Private endpoint subnet not found"
        fi
    else
        print_status "FAIL" "Virtual Network not found"
    fi
}

# Function to validate private endpoints
validate_private_endpoints() {
    echo -e "\n${BLUE}=== Private Endpoints Validation ===${NC}"
    
    local pe_count=$(az network private-endpoint list --resource-group "$RESOURCE_GROUP" --query "length(@)")
    if [ "$pe_count" -gt 0 ]; then
        print_status "PASS" "$pe_count private endpoints found"
        
        # List private endpoints
        local endpoints=$(az network private-endpoint list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv)
        while read -r endpoint; do
            if [ -n "$endpoint" ]; then
                print_status "INFO" "Private endpoint: $endpoint"
            fi
        done <<< "$endpoints"
    else
        print_status "FAIL" "No private endpoints found"
    fi
}

# Function to validate storage account security
validate_storage_security() {
    echo -e "\n${BLUE}=== Storage Account Security Validation ===${NC}"
    
    if resource_exists "Microsoft.Storage/storageAccounts"; then
        local storage_name=$(get_resource_name "Microsoft.Storage/storageAccounts")
        print_status "PASS" "Storage Account '$storage_name' exists"
        
        # Check public network access
        local public_access=$(az storage account show --name "$storage_name" --resource-group "$RESOURCE_GROUP" --query "publicNetworkAccess" -o tsv)
        if [ "$public_access" = "Disabled" ]; then
            print_status "PASS" "Storage Account public network access is disabled"
        else
            print_status "FAIL" "Storage Account public network access is enabled (should be disabled)"
        fi
        
        # Check HTTPS only
        local https_only=$(az storage account show --name "$storage_name" --resource-group "$RESOURCE_GROUP" --query "enableHttpsTrafficOnly" -o tsv)
        if [ "$https_only" = "true" ]; then
            print_status "PASS" "Storage Account requires HTTPS traffic only"
        else
            print_status "FAIL" "Storage Account allows HTTP traffic (should require HTTPS only)"
        fi
    else
        print_status "FAIL" "Storage Account not found"
    fi
}

# Function to validate Cosmos DB security
validate_cosmos_security() {
    echo -e "\n${BLUE}=== Cosmos DB Security Validation ===${NC}"
    
    if resource_exists "Microsoft.DocumentDB/databaseAccounts"; then
        local cosmos_name=$(get_resource_name "Microsoft.DocumentDB/databaseAccounts")
        print_status "PASS" "Cosmos DB Account '$cosmos_name' exists"
        
        # Check public network access
        local public_access=$(az cosmosdb show --name "$cosmos_name" --resource-group "$RESOURCE_GROUP" --query "publicNetworkAccess" -o tsv)
        if [ "$public_access" = "Disabled" ]; then
            print_status "PASS" "Cosmos DB public network access is disabled"
        else
            print_status "FAIL" "Cosmos DB public network access is enabled (should be disabled)"
        fi
    else
        print_status "FAIL" "Cosmos DB Account not found"
    fi
}

# Function to validate Cognitive Services security
validate_cognitive_services_security() {
    echo -e "\n${BLUE}=== Cognitive Services Security Validation ===${NC}"
    
    if resource_exists "Microsoft.CognitiveServices/accounts"; then
        local cog_name=$(get_resource_name "Microsoft.CognitiveServices/accounts")
        print_status "PASS" "Cognitive Services Account '$cog_name' exists"
        
        # Check public network access
        local public_access=$(az cognitiveservices account show --name "$cog_name" --resource-group "$RESOURCE_GROUP" --query "properties.publicNetworkAccess" -o tsv 2>/dev/null || echo "Enabled")
        if [ "$public_access" = "Disabled" ]; then
            print_status "PASS" "Cognitive Services public network access is disabled"
        else
            print_status "FAIL" "Cognitive Services public network access is enabled (should be disabled)"
        fi
    else
        print_status "FAIL" "Cognitive Services Account not found"
    fi
}

# Function to validate Key Vault security
validate_keyvault_security() {
    echo -e "\n${BLUE}=== Key Vault Security Validation ===${NC}"
    
    if resource_exists "Microsoft.KeyVault/vaults"; then
        local kv_name=$(get_resource_name "Microsoft.KeyVault/vaults")
        print_status "PASS" "Key Vault '$kv_name' exists"
        
        # Check public network access
        local public_access=$(az keyvault show --name "$kv_name" --resource-group "$RESOURCE_GROUP" --query "properties.publicNetworkAccess" -o tsv)
        if [ "$public_access" = "Disabled" ]; then
            print_status "PASS" "Key Vault public network access is disabled"
        else
            print_status "FAIL" "Key Vault public network access is enabled (should be disabled)"
        fi
    else
        print_status "FAIL" "Key Vault not found"
    fi
}

# Function to validate App Service configuration
validate_app_service() {
    echo -e "\n${BLUE}=== App Service Security Validation ===${NC}"
    
    if resource_exists "Microsoft.Web/sites"; then
        local app_name=$(get_resource_name "Microsoft.Web/sites")
        print_status "PASS" "App Service '$app_name' exists"
        
        # Check VNET integration
        local vnet_integration=$(az webapp vnet-integration list --name "$app_name" --resource-group "$RESOURCE_GROUP" --query "length(@)")
        if [ "$vnet_integration" -gt 0 ]; then
            print_status "PASS" "App Service has VNET integration configured"
        else
            print_status "FAIL" "App Service VNET integration not found"
        fi
        
        # Check HTTPS only
        local https_only=$(az webapp show --name "$app_name" --resource-group "$RESOURCE_GROUP" --query "httpsOnly" -o tsv)
        if [ "$https_only" = "true" ]; then
            print_status "PASS" "App Service requires HTTPS only"
        else
            print_status "WARN" "App Service allows HTTP traffic (consider enabling HTTPS only)"
        fi
    else
        print_status "FAIL" "App Service not found"
    fi
}

# Function to validate Log Analytics
validate_log_analytics() {
    echo -e "\n${BLUE}=== Log Analytics Validation ===${NC}"
    
    if resource_exists "Microsoft.OperationalInsights/workspaces"; then
        local workspace_name=$(get_resource_name "Microsoft.OperationalInsights/workspaces")
        print_status "PASS" "Log Analytics Workspace '$workspace_name' exists"
        
        # Check public network access
        local public_ingestion=$(az monitor log-analytics workspace show --workspace-name "$workspace_name" --resource-group "$RESOURCE_GROUP" --query "publicNetworkAccessForIngestion" -o tsv 2>/dev/null || echo "Enabled")
        if [ "$public_ingestion" = "Disabled" ]; then
            print_status "PASS" "Log Analytics public network access for ingestion is disabled"
        else
            print_status "FAIL" "Log Analytics public network access for ingestion is enabled (should be disabled)"
        fi
    else
        print_status "FAIL" "Log Analytics Workspace not found"
    fi
}

# Function to generate summary report
generate_summary() {
    echo -e "\n${BLUE}=== Security Validation Summary ===${NC}"
    echo "Total tests run: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    
    local pass_percentage=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Pass rate: $pass_percentage%"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All security validations passed! The solution is compliant.${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Some security validations failed. Please review and fix the issues.${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}CoPA Stop & Search - Security Compliance Validation${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        echo -e "${RED}Error: Azure CLI is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        echo -e "${RED}Error: Not logged in to Azure. Please run 'az login' first.${NC}"
        exit 1
    fi
    
    # Get parameters
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: $0 <resource-group> <subscription-id>"
        echo "Example: $0 rg-copa-prod 12345678-1234-1234-1234-123456789012"
        exit 1
    fi
    
    RESOURCE_GROUP=$1
    SUBSCRIPTION_ID=$2
    
    # Set subscription
    az account set --subscription "$SUBSCRIPTION_ID"
    
    echo -e "${BLUE}Validating resources in Resource Group: $RESOURCE_GROUP${NC}"
    echo -e "${BLUE}Subscription: $SUBSCRIPTION_ID${NC}\n"
    
    # Run validations
    validate_nsg
    validate_vnet
    validate_private_endpoints
    validate_storage_security
    validate_cosmos_security
    validate_cognitive_services_security
    validate_keyvault_security
    validate_app_service
    validate_log_analytics
    
    # Generate summary
    generate_summary
}

# Run main function with all arguments
main "$@"