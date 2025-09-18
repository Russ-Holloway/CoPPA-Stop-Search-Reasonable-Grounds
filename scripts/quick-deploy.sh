#!/bin/bash

# Quick deployment script for CoPA Stop & Search project
# This helps speed up development by skipping stages when you only need to test specific parts

set -e

echo "🚀 CoPA Quick Deployment Helper"
echo "================================"

# Check if we're on the correct branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "Dev-Ops-Deployment" ]; then
    echo "⚠️  Warning: You're on branch '$CURRENT_BRANCH', not 'Dev-Ops-Deployment'"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "Choose deployment type:"
echo "1. 🏗️  Infrastructure Only (fastest - skips all builds, ~5-10 minutes)"
echo "2. 🔧 Skip Validation (moderate - skips code validation, ~15-20 minutes)" 
echo "3. 📦 Skip Build (validation only, ~10-15 minutes)"
echo "4. 🌟 Full Pipeline (everything, ~25-30 minutes)"
echo ""
read -p "Enter choice (1-4): " -n 1 -r CHOICE
echo

COMMIT_FLAGS=""
case $CHOICE in
    1)
        COMMIT_FLAGS="[infra-only]"
        echo "🏗️  Infrastructure-only deployment selected"
        echo "   ✅ Skips: Code validation, builds, application deployment"
        echo "   🚀 Runs: Quick Bicep validation + Infrastructure deployment only"
        ;;
    2)
        COMMIT_FLAGS="[skip-validation]"
        echo "🔧 Skip validation selected"
        echo "   ✅ Skips: Code validation and security scans"
        echo "   🚀 Runs: Build + Package + Deploy"
        ;;
    3)
        COMMIT_FLAGS="[skip-build]"
        echo "📦 Skip build selected"
        echo "   ✅ Skips: Application building and packaging"
        echo "   🚀 Runs: Validation + Infrastructure deployment"
        ;;
    4)
        COMMIT_FLAGS=""
        echo "🌟 Full pipeline selected"
        echo "   🚀 Runs: Everything (validation, build, package, deploy)"
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
read -p "Enter commit message: " COMMIT_MESSAGE

# Check if there are changes to commit
if git diff --quiet && git diff --staged --quiet; then
    echo "❌ No changes to commit. Make your changes first, then run this script."
    exit 1
fi

# Commit and push
FULL_MESSAGE="$COMMIT_FLAGS $COMMIT_MESSAGE"
echo ""
echo "📝 Committing with message: $FULL_MESSAGE"
git add .
git commit -m "$FULL_MESSAGE"

echo "📤 Pushing to trigger pipeline..."
git push

echo ""
echo "✅ Done! Pipeline should start shortly with optimized stages."
echo ""
echo "💡 Pipeline stages that will run:"
case $CHOICE in
    1)
        echo "   - FastInfraValidation (~2-3 min)"
        echo "   - DeployDevelopment/Infrastructure (~5-8 min)"
        echo "   - Total: ~5-10 minutes"
        ;;
    2)
        echo "   - BuildAndPackage (~10-15 min)"
        echo "   - DeployDevelopment (~5-8 min)"
        echo "   - Total: ~15-20 minutes"
        ;;
    3)
        echo "   - Validate (~8-12 min)"
        echo "   - DeployDevelopment/Infrastructure (~5-8 min)"
        echo "   - Total: ~10-15 minutes"
        ;;
    4)
        echo "   - Validate (~8-12 min)"
        echo "   - BuildAndPackage (~10-15 min)"
        echo "   - DeployDevelopment (~5-8 min)"
        echo "   - Total: ~25-30 minutes"
        ;;
esac

echo ""
echo "🔗 Check pipeline status at:"
echo "   https://dev.azure.com/your-org/your-project/_build"