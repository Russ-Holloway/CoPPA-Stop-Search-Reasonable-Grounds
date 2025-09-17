# CoPA Stop & Search - BTP Portal Deployment Guide

## 🌐 Deploy via Azure Portal (Recommended for CA Policy Environments)

### Prerequisites
- Access to Azure Portal (portal.azure.com)
- Appropriate permissions in the target subscription
- Bicep template file ready

### Step 1: Access Azure Portal
1. Go to https://portal.azure.com
2. Sign in with your Azure credentials
3. Switch to your AI subscription:
   - Click on the subscription dropdown (top-right)
   - Select your AI subscription

### Step 2: Start Custom Deployment
1. In the search bar, type "Deploy a custom template"
2. Click on "Deploy a custom template" service
3. Click "Build your own template in the editor"

### Step 3: Upload Bicep Template
1. Click "Load file"
2. Upload: `/workspaces/CoPA-Stop-Search-Reasonable-Grounds/infra/main.bicep`
3. Click "Save"

### Step 4: Configure Deployment Parameters

**IMPORTANT: Use these exact values for secure BTP deployment:**

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Subscription** | Your AI Subscription | Auto-selected |
| **Resource group** | Create new: `rg-btp-p-copa-stop-search` | Will be created by template |
| **Region** | UK South | Primary deployment region |
| **Environment Name** | `copa-btp` | Environment identifier |
| **Location** | `uksouth` | Same as region |
| **Environment Code** | `p` | Production environment |
| **Instance Number** | `001` | Instance identifier |
| **Enable Private Endpoints** | `true` | ✅ SECURITY: Enable for production |
| **VNet Address Prefix** | `10.0.0.0/16` | Network range |
| **App Service Subnet** | `10.0.1.0/24` | App subnet |
| **Private Endpoint Subnet** | `10.0.2.0/24` | PE subnet |
| **Resource Group Name** | `rg-btp-p-copa-stop-search` | Target RG |
| **OpenAI Sku Name** | `S0` | Standard tier |
| **Search Service Sku Name** | `basic` | Basic search tier |
| **Form Recognizer Sku Name** | `S0` | Standard tier |

**Leave these EMPTY (will use defaults):**
- OpenAI Resource Name
- OpenAI Resource Group Name
- Search Service Name
- Search Service Resource Group Name
- Form Recognizer Service Name
- Form Recognizer Resource Group Name
- Auth Client ID
- Auth Client Secret
- Cosmos Account Name
- Key Vault Name
- Log Analytics Workspace Name
- App Service Plan Name
- Backend Service Name

### Step 5: Review and Deploy
1. Click "Review + create"
2. Review the configuration
3. Look for: **Cosmos DB: db-btp-p-copa-stop-search-001** ✅
4. Click "Create"

### Step 6: Monitor Deployment
- Deployment typically takes 20-40 minutes
- Watch the progress in the deployment blade
- You'll see each resource being created

### Step 7: Verify Resources
After deployment completes, verify these key resources exist:
- ✅ Resource Group: `rg-btp-p-copa-stop-search`
- ✅ Cosmos DB: `db-btp-p-copa-stop-search-001`
- ✅ App Service: `app-btp-p-copa-stop-search-001`
- ✅ Key Vault: `kv-btp-p-copa-stop-search-001`
- ✅ Private Endpoints for all services
- ✅ Virtual Network with proper subnets

## 🔒 Security Verification
1. Go to Virtual Networks → Check private endpoints
2. Go to Cosmos DB → Verify networking is set to private endpoints only
3. Check all services have private endpoint connections

## ⚠️ Important Notes
- This creates a PRODUCTION-READY secure environment
- All services will only be accessible via private network
- You may need VPN/Bastion for management access
- Perfect for sensitive police data

## 🆘 Troubleshooting
If deployment fails:
1. Check the error message in the portal
2. Common issues:
   - Subscription limits/quotas
   - Resource name conflicts
   - Permissions issues
3. You can retry the deployment with same parameters