# Citation Configuration Guide

## Overview
Citations are not working because the backend requires proper environment variable configuration to connect to a search service that contains the source documents. The frontend code is correctly implemented, but without backend data source configuration, citations appear as plain text instead of clickable links.

## Root Cause
The issue you experienced ("this was happening before in the main copa web app and it was something to do with environment variables") is exactly what's happening here. Citations require:

1. **Data Source Configuration**: A search service (Azure AI Search, CosmosDB, etc.) that contains indexed documents
2. **Environment Variables**: Proper configuration to connect to the search service
3. **Content Mapping**: Field mappings so the system knows which fields contain content, titles, URLs, etc.

## Required Environment Variables

### 1. Core Data Source Configuration
```bash
# Specify which search service to use
DATASOURCE_TYPE=AzureCognitiveSearch

# Search behavior settings
SEARCH_TOP_K=5
SEARCH_STRICTNESS=3
SEARCH_ENABLE_IN_DOMAIN=True
```

### 2. Azure AI Search Configuration (Recommended)
```bash
# Azure AI Search service details
AZURE_SEARCH_SERVICE=your-search-service-name
AZURE_SEARCH_INDEX=your-search-index-name  
AZURE_SEARCH_KEY=your-search-api-key

# Field mappings (CRITICAL for citations)
AZURE_SEARCH_CONTENT_COLUMNS=content
AZURE_SEARCH_FILENAME_COLUMN=filename
AZURE_SEARCH_TITLE_COLUMN=title
AZURE_SEARCH_URL_COLUMN=url

# Search configuration
AZURE_SEARCH_TOP_K=5
AZURE_SEARCH_ENABLE_IN_DOMAIN=True
AZURE_SEARCH_QUERY_TYPE=simple
AZURE_SEARCH_STRICTNESS=3
```

### 3. Alternative Data Sources
If not using Azure AI Search, you can configure other data sources:

- **CosmosDB**: Set `DATASOURCE_TYPE=AzureCosmosDB`
- **Elasticsearch**: Set `DATASOURCE_TYPE=Elasticsearch`
- **Pinecone**: Set `DATASOURCE_TYPE=Pinecone`
- **MongoDB**: Set `DATASOURCE_TYPE=MongoDB`

## Setup Steps

### Step 1: Create Search Service
1. Create an Azure AI Search service in the Azure portal
2. Index your police documents (PACE Code A, College of Policing APP, etc.)
3. Note the service name, index name, and API key

### Step 2: Configure Environment Variables
1. Copy `.env.sample` to `.env`
2. Fill in the Azure Search configuration:
   ```bash
   AZURE_SEARCH_SERVICE=your-actual-service-name
   AZURE_SEARCH_INDEX=your-actual-index-name
   AZURE_SEARCH_KEY=your-actual-api-key
   ```

### Step 3: Verify Field Mappings
Ensure your search index has these fields and update the mappings:
```bash
AZURE_SEARCH_CONTENT_COLUMNS=content     # Field containing document text
AZURE_SEARCH_FILENAME_COLUMN=filename   # Field containing file names
AZURE_SEARCH_TITLE_COLUMN=title         # Field containing document titles
AZURE_SEARCH_URL_COLUMN=url             # Field containing document URLs
```

### Step 4: Test Citations
1. Restart the backend service
2. Ask a question that should reference police guidelines
3. Citations should now appear as clickable blue links `[1]`, `[2]`
4. Clicking citations should open the citation panel with source documents

## Troubleshooting

### Citations Still Not Clickable
- Check backend logs for connection errors
- Verify search service is accessible
- Confirm index contains data
- Validate field mappings match your index schema

### Citations Appear But Panel Is Empty
- Check `AZURE_SEARCH_CONTENT_COLUMNS` mapping
- Verify documents have content in the mapped field
- Check search service permissions

### Backend Connection Errors
- Verify `AZURE_SEARCH_SERVICE` name is correct
- Check `AZURE_SEARCH_KEY` is valid and has read permissions
- Ensure search service is in the same region/subscription

## Current Status
- ✅ Frontend citation code is correctly implemented
- ✅ Citation parsing and display logic works
- ✅ CSS styling for citation links is configured
- ❌ Backend data source is not configured
- ❌ Environment variables are missing
- ❌ No search index with police documents

## Next Steps
1. Set up Azure AI Search service with police documents
2. Configure environment variables in `.env`
3. Test citation functionality
4. Deploy with proper search service configuration
