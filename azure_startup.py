#!/usr/bin/env python3
"""
Production startup script for CoPA on Azure App Service
"""
import os
import sys
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def check_critical_vars():
    """Check critical environment variables"""
    required_vars = [
        'AZURE_OPENAI_MODEL',
        'AZURE_OPENAI_RESOURCE'
    ]
    
    missing = []
    for var in required_vars:
        if not os.environ.get(var):
            missing.append(var)
    
    if missing:
        logger.error(f"Missing required environment variables: {', '.join(missing)}")
        logger.error("Please configure these in Azure App Service Configuration")
        return False
    
    return True

def main():
    """Main startup function"""
    logger.info("Starting CoPA application...")
    
    # Check configuration
    if not check_critical_vars():
        logger.error("Configuration check failed")
        sys.exit(1)
    
    # Import and start the app
    try:
        from app import app
        logger.info("App imported successfully")
        
        # For Azure App Service, the platform handles the server
        # This script just validates the app can be imported
        logger.info("✅ CoPA is ready to start")
        
    except Exception as e:
        logger.error(f"Failed to import app: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
