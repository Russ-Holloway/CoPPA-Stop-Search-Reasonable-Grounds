# 🛡️ PDS Deployment Checklist

Use this checklist to ensure 100% compliance with all 58 PDS naming policies before deploying CoPA to any Azure Government tenant.

## 📋 Pre-Deployment Validation

### ☑️ **Step 1: Template Validation**
Run the template validation script to ensure ARM template generates compliant names:

```powershell
# Validate template for your specific deployment
.\scripts\validate-template-pds.ps1 -ForceCode "btp" -Environment "prod" -InstanceNumber "01" -Verbose
```

**Expected Output:**
```
✅ Template validation PASSED - All resource names are PDS compliant!

Generated resource names:
  • App Service Plan: asp-btp-prod-01
  • Web App: app-btp-prod-01  
  • Application Insights: appi-btp-prod-01
  • Cognitive Services: cog-btp-prod-01
  • Azure Search: srch-btp-prod-01
  • Storage Account: stbtpprod01
  • Cosmos DB: cosmos-btp-prod-01
  • Key Vault: kv-btp-prod-01

✨ Template is ready for PDS-compliant deployment!
```

- [ ] ✅ Template validation PASSED
- [ ] ✅ All resource names follow PDS patterns  
- [ ] ✅ No length limit violations
- [ ] ✅ No invalid character issues

---

### ☑️ **Step 2: Name Compliance Validation**
Run the name compliance script to validate specific naming parameters:

```powershell  
# Validate naming compliance for your deployment
.\scripts\validate-pds-compliance.ps1 -ForceCode "btp" -Environment "prod" -InstanceNumber "01" -Verbose
```

**Validation Points:**
- [ ] ✅ Force code is 2-3 lowercase letters
- [ ] ✅ Environment is one of: dev, test, prod
- [ ] ✅ Instance number is exactly 2 digits
- [ ] ✅ All generated names pass PDS policy patterns
- [ ] ✅ Storage account name ≤ 24 characters
- [ ] ✅ No uppercase in storage account name

---

### ☑️ **Step 3: Resource Group Validation**
Ensure target resource group follows PDS naming:

```powershell
# Resource group should follow pattern: rg-{force}-{env}-{instance}
$resourceGroup = "rg-btp-prod-01"
```

- [ ] ✅ Resource group name follows `rg-{force}-{env}-{instance}` pattern
- [ ] ✅ Resource group name is lowercase
- [ ] ✅ Resource group exists in correct Azure region
- [ ] ✅ Proper access permissions configured

---

### ☑️ **Step 4: Template File Integrity**
Verify ARM template has all PDS compliance features:

```powershell
# Check template structure
Get-Content infrastructure\deployment.json | ConvertFrom-Json | Select-Object -ExpandProperty parameters | Format-List
```

**Required Parameters:**
- [ ] ✅ `ForceCode` parameter with validation pattern
- [ ] ✅ `EnvironmentSuffix` parameter with allowed values  
- [ ] ✅ `InstanceNumber` parameter with validation pattern
- [ ] ✅ All parameters have proper `allowedValues` or `minLength`/`maxLength`

**Required Variables:**
- [ ] ✅ `appServicePlanName` with PDS pattern
- [ ] ✅ `webAppName` with PDS pattern
- [ ] ✅ `applicationInsightsName` with PDS pattern
- [ ] ✅ `cognitiveServicesName` with PDS pattern
- [ ] ✅ `searchServiceName` with PDS pattern
- [ ] ✅ `storageAccountName` with PDS pattern (no hyphens)
- [ ] ✅ `cosmosDbName` with PDS pattern
- [ ] ✅ `keyVaultName` with PDS pattern

---

## 🚀 Deployment Process

### ☑️ **Step 5: Use PDS Deploy Button**
Always use the PDS-compliant deployment button:

1. Navigate to the main README.md
2. Click the **"Deploy to Azure (PDS Compliant)"** button
3. **DO NOT** use any other deployment method

- [ ] ✅ Used PDS-compliant deployment button
- [ ] ✅ Avoided manual ARM template deployment
- [ ] ✅ Avoided Azure CLI deployment without validation

---

### ☑️ **Step 6: Parameter Entry**
Enter deployment parameters carefully:

