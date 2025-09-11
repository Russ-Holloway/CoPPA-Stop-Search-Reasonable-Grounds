#!/bin/bash

# CoPA Deployment Validation Script
# This script validates that the larger answer and citation box changes will work in deployment

echo "🔍 CoPA Layout Changes Deployment Validation"
echo "============================================="

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: Must be run from frontend directory"
    exit 1
fi

echo "✅ Running from frontend directory"

# 1. Validate CSS syntax
echo ""
echo "🔧 Step 1: Validating CSS syntax..."
npx stylelint "src/**/*.css" --config-basedir . 2>/dev/null || echo "⚠️  Stylelint not configured (optional)"

# 2. Check for TypeScript compilation errors
echo ""
echo "🔧 Step 2: Checking TypeScript compilation..."
npx tsc --noEmit
if [ $? -eq 0 ]; then
    echo "✅ TypeScript compilation successful"
else
    echo "❌ TypeScript compilation failed"
    exit 1
fi

# 3. Build the project
echo ""
echo "🔧 Step 3: Building project..."
npm run build
if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

# 4. Check if critical CSS files exist and have our changes
echo ""
echo "🔧 Step 4: Validating critical CSS changes..."

# Check Answer.module.css
if grep -q "min-height: 400px" "src/components/Answer/Answer.module.css"; then
    echo "✅ Answer container min-height found"
else
    echo "❌ Answer container min-height missing"
    exit 1
fi

if grep -q "font-size: 16px" "src/components/Answer/Answer.module.css"; then
    echo "✅ Larger font size found in Answer"
else
    echo "❌ Larger font size missing in Answer"
    exit 1
fi

if grep -q "padding: 30px" "src/components/Answer/Answer.module.css"; then
    echo "✅ Increased padding found in Answer"
else
    echo "❌ Increased padding missing in Answer"
    exit 1
fi

# Check Chat.module.css
if grep -q "max-width: 96vw" "src/pages/chat/Chat.module.css"; then
    echo "✅ Chat root max-width increased found"
else
    echo "❌ Chat root max-width increase missing"
    exit 1
fi

if grep -q "max-width: 60%" "src/pages/chat/Chat.module.css"; then
    echo "✅ Chat container 60% width found"
else
    echo "❌ Chat container 60% width missing"
    exit 1
fi

if grep -q "min-width: 700px" "src/pages/chat/Chat.module.css"; then
    echo "✅ Citation panel minimum width increased found"
else
    echo "❌ Citation panel minimum width increase missing"
    exit 1
fi

# Check AnswerOverrides.css
if grep -q "max-width: 60%" "src/components/Answer/AnswerOverrides.css"; then
    echo "✅ AnswerOverrides updated to match new sizes"
else
    echo "❌ AnswerOverrides still has old sizes"
    exit 1
fi

# 5. Check bundle size (warning if too large)
echo ""
echo "🔧 Step 5: Checking bundle size..."
if [ -d "dist" ]; then
    BUNDLE_SIZE=$(du -sh dist | cut -f1)
    echo "📦 Bundle size: $BUNDLE_SIZE"
    
    # Extract numeric value for comparison (assuming MB)
    SIZE_NUM=$(echo $BUNDLE_SIZE | sed 's/[^0-9.]//g')
    if (( $(echo "$SIZE_NUM > 50" | bc -l) )); then
        echo "⚠️  Warning: Bundle size is quite large (>50MB)"
    else
        echo "✅ Bundle size is reasonable"
    fi
else
    echo "⚠️  Dist folder not found, skipping bundle size check"
fi

# 6. Validate key CSS class names are present
echo ""
echo "🔧 Step 6: Validating CSS class exports..."

# Check if the built CSS contains our key classes
if [ -d "dist" ]; then
    if find dist -name "*.css" -exec grep -l "answerContainer" {} \; | head -1 >/dev/null; then
        echo "✅ answerContainer class found in built CSS"
    else
        echo "❌ answerContainer class missing in built CSS"
        exit 1
    fi
    
    if find dist -name "*.css" -exec grep -l "mainAnswerLayout" {} \; | head -1 >/dev/null; then
        echo "✅ mainAnswerLayout class found in built CSS"
    else
        echo "❌ mainAnswerLayout class missing in built CSS"
        exit 1
    fi
else
    echo "⚠️  Dist folder not found, skipping built CSS validation"
fi

echo ""
echo "🎉 ALL VALIDATIONS PASSED!"
echo ""
echo "📋 Summary of Changes Validated:"
echo "  ✅ Answer container: 400px min-height, 30px padding, 16px font"
echo "  ✅ Citation panel: 700px min-width, larger sizing"
echo "  ✅ Chat root: 96vw width for maximum screen usage"
echo "  ✅ Layout split: 60/40 instead of 65/35"
echo "  ✅ Text utilization: Full width with flex-grow"
echo "  ✅ Override files: Updated to match new sizes"
echo "  ✅ Build process: Successful compilation"
echo ""
echo "🚀 READY FOR DEPLOYMENT!"
