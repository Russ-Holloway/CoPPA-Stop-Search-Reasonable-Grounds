// Parameters file for BTP CoPA Stop & Search deployment
using './deployment-btp.bicep'

// BTP-specific deployment parameters
param location = 'uksouth'
param azureOpenAIModelName = 'gpt-4o'
param azureOpenAIEmbeddingName = 'text-embedding-ada-002'

// Note: Force code (btp), region (uks), and environment (p) will be automatically
// extracted from the resource group name: rg-btp-uks-p-copa-stop-search
