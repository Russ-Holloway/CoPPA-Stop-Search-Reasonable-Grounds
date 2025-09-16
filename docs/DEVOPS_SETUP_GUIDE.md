# Azure DevOps Setup Guide for CoPA Stop & Search

This guide walks you through setting up secure Azure DevOps deployment for the CoPA Stop & Search application using the converted Bicep templates.

## 🚀 Quick Start Checklist

- [ ] Azure DevOps project created
- [ ] Service connections configured  
- [ ] Variable groups created
- [ ] Pipeline imported
- [ ] Environments configured
- [ ] First deployment tested

## 📋 Prerequisites

### Azure Requirements
- Azure subscription with appropriate permissions
- Resource group creation permissions
- Service Principal for DevOps authentication

### Azure DevOps Requirements  
- Azure DevOps organization and project
- Project administrator permissions
- Agent pools configured (uses Microsoft-hosted Ubuntu agents)

## 🔧 Step-by-Step Setup

### Step 1: Create Service Connections

Create secure service connections for each environment:

#### Development Service Connection
1. Go to **Project Settings** → **Service connections**
2. Click **Create service connection** → **Azure Resource Manager**  
3. Choose **Service principal (automatic)**
4. Configure:
   - **Connection name**: `copa-azure-service-connection-dev`
   - **Subscription**: Your Azure subscription
   - **Resource group**: `rg-dev-uksouth-copa-stop-search` (or create new)
   - **Security**: Grant access to all pipelines (for now)

#### Production Service Connection
1. Repeat above process with:
   - **Connection name**: `copa-azure-service-connection-prod`  
   - **Resource group**: Your production resource group
   - **Security**: Restrict to specific pipelines (recommended)

### Step 2: Create Variable Groups

Create variable groups for environment-specific configuration:

#### Development Variable Group
1. Go to **Pipelines** → **Library** → **Variable groups**
2. Click **+ Variable group**
3. Name: `copa-dev-variables`
4. Add variables from `.azure-devops/copa-dev-variables.yml`:

```yaml
resourceGroupName: rg-dev-uksouth-copa-stop-search
azureLocation: uksouth  
environmentName: development
openAIModel: gpt-4o
embeddingModel: text-embedding-ada-002
```

#### Production Variable Group  
1. Create another variable group: `copa-prod-variables`
2. Add variables from `.azure-devops/copa-prod-variables.yml`
3. **Important**: Mark sensitive variables as secrets:
   - `appClientId` 🔐
   - `appClientSecret` 🔐

### Step 3: Create Environments

Set up deployment environments with appropriate approvals:

#### Development Environment
1. Go to **Pipelines** → **Environments**
2. Click **Create environment**
3. Configure:
   - **Name**: `copa-development`
   - **Resource type**: None
   - **Approvers**: Optional (auto-deploy from Dev-Ops-Deployment branch)

#### Production Environment
1. Create another environment: `copa-production`
2. Configure security:
   - **Approvers**: Add required approvers
   - **Branch control**: Restrict to `main` branch only
   - **Required template**: Optional, for additional security

### Step 4: Import Pipeline

1. Go to **Pipelines** → **Pipelines**
2. Click **Create Pipeline**
3. Choose **Azure Repos Git** (or your source)
4. Select your repository
5. Choose **Existing Azure Pipelines YAML file**
6. Select `/azure-pipelines.yml`
7. **Review and Save** (don't run yet)

### Step 5: Configure Pipeline Variables

Update the main pipeline variables if needed:

```yaml
variables:
  - name: azureServiceConnection
    value: 'copa-azure-service-connection'  # Update if different
  - name: bicepTemplatePath  
    value: 'infra/main-pds-converted.bicep'
```

## 🏗️ Deployment Process

### Branch Strategy

The pipeline is configured for GitFlow-style deployment:

- **Dev-Ops-Deployment branch** → Development environment
- **main branch** → Production environment  

### Deployment Stages

1. **Validate**: Bicep template validation and security scanning
2. **Build**: Package application and infrastructure  
3. **Deploy Development**: Auto-deploy from Dev-Ops-Deployment branch
4. **Deploy Production**: Deploy from main branch with approvals

### First Deployment

#### Deploy to Development
1. Create/switch to `Dev-Ops-Deployment` branch
2. Commit your changes  
3. Push to trigger pipeline
4. Monitor deployment in Azure DevOps

#### Deploy to Production  
1. Merge `Dev-Ops-Deployment` to `main` via Pull Request
2. Pipeline will trigger production deployment
3. Approve deployment if required
4. Monitor production deployment

## 🔐 Security Configuration

### Service Principal Permissions

The service principal needs these permissions:

**Resource Group Level**:
- Contributor (for resource deployment)
- User Access Administrator (for role assignments)

**Subscription Level** (if creating resource groups):
- Contributor

### Variable Security

**Mark as secrets**:
- Application Client ID and Secret  
- Database connection strings
- API keys
- Any sensitive configuration

**Use Key Vault** for production secrets (recommended):
1. Deploy Azure Key Vault via Bicep
2. Reference secrets in app settings
3. Use managed identity for Key Vault access

## 🎯 Testing Your Setup

### Pre-Flight Checks

Before first deployment, verify:

```bash
# Check Bicep template validity
az bicep build --file infra/main-pds-converted.bicep

# Test resource group creation
az group create --name rg-test-deployment --location uksouth

# Validate deployment (dry-run)  
az deployment group validate \
  --resource-group rg-test-deployment \
  --template-file infra/main-pds-converted.bicep \
  --parameters location=uksouth
```

### Deployment Verification

After successful deployment, verify:

1. **Azure Resources**: Check all 15 resources are created
2. **Web App**: Verify application is running
3. **OpenAI**: Test model deployments
4. **Search Service**: Verify search index creation
5. **Monitoring**: Check Application Insights data

## 🚨 Troubleshooting

### Common Issues

#### Pipeline Fails at Validation
- Check Bicep syntax: `az bicep build --file infra/main-pds-converted.bicep`
- Verify service connection permissions
- Check resource provider registrations

#### Infrastructure Deployment Fails
- Check quota limits for OpenAI and other services
- Verify resource group permissions  
- Check for naming conflicts

#### Application Deployment Fails
- Verify web app creation succeeded
- Check application artifacts are properly packaged
- Verify runtime stack configuration

#### Service Connection Issues
- Verify service principal permissions
- Check subscription access
- Refresh service connection if expired

### Getting Help

1. Check Azure DevOps pipeline logs
2. Review Azure Activity Log for deployment errors
3. Verify Bicep template outputs
4. Check application logs in Azure Monitor

## 🔄 Ongoing Maintenance

### Regular Tasks

- Monitor pipeline success rates
- Review security scan results  
- Update dependencies regularly
- Rotate service principal credentials
- Review and update approvers

### Best Practices

- Use separate service connections per environment
- Implement approval processes for production
- Regular backup of variable groups
- Monitor costs and resource utilization
- Keep Bicep templates updated

## 📚 Additional Resources

- [Azure DevOps Documentation](https://docs.microsoft.com/azure/devops/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Security Best Practices](https://docs.microsoft.com/azure/security/)

## 🎉 Success Criteria

Your setup is complete when:

- [ ] Pipeline runs successfully on both branches
- [ ] Infrastructure deploys correctly with PDS naming
- [ ] Application is accessible and functional  
- [ ] Security scans pass without critical issues
- [ ] Monitoring and logging are working
- [ ] Team can deploy safely to production