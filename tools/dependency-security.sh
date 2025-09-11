#!/bin/bash

# =============================================================================
# Dependency Security Monitor
# =============================================================================
# Monitors and updates dependencies for security vulnerabilities

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
CHECK_PYTHON=true
CHECK_NODEJS=true
AUTO_FIX=false
REPORT_ONLY=false
SEVERITY_THRESHOLD="medium"

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Dependency Security Monitor - Check and fix vulnerable dependencies

OPTIONS:
    -h, --help              Show this help message
    -p, --python-only       Check only Python dependencies
    -n, --node-only         Check only Node.js dependencies
    -f, --fix               Attempt to fix vulnerabilities automatically
    -r, --report-only       Generate report only, don't attempt fixes
    -s, --severity LEVEL    Minimum severity level (low|medium|high|critical)
    --install-tools         Install required security tools

EXAMPLES:
    $0                      # Check all dependencies
    $0 -f                   # Check and auto-fix vulnerabilities
    $0 -p -f                # Check and fix Python dependencies only
    $0 -r                   # Generate vulnerability report only

EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -p|--python-only)
                CHECK_NODEJS=false
                shift
                ;;
            -n|--node-only)
                CHECK_PYTHON=false
                shift
                ;;
            -f|--fix)
                AUTO_FIX=true
                shift
                ;;
            -r|--report-only)
                REPORT_ONLY=true
                shift
                ;;
            -s|--severity)
                SEVERITY_THRESHOLD="$2"
                shift 2
                ;;
            --install-tools)
                install_tools
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Install security tools
install_tools() {
    echo -e "${BLUE}📦 Installing dependency security tools...${NC}"
    
    # Install safety for Python
    if [ "$CHECK_PYTHON" = true ]; then
        echo "• Installing safety for Python vulnerability scanning..."
        pip install --user safety || echo -e "${YELLOW}⚠️  Failed to install safety${NC}"
    fi
    
    # Install npm-check-updates for Node.js
    if [ "$CHECK_NODEJS" = true ]; then
        echo "• Installing npm tools for Node.js vulnerability scanning..."
        if command -v npm &> /dev/null; then
            npm install -g npm-check-updates @npmcli/arborist || echo -e "${YELLOW}⚠️  Failed to install npm tools${NC}"
        fi
    fi
    
    # Install trivy if not already available
    if ! command -v trivy &> /dev/null; then
        echo "• Installing Trivy for comprehensive vulnerability scanning..."
        if command -v wget &> /dev/null && command -v sudo &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y wget apt-transport-https gnupg lsb-release
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
            sudo apt-get update && sudo apt-get install -y trivy
        else
            echo -e "${YELLOW}⚠️  Cannot install Trivy automatically. Please install manually.${NC}"
        fi
    fi
    
    echo -e "${GREEN}✅ Tool installation completed${NC}"
}

# Check Python dependencies
check_python_dependencies() {
    echo -e "${CYAN}🐍 Checking Python dependencies...${NC}"
    
    local issues=0
    local report_file="$PROJECT_ROOT/security-reports/python-vulns.json"
    mkdir -p "$(dirname "$report_file")"
    
    if [ ! -f "$PROJECT_ROOT/requirements.txt" ]; then
        echo -e "${YELLOW}⚠️  No requirements.txt found${NC}"
        return 0
    fi
    
    # Use safety if available
    if command -v safety &> /dev/null; then
        echo "• Running safety scan..."
        if safety check -r "$PROJECT_ROOT/requirements.txt" --json --output "$report_file" 2>/dev/null; then
            echo -e "${GREEN}  ✅ No known vulnerabilities found by safety${NC}"
        else
            local vuln_count=$(jq length "$report_file" 2>/dev/null || echo "0")
            if [ "$vuln_count" -gt 0 ]; then
                echo -e "${RED}  ❌ Found $vuln_count vulnerabilities${NC}"
                issues=$((issues + vuln_count))
                
                # Show vulnerability details
                if [ "$REPORT_ONLY" = false ]; then
                    echo "    Vulnerabilities found:"
                    jq -r '.[] | "    - \(.package_name) \(.installed_version): \(.vulnerability_id)"' "$report_file" 2>/dev/null || true
                fi
                
                # Auto-fix if requested
                if [ "$AUTO_FIX" = true ]; then
                    echo "  • Attempting to fix Python vulnerabilities..."
                    fix_python_vulnerabilities "$report_file"
                fi
            fi
        fi
    else
        echo -e "${YELLOW}  ⚠️  safety not available - installing...${NC}"
        pip install --user safety 2>/dev/null || echo -e "${RED}    Failed to install safety${NC}"
    fi
    
    # Use trivy if available
    if command -v trivy &> /dev/null; then
        echo "• Running Trivy Python scan..."
        local trivy_report="$PROJECT_ROOT/security-reports/trivy-python.json"
        if trivy fs --format json --output "$trivy_report" "$PROJECT_ROOT/requirements.txt" 2>/dev/null; then
            local trivy_vulns=$(jq '.Results[]?.Vulnerabilities // [] | length' "$trivy_report" 2>/dev/null || echo "0")
            if [ "$trivy_vulns" -gt 0 ]; then
                echo -e "${RED}  ❌ Trivy found $trivy_vulns vulnerabilities${NC}"
                issues=$((issues + trivy_vulns))
            else
                echo -e "${GREEN}  ✅ No vulnerabilities found by Trivy${NC}"
            fi
        fi
    fi
    
    # Check for outdated packages
    echo "• Checking for outdated packages..."
    if pip list --outdated --format=json > "$PROJECT_ROOT/security-reports/python-outdated.json" 2>/dev/null; then
        local outdated_count=$(jq length "$PROJECT_ROOT/security-reports/python-outdated.json" 2>/dev/null || echo "0")
        if [ "$outdated_count" -gt 0 ]; then
            echo -e "${YELLOW}  ⚠️  $outdated_count packages are outdated${NC}"
            if [ "$AUTO_FIX" = true ]; then
                echo "  • Attempting to update outdated packages..."
                update_python_packages
            fi
        else
            echo -e "${GREEN}  ✅ All packages are up to date${NC}"
        fi
    fi
    
    return $issues
}

