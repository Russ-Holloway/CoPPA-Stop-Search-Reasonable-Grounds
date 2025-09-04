#!/bin/bash

# =============================================================================
# Git Security Hooks Setup Script
# =============================================================================
# Sets up pre-commit and pre-push hooks to run security checks automatically

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo -e "${BLUE}🔒 Setting up Git security hooks for CoPPA...${NC}"
echo ""

# Ensure hooks directory exists
mkdir -p "$HOOKS_DIR"

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Git pre-commit hook for CoPPA Security Checks

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Running pre-commit security checks...${NC}"

# Get project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TOOLS_DIR="$PROJECT_ROOT/tools"

# Quick secrets scan on staged files
echo "• Checking staged files for secrets..."
if git diff --cached --name-only | grep -E '\.(py|js|ts|json|yaml|yml)$' | xargs grep -l -i -E '(password|secret|key|token)\s*[=:]\s*[\"'\''][^\"'\'']{8,}' 2>/dev/null; then
    echo -e "${RED}❌ Potential secrets detected in staged files!${NC}"
    echo -e "${RED}   Please review and remove any hardcoded credentials.${NC}"
    exit 1
fi

# Check for debug/console statements in production code
echo "• Checking for debug statements..."
if git diff --cached --name-only | grep -E '\.(py|js|ts)$' | xargs grep -l -E '(console\.log|print\(.*debug|debugger|pdb\.set_trace)' 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Debug statements found in staged files.${NC}"
    echo -e "${YELLOW}   Consider removing debug code before committing.${NC}"
fi

# Check for TODO/FIXME in critical files
echo "• Checking for unresolved TODOs in critical paths..."
if git diff --cached --name-only | grep -E '(security|auth|credential)' | xargs grep -l -i -E '(TODO|FIXME|XXX|HACK)' 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Unresolved TODOs found in security-related files.${NC}"
    echo -e "${YELLOW}   Please address before committing.${NC}"
fi

echo -e "${GREEN}✅ Pre-commit security checks passed${NC}"
EOF

# Create pre-push hook
cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash
# Git pre-push hook for CoPPA Security Checks

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Running pre-push security validation...${NC}"

# Get project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TOOLS_DIR="$PROJECT_ROOT/tools"

# Run quick security scan before push
if [ -f "$TOOLS_DIR/security-scan.sh" ]; then
    echo "• Running quick security scan..."
    if ! "$TOOLS_DIR/security-scan.sh" -q; then
        echo -e "${RED}❌ Security scan failed!${NC}"
        echo -e "${RED}   Please address security issues before pushing.${NC}"
        echo -e "${YELLOW}   Run './tools/security-scan.sh' for detailed analysis.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Security scan script not found. Skipping security check.${NC}"
fi

# Validate ARM templates if changed
if git diff --name-only HEAD~1..HEAD | grep -E '\.(json|bicep)$' > /dev/null; then
    echo "• Validating ARM templates..."
    if [ -f "$TOOLS_DIR/validate-templates.sh" ]; then
        if ! "$TOOLS_DIR/validate-templates.sh" --quick 2>/dev/null; then
            echo -e "${YELLOW}⚠️  ARM template validation warnings found.${NC}"
            echo -e "${YELLOW}   Review template changes carefully.${NC}"
        fi
    fi
fi

echo -e "${GREEN}✅ Pre-push security validation passed${NC}"
EOF

# Make hooks executable
chmod +x "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-push"

echo -e "${GREEN}✅ Git security hooks installed successfully!${NC}"
echo ""
echo -e "${YELLOW}Hooks installed:${NC}"
echo "• pre-commit: Quick secrets and debug statement checks"
echo "• pre-push: Comprehensive security scan before push"
echo ""
echo -e "${BLUE}💡 To bypass hooks temporarily (not recommended):${NC}"
echo "   git commit --no-verify"
echo "   git push --no-verify"
echo ""
