# Azure CLI Deployment Guide for BTP Environment

This guide provides step-by-step instructions to deploy the CoPA Stop & Search application to the BTP environment using Azure CLI, bypassing the need for DevOps parallelism.

## Prerequisites

### 1. Azure CLI Installation
Ensure Azure CLI is installed and up to date:
```bash
# Check if Azure CLI is installed
az --version

# Update Azure CLI (if needed)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 2. Authentication Options

#### Option A: Regular Login (if no Conditional Access policies)
```bash
az login
```

#### Option B: Device Code Flow (recommended for Conditional Access environments)
```bash
az login --use-device-code
```

#### Option C: Service Principal (for automated deployments)
```bash
az login --service-principal -u <app-id> -p <password-or-cert> --tenant <tenant-id>
```

### 3. Required Permissions
Your Azure account needs the following permissions on the target subscription:
- **Contributor** role (minimum)
- **User Access Administrator** role (for role assignments)
- Permissions to create resources in the target subscription

## Deployment Options

### Option 1: Full Automated Deployment (Recommended)

**Step 1: Run the deployment script**
```bash
cd /workspaces/CoPA-Stop-Search-Reasonable-Grounds
./scripts/deploy-btp-cli.sh
```

The script will:
- ✅ Check Azure authentication
- ✅ Allow subscription selection
- ✅ Create the resource group
- ✅ Validate the Bicep template
- ✅ Run What-If analysis
- ✅ Deploy the infrastructure
- ✅ Retrieve deployment outputs
- ✅ Verify key resources
- ✅ Display next steps

**Step 2: Follow the interactive prompts**
- Confirm your subscription
- Review the What-If analysis
- Confirm deployment when prompted

### Option 2: Step-by-Step Manual Deployment

**Step 1: Authenticate and set subscription**
```bash
# Login (use device code if you have CA policies)
az login --use-device-code

# List available subscriptions
az account list --output table

# Set the target subscription
az account set --subscription "<subscription-id-or-name>"
```

**Step 2: Create resource group**
```bash
az group create \
    --name "rg-btp-p-copa-stop-search" \
    --location "uksouth" \
    --tags Environment=Production Project=CoPA-Stop-Search
```

**Step 3: Validate the template**
```bash
cd /workspaces/CoPA-Stop-Search-Reasonable-Grounds

# Compile Bicep template
az bicep build --file ./infra/main.bicep

# Validate against Azure
az deployment group validate \
    --resource-group "rg-btp-p-copa-stop-search" \
    --template-file "./infra/main.bicep" \
    --parameters "@./infra/main.parameters.json"
```

**Step 4: Run What-If analysis (optional but recommended)**
```bash
az deployment group what-if \
    --resource-group "rg-btp-p-copa-stop-search" \
    --template-file "./infra/main.bicep" \
    --parameters "@./infra/main.parameters.json"
```

**Step 5: Deploy the infrastructure**
```bash
az deployment group create \
    --resource-group "rg-btp-p-copa-stop-search" \
    --name "btp-copa-deployment-$(date +%Y%m%d-%H%M%S)" \
    --template-file "./infra/main.bicep" \
    --parameters "@./infra/main.parameters.json" \
    --verbose
```

### Option 3: Validation Only

If you just want to validate without deploying:
```bash
./scripts/deploy-btp-cli.sh --validate
```

### Option 4: What-If Analysis Only

To see what would be deployed without making changes:
```bash
./scripts/deploy-btp-cli.sh --whatif
```

## Expected Resources

The deployment will create these resources with BTP naming convention:

| Resource Type | Resource Name | Purpose |
|---------------|---------------|---------|
| Resource Group | `rg-btp-p-copa-stop-search` | Container for all resources |
| App Service Plan | `asp-btp-p-copa-stop-search-001` | Hosting plan for web app |
| App Service | `app-btp-p-copa-stop-search-001` | Main web application |
| Cosmos DB | `db-btp-p-copa-stop-search-001` | Document database |
| Key Vault | `kvbtppcopastopsearch001` | Secrets management |
| OpenAI Service | `cog-btp-p-copa-stop-search-001` | AI services |
| Search Service | `srch-btp-p-copa-stop-search-001` | Azure Cognitive Search |
| Storage Account | `stbtppcopastopsearch001` | File and blob storage |
| Virtual Network | `vnet-btp-p-copa-stop-search-001` | Network isolation |
| Log Analytics | `log-btp-p-copa-stop-search-001` | Monitoring and logging |

## Deployment Time

- **Expected Duration**: 15-30 minutes
- **Critical Path**: OpenAI service provisioning (typically the slowest)
- **Parallel Operations**: Most resources deploy concurrently

## Monitoring Deployment Progress

### Real-time Monitoring
```bash
# Watch deployment progress
az deployment group list \
    --resource-group "rg-btp-p-copa-stop-search" \
    --output table

