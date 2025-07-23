#!/bin/bash

echo "Starting CoPPA application..."

# Build frontend if needed
if [ ! -d "static" ]; then
    echo "Building frontend..."
    cd frontend
    npm install
    npm run build
    cd ..
fi

# Start the application with gunicorn
echo "Starting backend with gunicorn..."
python -m gunicorn app:app
