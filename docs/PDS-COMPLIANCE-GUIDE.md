# PDS Naming Compliance and Deployment Validation Guide

This guide explains how CoPA ensures 100% compliance with the 58 PDS (Police Digital Service) naming policies enforced in Azure Government tenants.

## 🎯 Overview

The **58 PDS policies** enforce strict naming conventions for all Azure resources. Non-compliance results in:
- ❌ **Deployment failures**
- ❌ **Policy violations**
- ❌ **Audit failures**
- ❌ **Remediation requirements**

## 🛡️ Our Multi-Layer Compliance Strategy

### **Layer 1: ARM Template Enforcement**
- **Built-in PDS naming**: Every resource name automatically follows PDS patterns
- **Parameter validation**: Input constraints ensure valid force codes and environments
- **No manual naming**: Eliminates human error in resource naming

### **Layer 2: UI Definition Validation**
- **Dropdown restrictions**: Environment selection limited to approved values
- **Input validation**: Real-time validation of force codes and instance numbers
- **Pattern enforcement**: UI prevents invalid character entry

### **Layer 3: Pre-Deployment Validation**
- **Automated scripts**: Validate compliance before deployment starts
- **Policy simulation**: Check names against all 58 policies
- **Early error detection**: Catch issues before Azure resource creation

## 📋 PDS Naming Patterns Used

| Resource Type | PDS Pattern | Example |
|---|---|---|
| **App Service Plan** | `asp-{force}-{env}-{instance}` | `asp-btp-prod-01` |
| **Web App** | `app-{force}-{env}-{instance}` | `app-btp-prod-01` |
| **Application Insights** | `appi-{force}-{env}-{instance}` | `appi-btp-prod-01` |
| **Cognitive Services** | `cog-{force}-{env}-{instance}` | `cog-btp-prod-01` |
| **Azure Search** | `srch-{force}-{env}-{instance}` | `srch-btp-prod-01` |
| **Storage Account** | `st{force}{env}{instance}` | `stbtpprod01` |
| **Cosmos DB** | `cosmos-{force}-{env}-{instance}` | `cosmos-btp-prod-01` |
| **Key Vault** | `kv-{force}-{env}-{instance}` | `kv-btp-prod-01` |

## 🔧 Pre-Deployment Validation

### **1. Quick Validation**
```powershell
.\scripts\validate-pds-compliance.ps1 -ForceCode "btp" -Environment "prod" -InstanceNumber "01"
```

### **2. Detailed Validation**
```powershell
.\scripts\validate-pds-compliance.ps1 -ForceCode "btp" -Environment "prod" -InstanceNumber "01" -Verbose
```

### **3. Batch Validation (Multiple Forces)**
```powershell
# Validate for multiple police forces
$forces = @("btp", "met", "gmp", "wmp")
foreach ($force in $forces) {
    .\scripts\validate-pds-compliance.ps1 -ForceCode $force -Environment "prod" -InstanceNumber "01"
}
```

## 🚀 Deployment Process

### **Step 1: Validate Compliance**
```powershell
# Always run validation first
.\scripts\validate-pds-compliance.ps1 -ForceCode "btp" -Environment "prod" -InstanceNumber "01"
```

### **Step 2: Deploy via Button**
1. Click the **Deploy to Azure** button
2. Enter your force code (e.g., "btp")
3. Select environment (dev/test/prod)
4. Enter instance number (01, 02, etc.)
5. Deploy - all names are automatically compliant!

### **Step 3: Verify Deployment**
```powershell
# Check deployed resources follow PDS patterns
.\scripts\verify-deployed-resources.ps1 -ResourceGroup "rg-btp-prod-01"
```

## ⚡ Benefits of This Approach

### **✅ Guaranteed Compliance**
- **100% policy compliance**: Every deployment passes all 58 PDS policies
- **Zero manual naming**: Eliminates human error
- **Automatic patterns**: No need to remember complex naming rules

### **✅ Deployment Reliability**  
- **No failed deployments**: Names are validated before deployment
- **Consistent naming**: Same patterns across all police forces
- **Audit ready**: All resources follow approved conventions

### **✅ Operational Excellence**
- **Easy identification**: Resource names clearly indicate force, environment, and instance
- **Scalable**: Supports all 44 UK police forces
- **Maintainable**: Single template manages all naming logic

## 🔍 Common PDS Policy Violations (Avoided)

| Issue | PDS Requirement | Our Solution |
|---|---|---|
| **Mixed case** | Lowercase only for storage | Template enforces lowercase |
| **Invalid characters** | Alphanumeric + hyphens only | Input validation prevents invalid chars |
| **Length limits** | Max 24 chars for storage | Template calculates and validates length |
| **Missing prefixes** | Resource type prefixes required | Built into template patterns |
| **Environment naming** | Standard env names (dev/test/prod) | Dropdown restricts to valid options |

## 📊 Validation Checklist

Before every deployment, ensure:

- [ ] ✅ Force code is 2-3 lowercase letters
- [ ] ✅ Environment is one of: dev, test, prod  
- [ ] ✅ Instance number is exactly 2 digits
- [ ] ✅ Validation script passes with no errors
- [ ] ✅ Resource group follows pattern: `rg-{force}-{env}-{instance}`

## 🚨 Troubleshooting

### **Policy Violation Error**
```
Error: Resource name 'policing-assistant' violates policy 'PDS Naming Convention'
```
**Solution**: Use the PDS compliant deployment button - it generates compliant names automatically.

### **Storage Account Name Too Long**
```  
Error: Storage account name exceeds 24 characters
```
**Solution**: Use shorter force codes or different instance numbers. The template automatically handles this.

### **Invalid Characters**
```
Error: Resource name contains invalid characters
```
**Solution**: The UI definition prevents invalid character entry, but double-check your force code contains only lowercase letters.

## 💡 Best Practices

1. **Always validate first**: Run the validation script before deployment
2. **Use standard patterns**: Don't modify the ARM template naming logic
3. **Document instances**: Keep track of instance numbers for each environment
4. **Test in dev first**: Deploy to dev environment before prod
5. **Monitor policies**: Watch for new PDS policy updates

## 📞 Support

For PDS compliance issues:
- Check the validation script output for specific guidance
- Review the ARM template for naming logic
- Consult with your Azure Policy administrator
- Contact the development team for template updates

---

**Remember**: With our PDS-compliant template, you get automatic compliance with all 58 naming policies - no manual work required! 🎉