# Get detailed deployment status
az deployment group show \
    --resource-group "rg-btp-p-copa-stop-search" \
    --name "<deployment-name>"
```

### Azure Portal Monitoring
Visit: `https://portal.azure.com` → Resource Groups → `rg-btp-p-copa-stop-search` → Deployments

## Post-Deployment Configuration

### 1. Application Settings
Configure the App Service with required environment variables:
```bash
# Set application settings (example)
az webapp config appsettings set \
    --name "app-btp-p-copa-stop-search-001" \
    --resource-group "rg-btp-p-copa-stop-search" \
    --settings \
        AZURE_COSMOSDB_ACCOUNT="db-btp-p-copa-stop-search-001" \
        AZURE_OPENAI_SERVICE="cog-btp-p-copa-stop-search-001"
```

### 2. Deploy Application Code
```bash
# Option A: Deploy from local source
az webapp deployment source config-zip \
    --name "app-btp-p-copa-stop-search-001" \
    --resource-group "rg-btp-p-copa-stop-search" \
    --src "path/to/your/app.zip"

# Option B: Configure continuous deployment from Git
az webapp deployment source config \
    --name "app-btp-p-copa-stop-search-001" \
    --resource-group "rg-btp-p-copa-stop-search" \
    --repo-url "https://github.com/your-repo/copa-app" \
    --branch "main" \
    --manual-integration
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Solution: Use `az login --use-device-code` for CA policy environments
   - Check: `az account show` to verify logged in account

2. **Permission Denied**
   - Ensure your account has Contributor + User Access Administrator roles
   - Check subscription permissions: `az role assignment list --assignee $(az account show --query user.name -o tsv)`

3. **Resource Name Conflicts**
   - Resource names must be globally unique (especially Key Vault, Storage Account)
   - The script uses BTP naming convention to minimize conflicts

4. **Template Validation Failures**
   - Run: `az bicep build --file ./infra/main.bicep` to check syntax
   - Review error messages for specific parameter issues

5. **Deployment Timeout**
   - OpenAI services can take 10-15 minutes to provision
   - Monitor in Azure Portal for detailed progress

### Getting Help

1. **View deployment operation details:**
   ```bash
   az deployment group show \
       --resource-group "rg-btp-p-copa-stop-search" \
       --name "<deployment-name>" \
       --query "properties.error"
   ```

2. **Check activity log:**
   ```bash
   az monitor activity-log list \
       --resource-group "rg-btp-p-copa-stop-search" \
       --max-events 50
   ```

3. **Resource-specific troubleshooting:**
   ```bash
   # Check specific resource status
   az resource show \
       --name "<resource-name>" \
       --resource-group "rg-btp-p-copa-stop-search" \
       --resource-type "<resource-type>"
   ```

## Cleanup (When No Longer Needed)

To remove all deployed resources:
```bash
# Delete the entire resource group (removes all resources)
az group delete \
    --name "rg-btp-p-copa-stop-search" \
    --yes \
    --no-wait

# Monitor deletion progress
az group show --name "rg-btp-p-copa-stop-search"
```

## Cost Management

- **Monitor costs**: Set up budget alerts in Azure Portal
- **Resource optimization**: Consider scaling down non-production resources
- **Clean up**: Remove unused deployments and resources regularly

## Security Considerations

1. **Private Endpoints**: All services are configured with private endpoints
2. **Network Security Groups**: Restrict traffic to necessary ports only
3. **Key Vault**: All secrets are stored securely
4. **Managed Identity**: Used for secure service-to-service authentication
5. **Public Access**: Disabled for storage accounts and databases

## Next Steps After Deployment

1. 🌐 **Verify Resources**: Check all resources in Azure Portal
2. 🔑 **Configure App Settings**: Set environment variables
3. 📦 **Deploy Application Code**: Use deployment slots for zero-downtime
4. 🧪 **Test Functionality**: Run integration tests
5. 📊 **Set Up Monitoring**: Configure alerts and dashboards
6. 🔒 **Security Review**: Validate security configurations
7. 📈 **Performance Testing**: Run load tests if needed

---

**Need help?** Contact the development team or check the Azure documentation for specific service configurations.