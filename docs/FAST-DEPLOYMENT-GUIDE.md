# ⚡ Fast Development & Deployment Guide

This guide explains how to dramatically reduce build times during development and testing cycles.

## 🚀 Quick Start

Use the helper script for fastest deployments:
```bash
./scripts/quick-deploy.sh
```

## 📝 Manual Commit Message Flags

You can also manually add these flags to your commit messages to control pipeline behavior:

### `[infra-only]` - Infrastructure Only (⚡ Fastest: ~5-10 minutes)
```bash
git commit -m "[infra-only] Fix resource group tags"
```
**Skips:** Code validation, builds, application deployment  
**Runs:** Quick Bicep validation + Infrastructure deployment only  
**Use when:** Fixing Bicep templates, Azure resources, networking, tags, policies

### `[skip-validation]` - Skip Code Validation (~15-20 minutes)
```bash
git commit -m "[skip-validation] Update app settings"
```
**Skips:** Python linting, security scans, TypeScript checks  
**Runs:** Build + Package + Deploy  
**Use when:** Making small code changes you're confident about

### `[skip-build]` - Skip Application Build (~10-15 minutes)
```bash
git commit -m "[skip-build] Update deployment parameters"
```
**Skips:** Application building and packaging  
**Runs:** Validation + Infrastructure deployment  
**Use when:** Only changing infrastructure, not application code

### No flags - Full Pipeline (~25-30 minutes)
```bash
git commit -m "Add new feature with tests"
```
**Runs:** Everything (validation, build, package, deploy)  
**Use when:** Major changes, before merging to main

## 🎯 Use Case Examples

### Scenario: Pipeline Failed Due to Missing Tags
**Problem:** Resource group creation failed due to policy, need to fix quickly  
**Solution:** 
```bash
# Fix your Bicep templates or parameters
git add .
git commit -m "[infra-only] Add missing BTP policy tags"
git push
# ⚡ Total time: ~5-10 minutes instead of 25+
```

### Scenario: Web App Configuration Issue  
**Problem:** App service settings wrong, but code is fine  
**Solution:**
```bash
# Update app settings in Bicep
git add .
git commit -m "[infra-only] Fix app service configuration"
git push
# ⚡ Total time: ~5-10 minutes
```

### Scenario: Small Code Fix
**Problem:** Minor Python/frontend change  
**Solution:**
```bash
# Make your code changes
git add .
git commit -m "[skip-validation] Fix login button styling"
git push
# ⚡ Total time: ~15-20 minutes instead of 25+
```

### Scenario: Parameter File Changes
**Problem:** Need to update deployment parameters  
**Solution:**
```bash
# Update parameters files
git add .
git commit -m "[skip-build] Update OpenAI model parameters"
git push
# ⚡ Total time: ~10-15 minutes
```

## 🔧 Pipeline Stage Details

| Stage | What It Does | Time | Skip Conditions |
|-------|-------------|------|----------------|
| **FastInfraValidation** | Quick Bicep lint & build | ~2-3 min | Only runs with `[infra-only]` |
| **Validate** | Full code validation, security scans | ~8-12 min | Skipped with `[skip-validation]` or `[infra-only]` |
| **BuildAndPackage** | Build frontend, package app | ~10-15 min | Skipped with `[skip-build]` or `[infra-only]` |
| **DeployDevelopment** | Deploy infrastructure & app | ~5-8 min | Always runs |

## 🎯 Time Savings Summary

| Approach | Time | Use Case |
|----------|------|----------|
| Full Pipeline | ~25-30 min | Major changes, final testing |
| Skip Validation | ~15-20 min | Confident code changes |
| Skip Build | ~10-15 min | Infrastructure/config only |
| **Infrastructure Only** | **~5-10 min** | **Bicep/Azure resource fixes** |

## 💡 Pro Tips

1. **Chain fixes efficiently**: Use `[infra-only]` for your first few attempts to fix infrastructure issues
2. **Test incrementally**: Fix one thing at a time with the appropriate flag
3. **Use full pipeline before merging**: Always run a full pipeline before creating PRs
4. **Monitor your changes**: Check Azure portal to confirm infrastructure changes took effect

## 🚨 Important Notes

- **Infrastructure-only deployments** checkout source code directly (no artifacts needed)
- **Application deployment** is skipped in infrastructure-only mode
- **Variable groups** still work - OpenAI model parameters are applied if available
- **All deployment types** respect the same security and tagging requirements

## 🔗 Quick Links

- **Pipeline Status**: Check your Azure DevOps pipeline page
- **Helper Script**: `./scripts/quick-deploy.sh`
- **Logs**: Look for "Infrastructure deployment completed successfully" in deployment logs

---

*This optimization can reduce your development cycle from 25+ minutes to 5-10 minutes for infrastructure fixes!*