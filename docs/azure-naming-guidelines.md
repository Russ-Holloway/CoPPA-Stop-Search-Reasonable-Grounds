# PDS Compliant Azure Resource Naming Guidelines for UK Police Forces

## Overview
This document provides PDS-compliant naming guidelines for Azure resources in the CoPPA deployment. These guidelines ensure consistency across all 44 UK police forces and compliance with the PDS (Police Digital Service) naming strategy.

## PDS Naming Convention Pattern

### Standard Format
`{force-code}-{service-type}-{workload}-{environment}-{instance}`

Where:
- **force-code**: 2-3 letter abbreviation for the police force (e.g., btp, met, gmp)
- **service-type**: Resource type abbreviation (app, srch, ai, st, etc.)
- **workload**: Application/workload identifier (policing, assistant)
- **environment**: dev, test, prod
- **instance**: 2-digit number (01, 02, etc.)

### Force Code Examples
- **BTP**: British Transport Police
- **MET**: Metropolitan Police
- **GMP**: Greater Manchester Police
- **WMP**: West Midlands Police
- **NYP**: North Yorkshire Police
- **AVS**: Avon and Somerset Police

## Resource-Specific Guidelines

### 1. Web Applications (App Service)
- **Format**: `{force-code}-app-policing-{environment}-{instance}`
- **Example**: `btp-app-policing-prod-01`
- **Character Limit**: 2-60 characters
- **Allowed Characters**: Letters, numbers, hyphens
- **Must be unique**: Globally unique across Azure

### 2. Azure AI Search Services
- **Format**: `{force-code}-srch-policing-{environment}-{instance}`
- **Example**: `btp-srch-policing-prod-01`
- **Character Limit**: 2-60 characters
- **Allowed Characters**: Letters, numbers, hyphens
- **Must be unique**: Globally unique across Azure

### 3. Azure OpenAI Services
- **Format**: `{force-code}-ai-policing-{environment}-{instance}`
- **Example**: `btp-ai-policing-prod-01`
- **Character Limit**: 2-64 characters
- **Allowed Characters**: Letters, numbers, hyphens
- **Must be unique**: Globally unique across Azure

### 4. Storage Accounts
- **Format**: `st{forcecode}{workload}{environment}{instance}`
- **Example**: `stbtppolicingprod01`
- **Character Limit**: 3-24 characters
- **Allowed Characters**: Lowercase letters and numbers only
- **Must be unique**: Globally unique across all Azure subscriptions
- **Note**: No hyphens or uppercase letters allowed

### 5. Cosmos DB Accounts
- **Format**: `{force-code}-cosmos-policing-{environment}-{instance}`
- **Example**: `btp-cosmos-policing-prod-01`
- **Character Limit**: 3-44 characters
- **Allowed Characters**: Letters, numbers, hyphens
- **Must be unique**: Globally unique across Azure

### 6. Resource Groups
- **Format**: `rg-{force-code}-policing-{environment}-{instance}`
- **Example**: `rg-btp-policing-prod-01`
- **Character Limit**: 1-90 characters
- **Allowed Characters**: Letters, numbers, hyphens, periods, parentheses, underscores

### 7. Search Components
- **Index**: `{force-code}-policing-index-{environment}`
- **Indexer**: `{force-code}-policing-indexer-{environment}`
- **Data Source**: `{force-code}-policing-datasource-{environment}`
- **Examples**: 
  - `btp-policing-index-prod`
  - `btp-policing-indexer-prod`
  - `btp-policing-datasource-prod`

### 8. Key Vault
- **Format**: `kv-{force-code}-policing-{environment}-{instance}`
- **Example**: `kv-btp-policing-prod-01`
- **Character Limit**: 3-24 characters
- **Allowed Characters**: Letters, numbers, hyphens
- **Must be unique**: Globally unique across Azure

## Environment Codes
- **dev**: Development environment
- **test**: Test/UAT environment
- **prod**: Production environment

## Validation Rules
1. All resource names must be lowercase (except where Azure requires specific casing)
2. Use hyphens as separators (except for storage accounts)
3. Force codes must be 2-3 characters from the approved list
4. Instance numbers must be zero-padded (01, 02, etc.)
5. Names must not end with a hyphen
6. Resource names must be unique within their scope (subscription, resource group, or globally)
- **Indexer**: `policing-indexer` or `policing-indexer-{environment}`
- **Data Source**: `policing-datasource` or `policing-datasource-{environment}`

## Environment Codes
- **dev** - Development environment
- **test** - Testing environment
- **uat** - User Acceptance Testing
- **prod** - Production environment

## Deployment Prefixes
- **btp-policing** - Standard BTP policing applications
- **btp-training** - Training-related applications
- **btp-ops** - Operational applications

## Best Practices

### 1. Consistency
- Always use the same prefix across related resources
- Use lowercase for storage accounts
- Use consistent environment suffixes

### 2. Uniqueness
- Storage account names must be globally unique
- Consider adding numbers (001, 002) for uniqueness if needed
- Test name availability before deployment

### 3. Length Considerations
- Keep names descriptive but within Azure limits
- Shorter prefixes allow for more descriptive service names
- Consider abbreviations for long department names

### 4. Special Characters
- Use hyphens (-) to separate words in most resources
- Storage accounts cannot use hyphens
- Avoid special characters except where specified

## Pre-Deployment Checklist

✅ **Verify naming follows BTP conventions**  
✅ **Check Azure naming requirements for each resource type**  
✅ **Ensure storage account name is globally unique**  
✅ **Confirm environment suffix matches deployment target**  
✅ **Validate character limits for each resource**  
✅ **Review with IT governance if required**  

## Example Complete Deployment Names

### Development Environment
- Web App: `btp-policing-assistant-dev`
- Search Service: `btp-policing-search-dev`
- OpenAI Service: `btp-policing-openai-dev`
- Storage Account: `stbtppolicingdev001`
- Cosmos DB: `btp-policing-cosmos-dev`
- Search Index: `policing-index`

### Production Environment
- Web App: `btp-policing-assistant-prod`
- Search Service: `btp-policing-search-prod`
- OpenAI Service: `btp-policing-openai-prod`
- Storage Account: `stbtppolicingprod001`
- Cosmos DB: `btp-policing-cosmos-prod`
- Search Index: `policing-index`

## Contact Information
For questions about naming conventions or to request exceptions, contact:
- **IT Governance Team**: [contact information]
- **Cloud Architecture Team**: [contact information]
