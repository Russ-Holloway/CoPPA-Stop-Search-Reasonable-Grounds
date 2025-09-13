#!/usr/bin/env python3
import os
import sys
sys.path.append('/workspaces/CoPA-Stop-Search-Reasonable-Grounds')

# Set the environment variables
os.environ['AZURE_OPENAI_ENDPOINT'] = 'https://dummy.openai.azure.com/'
os.environ['AZURE_SEARCH_SERVICE'] = 'dummy'
os.environ['AZURE_SEARCH_INDEX'] = 'dummy'
os.environ['AZURE_SEARCH_KEY'] = 'dummy-key-for-development'
os.environ['AZURE_OPENAI_KEY'] = 'dummy-key-for-development'
os.environ['UI_POLICE_FORCE_TAGLINE'] = 'This version of CoPPA is configured for British Transport Police Stop & Search Reasonable Grounds Review'
os.environ['UI_POLICE_FORCE_TAGLINE_2'] = 'Paste the reasonable grounds from a stop search record exactly as they are written and the CoPPA Assistant will provide operational guidance and feedback'

from backend.settings import app_settings

print("UI Settings:")
print(f"Title: {app_settings.ui.title}")
print(f"Police Force Tagline: {app_settings.ui.police_force_tagline}")
print(f"Police Force Tagline 2: {app_settings.ui.police_force_tagline_2}")

print("\nEnvironment Variables:")
print(f"UI_POLICE_FORCE_TAGLINE: {os.environ.get('UI_POLICE_FORCE_TAGLINE')}")
print(f"UI_POLICE_FORCE_TAGLINE_2: {os.environ.get('UI_POLICE_FORCE_TAGLINE_2')}")