# Azure DevOps Pipelines Structure

## 📋 **Primary Pipeline for DevOps Deployment**

### **Main Pipeline:** `../azure-pipelines.yml` 
- **Purpose:** Complete CI/CD pipeline for CoPA Stop & Search application
- **Triggers:** Branches `main` and `Dev-Ops-Deployment`
- **Features:**
  - Infrastructure deployment using Bicep templates
  - Application build and deployment
  - Security scanning
  - Multi-environment support
- **Use this for:** Standard DevOps deployments

## 🔧 **Supporting Files**

### **Azure Developer CLI:** `../azure.yaml`
- **Purpose:** Configuration for Azure Developer CLI (azd) deployments
- **Use case:** Alternative deployment method using `azd up`
- **Note:** Different from Azure DevOps - this is for local/azd deployments

## 📁 **Specialized Pipelines** (`specialized/` folder)

These pipelines are for specific scenarios and should not be used for standard deployments:

### `azure-pipelines-infra.yml`
- **Purpose:** Infrastructure-only testing pipeline
- **Use case:** Testing Bicep template changes without app deployment
- **Trigger:** Only `infra-test` and `feature/infrastructure/*` branches

### `btp-deployment-pipeline.yml`
- **Purpose:** British Transport Police specific production deployment
- **Use case:** Manual production deployments for BTP only
- **Trigger:** Manual only

### `derbyshire-deployment-pipeline.yml` 
- **Purpose:** Derbyshire Police specific deployment
- **Use case:** Custom deployment for Derbyshire Police force
- **Trigger:** Manual only

## 🎯 **For DevOps Deployment - Use This:**

**Primary Pipeline:** `azure-pipelines.yml` (root directory)

This is your main pipeline that handles:
- ✅ Complete infrastructure provisioning
- ✅ Application build and deployment  
- ✅ Security scanning and compliance
- ✅ Multi-environment support
- ✅ Automated CI/CD workflows

## 🚀 **Setup Instructions**

1. **Azure DevOps:** Import `azure-pipelines.yml` as your main pipeline
2. **Configure:** Set up your service connection and variable groups
3. **Deploy:** Pipeline will trigger on pushes to `main` or `Dev-Ops-Deployment` branches

---
*For questions about pipeline setup, refer to the DevOps setup documentation.*