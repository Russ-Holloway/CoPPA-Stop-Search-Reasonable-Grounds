# Manual Azure Portal Setup Guide

## Setting up stcopadeployment02 for CoPA Deployment

Since Azure CLI authentication is restricted by CA policies, follow these manual steps in the Azure Portal.

### Step 1: Upload Files to Storage Account

1. **Navigate to Azure Portal** → Storage Accounts → `stcopadeployment02`
2. **Go to Containers** → Create container named `copa-deployment` with **Public access level: Blob**
3. **Upload the following files** to the `copa-deployment` container:
   - `infrastructure/deployment.json` → upload as `deployment.json`
   - `infrastructure/createUiDefinition-simple.json` → upload as `createUiDefinition-simple.json`
   - `infrastructure/createUiDefinition-pds.json` → upload as `createUiDefinition-pds.json`
   - `infrastructure/createUiDefinition.json` → upload as `createUiDefinition.json`

### Step 2: Configure CORS Settings

1. **In the storage account**, go to **Settings** → **Resource Sharing (CORS)**
2. **For Blob service**, add a new rule:
   - **Allowed origins:** `https://portal.azure.com,https://ms.portal.azure.com,*`
   - **Allowed methods:** `GET,POST,PUT`
   - **Allowed headers:** `*`
   - **Exposed headers:** `*`
   - **Max age:** `3600`
3. **Save** the CORS settings

### Step 3: Generate SAS Token

1. **In the storage account**, go to **Security + networking** → **Shared access signature**
2. **Configure the SAS:**
   - **Allowed services:** ✅ Blob
   - **Allowed resource types:** ✅ Service, ✅ Container, ✅ Object
   - **Allowed permissions:** ✅ Read, ✅ List, ✅ Write, ✅ Create
   - **Start date/time:** Today's date
   - **Expiry date/time:** 1 year from today
   - **Allowed protocols:** HTTPS only
3. **Click "Generate SAS and connection string"**
4. **Copy the SAS token** (the part after the `?` in the Blob service SAS URL)

### Step 4: Construct New Deploy to Azure URLs

Use this format to build your new URLs:

#### Base URLs:
- **Storage Base:** `https://stcopadeployment02.blob.core.windows.net/copa-deployment`
- **Deployment JSON:** `{StorageBase}/deployment.json?{SAS_TOKEN}`
- **Simple UI:** `{StorageBase}/createUiDefinition-simple.json?{SAS_TOKEN}`
- **PDS UI:** `{StorageBase}/createUiDefinition-pds.json?{SAS_TOKEN}`

#### Deploy to Azure Button Format:
```
https://portal.azure.com/#create/Microsoft.Template/uri/{URL_ENCODED_DEPLOYMENT_JSON}/createUIDefinitionUri/{URL_ENCODED_CREATE_UI_JSON}
```

### Step 5: URL Encoding

Use an online URL encoder (like https://www.urlencoder.org/) to encode your full URLs including the SAS token.

### Step 6: Update Repository Files

Replace the Deploy to Azure button URLs in:
- `README.md`
- `docs/PDS-DEPLOYMENT-GUIDE.md`
- Any other documentation files

### Example Final URL Structure:

```markdown
[![Deploy PDS Compliant](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fstcopadeployment02.blob.core.windows.net%2Fcopa-deployment%2Fdeployment.json%3F{YOUR_ENCODED_SAS_TOKEN}/createUIDefinitionUri/https%3A%2F%2Fstcopadeployment02.blob.core.windows.net%2Fcopa-deployment%2FcreateUiDefinition-simple.json%3F{YOUR_ENCODED_SAS_TOKEN})
```

### Step 7: Test the Deployment

1. **Click the Deploy to Azure button** in your updated README.md
2. **Verify** that the Azure Portal opens with your custom UI
3. **Test a deployment** to ensure resource names end with `-02`

---

## 🚨 Important Notes:

- **Resource Names:** Your deployment template is already configured to use `-02` suffix
- **SAS Token Security:** Store the SAS token securely as it provides access to your storage account
- **Expiry:** Remember to renew the SAS token before it expires (1 year from creation)
- **Testing:** Always test the Deploy to Azure button after updating URLs
