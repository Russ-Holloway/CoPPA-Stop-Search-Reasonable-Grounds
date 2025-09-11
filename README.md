# CoPA Stop & Search Assistant

![Version](https://img.shields.io/badge/Version-2.0.0-blue)
![Security Status](https://img.shields.io/badge/Security-Production%20Ready-brightgreen)
![Compliance](https://img.shields.io/badge/PDS%20Compliance-Ready-blue)
![Accessibility](https://img.shields.io/badge/WCAG%202.1%20AA-Compliant-green)

**CoPA Stop & Search Assistant v2.0.0** is an AI-powered decision support tool designed to enhance police effectiveness through intelligent guidance. Built on Microsoft Azure, it integrates trusted data sources and policies to deliver secure, accessible, and transparent assistance for law enforcement professionals.

## � Key Highlights

- 🔒 **Enterprise Security** - Production-ready with zero critical vulnerabilities
- 🎯 **PDS Compliance** - Meets Police Digital Service standards  
- ♿ **WCAG 2.1 AA Accessible** - Inclusive design for all users
- � **Transparent AI** - Every response includes source citations
- 🛡️ **Secure by Design** - Built with Azure enterprise security framework

---

## Table of Contents

- [Quick Start](#quick-start)
- [Deployment](#deployment)
- [Features](#features)
- [How It Works](#how-it-works)
- [Authentication](#authentication)
- [Configuration](#configuration)
- [Accessibility](#accessibility)
- [Security](#security)
- [Contributing](#contributing)
- [Support](#support)

---

## Deployment

### PDS Compliant Deployment (For UK Police Forces)

**🚔 For all 44 UK Police Forces:** Use our simplified PDS-compliant deployment. Just create a resource group following PDS naming (e.g., `rg-btp-prod-01`) and deploy - all resource names are generated automatically!

**✅ Compliance Features:**
- **PDS Naming Standards:** Automatic compliance with Police Digital Service naming conventions
- **WCAG 2.1 AA Accessibility:** Full accessibility compliance for inclusive access
- **Security Standards:** Enterprise-grade security with Azure best practices

[![Deploy PDS Compliant](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fstcopadeployment02.blob.core.windows.net%2Fcopa-deployment%2Fdeployment.json/createUIDefinitionUri/https%3A%2F%2Fstcopadeployment02.blob.core.windows.net%2Fcopa-deployment%2FcreateUiDefinition.json)

**🎯 Simplified Deployment Process:**
1. **Create Resource Group:** Use PDS naming like `rg-btp-prod-01`, `rg-met-prod-01`, etc.
2. **Click Deploy:** All Azure resources are automatically created with PDS-compliant names
3. **Choose OpenAI Models:** Select your preferred chat and embedding models
4. **Deploy:** Infrastructure deployment completes automatically!
5. **Deploy Code:** Upload your application code to the created App Service (manual step)

📋 **[PDS Deployment Guide](docs/PDS-DEPLOYMENT-GUIDE.md)** - Complete guide for police forces  
📋 **[Azure Naming Guidelines](docs/azure-naming-guidelines.md)** - PDS naming conventions

### Post-Deployment Setup

After infrastructure deployment completes, you need to deploy your application code and configure authentication.

#### Code Deployment (Required)
The ARM template creates the Azure infrastructure but doesn't automatically deploy application code. You have several options:

**Option 1: GitHub Actions (Recommended)**
```yaml
# Set up GitHub Actions workflow for automated deployment
- uses: azure/webapps-deploy@v2
  with:
    app-name: 'your-app-name'
    package: '.'
```

**Option 2: Azure CLI**
```bash
# Deploy using Azure CLI
az webapp deployment source config-zip \
  --resource-group your-resource-group \
  --name your-app-name \
  --src app.zip
```

**Option 3: Visual Studio Code**
- Install Azure App Service extension
- Right-click on your app folder and select "Deploy to Web App"

**📖 Full Guide:** [Code Deployment Guide](docs/code-deployment-guide.md)

#### Authentication Setup (Required)
**🚀 New: Post-Deployment Configuration**  
Authentication is now configured *after* deployment, so you no longer need client secrets during the initial deployment!

**Automated Setup (Recommended):**
```bash
# Linux/macOS
./configure-auth.sh

# Windows PowerShell  
.\configure-auth.ps1
```

**Legacy Manual Setup:**
```powershell
.\scripts\setup_azure_ad_auth.ps1 -WebAppName "your-web-app-name" -ResourceGroupName "your-resource-group"
```

**📋 Quick Reference:** [Azure AD Quick Reference](AZURE_AD_QUICK_REFERENCE.md)  
**📖 Post-Deployment Guide:** [Post-Deployment Authentication Setup](POST_DEPLOYMENT_AUTH_SETUP.md)  
**📖 Full Guide:** [Azure AD Setup Guide](AZURE_AD_SETUP_GUIDE.md)

#### Search Components Setup (Required)
After infrastructure deployment, you'll need to manually configure the Azure Cognitive Search components:

```powershell
.\scripts\setup-search-components.ps1 -ResourceGroupName "your-resource-group-name" -SearchServiceName "your-search-service-name" -StorageAccountName "your-storage-account-name" -OpenAIServiceName "your-openai-service-name"
```

This will create:
- Search index with vector search capabilities
- Data source connected to blob storage
- Skillsets for document processing and embedding generation
- Indexers to process documents

**📖 Full Guide:** [Search Components Setup Guide](docs/search_components_setup.md)

---

## Vision & Purpose

- **Improving Police Decision-Making:**  
  Supports officers with advice grounded in national/local policy, leveraging AI to process information from trusted sources such as the College of Policing, CPS Guidance, and local force policies.

- **Human in the Loop:**  
  Augments (but does not replace) human decision-making, supporting College of Policing’s four key areas: Criminal Justice, Investigations, Prevention, and Neighbourhood Policing.

---

## Features

**Core Capabilities:**
- **Comprehensive Guidance** - Covers Criminal Justice, Investigations, Prevention, and Neighbourhood Policing
- **Source Transparency** - Every response includes citations from trusted sources
- **Continuous Updates** - Daily data indexing and user feedback integration
- **Speech Integration** - Voice-to-text for mobile efficiency
- **Multi-Source Integration** - College of Policing APP, CPS Guidance, Gov.uk, and local policies

**Technical Excellence:**
- **Enterprise Security** - Secure Azure environment with PDS compliance
- **WCAG 2.1 AA Accessibility** - Inclusive design for all users
- **Real-time Processing** - Fast, responsive AI-powered assistance
- **Seamless Integration** - Works with existing police systems and workflows

## How It Works

1. **Data Integration** - Curated sources (College of Policing APP, CPS Guidance, Gov.uk) indexed daily with local force policies managed in Azure Storage

2. **AI Processing** - Secure OpenAI models running on Police Service Azure Tenant deliver context-aware responses

3. **User Interface** - Accessible chatbot interface with speech-to-text capabilities for mobile use

4. **Transparency** - All responses include source references and citations for trust and accountability

> **Human-in-the-Loop Design:** CoPA augments but never replaces human decision-making, supporting officers across all key policing areas.

---

## Accessibility

**🌟 WCAG 2.1 AA Compliant** - Designed for inclusive access by all users.

### Features
- **✅ Screen Reader Support** - Compatible with NVDA, JAWS, VoiceOver, TalkBack
- **✅ Keyboard Navigation** - Complete keyboard accessibility
- **✅ High Contrast** - 4.5:1 color contrast ratios
- **✅ Focus Management** - Clear visual indicators and proper focus trapping
- **✅ Error Handling** - Accessible validation with screen reader announcements
- **✅ Responsive Design** - Works across all devices and screen sizes

### Standards Compliance
- Web Content Accessibility Guidelines (WCAG) 2.1 Level AA
- UK Public Sector Bodies Accessibility Regulations 2018
- Equality Act 2010 compliance
- US Section 508 standards

📋 **[Accessibility Implementation Report](docs/accessibility/ACCESSIBILITY_IMPLEMENTATION_COMPLETE.md)**

## Security

### Production-Ready Security
- **Zero Critical Vulnerabilities** - Comprehensive security scanning
- **Enterprise Security Headers** - Protection against common attacks
- **Azure Security Framework** - Built-in Azure security best practices
- **PDS Compliance** - Meets Police Digital Service standards
- **Continuous Monitoring** - Automated security validation

### Validation & Testing
```bash
# Security validation
./tools/security-scan.sh

# ARM template validation  
./tools/validate-templates.sh

# Deployment readiness check
./scripts/check_deployment_readiness.ps1
```

📋 **[Security Assessment](docs/security/SECURITY_STATUS.md)**

---

## Screenshots

> _Include screenshots or GIFs here to demonstrate the interface and functionality._

---

## Quick Start

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/Russ-Holloway/CoPA.git
   cd CoPA
   ```

2. **Install Dependencies:**
   ```bash
   # Backend (Python)
   pip install -r requirements.txt

   # Frontend (TypeScript)
   cd frontend
   npm install
   npm run build
   ```

3. **Start the App:**
   - Use `start.cmd` or `start.sh` to build and launch both frontend and backend, or follow [Configure the App](#configure-the-app) for environment setup.

4. **Access the App:**
   - Open [http://127.0.0.1:50505](http://127.0.0.1:50505) in your browser.

---

## Configure the App

### Create a `.env` file

Follow instructions in the [App Settings](#app-settings) section to create a `.env` file for local development.

### Create a JSON file for Azure App Service

After creating your `.env` file, use provided PowerShell or Bash commands to generate a JSON file (`env.json`) for Azure App Service deployment.

---

## Authentication

### Post-Deployment Setup (Recommended)

Authentication is configured after deployment to eliminate client secret requirements during initial setup.

```bash
# Automated setup
./configure-auth.sh      # Linux/macOS
.\configure-auth.ps1     # Windows
```

### Manual Configuration

```powershell
# Legacy setup method
.\scripts\setup_azure_ad_auth.ps1 -WebAppName "your-web-app-name" -ResourceGroupName "your-resource-group"
```

**Access Control:** Update logic in `frontend/src/pages/chat/Chat.tsx` for additional restrictions.
**Disable Authentication:** Set `AUTH_ENABLED=False` (not recommended for production).

📋 **Guides:**
- [Post-Deployment Authentication Setup](docs/authentication/POST_DEPLOYMENT_AUTH_SETUP.md)
- [Azure AD Setup Guide](docs/authentication/AZURE_AD_SETUP_GUIDE.md)

## Configuration

### Environment Variables

Create a `.env` file for local development or configure Azure App Service settings:

```bash
# Essential Configuration
AZURE_OPENAI_ENDPOINT=your-openai-endpoint
AZURE_OPENAI_API_KEY=your-api-key
AZURE_SEARCH_SERVICE=your-search-service
AZURE_SEARCH_KEY=your-search-key

# Optional Customization
UI_POLICE_FORCE_LOGO=https://your-storage.blob.core.windows.net/images/logo.png
UI_POLICE_FORCE_TAGLINE=Your Custom Tagline
UI_FIND_OUT_MORE_LINK=https://your-website.com/about
```

### Police Force Customization

Environment-based customization for police force branding:
- **Custom Logo** - Police force logo in header (admin-only)
- **Custom Tagline** - Force-specific messaging (admin-only)  
- **Find Out More Link** - Optional information button

📋 **[Police Force Customization Guide](docs/police-force-customization.md)**

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

- Contributors must agree to the [Contributor License Agreement (CLA)](https://cla.opensource.microsoft.com)
- Follow the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)

## Support

- **Issues & Questions:** Open an issue on GitHub
- **Email:** [opencode@microsoft.com](mailto:opencode@microsoft.com)
- **Documentation:** See [docs/](docs/) folder for detailed guides

### Additional Resources
- [Changelog](CHANGELOG.md) - Release history and updates
- [Security Reports](docs/security/) - Security documentation
- [Deployment Guides](docs/deployment/) - Step-by-step deployment instructions

---

## Important Notices

### Disclaimer
CoPA is an advisory tool based on curated data sources. Ultimate responsibility for decisions remains with the user. **Do not use as sole source for critical or time-sensitive decisions.**

### Trademarks
This project may contain trademarks or logos for projects, products, or services. Use of Microsoft or third-party trademarks is subject to their respective policies.

### License
This project is licensed under the terms specified in the [LICENSE](LICENSE) file.
