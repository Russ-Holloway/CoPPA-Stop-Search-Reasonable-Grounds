"""
Azure Cognitive Search Setup Script

This script configures Azure Cognitive Search components automatically on application startup.
It creates:
1. Data source (connected to Azure Blob Storage)
2. Index with vector search capabilities
3. Skillsets for text processing and AI enrichment
4. Indexer to tie everything together

This runs automatically during web app startup to ensure a true one-click deployment experience.
"""

import os
import json
import logging
import time
import requests
from azure.storage.blob import BlobServiceClient
from azure.core.exceptions import ResourceExistsError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def setup_search_components():
    """Main function to set up all search components"""
    
    logger.info("Starting Azure Cognitive Search components setup")
    
    # Get environment variables
    search_service = os.environ.get("AZURE_SEARCH_SERVICE")
    search_admin_key = os.environ.get("AZURE_SEARCH_KEY")
    openai_endpoint = os.environ.get("AZURE_OPENAI_RESOURCE_ENDPOINT", os.environ.get("AZURE_OPENAI_RESOURCE"))
    openai_key = os.environ.get("AZURE_OPENAI_KEY")
    openai_embedding_deployment = os.environ.get("AZURE_OPENAI_EMBEDDING_NAME")
    
    # Validate required environment variables
    if not all([search_service, search_admin_key, openai_endpoint, openai_key, openai_embedding_deployment]):
        logger.error("Required environment variables are not set. Search components setup failed.")
        return
    
    # Create storage account for data source
    storage_account_name, storage_account_key = create_storage_account()
    
    if not storage_account_name or not storage_account_key:
        logger.error("Failed to create storage account. Search components setup failed.")
        return
    
    # Format service endpoints
    search_endpoint = f"https://{search_service}.search.windows.net"
    
    # Prepare request headers
    headers = {
        "Content-Type": "application/json",
        "api-key": search_admin_key
    }
    
    # Define component names
    index_name = "policingindex"
    data_source_name = "policingdata"
    skillset1_name = "policing-text-skillset"
    skillset2_name = "policing-enrichment-skillset"
    indexer_name = "policingindexer"
    container_name = "documents"
    
    # Create components in the right order
    try:
        # 1. Create the blob container
        create_blob_container(storage_account_name, storage_account_key, container_name)
        
        # 2. Create the search index
        create_index(search_endpoint, headers, index_name)
        
        # 3. Create the data source
        create_data_source(search_endpoint, headers, data_source_name, 
                          storage_account_name, storage_account_key, container_name)
        
        # 4. Create the text processing skillset
        create_text_skillset(search_endpoint, headers, skillset1_name)
        
        # 5. Create the AI enrichment skillset
        create_ai_skillset(search_endpoint, headers, skillset2_name, 
                          openai_endpoint, openai_key, openai_embedding_deployment)
        
        # 6. Create the indexer
        create_indexer(search_endpoint, headers, indexer_name, data_source_name, 
                      index_name, skillset1_name)
        
        # 7. Update the app settings with the newly created components
        update_app_settings(index_name)
        
        logger.info("Azure Cognitive Search components setup completed successfully")
        
    except Exception as e:
        logger.error(f"Error setting up search components: {str(e)}")
        return