# Fix Python vulnerabilities
fix_python_vulnerabilities() {
    local report_file="$1"
    
    echo "    • Analyzing vulnerable packages..."
    
    # Extract vulnerable packages and their recommendations
    if jq -e '.[0]' "$report_file" >/dev/null 2>&1; then
        jq -r '.[] | select(.more_info_url != null) | "\(.package_name)>=\(.fixed_version // "latest")"' "$report_file" 2>/dev/null | while read -r package_spec; do
            if [ -n "$package_spec" ]; then
                echo "      Updating: $package_spec"
                pip install --user --upgrade "$package_spec" 2>/dev/null || echo -e "${RED}        Failed to update $package_spec${NC}"
            fi
        done
    fi
}

# Update Python packages
update_python_packages() {
    echo "    • Updating packages to latest secure versions..."
    
    # Update all packages in requirements.txt
    if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        pip install --user -r "$PROJECT_ROOT/requirements.txt" --upgrade 2>/dev/null || echo -e "${RED}      Failed to update some packages${NC}"
    fi
}

# Check Node.js dependencies
check_nodejs_dependencies() {
    echo -e "${CYAN}📦 Checking Node.js dependencies...${NC}"
    
    local issues=0
    local frontend_dir="$PROJECT_ROOT/frontend"
    
    if [ ! -f "$frontend_dir/package.json" ]; then
        echo -e "${YELLOW}⚠️  No package.json found in frontend/${NC}"
        return 0
    fi
    
    cd "$frontend_dir"
    
    # Run npm audit
    echo "• Running npm audit..."
    local audit_report="$PROJECT_ROOT/security-reports/npm-audit.json"
    mkdir -p "$(dirname "$audit_report")"
    
    if npm audit --audit-level="$SEVERITY_THRESHOLD" --json > "$audit_report" 2>/dev/null; then
        echo -e "${GREEN}  ✅ No vulnerabilities found above $SEVERITY_THRESHOLD level${NC}"
    else
        local audit_exit_code=$?
        if [ $audit_exit_code -eq 1 ]; then
            # Parse audit results
            local vuln_info=$(jq -r '.metadata.vulnerabilities | to_entries[] | "\(.key): \(.value)"' "$audit_report" 2>/dev/null)
            if [ -n "$vuln_info" ]; then
                echo -e "${RED}  ❌ npm audit found vulnerabilities:${NC}"
                echo "$vuln_info" | while read -r line; do
                    echo "    $line"
                done
                issues=$((issues + 1))
                
                # Auto-fix if requested
                if [ "$AUTO_FIX" = true ]; then
                    echo "  • Attempting to fix npm vulnerabilities..."
                    fix_npm_vulnerabilities
                fi
            fi
        fi
    fi
    
    # Use trivy for Node.js if available
    if command -v trivy &> /dev/null; then
        echo "• Running Trivy Node.js scan..."
        local trivy_report="$PROJECT_ROOT/security-reports/trivy-nodejs.json"
        if trivy fs --format json --output "$trivy_report" "$frontend_dir/package.json" 2>/dev/null; then
            local trivy_vulns=$(jq '.Results[]?.Vulnerabilities // [] | length' "$trivy_report" 2>/dev/null || echo "0")
            if [ "$trivy_vulns" -gt 0 ]; then
                echo -e "${RED}  ❌ Trivy found $trivy_vulns vulnerabilities${NC}"
                issues=$((issues + trivy_vulns))
            else
                echo -e "${GREEN}  ✅ No vulnerabilities found by Trivy${NC}"
            fi
        fi
    fi
    
    # Check for outdated packages
    echo "• Checking for outdated packages..."
    if npm outdated --json > "$PROJECT_ROOT/security-reports/npm-outdated.json" 2>/dev/null; then
        local outdated_count=$(jq 'keys | length' "$PROJECT_ROOT/security-reports/npm-outdated.json" 2>/dev/null || echo "0")
        if [ "$outdated_count" -gt 0 ]; then
            echo -e "${YELLOW}  ⚠️  $outdated_count packages are outdated${NC}"
            if [ "$AUTO_FIX" = true ]; then
                echo "  • Attempting to update outdated packages..."
                update_npm_packages
            fi
        else
            echo -e "${GREEN}  ✅ All packages are up to date${NC}"
        fi
    fi
    
    cd "$PROJECT_ROOT"
    return $issues
}

