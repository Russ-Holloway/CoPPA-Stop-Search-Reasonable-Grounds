# Simplified Prerequisites Approach

## 🎯 New Simplified Architecture

After reviewing the storage account and Key Vault dependencies, here's the recommended approach that balances automation with security:

## Prerequisites (Minimal Manual Steps)

### 1. App Registration Only
**What you create manually:**
- Azure AD App Registration
- Client Secret

**Why manual:**
- Requires elevated permissions often not available to service principals
- One-time setup that doesn't change between deployments

### 2. Everything Else Automated
**What the pipeline creates:**
- ✅ Key Vault (with proper dependencies)
- ✅ Storage Account (with CMK if desired)
- ✅ All private endpoints
- ✅ Network security groups
- ✅ Virtual network infrastructure
- ✅ All Azure services (OpenAI, Search, Cosmos, etc.)

## Key Benefits of This Approach

### 🔒 **Security Handled Correctly**
- Key Vault created first, then storage with CMK
- Private endpoints for all services
- Network isolation properly configured
- CMK encryption available if needed

### 🚀 **Deployment Simplicity**
- Only need App Registration as prerequisite
- Pipeline handles all infrastructure complexity
- No storage account naming conflicts
- No manual private endpoint setup

### 🔧 **Technical Correctness**
- Proper dependency order (Key Vault → Storage → Private Endpoints)
- Consistent naming across all resources
- Integrated security model

## Updated Prerequisites Steps

### Step 1: Create App Registration

**Using Azure Portal:**
1. Navigate to Azure Active Directory → App registrations
2. Click "New registration"
3. Configure:
   - **Name**: `CoPA-Stop-Search-Prod-001` (or Dev-001 for development)
   - **Account types**: "Accounts in this organizational directory only"
   - **Redirect URI**: `https://app-btp-p-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback`
     - For development: `https://app-btp-d-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback`
     - Replace `001` with your instance number if different

**Using Azure CLI:**
```bash
# For Production
az ad app create \
  --display-name "CoPA-Stop-Search-Prod-001" \
  --web-redirect-uris "https://app-btp-p-copa-stop-search-001.azurewebsites.net/.auth/login/aad/callback"

# Create service principal
az ad sp create --id <app-id>

# Create client secret
az ad app credential reset --id <app-id>
```

**Important URI Format:**
- Base pattern: `https://{app-service-name}.azurewebsites.net/.auth/login/aad/callback`
- The `/.auth/login/aad/callback` path is required and must be exact

### Step 2: Update Parameter Files
```json
{
  "authClientId": "<app-registration-id>",
  "authClientSecret": "<client-secret>"
}
```

### Step 3: Run Pipeline
Everything else is automated!

## CMK Support

If you want Customer Managed Keys:

1. **Pipeline creates Key Vault first**
2. **Pipeline creates CMK in Key Vault**
3. **Pipeline creates Storage Account with CMK**
4. **No circular dependencies**

## Network Security

- All services get private endpoints automatically
- Network Security Groups applied consistently
- Virtual network properly configured
- No manual networking required

## Storage Account Benefits

**Pipeline-created storage provides:**
- Proper naming consistency
- CMK encryption support
- Private endpoint integration
- Container creation
- RBAC assignments
- Network access policies

## Migration Path

If you already have manual storage prerequisites configured:

1. **Keep existing approach** - parameter files support both
2. **Migrate gradually** - remove storage prerequisites when ready
3. **Test thoroughly** - validate logo URLs and file uploads

## Recommendation

**Use this simplified approach** because:
- ✅ Eliminates storage account prerequisite complexity
- ✅ Proper Key Vault → Storage → Private Endpoint ordering
- ✅ Better security with CMK support
- ✅ Simpler deployment workflow
- ✅ Consistent resource naming
- ✅ Reduces manual errors

The only manual prerequisite becomes the App Registration, which truly needs elevated permissions that many service principals don't have.