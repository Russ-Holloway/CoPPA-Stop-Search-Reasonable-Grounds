# Pipeline Management Guide

## Issue: Multiple Pipeline Runs from Single Push

### Root Cause Analysis
The multiple pipeline runs are likely caused by:

1. **Multiple Pipeline Definitions**: You may have multiple pipeline definitions in Azure DevOps that all reference the same `azure-pipelines.yml` file
2. **Webhook Duplication**: GitHub webhooks may be duplicated
3. **Manual Triggers**: Someone manually triggering builds

### Solutions Implemented

#### 1. Pipeline Trigger Optimization
- Added `batch: true` - Only builds the latest commit if multiple commits are pushed quickly
- Added `pr: none` - Disables automatic PR builds 
- Added more exclusion paths to prevent builds on documentation changes

#### 2. How to Check for Multiple Pipeline Definitions

**In Azure DevOps:**
1. Go to your project → Pipelines
2. Look for multiple pipelines with the same or similar names
3. Check if multiple pipelines are configured to use the same YAML file
4. **Delete duplicate pipeline definitions** (keep only one)

#### 3. How to Check GitHub Webhooks

**In GitHub:**
1. Go to your repository → Settings → Webhooks
2. Look for multiple webhooks pointing to the same Azure DevOps organization
3. Delete duplicates if found

### Emergency Pipeline Cleanup

If you need to cancel running/queued builds:

**Option 1: Azure DevOps Web Interface**
1. Go to Pipelines → Runs
2. Select multiple runs (Ctrl+Click)
3. Click "Cancel" to stop them

**Option 2: Azure CLI (if you have access)**
```bash
# List recent builds
az pipelines runs list --organization https://dev.azure.com/YourOrg --project YourProject

# Cancel specific builds
az pipelines runs cancel --organization https://dev.azure.com/YourOrg --project YourProject --run-id BUILD_ID
```

### Prevention Going Forward

1. **Check Pipeline Definitions**: Ensure only ONE pipeline definition exists in Azure DevOps
2. **Use Manual Triggers**: For production deployments, consider manual triggers only
3. **Batch Builds**: The `batch: true` setting will help consolidate multiple commits
4. **Path Filters**: Only trigger on actual code changes, not documentation

### Current Pipeline Trigger Configuration

```yaml
trigger:
  branches:
    include:
    - main
    - Dev-Ops-Deployment
  paths:
    exclude:
    - '**/*.md'
    - 'docs/**'
    - '**/README*'
    - '.gitignore'
    - '.vscode/**'
    - '.devcontainer/**'
  batch: true  # Batch builds

pr: none  # No automatic PR builds
```

This should significantly reduce unnecessary pipeline runs.