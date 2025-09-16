# CoPA Stop & Search Deployment Guide for UK Police Forces

## 🏛️ Overview
This guide explains how any UK Police Force can deploy the CoPA Stop & Search application using the centralized Azure DevOps deployment system managed by British Transport Police (BTP).

## 🎯 What You Get
- **Your own dedicated application instance** at `https://app-{force}-uks-p-copa-stop-search.azurewebsites.net`
- **Complete data isolation** - your data never mixes with other forces
- **Your own Azure infrastructure** in your subscription
- **Full control** over your deployment approvals and access
- **Professional deployment pipeline** with validation and verification

## 📋 Prerequisites

### What Your Force Needs:
- ✅ **Azure subscription** (your own, separate from other forces)
- ✅ **Contributor access** to your Azure subscription
- ✅ **Technical contact person** for coordination
- ✅ **Designated approvers** for production deployments
- ✅ **Budget approval** for Azure costs (typically £200-500/month)

### Azure Resources That Will Be Created:
- Web Application (App Service)
- Azure OpenAI Service (GPT-4o + Embeddings)
- Azure AI Search Service
- Cosmos DB Database
- Application Insights
- Storage Account
- Log Analytics Workspace

## 🚀 Deployment Process

### Phase 1: Initial Setup (Your Force)

#### 1.1 Azure Subscription Setup
```
✅ Ensure you have your own Azure subscription
✅ Verify you have Contributor or Owner access
✅ Note your subscription ID for BTP team
```

#### 1.2 Designate Key Personnel
```
Technical Contact: [Name, Email, Role]
Deployment Approvers: [List of personnel who can approve production deployments]
Application Administrators: [Who will manage the deployed application]
```

#### 1.3 Contact BTP Deployment Team
Send email to BTP deployment team with:

```
Subject: CoPA Stop & Search Deployment Request - [Your Force Name]

Dear BTP CoPA Deployment Team,

We would like to deploy CoPA Stop & Search for [Your Force Name].

Our Details:
Force Name: [e.g., "Derbyshire Constabulary"]
Force Code: [e.g., "derbyshire"] 
Azure Subscription ID: [Your subscription ID]
Technical Contact: [Name, Email, Phone]
Deployment Approvers: 
  - [Name, Email, Role]
  - [Name, Email, Role]

We confirm:
- We have Contributor access to our Azure subscription
- We have budget approval for Azure resources
- We understand we will own and manage our deployed instance
- We are ready to coordinate the initial deployment

Please let us know the next steps.

Best regards,
[Your Name]
[Your Role]
[Your Force]
```

### Phase 2: BTP Configuration (BTP Team)

BTP will configure:
- ✅ Variable group: `copa-{force}-production`
- ✅ Service connection: `{Force}-Production`
- ✅ Environment: `{Force}-Production`
- ✅ Deployment pipeline: `{force}-deployment-pipeline.yml`

### Phase 3: Joint Deployment

#### 3.1 Initial Deployment
- BTP team runs the deployment pipeline
- Your designated approvers receive approval notification
- **You approve the deployment** when ready
- Pipeline deploys all Azure resources to your subscription

#### 3.2 Verification
- BTP and your team verify successful deployment
- Test application functionality together
- Confirm all resources are created correctly

#### 3.3 Handover
- Application URL provided: `https://app-{force}-uks-p-copa-stop-search.azurewebsites.net`
- Access credentials and configuration details shared
- Training provided on managing your instance

## 💰 Cost Estimates

### Typical Monthly Azure Costs:
| Resource | Estimated Cost |
|----------|----------------|
| App Service (B3) | £50-80 |
| Azure OpenAI | £100-300* |
| AI Search (Standard) | £200-250 |
| Cosmos DB | £30-60 |
| Application Insights | £20-40 |
| Storage Account | £5-15 |
| **Total Estimate** | **£405-745/month** |

*OpenAI costs depend on usage volume

### Cost Optimization Tips:
- Start with lower tiers and scale up as needed
- Monitor usage regularly through Azure portal
- Set up cost alerts and budgets
- Review and optimize monthly

## 🔐 Security & Compliance

### Data Protection:
- ✅ **Complete isolation** - your data stays in your subscription
- ✅ **UK data residency** - all resources hosted in UK South
- ✅ **Encrypted at rest and in transit**
- ✅ **Access controls** managed by your force
- ✅ **Audit logging** enabled throughout

### Compliance Features:
- GDPR compliant data handling
- Audit trails for all activities
- Role-based access control
- Secure authentication integration
- Data retention controls

## 🛠️ Ongoing Management

### Your Responsibilities:
- ✅ **User management** - who can access your application
- ✅ **Content management** - uploading your policy documents
- ✅ **Cost monitoring** - Azure subscription costs
- ✅ **Approval of updates** - when BTP releases new versions
- ✅ **Incident response** - for your application issues

### BTP Support:
- ✅ **Infrastructure updates** - pipeline and template improvements
- ✅ **Application updates** - new features and bug fixes
- ✅ **Technical support** - deployment and configuration help
- ✅ **Best practice guidance** - optimization recommendations

## 🔄 Future Deployments

Once set up, you can:
- **Request updates** through BTP team
- **Approve deployments** independently
- **Monitor your resources** through Azure portal
- **Manage your application** through the web interface

## 📞 Support & Contact

### For Deployment Requests:
- **Email**: [BTP CoPA Team Email]
- **Include**: Force name, subscription details, contact information

### For Technical Support:
- **Email**: [BTP Technical Support Email]  
- **Response Time**: 24-48 hours for non-urgent issues

### For Emergency Support:
- **Email**: [BTP Emergency Contact]
- **Phone**: [Emergency Contact Number]

## ❓ Frequently Asked Questions

### Q: How long does deployment take?
**A**: Initial setup takes 1-2 weeks for coordination, actual deployment is 2-3 hours.

### Q: Can we customize the application?
**A**: Limited customization available - contact BTP team for requirements.

### Q: What if we want to cancel our deployment?
**A**: You can delete your Azure resources at any time. Contact BTP team to remove pipeline configuration.

### Q: Who owns the deployed infrastructure?
**A**: You own all resources in your Azure subscription. BTP provides deployment automation only.

### Q: Can we deploy to multiple environments?
**A**: Yes, development/test environments can be configured separately.

### Q: What training is provided?
**A**: Basic application usage training provided post-deployment. Advanced training available on request.

## 🎯 Next Steps

1. **Review this guide** with your technical team
2. **Confirm budget approval** for Azure costs  
3. **Prepare your Azure subscription** 
4. **Contact BTP deployment team** using the template above
5. **Coordinate deployment** with BTP team
6. **Go live** with your CoPA Stop & Search instance!

## 📋 Deployment Checklist

### Before Contacting BTP:
- [ ] Azure subscription ready with Contributor access
- [ ] Budget approved for ongoing costs
- [ ] Technical contact designated
- [ ] Deployment approvers identified
- [ ] Force code confirmed (short name for your force)

### After BTP Contact:
- [ ] Service connection configured
- [ ] Environment created with your approvers
- [ ] Pipeline tested and validated
- [ ] Initial deployment approved and completed
- [ ] Application tested and verified
- [ ] Handover documentation received
- [ ] Team trained on application usage

---

**Ready to deploy CoPA Stop & Search for your force? Contact the BTP deployment team today!** 🚀

*This deployment model ensures every UK Police Force gets their own secure, compliant, and fully managed CoPA Stop & Search instance while maintaining cost-effective centralized deployment automation.*