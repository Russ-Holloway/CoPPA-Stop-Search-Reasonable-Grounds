// DevOps Bicep Parameters for CoPA Stop & Search
// This file provides parameter defaults for DevOps pipeline deployment

using './main-pds-converted.bicep'

// Environment and location configuration
param location = 'uksouth'

// OpenAI Model Configuration 
// These defaults will be overridden by pipeline variables per environment
param azureOpenAIModelName = 'gpt-4o'
param azureOpenAIEmbeddingName = 'text-embedding-ada-002'

// Note: Additional environment-specific parameters will be provided
// by Azure DevOps variable groups during pipeline execution
