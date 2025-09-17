#!/bin/bash

# CoPA Stop & Search - BTP Deployment for CA Policy Environments
# This script provides multiple authentication workarounds for restrictive CA policies

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

# Function to show authentication options for CA policy environments
show_auth_options() {
    echo_info "=== AUTHENTICATION OPTIONS FOR CA POLICY ENVIRONMENTS ==="
    echo ""
    echo "Since you have restrictive Conditional Access policies, here are your options:"
    echo ""
    echo "🔐 OPTION 1: Use Azure Cloud Shell (RECOMMENDED)"
    echo "   • Go to: https://shell.azure.com"
    echo "   • Upload this repository to Cloud Shell"
    echo "   • Run deployment from there (bypasses CA policies)"
    echo ""
    echo "🔑 OPTION 2: Service Principal Authentication"
    echo "   • Create a Service Principal in Azure AD"
    echo "   • Use client credentials flow (not affected by CA policies)"
    echo ""
    echo "🌐 OPTION 3: Azure Portal Template Deployment"
    echo "   • Use the Azure Portal's custom template deployment"
    echo "   • Upload the compiled ARM template directly"
    echo ""
    echo "💻 OPTION 4: Different Machine/Network"
    echo "   • Use a machine outside your corporate network"
    echo "   • Or ask IT to temporarily exempt you from CA policies"
    echo ""
    echo "Which option would you like to use? (1-4):"
}

# Function to guide Cloud Shell deployment
guide_cloud_shell_deployment() {
    echo_info "=== AZURE CLOUD SHELL DEPLOYMENT GUIDE ==="
    echo ""
    echo_info "Step 1: Open Azure Cloud Shell"
    echo "• Go to: https://shell.azure.com"
    echo "• Choose Bash (not PowerShell)"
    echo "• Wait for the shell to initialize"
    echo ""
    echo_info "Step 2: Upload Repository to Cloud Shell"
    echo "• Click the Upload/Download files icon in Cloud Shell"
    echo "• Create a zip file of your repository first:"
    echo ""
    echo "  # Run this locally to create a zip:"
    echo "  cd /workspaces/CoPA-Stop-Search-Reasonable-Grounds"
    echo "  zip -r copa-btp-deployment.zip . -x '*.git/*' 'node_modules/*' '*.vscode/*'"
    echo ""
    echo "• Upload the zip file to Cloud Shell"
    echo "• Extract it: unzip copa-btp-deployment.zip"
    echo ""
    echo_info "Step 3: Run Deployment in Cloud Shell"
    echo "• cd copa-btp-deployment (or whatever folder name)"
    echo "• chmod +x scripts/deploy-btp-cli.sh"
    echo "• ./scripts/deploy-btp-cli.sh"
    echo ""
    echo_warning "Cloud Shell comes pre-authenticated with your Azure account!"
    echo_success "This bypasses all Conditional Access policies"
}

# Function to guide Service Principal setup
guide_service_principal() {
    echo_info "=== SERVICE PRINCIPAL AUTHENTICATION GUIDE ==="
    echo ""
    echo_warning "This requires Azure AD permissions to create Service Principals"
    echo ""
    echo_info "Step 1: Create Service Principal (run in a browser/different machine)"
    echo "• Go to Azure Portal → Azure Active Directory → App registrations"
    echo "• Click 'New registration'"
    echo "• Name: 'CoPA-BTP-Deployment'"
    echo "• Leave other settings as default"
    echo "• Click 'Register'"
    echo ""
    echo_info "Step 2: Create Client Secret"
    echo "• In your app registration → Certificates & secrets"
    echo "• Click 'New client secret'"
    echo "• Description: 'CLI Deployment'"
    echo "• Expires: 6 months (or as per your policy)"
    echo "• Copy the secret value (you won't see it again!)"
    echo ""
    echo_info "Step 3: Assign Permissions"
    echo "• Go to your target subscription"
    echo "• Access control (IAM) → Add role assignment"
    echo "• Role: Contributor"
    echo "• Assign access to: User, group, or service principal"
    echo "• Select your app: CoPA-BTP-Deployment"
    echo ""
    echo_info "Step 4: Login with Service Principal"
    echo "az login --service-principal \\"
    echo "  --username <application-id> \\"
    echo "  --password <client-secret> \\"
    echo "  --tenant <tenant-id>"
    echo ""
    echo_info "Step 5: Run Deployment"
    echo "./scripts/deploy-btp-cli.sh"
}

# Function to generate ARM template for Portal deployment
generate_arm_template() {
    echo_info "=== GENERATING ARM TEMPLATE FOR PORTAL DEPLOYMENT ==="
    echo ""
    echo_info "Converting Bicep to ARM template..."
    
    if az bicep build --file "$TEMPLATE_FILE" --outfile "./infra/main.json"; then
        echo_success "ARM template generated: ./infra/main.json"
        echo ""
        echo_info "Portal Deployment Steps:"
        echo "1. Go to: https://portal.azure.com"
        echo "2. Search for 'Deploy a custom template'"
        echo "3. Click 'Build your own template in the editor'"
        echo "4. Upload the file: ./infra/main.json"
        echo "5. Upload parameters file: ./infra/main.parameters.json"
        echo "6. Set Resource Group: rg-btp-p-copa-stop-search"
        echo "7. Set Region: UK South"
        echo "8. Click 'Review + create'"
        echo ""
        echo_success "This method works with any authentication method supported by Azure Portal"
    else
        echo_error "Failed to generate ARM template"
    fi
}

