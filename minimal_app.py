#!/usr/bin/env python3
import os
import sys
from flask import Flask, jsonify, send_from_directory

# Set environment variables
os.environ['AZURE_OPENAI_ENDPOINT'] = 'https://dummy.openai.azure.com/'
os.environ['AZURE_SEARCH_SERVICE'] = 'dummy'
os.environ['AZURE_SEARCH_INDEX'] = 'dummy'
os.environ['AZURE_SEARCH_KEY'] = 'dummy-key-for-development'
os.environ['AZURE_OPENAI_KEY'] = 'dummy-key-for-development'
os.environ['UI_POLICE_FORCE_TAGLINE'] = 'This version of CoPPA is configured for British Transport Police Stop & Search Reasonable Grounds Review'
os.environ['UI_POLICE_FORCE_TAGLINE_2'] = 'Paste the reasonable grounds from a stop search record exactly as they are written and the CoPPA Assistant will provide operational guidance and feedback'
os.environ['UI_TITLE'] = 'CoPA (College of Policing Assistant) for Stop Search'
os.environ['UI_CHAT_TITLE'] = 'CoPA for Stop Search'

sys.path.append('/workspaces/CoPA-Stop-Search-Reasonable-Grounds')

from backend.settings import app_settings

app = Flask(__name__, static_folder='static')

@app.route('/frontend_settings')
def get_frontend_settings():
    settings = {
        "auth_enabled": False,
        "feedback_enabled": False,
        "ui": {
            "title": app_settings.ui.title,
            "logo": app_settings.ui.logo,
            "chat_logo": app_settings.ui.chat_logo or app_settings.ui.logo,
            "chat_title": app_settings.ui.chat_title,
            "chat_description": app_settings.ui.chat_description,
            "subtitle": app_settings.ui.subtitle,
            "show_share_button": app_settings.ui.show_share_button,
            "show_chat_history_button": False,
            "police_force_logo": app_settings.ui.police_force_logo,
            "police_force_tagline": app_settings.ui.police_force_tagline,
            "police_force_tagline_2": app_settings.ui.police_force_tagline_2,
            "feedback_email": app_settings.ui.feedback_email,
            "find_out_more_link": app_settings.ui.find_out_more_link,
        },
        "sanitize_answer": True,
        "oyd_enabled": False,
        "chat_history_enabled": False,
        "chat_history_required": False,
        "chat_history_delete_enabled": False,
        "chat_history_clear_enabled": False,
    }
    return jsonify(settings)

@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/<path:path>')
def static_files(path):
    return send_from_directory('static', path)

if __name__ == '__main__':
    print("Starting minimal Flask app for testing...")
    print(f"Police Force Tagline: {app_settings.ui.police_force_tagline}")
    print(f"Police Force Tagline 2: {app_settings.ui.police_force_tagline_2}")
    app.run(host='0.0.0.0', port=8000, debug=True)