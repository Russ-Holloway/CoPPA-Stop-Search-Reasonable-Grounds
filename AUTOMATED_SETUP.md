# 🎯 CoPA DevOps - 2-Step Setup (Automated)

**You asked: "If I create the project can you do everything else?"**

**Answer: Yes! Here's how we can automate 90% of the setup:**

---

## ⚡ **AUTOMATED SETUP - Just 2 Steps!**

### **🎯 What YOU Need to Do (5 minutes):**

#### **Step 1: Create Project & Import Repository**
1. **Go to:** https://dev.azure.com/uk-police-copa/
2. **Click:** `+ New project`
3. **Name:** `CoPA-Stop-Search`
4. **Settings:** Private, Git, Agile → **Create**
5. **Click:** `Repos` → `Import repository` → `Import from GitHub`
6. **URL:** `https://github.com/Russ-Holloway/CoPA-Stop-Search-Reasonable-Grounds.git`
7. **Authenticate** with GitHub → **Import**

#### **Step 2: Run Automation Script**
```bash
# In your terminal/command prompt:
cd /workspaces/CoPA-Stop-Search-Reasonable-Grounds
./scripts/automate-devops-setup.sh
```

**That's it!** ⚡

---

### **🤖 What the AUTOMATION Does (55 minutes of work):**

The script will automatically create:
- ✅ **Service Connections** (dev & prod)
- ✅ **Variable Groups** (with all required variables)
- ✅ **Environments** (development & production)
- ✅ **Pipeline** (imported and configured)
- ✅ **Azure Resource Groups** (ready for deployment)

---

### **📋 Script Requirements:**

**Prerequisites (the script checks these):**
- Azure CLI installed
- Logged into Azure (`az login`)
- Access to Azure DevOps organization

**What the script will ask you:**
- Your Azure Subscription ID
- Your police force code (e.g., "met", "gmp", "west-midlands")

**Time:** ~5-10 minutes to run

---

### **⚙️ Manual Steps Still Required (minimal):**

After automation completes, you'll need to:

1. **Configure production approvals** (2 minutes):
   - Go to Environments → copa-production → Add approval checks

2. **Grant pipeline permissions** (2 minutes):
   - Pipeline → Security → Grant access to service connections & environments

3. **Test deployment** (5 minutes):
   - Run pipeline to validate everything works

---

### **🚀 Alternative Methods:**

**For Bash/Linux:**
```bash
./scripts/automate-devops-setup.sh
```

**For PowerShell/Windows:**
```powershell
.\scripts\automate-devops-setup.ps1 -ForceCode "your-force-code"
```

---

## **🎉 Summary:**

**You do:** 5 minutes (create project, import repo)  
**Automation does:** 55 minutes (everything else)  
**Manual finish:** 5 minutes (approvals, test)  

**Total effort for you:** ~10 minutes instead of 60+ minutes!

---

## **🚨 Troubleshooting:**

If the automation script has issues:
- **Check Azure login:** `az login`
- **Install Azure DevOps extension:** `az extension add --name azure-devops`
- **Verify project name:** Must be exactly "CoPA-Stop-Search"
- **Check repository name:** Must be exactly "CoPA-Stop-Search-Reasonable-Grounds"

---

## **Ready to Start?**

1. **Create the project** (5 minutes)
2. **Run the automation script** 
3. **Your DevOps is ready!** 🎉

The automation will handle all the tedious configuration work, and you'll have a fully functional, secure DevOps deployment pipeline ready to go!

**Start here:** https://dev.azure.com/uk-police-copa/