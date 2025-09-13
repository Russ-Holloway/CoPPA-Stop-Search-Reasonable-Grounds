# Azure Environment Variables Comparison

## Critical Variables for Flask App Boot (likely missing from Azure)

Based on the main branch deployment.json and our local testing, these environment variables are **required** for the Flask app to start properly:

### **Azure Search Configuration**
- `AZURE_SEARCH_USE_SEMANTIC_SEARCH=true`
- `AZURE_SEARCH_SEMANTIC_SEARCH_CONFIG=copa-stop-search-semantic-configuration`
- `AZURE_SEARCH_TOP_K=5`
- `AZURE_SEARCH_ENABLE_IN_DOMAIN=true`
- `AZURE_SEARCH_QUERY_TYPE=vector_semantic_hybrid`
- `AZURE_SEARCH_PERMITTED_GROUPS_COLUMN=` (empty but must exist)
- `AZURE_SEARCH_STRICTNESS=3`
- `AZURE_SEARCH_DATA_SOURCE=copa-stop-search-datasource`
- `AZURE_SEARCH_INDEXER=copa-stop-search-indexer`
- `AZURE_SEARCH_SKILLSET=copa-stop-search-skillset`

### **Azure OpenAI Configuration**
- `AZURE_OPENAI_STOP_SEQUENCE=` (empty but must exist)
- `AZURE_OPENAI_STREAM=true`
- `AZURE_OPENAI_SYSTEM_MESSAGE=` (long system message from deployment.json)

### **Storage Configuration** 
- `AZURE_STORAGE_CONTAINER_NAME=ai-library-stop-search`

### **CosmosDB Configuration**
- `AZURE_COSMOSDB_ACCOUNT=` (cosmos account name)
- `AZURE_COSMOSDB_URI=` (cosmos URI)
- `AZURE_COSMOSDB_DATABASE=db_conversation_history`
- `AZURE_COSMOSDB_CONVERSATIONS_CONTAINER=conversations`

### **Data Source Configuration**
- `DATASOURCE_TYPE=AzureCognitiveSearch`

### **UI Configuration (for proper tagline display)**
- `UI_FAVICON=` (empty but must exist)
- `UI_FEEDBACK_EMAIL=` (empty but must exist)  
- `UI_FIND_OUT_MORE_LINK=` (empty but must exist)
- `UI_POLICE_FORCE_LOGO=` (empty but must exist)

## Variables That Should Already Exist (from previous fixes)

These should already be configured in Azure:
- `AZURE_OPENAI_ENDPOINT` ✅ (we added this)
- `UI_POLICE_FORCE_TAGLINE` ✅ (should be set)
- `UI_POLICE_FORCE_TAGLINE_2` ✅ (should be set)

## How to Check Azure Configuration

1. Go to Azure Portal → Your App Service
2. Settings → Configuration → Application Settings
3. Compare with the list above
4. Add any missing variables with the values from deployment.json

## Priority Order for Adding Missing Variables

1. **First Priority** (App startup): All Azure Search config variables
2. **Second Priority** (UI display): UI configuration variables  
3. **Third Priority** (Full functionality): CosmosDB and storage variables

The Flask app boot failure is most likely due to missing Azure Search configuration variables.