# Fix npm vulnerabilities
fix_npm_vulnerabilities() {
    echo "    • Running npm audit fix..."
    if npm audit fix --force 2>/dev/null; then
        echo -e "${GREEN}      ✅ npm audit fix completed${NC}"
    else
        echo -e "${YELLOW}      ⚠️  Some vulnerabilities could not be automatically fixed${NC}"
    fi
}

# Update npm packages
update_npm_packages() {
    echo "    • Updating packages to latest versions..."
    if command -v ncu &> /dev/null; then
        ncu -u && npm install 2>/dev/null || echo -e "${RED}      Failed to update some packages${NC}"
    else
        echo -e "${YELLOW}      npm-check-updates not available - install with: npm install -g npm-check-updates${NC}"
    fi
}

# Generate comprehensive report
generate_report() {
    local total_issues=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="$PROJECT_ROOT/security-reports/dependency-security-report.md"
    
    echo -e "${BLUE}📊 Generating dependency security report...${NC}"
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# Dependency Security Report

**Generated:** $timestamp  
**Severity Threshold:** $SEVERITY_THRESHOLD  
**Auto-fix Enabled:** $([ "$AUTO_FIX" = true ] && echo "Yes" || echo "No")  

## Summary

Total issues found: **$total_issues**

## Scanned Components

$([ "$CHECK_PYTHON" = true ] && echo "- ✅ Python dependencies (requirements.txt)")
$([ "$CHECK_NODEJS" = true ] && echo "- ✅ Node.js dependencies (package.json)")

## Detailed Reports

The following detailed vulnerability reports have been generated:

EOF

    # Add links to detailed reports
    for report in "$PROJECT_ROOT/security-reports"/*.json; do
        if [ -f "$report" ]; then
            local basename=$(basename "$report")
            echo "- [$basename]($basename)" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## Recommendations

### Immediate Actions
$([ $total_issues -eq 0 ] && echo "- ✅ No critical vulnerabilities detected
- Continue regular dependency monitoring
- Keep dependencies up to date" || echo "- ❌ Address the $total_issues security issues identified
- Review vulnerable packages and update or replace them
- Consider implementing automated dependency updates")

### Best Practices
- Enable automated security updates where possible
- Regularly run dependency security scans
- Monitor security advisories for used packages
- Use dependency pinning for critical applications
- Implement security scanning in CI/CD pipeline

### Monitoring Schedule
- **Daily:** Automated vulnerability scanning
- **Weekly:** Dependency update review
- **Monthly:** Comprehensive security assessment
- **Quarterly:** Security policy review

---
*Generated by CoPA Dependency Security Monitor*
EOF

    echo -e "${GREEN}📄 Report generated: $report_file${NC}"
}

# Main execution
main() {
    parse_args "$@"
    
    echo -e "${BLUE}🔍 CoPA Dependency Security Monitor${NC}"
    echo -e "${BLUE}════════════════════════════════════${NC}"
    echo ""
    
    local total_issues=0
    
    # Check Python dependencies
    if [ "$CHECK_PYTHON" = true ]; then
        check_python_dependencies
        total_issues=$((total_issues + $?))
    fi
    
    # Check Node.js dependencies
    if [ "$CHECK_NODEJS" = true ]; then
        check_nodejs_dependencies
        total_issues=$((total_issues + $?))
    fi
    
    # Generate report
    generate_report $total_issues
    
    # Summary
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 Dependency Scan Complete                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ $total_issues -eq 0 ]; then
        echo -e "${GREEN}🎉 No security vulnerabilities found in dependencies!${NC}"
        echo -e "${GREEN}   Continue following secure development practices.${NC}"
    elif [ $total_issues -le 3 ]; then
        echo -e "${YELLOW}⚠️  Found $total_issues dependency security issues.${NC}"
        echo -e "${YELLOW}   Review and address these vulnerabilities.${NC}"
    else
        echo -e "${RED}🚨 Found $total_issues dependency security issues!${NC}"
        echo -e "${RED}   Immediate action required to secure dependencies.${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}💡 To auto-fix vulnerabilities, run:${NC}"
    echo "   $0 --fix"
    echo ""
    
    return $total_issues
}

# Execute main function
main "$@"
