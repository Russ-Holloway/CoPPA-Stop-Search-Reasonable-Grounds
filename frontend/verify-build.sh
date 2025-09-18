#!/bin/bash

# Frontend Build Verification Script
# This script verifies that the frontend can build successfully

set -e

echo "🔍 Starting frontend build verification..."

# Check if we're in the frontend directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: Not in frontend directory or package.json not found"
    exit 1
fi

# Clean any previous build
if [ -d "../static" ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf ../static/assets/*
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm ci

# Run type checking
echo "🔧 Running TypeScript type checking..."
npm run typecheck

# Build the application
echo "🏗️  Building application..."
npm run build

# Verify build output
if [ -f "../static/index.html" ] && [ -d "../static/assets" ]; then
    echo "✅ Build successful!"
    echo "📄 Build output:"
    ls -la ../static/
    
    # Check for essential files
    if [ -f "../static/index.html" ]; then
        echo "✅ index.html found"
    else
        echo "⚠️  Warning: index.html not found in build output"
    fi
    
    if [ -d "../static/assets" ]; then
        echo "✅ Assets directory found"
        echo "📁 Assets:"
        ls -la ../static/assets/
    else
        echo "⚠️  Warning: Assets directory not found"
    fi
    
    echo ""
    echo "🎉 Frontend build verification completed successfully!"
    
else
    echo "❌ Build failed - no static directory or assets found"
    echo "Expected files:"
    echo "  - ../static/index.html"
    echo "  - ../static/assets/"
    echo ""
    echo "Actual contents of ../static/:"
    if [ -d "../static" ]; then
        ls -la ../static/
    else
        echo "  Directory does not exist"
    fi
    exit 1
fi