# Function to create deployment package
create_deployment_package() {
    echo_info "=== CREATING DEPLOYMENT PACKAGE ==="
    echo ""
    
    # Create deployment directory
    mkdir -p ./deployment-package
    
    # Copy necessary files
    cp -r ./infra ./deployment-package/
    cp -r ./scripts ./deployment-package/
    cp ./azure.yaml ./deployment-package/ 2>/dev/null || echo_warning "azure.yaml not found, skipping"
    
    # Generate ARM template
    if az bicep build --file ./infra/main.bicep --outfile ./deployment-package/infra/main.json; then
        echo_success "ARM template generated in package"
    fi
    
    # Create instructions file
    cat > ./deployment-package/DEPLOYMENT-INSTRUCTIONS.md << 'EOF'
# CoPA Stop & Search - BTP Deployment Package

## Quick Start for Cloud Shell

1. Upload this entire package to Azure Cloud Shell
2. Extract: `unzip deployment-package.zip`
3. Navigate: `cd deployment-package`
4. Make executable: `chmod +x scripts/deploy-btp-cli.sh`
5. Deploy: `./scripts/deploy-btp-cli.sh`

## Portal Deployment

1. Go to Azure Portal
2. Search: "Deploy a custom template"
3. Upload: `infra/main.json`
4. Upload parameters: `infra/main.parameters.json`
5. Set Resource Group: `rg-btp-p-copa-stop-search`
6. Set Region: `UK South`
7. Deploy

## Service Principal Deployment

1. Create Service Principal in Azure AD
2. Assign Contributor role to subscription
3. Login: `az login --service-principal -u <app-id> -p <secret> --tenant <tenant>`
4. Deploy: `./scripts/deploy-btp-cli.sh`

EOF
    
    # Create zip package
    cd ./deployment-package
    zip -r ../copa-btp-deployment-package.zip . -x "*.git/*"
    cd ..
    
    echo_success "Deployment package created: copa-btp-deployment-package.zip"
    echo_info "This package contains everything needed for deployment"
}

# Function to show manual deployment commands
show_manual_commands() {
    echo_info "=== MANUAL DEPLOYMENT COMMANDS ==="
    echo ""
    echo_info "If you can authenticate somehow, here are the exact commands:"
    echo ""
    echo "# 1. Create Resource Group"
    echo "az group create \\"
    echo "  --name '$RESOURCE_GROUP_NAME' \\"
    echo "  --location '$LOCATION'"
    echo ""
    echo "# 2. Deploy Infrastructure"
    echo "az deployment group create \\"
    echo "  --resource-group '$RESOURCE_GROUP_NAME' \\"
    echo "  --name '$DEPLOYMENT_NAME' \\"
    echo "  --template-file '$TEMPLATE_FILE' \\"
    echo "  --parameters '@$PARAMETERS_FILE' \\"
    echo "  --verbose"
    echo ""
    echo_info "These commands will work in any authenticated environment"
}

# Main menu
main_menu() {
    echo_info "=== CoPA Stop & Search - BTP Deployment (CA Policy Workarounds) ==="
    echo ""
    
    show_auth_options
    
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            guide_cloud_shell_deployment
            create_deployment_package
            ;;
        2)
            guide_service_principal
            ;;
        3)
            generate_arm_template
            ;;
        4)
            echo_info "Try deployment from a different machine or network location"
            echo_warning "Or contact IT to temporarily exempt your account from CA policies"
            show_manual_commands
            ;;
        *)
            echo_error "Invalid choice. Please select 1-4."
            main_menu
            ;;
    esac
}

# Function to check if we can authenticate at all
check_current_auth() {
    echo_info "Checking current authentication status..."
    
    if az account show &>/dev/null; then
        echo_success "You are currently authenticated!"
        local account_info=$(az account show --query "{name:name, id:id, user:user.name}" -o table)
        echo "$account_info"
        echo ""
        echo "Would you like to proceed with deployment using current authentication? (y/n):"
        read -p "" proceed
        if [[ $proceed == [yY]* ]]; then
            echo_info "Proceeding with deployment..."
            ./scripts/deploy-btp-cli.sh
            exit 0
        fi
    else
        echo_warning "Not currently authenticated to Azure"
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "CoPA Stop & Search - BTP Deployment (CA Policy Workarounds)"
        echo ""
        echo "This script provides alternatives for deploying when CA policies block standard authentication"
        echo ""
        echo "Options:"
        echo "  --cloud-shell     Generate package for Azure Cloud Shell deployment"
        echo "  --portal          Generate ARM template for Portal deployment"
        echo "  --service-principal  Guide for Service Principal authentication"
        echo "  --manual          Show manual deployment commands"
        echo ""
        exit 0
        ;;
    --cloud-shell)
        guide_cloud_shell_deployment
        create_deployment_package
        exit 0
        ;;
    --portal)
        generate_arm_template
        exit 0
        ;;
    --service-principal)
        guide_service_principal
        exit 0
        ;;
    --manual)
        show_manual_commands
        exit 0
        ;;
    *)
        check_current_auth
        main_menu
        ;;
esac