def create_storage_account():
    """
    Create a storage account programmatically using Azure management API
    For this example, we'll use an existing storage account from app settings
    In a real scenario, you would create one dynamically
    """
    # For simplicity, we'll just return predefined values
    # In a production environment, you would use Azure Management API to create a storage account
    storage_account_name = os.environ.get("SETUP_STORAGE_ACCOUNT_NAME")
    storage_account_key = os.environ.get("SETUP_STORAGE_ACCOUNT_KEY")
    
    if not storage_account_name or not storage_account_key:
        # Create temporary storage account using resource manager API
        # This is simplified - in reality you would use Azure Management API
        import uuid
        from azure.identity import DefaultAzureCredential
        from azure.mgmt.resource import ResourceManagementClient
        from azure.mgmt.storage import StorageManagementClient
        
        try:
            # Get credentials and subscription
            credential = DefaultAzureCredential()
            subscription_id = os.environ.get("WEBSITE_OWNER_NAME", "").split('+')[0]
            resource_group = os.environ.get("WEBSITE_RESOURCE_GROUP")
            
            if not subscription_id or not resource_group:
                logger.error("Cannot determine subscription ID or resource group")
                return None, None
            
            # Create unique storage account name
            storage_account_name = f"policing{uuid.uuid4().hex[:8]}"
            
            # Create storage account
            storage_client = StorageManagementClient(credential, subscription_id)
            poller = storage_client.storage_accounts.begin_create(
                resource_group,
                storage_account_name,
                {
                    "location": os.environ.get("WEBSITE_SITE_NAME", "").split(',')[1] or "eastus",
                    "kind": "StorageV2",
                    "sku": {"name": "Standard_LRS"}
                }
            )
            
            # Wait for creation to complete
            account_result = poller.result()
            
            # Get access keys
            keys = storage_client.storage_accounts.list_keys(resource_group, storage_account_name)
            storage_account_key = keys.keys[0].value
            
            logger.info(f"Created storage account: {storage_account_name}")
            return storage_account_name, storage_account_key
            
        except Exception as e:
            logger.error(f"Failed to create storage account: {str(e)}")
            return None, None
    
    return storage_account_name, storage_account_key

def create_blob_container(storage_account_name, storage_account_key, container_name):
    """Create a blob container in the storage account"""
    try:
        # Create the blob service client
        conn_str = f"DefaultEndpointsProtocol=https;AccountName={storage_account_name};AccountKey={storage_account_key};EndpointSuffix=core.windows.net"
        blob_service_client = BlobServiceClient.from_connection_string(conn_str)
        
        # Create the container
        try:
            blob_service_client.create_container(container_name)
            logger.info(f"Created blob container: {container_name}")
        except ResourceExistsError:
            logger.info(f"Blob container {container_name} already exists")
          # Upload a sample document if none exists
        container_client = blob_service_client.get_container_client(container_name)
        blobs = list(container_client.list_blobs(max_results=1))
        
        if not blobs:
            # Upload sample documents from the data directory
            import os
            data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
            if os.path.exists(data_dir):
                for filename in os.listdir(data_dir):
                    if filename.endswith(".md") or filename.endswith(".pdf") or filename.endswith(".docx") or filename.endswith(".txt"):
                        file_path = os.path.join(data_dir, filename)
                        with open(file_path, "rb") as file_data:
                            blob_client = container_client.get_blob_client(filename)
                            blob_client.upload_blob(file_data.read(), overwrite=True)
                            logger.info(f"Uploaded document {filename} to blob container")
            else:
                # Create a sample document if data directory doesn't exist
                sample_content = """
                # Police Department Guidelines
                
                ## Introduction
                This document provides guidelines for police officers in the field.
                
                ## Patrol Procedures
                Officers should maintain visibility in their assigned areas and engage with community members.
                
                ## Investigation Protocols
                All investigations must follow department protocols for evidence collection and chain of custody.
                
                ## Community Engagement
                Building trust with the community is essential for effective policing.
                """
                
                # Upload the sample document
                blob_client = container_client.get_blob_client("sample_guidelines.md")
                blob_client.upload_blob(sample_content, overwrite=True)
                logger.info("Uploaded sample document to blob container")
            
    except Exception as e:
        logger.error(f"Error creating blob container: {str(e)}")
        raise