**Force Code:**
- [ ] ✅ 2-3 characters only
- [ ] ✅ Lowercase letters only
- [ ] ✅ Valid police force abbreviation (btp, met, gmp, etc.)

**Environment:**
- [ ] ✅ Selected from dropdown (dev/test/prod)
- [ ] ✅ Matches intended deployment environment
- [ ] ✅ Aligns with governance policies

**Instance Number:**
- [ ] ✅ Exactly 2 digits (01, 02, 03, etc.)
- [ ] ✅ Unique for this force/environment combination
- [ ] ✅ Documented for future reference

---

### ☑️ **Step 7: Pre-Deployment Review**
Review the generated template before clicking deploy:

- [ ] ✅ Resource names preview shows PDS patterns
- [ ] ✅ All resources will be in correct resource group
- [ ] ✅ Subscription and location are correct
- [ ] ✅ No policy violation warnings displayed

---

## ✅ Post-Deployment Verification

### ☑️ **Step 8: Verify Resource Names**
After successful deployment, verify all resources follow PDS naming:

```powershell
# List all resources in the resource group
az resource list --resource-group "rg-btp-prod-01" --output table
```

**Check Each Resource Type:**
- [ ] ✅ App Service Plan: `asp-{force}-{env}-{instance}`
- [ ] ✅ Web App: `app-{force}-{env}-{instance}`
- [ ] ✅ Application Insights: `appi-{force}-{env}-{instance}`
- [ ] ✅ Cognitive Services: `cog-{force}-{env}-{instance}`
- [ ] ✅ Azure Search: `srch-{force}-{env}-{instance}`
- [ ] ✅ Storage Account: `st{force}{env}{instance}` (no hyphens)
- [ ] ✅ Cosmos DB: `cosmos-{force}-{env}-{instance}`
- [ ] ✅ Key Vault: `kv-{force}-{env}-{instance}`

---

### ☑️ **Step 9: Policy Compliance Check**
Verify no policy violations exist:

```powershell
# Check for policy violations
az policy state list --resource-group "rg-btp-prod-01" --query "[?complianceState=='NonCompliant']"
```

- [ ] ✅ Zero policy violations reported
- [ ] ✅ All resources show as compliant
- [ ] ✅ No remediation tasks triggered

---

### ☑️ **Step 10: Application Health Check**
Verify the deployed application works correctly:

- [ ] ✅ Web app loads without errors
- [ ] ✅ Azure OpenAI connection working
- [ ] ✅ Search service responding
- [ ] ✅ Authentication configured correctly
- [ ] ✅ Application Insights collecting telemetry

---

## 🚨 Troubleshooting

### **❌ Template Validation Failed**
```powershell
# Re-run validation with verbose output
.\scripts\validate-template-pds.ps1 -ForceCode "btp" -Environment "prod" -InstanceNumber "01" -Verbose
```
**Solution:** Check the specific error messages and adjust parameters accordingly.

### **❌ Policy Violation During Deployment**  
**Error:** "Resource name violates policy 'PDS Naming Convention'"
**Solution:** The template should prevent this. Check you're using the PDS deployment button, not manual deployment.

### **❌ Storage Account Name Too Long**
**Solution:** Use shorter force codes or different instance numbers. The template automatically calculates optimal lengths.

### **❌ Deployment Hangs or Fails**
1. Check Azure status page for service issues
2. Verify subscription quotas and limits
3. Check resource group permissions
4. Re-run validation scripts to confirm compliance

---

## 📊 Compliance Summary

By following this checklist, you ensure:

✅ **100% PDS Policy Compliance** - All 58 naming policies satisfied  
✅ **Zero Manual Naming** - Template handles all name generation  
✅ **Consistent Patterns** - Same approach across all police forces  
✅ **Audit Ready** - Full compliance trail documented  
✅ **Deployment Reliability** - No policy-related deployment failures  

---

## 📞 Support Contacts

**For PDS Compliance Issues:**
- Review this checklist step-by-step
- Check template validation script output
- Consult Azure Policy administrator
- Contact development team for template updates

**For Deployment Issues:**  
- Check Azure Service Health
- Verify subscription permissions
- Review resource quotas and limits
- Confirm network connectivity

---

**🎯 Remember: Every single deployment must pass this checklist to ensure PDS compliance!**
