#!/bin/bash

# Azure DevOps Setup Verification Script
# Run this after completing the DevOps project setup to verify everything is configured correctly

set -e

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

echo "🚀 Azure DevOps Setup Verification"
echo "================================="
echo

# Configuration - Update these with your actual values
ORG_URL="https://dev.azure.com/uk-police-copa"
PROJECT_NAME="CoPA-Stop-Search"
REPO_NAME="CoPA-Stop-Search-Reasonable-Grounds"

print_status "blue" "Verifying Azure DevOps setup..."
echo

# Check 1: Repository files
print_status "blue" "1. Checking repository files..."

if [ -f "azure-pipelines.yml" ]; then
    print_status "green" "Main pipeline file exists"
else
    print_status "red" "Main pipeline file missing: azure-pipelines.yml"
fi

if [ -f "azure-pipelines-infra.yml" ]; then
    print_status "green" "Infrastructure pipeline file exists"
else
    print_status "yellow" "Infrastructure pipeline file missing (optional)"
fi

if [ -f "infra/main-pds-converted.bicep" ]; then
    print_status "green" "Bicep template exists"
else
    print_status "red" "Bicep template missing: infra/main-pds-converted.bicep"
fi

if [ -d ".azure-devops" ]; then
    print_status "green" "DevOps configuration directory exists"
    
    if [ -f ".azure-devops/QUICK_START_GUIDE.md" ]; then
        print_status "green" "Quick start guide exists"
    fi
    
    if [ -f ".azure-devops/SETUP_CHECKLIST.md" ]; then
        print_status "green" "Setup checklist exists"
    fi
else
    print_status "red" "DevOps configuration directory missing"
fi

echo

# Check 2: Bicep template validation
print_status "blue" "2. Validating Bicep template..."

if command -v az > /dev/null 2>&1; then
    if az bicep build --file infra/main-pds-converted.bicep > /dev/null 2>&1; then
        print_status "green" "Bicep template compiles successfully"
    else
        print_status "red" "Bicep template has compilation errors"
        print_status "gray" "Run: az bicep build --file infra/main-pds-converted.bicep"
    fi
else
    print_status "yellow" "Azure CLI not found - cannot validate Bicep template"
    print_status "gray" "Install Azure CLI to validate templates"
fi

echo

# Check 3: Pipeline YAML validation
print_status "blue" "3. Checking pipeline configuration..."

if grep -q "copa-azure-service-connection" azure-pipelines.yml; then
    print_status "green" "Service connection references found in pipeline"
else
    print_status "yellow" "Service connection references might be missing"
fi

if grep -q "copa-dev-variables" azure-pipelines.yml; then
    print_status "green" "Development variable group referenced"
else
    print_status "yellow" "Development variable group reference might be missing"
fi

if grep -q "copa-prod-variables" azure-pipelines.yml; then
    print_status "green" "Production variable group referenced"
else
    print_status "yellow" "Production variable group reference might be missing"
fi

if grep -q "copa-development" azure-pipelines.yml; then
    print_status "green" "Development environment referenced"
else
    print_status "yellow" "Development environment reference might be missing"
fi

if grep -q "copa-production" azure-pipelines.yml; then
    print_status "green" "Production environment referenced"
else
    print_status "yellow" "Production environment reference might be missing"
fi

echo

# Check 4: Security configuration
print_status "blue" "4. Checking security configuration..."

if grep -q "bandit" azure-pipelines.yml; then
    print_status "green" "Python security scanning (bandit) configured"
else
    print_status "yellow" "Python security scanning might be missing"
fi

if grep -q "safety" azure-pipelines.yml; then
    print_status "green" "Dependency security scanning (safety) configured"
else
    print_status "yellow" "Dependency security scanning might be missing"
fi

if grep -q "npm audit" azure-pipelines.yml; then
    print_status "green" "Node.js security scanning configured"
else
    print_status "yellow" "Node.js security scanning might be missing"
fi

echo

# Check 5: Branch configuration
print_status "blue" "5. Checking branch setup..."

current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$current_branch" = "Dev-Ops-Deployment" ]; then
    print_status "green" "Currently on Dev-Ops-Deployment branch"
else
    print_status "yellow" "Current branch: $current_branch (expected: Dev-Ops-Deployment)"
fi

if git show-ref --verify --quiet refs/heads/main; then
    print_status "green" "Main branch exists"
else
    print_status "yellow" "Main branch might not exist locally"
fi

echo

# Summary
print_status "blue" "📋 Setup Verification Summary"
echo
print_status "gray" "Manual verification needed in Azure DevOps:"
print_status "gray" "1. Project exists: $ORG_URL/$PROJECT_NAME"
print_status "gray" "2. Repository imported: $REPO_NAME"
print_status "gray" "3. Service connections created:"
print_status "gray" "   - copa-azure-service-connection-dev"
print_status "gray" "   - copa-azure-service-connection-prod"
print_status "gray" "4. Variable groups created:"
print_status "gray" "   - copa-dev-variables"
print_status "gray" "   - copa-prod-variables"
print_status "gray" "5. Environments created:"
print_status "gray" "   - copa-development"
print_status "gray" "   - copa-production"
print_status "gray" "6. Pipeline imported: CoPA-Stop-Search-Main-Deploy"

echo
print_status "blue" "🎯 Next Steps:"
print_status "gray" "1. Run pipeline validation in Azure DevOps"
print_status "gray" "2. Create Azure resources (if not already done)"
print_status "gray" "3. Test development deployment"
print_status "gray" "4. Configure production approvals"
print_status "gray" "5. Deploy to production"

echo
print_status "green" "🎉 Local verification complete!"
print_status "gray" "Check Azure DevOps web interface to confirm all components are created"