def create_index(search_endpoint, headers, index_name):
    """Create a search index with vector search capabilities"""
    try:
        # Define the index schema
        index_schema = {
            "name": index_name,
            "fields": [
                {
                    "name": "id",
                    "type": "Edm.String",
                    "key": True,
                    "searchable": False
                },
                {
                    "name": "content",
                    "type": "Edm.String",
                    "searchable": True,
                    "filterable": False,
                    "sortable": False,
                    "facetable": False
                },
                {
                    "name": "title",
                    "type": "Edm.String",
                    "searchable": True,
                    "filterable": True,
                    "sortable": True,
                    "facetable": False
                },
                {
                    "name": "url",
                    "type": "Edm.String",
                    "searchable": False,
                    "filterable": False,
                    "sortable": False,
                    "facetable": False
                },
                {
                    "name": "filename",
                    "type": "Edm.String",
                    "searchable": True,
                    "filterable": True,
                    "sortable": True,
                    "facetable": False
                },
                {
                    "name": "metadata_author",
                    "type": "Edm.String",
                    "searchable": True,
                    "filterable": True,
                    "sortable": False,
                    "facetable": False
                },
                {
                    "name": "metadata_creation_date",
                    "type": "Edm.DateTimeOffset",
                    "searchable": False,
                    "filterable": True,
                    "sortable": True,
                    "facetable": False
                },
                {
                    "name": "category",
                    "type": "Edm.String",
                    "searchable": True,
                    "filterable": True,
                    "sortable": False,
                    "facetable": True
                },
                {
                    "name": "contentVector",
                    "type": "Collection(Edm.Single)",
                    "searchable": True,
                    "filterable": False,
                    "sortable": False,
                    "facetable": False,
                    "dimensions": 1536,
                    "vectorSearchConfiguration": "vectorConfig"
                }
            ],
            "vectorSearch": {
                "algorithmConfigurations": [
                    {
                        "name": "vectorConfig",
                        "kind": "hnsw",
                        "parameters": {
                            "m": 4,
                            "efConstruction": 400,
                            "efSearch": 500,
                            "metric": "cosine"
                        }
                    }
                ]
            },
            "semantic": {
                "configurations": [
                    {
                        "name": "default",
                        "prioritizedFields": {
                            "titleField": {
                                "fieldName": "title"
                            },
                            "contentFields": [
                                {
                                    "fieldName": "content"
                                }
                            ],
                            "keywordsFields": [
                                {
                                    "fieldName": "category"
                                }
                            ]
                        }
                    }
                ]
            }
        }
        
        # Create the index
        response = requests.put(
            f"{search_endpoint}/indexes/{index_name}?api-version=2023-07-01-Preview",
            headers=headers,
            json=index_schema
        )
        
        if response.status_code in (201, 204):
            logger.info(f"Created search index: {index_name}")
        elif response.status_code == 400 and "already exists" in response.text:
            logger.info(f"Search index {index_name} already exists")
        else:
            response.raise_for_status()
            
    except Exception as e:
        logger.error(f"Error creating search index: {str(e)}")
        raise

def create_data_source(search_endpoint, headers, data_source_name, storage_account_name, 
                      storage_account_key, container_name):
    """Create a data source for the search service"""
    try:
        # Define the data source
        data_source = {
            "name": data_source_name,
            "type": "azureblob",
            "credentials": {
                "connectionString": f"DefaultEndpointsProtocol=https;AccountName={storage_account_name};AccountKey={storage_account_key};EndpointSuffix=core.windows.net"
            },
            "container": {
                "name": container_name
            }
        }
        
        # Create the data source
        response = requests.put(
            f"{search_endpoint}/datasources/{data_source_name}?api-version=2020-06-30",
            headers=headers,
            json=data_source
        )
        
        if response.status_code in (201, 204):
            logger.info(f"Created data source: {data_source_name}")
        elif response.status_code == 400 and "already exists" in response.text:
            logger.info(f"Data source {data_source_name} already exists")
        else:
            response.raise_for_status()
            
    except Exception as e:
        logger.error(f"Error creating data source: {str(e)}")
        raise

