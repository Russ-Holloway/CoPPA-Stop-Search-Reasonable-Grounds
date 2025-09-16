# Azure DevOps Variable Groups for CoPA Stop & Search

This directory contains example variable group configurations for different environments.

## Variable Groups Required

### 1. copa-dev-variables (Development Environment)
- **Resource Group**: `rg-dev-uksouth-copa-stop-search`
- **Location**: `uksouth`
- **OpenAI Models**: Conservative capacity settings for testing
- **Security**: Development-appropriate settings

### 2. copa-prod-variables (Production Environment)  
- **Resource Group**: User-defined production resource group
- **Location**: User-defined location (typically `uksouth` or `ukwest`)
- **OpenAI Models**: Production-appropriate capacity settings
- **Security**: Maximum security settings

## Setup Instructions

1. Create variable groups in Azure DevOps Library
2. Add variables from the example files
3. Mark sensitive variables as secrets (marked with 🔐 in examples)
4. Configure appropriate access permissions per environment

## Security Notes

- All sensitive variables should be marked as secrets in DevOps
- Production variables should have restricted access
- Use separate service connections per environment
- Enable approval processes for production deployments