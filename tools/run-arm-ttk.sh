#!/bin/bash

# Simple ARM TTK runner for CoPA templates
# Usage: ./tools/run-arm-ttk.sh [template-path]

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."
ARM_TTK_PATH="./tools/arm-ttk/arm-ttk/arm-ttk.psd1"

# Default to main deployment template if no path provided
TEMPLATE_PATH="${1:-./infrastructure/deployment.json}"

echo "🛡️ Running ARM Template Toolkit validation..."
echo "📄 Template: $TEMPLATE_PATH"
echo "════════════════════════════════════════════════"

# Check if template exists
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "❌ Template file not found: $TEMPLATE_PATH"
    exit 1
fi

# Run ARM TTK validation
pwsh -c "
    Import-Module '$ARM_TTK_PATH'
    \$results = Test-AzTemplate -TemplatePath '$TEMPLATE_PATH'
    
    # Count results
    \$passed = (\$results | Where-Object { \$_.Passed -eq \$true }).Count
    \$failed = (\$results | Where-Object { \$_.Passed -eq \$false }).Count
    \$total = \$results.Count
    
    Write-Host ''
    Write-Host '📊 SUMMARY:' -ForegroundColor Cyan
    Write-Host \"✅ Passed: \$passed\" -ForegroundColor Green
    Write-Host \"❌ Failed: \$failed\" -ForegroundColor Red
    Write-Host \"📋 Total:  \$total\" -ForegroundColor White
    Write-Host ''
    
    # Show failed tests details
    if (\$failed -gt 0) {
        Write-Host '❌ FAILED TESTS:' -ForegroundColor Red
        \$results | Where-Object { \$_.Passed -eq \$false } | ForEach-Object {
            Write-Host \"   • \$(\$_.Name)\" -ForegroundColor Red
            if (\$_.Errors.Count -gt 0) {
                \$_.Errors | ForEach-Object {
                    Write-Host \"     → \$_\" -ForegroundColor Yellow
                }
            }
        }
        Write-Host ''
    }
    
    # Show detailed results in table format
    Write-Host '📋 DETAILED RESULTS:' -ForegroundColor Cyan
    \$results | Format-Table Name, Passed, @{Label='Issues'; Expression={ if (\$_.Errors.Count -gt 0) { \$_.Errors.Count } else { '' } }} -AutoSize
    
    # Exit with error code if any tests failed
    if (\$failed -gt 0) {
        exit 1
    } else {
        Write-Host '🎉 All tests passed!' -ForegroundColor Green
        exit 0
    }
"