def create_text_skillset(search_endpoint, headers, skillset_name):
    """Create a text processing skillset"""
    try:
        # Define the skillset
        skillset = {
            "name": skillset_name,
            "description": "Text processing skillset for policing documents",
            "skills": [
                {
                    "@odata.type": "#Microsoft.Skills.Text.SplitSkill",
                    "name": "split-text",
                    "description": "Split content into pages",
                    "context": "/document",
                    "textSplitMode": "pages",
                    "maximumPageLength": 5000,
                    "inputs": [
                        {
                            "name": "text",
                            "source": "/document/content"
                        }
                    ],
                    "outputs": [
                        {
                            "name": "textItems",
                            "targetName": "pages"
                        }
                    ]
                },
                {
                    "@odata.type": "#Microsoft.Skills.Text.LanguageDetectionSkill",
                    "name": "detect-language",
                    "description": "Detect language of the document",
                    "context": "/document",
                    "inputs": [
                        {
                            "name": "text",
                            "source": "/document/content"
                        }
                    ],
                    "outputs": [
                        {
                            "name": "languageCode",
                            "targetName": "languageCode"
                        }
                    ]
                },
                {
                    "@odata.type": "#Microsoft.Skills.Text.KeyPhraseExtractionSkill",
                    "name": "extract-key-phrases",
                    "description": "Extract key phrases from each page",
                    "context": "/document/pages/*",
                    "defaultLanguageCode": "en",
                    "inputs": [
                        {
                            "name": "text",
                            "source": "/document/pages/*"
                        },
                        {
                            "name": "languageCode",
                            "source": "/document/languageCode"
                        }
                    ],
                    "outputs": [
                        {
                            "name": "keyPhrases",
                            "targetName": "keyPhrases"
                        }
                    ]
                }
            ]
        }
        
        # Create the skillset
        response = requests.put(
            f"{search_endpoint}/skillsets/{skillset_name}?api-version=2023-07-01-Preview",
            headers=headers,
            json=skillset
        )
        
        if response.status_code in (201, 204):
            logger.info(f"Created text processing skillset: {skillset_name}")
        elif response.status_code == 400 and "already exists" in response.text:
            logger.info(f"Skillset {skillset_name} already exists")
        else:
            response.raise_for_status()
            
    except Exception as e:
        logger.error(f"Error creating text processing skillset: {str(e)}")
        raise

def create_ai_skillset(search_endpoint, headers, skillset_name, openai_endpoint, 
                      openai_key, openai_embedding_deployment):
    """Create an AI enrichment skillset with OpenAI capabilities"""
    try:
        # Define the skillset
        skillset = {
            "name": skillset_name,
            "description": "AI enrichment skillset using Azure OpenAI",
            "skills": [
                {
                    "@odata.type": "#Microsoft.Skills.Text.AzureOpenAIEmbeddingSkill",
                    "name": "text-embedding",
                    "description": "Generate embeddings for the document content",
                    "context": "/document",
                    "resourceUri": openai_endpoint,
                    "apiKey": openai_key,
                    "deploymentId": openai_embedding_deployment,
                    "inputs": [
                        {
                            "name": "text",
                            "source": "/document/content"
                        }
                    ],
                    "outputs": [
                        {
                            "name": "embedding",
                            "targetName": "contentVector"
                        }
                    ]
                },
                {
                    "@odata.type": "#Microsoft.Skills.Text.AzureOpenAISkill",
                    "name": "document-categorizer",
                    "description": "Categorize documents into policing categories",
                    "context": "/document",
                    "resourceUri": openai_endpoint,
                    "apiKey": openai_key,
                    "deploymentId": "gpt-4o",
                    "modelVersion": "2023-09-01-preview",
                    "apiVersion": "2023-05-15",
                    "completionOptions": {
                        "temperature": 0,
                        "maxTokens": 50
                    },
                    "inputs": [
                        {
                            "name": "messages",
                            "sourceContext": "/document",
                            "inputs": [
                                {
                                    "name": "item",
                                    "inputs": [
                                        {
                                            "name": "role",
                                            "value": "system"
                                        },
                                        {
                                            "name": "content",
                                            "value": "You are a law enforcement document classifier. Analyze the document content and assign a single category from this list: 'Investigation', 'Patrol', 'Community', 'Evidence', 'Training', 'Legal', 'Administration', 'Intelligence', 'Emergency'. Respond with ONLY the category name."
                                        }
                                    ]
                                },
                                {
                                    "name": "item",
                                    "inputs": [
                                        {
                                            "name": "role",
                                            "value": "user"
                                        },
                                        {
                                            "name": "content",
                                            "source": "/document/content"
                                        }
                                    ]
                                }
                            ]
                        }
                    ],
                    "outputs": [
                        {
                            "name": "output",
                            "targetName": "category"
                        }
                    ]
                }
            ]
        }
        
        # Create the skillset
        response = requests.put(
            f"{search_endpoint}/skillsets/{skillset_name}?api-version=2023-07-01-Preview",
            headers=headers,
            json=skillset
        )
        
        if response.status_code in (201, 204):
            logger.info(f"Created AI enrichment skillset: {skillset_name}")
        elif response.status_code == 400 and "already exists" in response.text:
            logger.info(f"Skillset {skillset_name} already exists")
        else:
            response.raise_for_status()
            
    except Exception as e:
        logger.error(f"Error creating AI enrichment skillset: {str(e)}")
        raise

def create_indexer(search_endpoint, headers, indexer_name, data_source_name, 
                  index_name, skillset_name):
    """Create an indexer to tie everything together"""
    try:
        # Define the indexer
        indexer = {
            "name": indexer_name,
            "dataSourceName": data_source_name,
            "targetIndexName": index_name,
            "skillsetName": skillset_name,
            "parameters": {
                "configuration": {
                    "dataToExtract": "contentAndMetadata",
                    "parsingMode": "default"
                }
            },
            "fieldMappings": [
                {
                    "sourceFieldName": "metadata_storage_name",
                    "targetFieldName": "filename"
                },
                {
                    "sourceFieldName": "metadata_storage_path",
                    "targetFieldName": "url"
                },
                {
                    "sourceFieldName": "metadata_title",
                    "targetFieldName": "title"
                },
                {
                    "sourceFieldName": "metadata_author",
                    "targetFieldName": "metadata_author"
                },
                {
                    "sourceFieldName": "metadata_creation_date",
                    "targetFieldName": "metadata_creation_date"
                }
            ],
            "outputFieldMappings": [
                {
                    "sourceFieldName": "/document/pages/*",
                    "targetFieldName": "content",
                    "mappingFunction": {
                        "name": "merge"
                    }
                },
                {
                    "sourceFieldName": "/document/contentVector",
                    "targetFieldName": "contentVector"
                },
                {
                    "sourceFieldName": "/document/category",
                    "targetFieldName": "category"
                }
            ],
            "schedule": {
                "interval": "PT12H"  # Run every 12 hours
            }
        }
        
        # Create the indexer
        response = requests.put(
            f"{search_endpoint}/indexers/{indexer_name}?api-version=2023-07-01-Preview",
            headers=headers,
            json=indexer
        )
        
        if response.status_code in (201, 204):
            logger.info(f"Created indexer: {indexer_name}")
        elif response.status_code == 400 and "already exists" in response.text:
            logger.info(f"Indexer {indexer_name} already exists")
        else:
            response.raise_for_status()
            
        # Run the indexer immediately
        run_response = requests.post(
            f"{search_endpoint}/indexers/{indexer_name}/run?api-version=2023-07-01-Preview",
            headers=headers
        )
        
        if run_response.status_code == 202:
            logger.info(f"Started indexer: {indexer_name}")
        else:
            logger.warning(f"Failed to start indexer: {run_response.status_code} - {run_response.text}")
            
    except Exception as e:
        logger.error(f"Error creating indexer: {str(e)}")
        raise

def update_app_settings(index_name):
    """Update the app settings to use the new index and components"""
    try:
        # For App Service, we can use environment variables directly
        # These will be in place for the current process
        os.environ["AZURE_SEARCH_INDEX"] = index_name
        os.environ["AZURE_SEARCH_QUERY_TYPE"] = "vectorSemanticHybrid"
        os.environ["AZURE_SEARCH_VECTOR_COLUMNS"] = "contentVector"
        os.environ["AZURE_SEARCH_USE_SEMANTIC_SEARCH"] = "true"
        
        logger.info("Updated application settings")
        
    except Exception as e:
        logger.error(f"Error updating app settings: {str(e)}")
        raise

# This function can be called during application startup
if __name__ == "__main__":
    setup_search_components()
