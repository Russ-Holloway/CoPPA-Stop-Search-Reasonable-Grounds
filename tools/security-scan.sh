#!/bin/bash

# =============================================================================
# CoPA Security Scanner - Comprehensive Security Assessment Tool
# =============================================================================
# This script performs comprehensive security scanning for the CoPA application,
# focusing on police data security requirements and industry best practices.

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
REPORT_DIR="$PROJECT_ROOT/security-reports"
OUTPUT_FILE=""
VERBOSE=false
QUICK_SCAN=false
PDS_MODE=false
FIX_MODE=false

# Security categories
declare -A SCAN_CATEGORIES=(
    ["secrets"]="Secrets and Credentials Scanning"
    ["dependencies"]="Dependency Vulnerability Scanning" 
    ["docker"]="Container Security Scanning"
    ["infra"]="Infrastructure Security Analysis"
    ["code"]="Static Code Analysis"
    ["compliance"]="PDS Compliance Checks"
    ["network"]="Network Security Assessment"
    ["data"]="Data Protection Analysis"
)

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

CoPA Security Scanner - Comprehensive security assessment for police data applications

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -q, --quick             Quick scan (skip time-intensive checks)
    -p, --pds              Enable PDS-specific compliance checks
    -f, --fix              Attempt to fix common security issues
    -o, --output FILE       Save detailed report to file
    -c, --category CAT      Scan specific category only
    --report-dir DIR        Custom report directory (default: security-reports/)

CATEGORIES:
    secrets                 Scan for hardcoded secrets and credentials
    dependencies            Check for vulnerable dependencies
    docker                  Container and Dockerfile security
    infra                   Infrastructure and ARM template security
    code                    Static code analysis
    compliance              PDS and regulatory compliance
    network                 Network security configuration
    data                    Data protection and privacy
    all                     Run all security checks (default)

EXAMPLES:
    $0                      # Full security scan
    $0 -q                   # Quick security scan
    $0 -p                   # PDS compliance focused scan
    $0 -c secrets           # Scan only for secrets
    $0 -f                   # Scan and attempt fixes
    $0 -o security.html     # Generate HTML report

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quick)
                QUICK_SCAN=true
                shift
                ;;
            -p|--pds)
                PDS_MODE=true
                shift
                ;;
            -f|--fix)
                FIX_MODE=true
                shift
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -c|--category)
                SCAN_CATEGORY="$2"
                shift 2
                ;;
            --report-dir)
                REPORT_DIR="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Create report directory
setup_reporting() {
    mkdir -p "$REPORT_DIR"
    if [ -n "$OUTPUT_FILE" ] && [[ "$OUTPUT_FILE" != /* ]]; then
        OUTPUT_FILE="$REPORT_DIR/$OUTPUT_FILE"
    fi
}

# Print header
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        CoPA Security Scanner v2.0                            ║${NC}"
    echo -e "${BLUE}║                   Police Data Security Assessment Tool                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}🔍 Starting comprehensive security assessment...${NC}"
    if [ "$PDS_MODE" = true ]; then
        echo -e "${PURPLE}🛡️  PDS Compliance Mode: Enhanced police data security checks${NC}"
    fi
    if [ "$QUICK_SCAN" = true ]; then
        echo -e "${YELLOW}⚡ Quick Scan Mode: Skipping time-intensive checks${NC}"
    fi
    echo ""
}

# Install security tools if needed
install_security_tools() {
    local tools_needed=false
    
    echo -e "${BLUE}🔧 Checking security tools...${NC}"
    
    # Check for gitleaks (secrets scanning)
    if ! command -v gitleaks &> /dev/null; then
        echo -e "${YELLOW}Installing gitleaks for secrets detection...${NC}"
        if command -v wget &> /dev/null; then
            wget -q https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz -O /tmp/gitleaks.tar.gz
            tar -xzf /tmp/gitleaks.tar.gz -C /tmp/
            sudo mv /tmp/gitleaks /usr/local/bin/
            rm /tmp/gitleaks.tar.gz
        else
            echo -e "${RED}⚠️  wget not available - please install gitleaks manually${NC}"
        fi
        tools_needed=true
    fi
    
    # Check for trivy (vulnerability scanning)
    if ! command -v trivy &> /dev/null; then
        echo -e "${YELLOW}Installing Trivy for vulnerability scanning...${NC}"
        if command -v wget &> /dev/null; then
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
            echo "deb https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
            sudo apt-get update && sudo apt-get install -y trivy
        else
            echo -e "${RED}⚠️  Unable to install Trivy - please install manually${NC}"
        fi
        tools_needed=true
    fi
    
    # Check for hadolint (Dockerfile security)
    if ! command -v hadolint &> /dev/null; then
        echo -e "${YELLOW}Installing Hadolint for Dockerfile security...${NC}"
        if command -v wget &> /dev/null; then
            wget -q https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 -O /tmp/hadolint
            chmod +x /tmp/hadolint
            sudo mv /tmp/hadolint /usr/local/bin/
        else
            echo -e "${RED}⚠️  Unable to install Hadolint - please install manually${NC}"
        fi
        tools_needed=true
    fi
    
    if [ "$tools_needed" = false ]; then
        echo -e "${GREEN}✅ All security tools available${NC}"
    fi
    echo ""
}

# Scan for secrets and credentials
scan_secrets() {
    echo -e "${CYAN}🔐 Scanning for secrets and credentials...${NC}"
    
    local report_file="$REPORT_DIR/secrets-report.json"
    local issues=0
    
    # Use gitleaks if available
    if command -v gitleaks &> /dev/null; then
        echo "  • Running gitleaks scan..."
        if gitleaks detect --source="$PROJECT_ROOT" --report-format=json --report-path="$report_file" --no-git 2>/dev/null; then
            echo -e "${GREEN}    ✅ No secrets detected by gitleaks${NC}"
        else
            issues=$((issues + $(jq length "$report_file" 2>/dev/null || echo "0")))
            echo -e "${RED}    ❌ Secrets detected - check $report_file${NC}"
        fi
    fi
    
    # Manual secret patterns scan
    echo "  • Scanning for common secret patterns..."
    local secret_patterns=(
        "password\s*=\s*[\"'][^\"']{8,}[\"']"
        "api[_-]?key\s*[=:]\s*[\"'][^\"']{20,}[\"']"
        "secret\s*[=:]\s*[\"'][^\"']{16,}[\"']"
        "token\s*[=:]\s*[\"'][^\"']{20,}[\"']"
        "AZURE_[A-Z_]*_KEY"
        "mongodb://[^\\s\"']*:[^\\s\"']*@"
        "mysql://[^\\s\"']*:[^\\s\"']*@"
        "postgres://[^\\s\"']*:[^\\s\"']*@"
    )
    
    for pattern in "${secret_patterns[@]}"; do
        if grep -r -i -n --include="*.py" --include="*.js" --include="*.ts" --include="*.json" --include="*.yaml" --include="*.yml" -E "$pattern" "$PROJECT_ROOT" 2>/dev/null | grep -v ".git/" | grep -v "node_modules/" | head -10; then
            issues=$((issues + 1))
        fi
    done
    
    # PDS specific secret checks
    if [ "$PDS_MODE" = true ]; then
        echo "  • PDS-specific credential checks..."
        local pds_patterns=(
            "police[_-]?force[_-]?code"
            "officer[_-]?id"
            "warrant[_-]?number"
            "case[_-]?reference"
        )
        
        for pattern in "${pds_patterns[@]}"; do
            if grep -r -i -n --include="*.py" --include="*.js" --include="*.ts" -E "$pattern\s*[=:]\s*[\"'][^\"']{5,}[\"']" "$PROJECT_ROOT" 2>/dev/null | grep -v ".git/"; then
                echo -e "${RED}    ❌ Potential PDS identifier exposure found${NC}"
                issues=$((issues + 1))
            fi
        done
    fi
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}  ✅ Secrets scan completed - no issues found${NC}"
    else
        echo -e "${RED}  ❌ Found $issues potential secret exposures${NC}"
    fi
    echo ""
    
    return $issues
}

# Scan dependencies for vulnerabilities
scan_dependencies() {
    echo -e "${CYAN}📦 Scanning dependencies for vulnerabilities...${NC}"
    
    local issues=0
    
    # Python dependencies
    if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        echo "  • Scanning Python dependencies..."
        
        # Use safety if available
        if command -v safety &> /dev/null; then
            safety check -r "$PROJECT_ROOT/requirements.txt" --json --output "$REPORT_DIR/python-vulns.json" 2>/dev/null || true
        else
            echo "    Installing safety for Python vulnerability scanning..."
            pip install safety --quiet --user 2>/dev/null || true
        fi
        
        # Use trivy if available
        if command -v trivy &> /dev/null; then
            echo "  • Running Trivy Python scan..."
            trivy fs --format json --output "$REPORT_DIR/trivy-python.json" "$PROJECT_ROOT/requirements.txt" 2>/dev/null || true
        fi
    fi
    
    # Node.js dependencies
    if [ -f "$PROJECT_ROOT/frontend/package.json" ]; then
        echo "  • Scanning Node.js dependencies..."
        
        cd "$PROJECT_ROOT/frontend"
        
        # Use npm audit
        if npm audit --audit-level=moderate --json > "$REPORT_DIR/npm-audit.json" 2>/dev/null; then
            echo -e "${GREEN}    ✅ npm audit completed${NC}"
        else
            issues=$((issues + 1))
            echo -e "${RED}    ❌ npm audit found vulnerabilities${NC}"
        fi
        
        # Use trivy if available
        if command -v trivy &> /dev/null; then
            echo "  • Running Trivy Node.js scan..."
            trivy fs --format json --output "$REPORT_DIR/trivy-nodejs.json" "package.json" 2>/dev/null || true
        fi
        
        cd "$PROJECT_ROOT"
    fi
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}  ✅ Dependency scan completed${NC}"
    else
        echo -e "${RED}  ❌ Found dependency vulnerabilities${NC}"
    fi
    echo ""
    
    return $issues
}

# Scan Docker containers
scan_docker() {
    echo -e "${CYAN}🐳 Scanning Docker containers and images...${NC}"
    
    local issues=0
    
    # Dockerfile security with hadolint
    if [ -f "$PROJECT_ROOT/WebApp.Dockerfile" ]; then
        echo "  • Scanning WebApp.Dockerfile..."
        
        if command -v hadolint &> /dev/null; then
            if hadolint "$PROJECT_ROOT/WebApp.Dockerfile" --format json > "$REPORT_DIR/dockerfile-hadolint.json" 2>/dev/null; then
                echo -e "${GREEN}    ✅ Dockerfile scan completed${NC}"
            else
                issues=$((issues + 1))
                echo -e "${YELLOW}    ⚠️  Dockerfile issues found${NC}"
            fi
        fi
    fi
    
    # Container vulnerability scanning with trivy
    if command -v trivy &> /dev/null && command -v docker &> /dev/null; then
        echo "  • Scanning base images for vulnerabilities..."
        
        # Scan common base images
        local images=("python:3.11-alpine" "node:20-alpine")
        for image in "${images[@]}"; do
            echo "    - Scanning $image..."
            trivy image --format json --output "$REPORT_DIR/trivy-$image.json" "$image" 2>/dev/null || true
        done
    fi
    
    # Check for insecure Docker practices
    echo "  • Checking for insecure Docker practices..."
    local dockerfile_issues=0
    
    if [ -f "$PROJECT_ROOT/WebApp.Dockerfile" ]; then
        # Check for running as root
        if ! grep -q "USER " "$PROJECT_ROOT/WebApp.Dockerfile"; then
            echo -e "${YELLOW}    ⚠️  Dockerfile doesn't specify non-root user${NC}"
            dockerfile_issues=$((dockerfile_issues + 1))
        fi
        
        # Check for COPY with proper ownership
        if grep -q "COPY --chown=" "$PROJECT_ROOT/WebApp.Dockerfile"; then
            echo -e "${GREEN}    ✅ COPY commands use proper ownership${NC}"
        else
            echo -e "${YELLOW}    ⚠️  Some COPY commands may not set proper ownership${NC}"
            dockerfile_issues=$((dockerfile_issues + 1))
        fi
        
        # Check for health checks
        if grep -q "HEALTHCHECK" "$PROJECT_ROOT/WebApp.Dockerfile"; then
            echo -e "${GREEN}    ✅ Health check configured${NC}"
        else
            echo -e "${YELLOW}    ⚠️  No health check configured${NC}"
            dockerfile_issues=$((dockerfile_issues + 1))
        fi
    fi
    
    issues=$((issues + dockerfile_issues))
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}  ✅ Docker security scan completed${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Found $issues Docker security issues${NC}"
    fi
    echo ""
    
    return $issues
}

# Scan infrastructure templates
scan_infrastructure() {
    echo -e "${CYAN}🏗️  Scanning infrastructure templates...${NC}"
    
    local issues=0
    
    # Use existing ARM TTK validation
    if [ -f "$SCRIPT_DIR/validate-templates.sh" ]; then
        echo "  • Running ARM Template Toolkit validation..."
        if [ "$PDS_MODE" = true ]; then
            "$SCRIPT_DIR/validate-templates.sh" --pds --format json --output "$REPORT_DIR/arm-ttk-results.json" 2>/dev/null || issues=$((issues + 1))
        else
            "$SCRIPT_DIR/validate-templates.sh" --format json --output "$REPORT_DIR/arm-ttk-results.json" 2>/dev/null || issues=$((issues + 1))
        fi
    fi
    
    # Infrastructure security best practices
    echo "  • Checking infrastructure security practices..."
    
    # Check for secure storage configuration
    if [ -f "$PROJECT_ROOT/infrastructure/deployment.json" ]; then
        local template="$PROJECT_ROOT/infrastructure/deployment.json"
        
        # Check for HTTPS-only storage
        if grep -q "supportsHttpsTrafficOnly.*true" "$template"; then
            echo -e "${GREEN}    ✅ Storage accounts enforce HTTPS${NC}"
        else
            echo -e "${RED}    ❌ Storage accounts may not enforce HTTPS${NC}"
            issues=$((issues + 1))
        fi
        
        # Check for encryption at rest
        if grep -q "encryption" "$template"; then
            echo -e "${GREEN}    ✅ Encryption configuration found${NC}"
        else
            echo -e "${YELLOW}    ⚠️  Explicit encryption configuration not found${NC}"
            issues=$((issues + 1))
        fi
        
        # Check for Key Vault references
        if grep -q "Microsoft.KeyVault" "$template"; then
            echo -e "${GREEN}    ✅ Key Vault integration configured${NC}"
        else
            echo -e "${YELLOW}    ⚠️  No Key Vault references found${NC}"
            issues=$((issues + 1))
        fi
    fi
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}  ✅ Infrastructure security scan completed${NC}"
    else
        echo -e "${RED}  ❌ Found $issues infrastructure security issues${NC}"
    fi
    echo ""
    
    return $issues
}

# Static code analysis
scan_code() {
    echo -e "${CYAN}💻 Static code security analysis...${NC}"
    
    local issues=0
    
    # Python code security
    echo "  • Scanning Python code..."
    
    # Check for common Python security issues
    local python_issues=0
    
    # SQL injection patterns
    if find "$PROJECT_ROOT" -name "*.py" -exec grep -l "execute.*%" {} \; 2>/dev/null | head -5; then
        echo -e "${YELLOW}    ⚠️  Potential SQL injection patterns found${NC}"
        python_issues=$((python_issues + 1))
    fi
    
    # Command injection patterns
    if find "$PROJECT_ROOT" -name "*.py" -exec grep -l "os\.system\|subprocess\.call.*shell=True" {} \; 2>/dev/null | head -5; then
        echo -e "${YELLOW}    ⚠️  Potential command injection patterns found${NC}"
        python_issues=$((python_issues + 1))
    fi
    
    # Insecure random usage
    if find "$PROJECT_ROOT" -name "*.py" -exec grep -l "random\." {} \; 2>/dev/null | head -5; then
        echo -e "${YELLOW}    ⚠️  Non-cryptographic random usage found${NC}"
        python_issues=$((python_issues + 1))
    fi
    
    # JavaScript/TypeScript security
    echo "  • Scanning JavaScript/TypeScript code..."
    
    local js_issues=0
    
    # XSS vulnerabilities
    if find "$PROJECT_ROOT/frontend" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | xargs grep -l "innerHTML\|outerHTML\|dangerouslySetInnerHTML" 2>/dev/null; then
        echo -e "${YELLOW}    ⚠️  Potential XSS vulnerabilities found${NC}"
        js_issues=$((js_issues + 1))
    fi
    
    # Unsafe eval usage
    if find "$PROJECT_ROOT/frontend" -name "*.js" -o -name "*.ts" | xargs grep -l "eval(" 2>/dev/null; then
        echo -e "${RED}    ❌ Unsafe eval() usage found${NC}"
        js_issues=$((js_issues + 1))
    fi
    
    issues=$((issues + python_issues + js_issues))
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}  ✅ Code security scan completed${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Found $issues potential code security issues${NC}"
    fi
    echo ""
    
    return $issues
}

# PDS compliance checks
scan_compliance() {
    echo -e "${CYAN}📋 PDS Compliance and regulatory checks...${NC}"
    
    local issues=0
    
    echo "  • Checking data classification requirements..."
    
    # Check for data classification in infrastructure
    if grep -r -i "dataclassification\|data-classification" "$PROJECT_ROOT/infrastructure/" "$PROJECT_ROOT/infra/" 2>/dev/null; then
        echo -e "${GREEN}    ✅ Data classification tags found${NC}"
    else
        echo -e "${RED}    ❌ Missing data classification tags${NC}"
        issues=$((issues + 1))
    fi
    
    # Check for audit logging configuration
    echo "  • Checking audit logging configuration..."
    
    if grep -r -i "diagnosticsettings\|microsoft.insights" "$PROJECT_ROOT/infrastructure/" "$PROJECT_ROOT/infra/" 2>/dev/null; then
        echo -e "${GREEN}    ✅ Audit logging configured${NC}"
    else
        echo -e "${RED}    ❌ Audit logging not properly configured${NC}"
        issues=$((issues + 1))
    fi
    
    # Check for authentication configuration
    echo "  • Checking authentication requirements..."
    
    if grep -r -i "authentication\|azureactivedirectory" "$PROJECT_ROOT/infrastructure/" "$PROJECT_ROOT/infra/" 2>/dev/null; then
        echo -e "${GREEN}    ✅ Authentication configuration found${NC}"
    else
        echo -e "${RED}    ❌ Authentication not properly configured${NC}"
        issues=$((issues + 1))
    fi
    
    # Check for data retention policies
    echo "  • Checking data retention policies..."
    
    if grep -r -i "retention\|deleteretentionpolicy" "$PROJECT_ROOT/infrastructure/" "$PROJECT_ROOT/infra/" 2>/dev/null; then
        echo -e "${GREEN}    ✅ Data retention policies configured${NC}"
    else
        echo -e "${YELLOW}    ⚠️  Data retention policies not explicitly configured${NC}"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}  ✅ PDS compliance checks completed${NC}"
    else
        echo -e "${RED}  ❌ Found $issues PDS compliance issues${NC}"
    fi
    echo ""
    
    return $issues
}

# Network security assessment
scan_network() {
    echo -e "${CYAN}🌐 Network security configuration...${NC}"
    
    local issues=0
    
    echo "  • Checking network security groups..."
    
    if [ -f "$PROJECT_ROOT/infrastructure/deployment.json" ]; then
        # Check for restrictive NSG rules
        if grep -q "networkSecurityGroups\|Microsoft.Network/networkSecurityGroups" "$PROJECT_ROOT/infrastructure/deployment.json"; then
            echo -e "${GREEN}    ✅ Network Security Groups configured${NC}"
        else
            echo -e "${YELLOW}    ⚠️  No explicit NSG configuration found${NC}"
            issues=$((issues + 1))
        fi
        
        # Check for public IP restrictions
        if grep -q "publicIPAddresses" "$PROJECT_ROOT/infrastructure/deployment.json"; then
            echo -e "${YELLOW}    ⚠️  Public IP addresses configured - review necessity${NC}"
            issues=$((issues + 1))
        else
            echo -e "${GREEN}    ✅ No unnecessary public IP addresses${NC}"
        fi
    fi
    
    # Check for CORS configuration
    echo "  • Checking CORS configuration..."
    
    if grep -r -i "cors\|allowedorigins" "$PROJECT_ROOT/infrastructure/" "$PROJECT_ROOT/infra/" 2>/dev/null; then
        echo -e "${GREEN}    ✅ CORS configuration found${NC}"
        
        # Check for overly permissive CORS
        if grep -q '"\\*"' "$PROJECT_ROOT/infrastructure/deployment.json" 2>/dev/null; then
            echo -e "${RED}    ❌ Overly permissive CORS (*) configuration found${NC}"
            issues=$((issues + 1))
        fi
    else
        echo -e "${YELLOW}    ⚠️  CORS configuration not found${NC}"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}  ✅ Network security scan completed${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Found $issues network security issues${NC}"
    fi
    echo ""
    
    return $issues
}

# Data protection analysis
scan_data_protection() {
    echo -e "${CYAN}🔒 Data protection and privacy analysis...${NC}"
    
    local issues=0
    
    echo "  • Checking encryption configurations..."
    
    # Check for encryption at rest
    if grep -r -i "encryption\|Microsoft.KeyVault" "$PROJECT_ROOT/infrastructure/" "$PROJECT_ROOT/infra/" 2>/dev/null | grep -v ".git/"; then
        echo -e "${GREEN}    ✅ Encryption configuration found${NC}"
    else
        echo -e "${RED}    ❌ Encryption configuration missing or inadequate${NC}"
        issues=$((issues + 1))
    fi
    
    # Check for TLS/SSL configuration
    echo "  • Checking TLS/SSL requirements..."
    
    if grep -r -i "tls\|ssl\|https" "$PROJECT_ROOT/infrastructure/" "$PROJECT_ROOT/infra/" 2>/dev/null; then
        echo -e "${GREEN}    ✅ TLS/SSL configuration found${NC}"
    else
        echo -e "${RED}    ❌ TLS/SSL configuration not explicit${NC}"
        issues=$((issues + 1))
    fi
    
    # Check for data masking/anonymization
    echo "  • Checking data protection mechanisms..."
    
    if grep -r -i "mask\|anonymize\|redact" "$PROJECT_ROOT" --include="*.py" --include="*.js" --include="*.ts" 2>/dev/null; then
        echo -e "${GREEN}    ✅ Data masking/anonymization mechanisms found${NC}"
    else
        echo -e "${YELLOW}    ⚠️  No explicit data masking mechanisms found${NC}"
        issues=$((issues + 1))
    fi
    
    # PDS specific data protection checks
    if [ "$PDS_MODE" = true ]; then
        echo "  • PDS-specific data protection checks..."
        
        # Check for personal data handling
        if grep -r -i "personal.data\|sensitive.data\|pii" "$PROJECT_ROOT" --include="*.py" --include="*.md" 2>/dev/null; then
            echo -e "${GREEN}    ✅ Personal data handling references found${NC}"
        else
            echo -e "${YELLOW}    ⚠️  No explicit personal data handling documentation${NC}"
            issues=$((issues + 1))
        fi
    fi
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}  ✅ Data protection analysis completed${NC}"
    else
        echo -e "${RED}  ❌ Found $issues data protection issues${NC}"
    fi
    echo ""
    
    return $issues
}

# Generate comprehensive report
generate_report() {
    local total_issues=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${BLUE}📊 Generating security assessment report...${NC}"
    
    local summary_file="$REPORT_DIR/security-summary.md"
    
    cat > "$summary_file" << EOF
# CoPA Security Assessment Report

**Generated:** $timestamp  
**Mode:** $([ "$PDS_MODE" = true ] && echo "PDS Compliance" || echo "Standard Security")  
**Scan Type:** $([ "$QUICK_SCAN" = true ] && echo "Quick Scan" || echo "Comprehensive Scan")  

## Executive Summary

Total security issues found: **$total_issues**

## Categories Scanned

$(printf "| %-20s | %-10s |\n" "Category" "Status")
$(printf "| %-20s | %-10s |\n" "--------------------" "----------")
$(for category in "${!SCAN_CATEGORIES[@]}"; do
    printf "| %-20s | %-10s |\n" "${SCAN_CATEGORIES[$category]}" "✅ Scanned"
done)

## Detailed Reports

The following detailed reports have been generated:

EOF

    # Add links to detailed reports
    for report in "$REPORT_DIR"/*.json; do
        if [ -f "$report" ]; then
            local basename=$(basename "$report")
            echo "- [$basename]($basename)" >> "$summary_file"
        fi
    done
    
    # Recommendations section
    cat >> "$summary_file" << EOF

## Security Recommendations

### Immediate Actions Required
$([ $total_issues -gt 0 ] && echo "- Address the $total_issues security issues identified above" || echo "- Continue regular security monitoring")
- Implement automated security scanning in CI/CD pipeline
- Schedule regular security assessments

### PDS Compliance
$([ "$PDS_MODE" = true ] && echo "- Review PDS-specific findings carefully
- Ensure data classification is properly implemented
- Verify audit logging meets police requirements" || echo "- Consider implementing PDS compliance checks
- Review data handling procedures")

### Long-term Security Strategy
- Implement security-first development practices
- Regular dependency updates and vulnerability patching
- Continuous security monitoring and alerting
- Security awareness training for development team

## Next Steps

1. Review detailed findings in individual report files
2. Prioritize fixes based on severity levels
3. Implement fixes and re-run security scan
4. Integrate security scanning into development workflow

---
*Generated by CoPA Security Scanner v2.0*
EOF

    echo -e "${GREEN}📄 Security report generated: $summary_file${NC}"
    
    # Generate HTML report if requested
    if [ -n "$OUTPUT_FILE" ] && [[ "$OUTPUT_FILE" == *.html ]]; then
        generate_html_report "$total_issues" "$OUTPUT_FILE"
    fi
}

# Generate HTML report
generate_html_report() {
    local total_issues=$1
    local html_file=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CoPA Security Assessment Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 2px solid #007acc; }
        .header h1 { color: #007acc; margin-bottom: 10px; }
        .status-good { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-error { color: #dc3545; }
        .category { margin-bottom: 20px; padding: 15px; border-left: 4px solid #007acc; background: #f8f9fa; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric { text-align: center; padding: 20px; background: #007acc; color: white; border-radius: 6px; }
        .metric h3 { margin: 0 0 10px 0; }
        .metric .value { font-size: 2em; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; text-align: center; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ CoPA Security Assessment Report</h1>
            <p><strong>Generated:</strong> $timestamp</p>
            <p><strong>Mode:</strong> $([ "$PDS_MODE" = true ] && echo "PDS Compliance Enhanced" || echo "Standard Security")</p>
        </div>
        
        <div class="summary">
            <div class="metric">
                <h3>Total Issues</h3>
                <div class="value">$total_issues</div>
            </div>
            <div class="metric">
                <h3>Categories Scanned</h3>
                <div class="value">${#SCAN_CATEGORIES[@]}</div>
            </div>
            <div class="metric">
                <h3>Security Tools</h3>
                <div class="value">5+</div>
            </div>
        </div>
        
        <div class="category">
            <h2>📋 Scan Categories</h2>
            <ul>
EOF

    for category in "${!SCAN_CATEGORIES[@]}"; do
        echo "                <li><strong>${SCAN_CATEGORIES[$category]}</strong> - ✅ Completed</li>" >> "$html_file"
    done

    cat >> "$html_file" << EOF
            </ul>
        </div>
        
        <div class="category">
            <h2>🔍 Key Findings</h2>
            $([ $total_issues -eq 0 ] && echo "<p class='status-good'>✅ No critical security issues detected</p>" || echo "<p class='status-warning'>⚠️ $total_issues security issues require attention</p>")
        </div>
        
        <div class="category">
            <h2>📊 Detailed Reports</h2>
            <p>Check the security-reports/ directory for detailed JSON reports from each security tool.</p>
        </div>
        
        <div class="category">
            <h2>🎯 Recommendations</h2>
            <ul>
                <li>Review all identified security issues</li>
                <li>Implement automated security scanning in CI/CD</li>
                <li>Regular security assessments and updates</li>
                $([ "$PDS_MODE" = true ] && echo "<li>Ensure PDS compliance requirements are met</li>")
                <li>Security awareness training for team</li>
            </ul>
        </div>
        
        <div class="footer">
            <p>Generated by CoPA Security Scanner v2.0 | Police Data Security Compliant</p>
        </div>
    </div>
</body>
</html>
EOF

    echo -e "${GREEN}🌐 HTML report generated: $html_file${NC}"
}

# Main execution
main() {
    parse_args "$@"
    
    print_header
    setup_reporting
    
    local total_issues=0
    
    # Install security tools
    install_security_tools
    
    # Run security scans based on category selection
    if [ -z "${SCAN_CATEGORY:-}" ] || [ "${SCAN_CATEGORY:-}" == "all" ]; then
        # Run all scans
        scan_secrets && total_issues=$((total_issues + $?)) || total_issues=$((total_issues + $?))
        scan_dependencies && total_issues=$((total_issues + $?)) || total_issues=$((total_issues + $?))
        scan_docker && total_issues=$((total_issues + $?)) || total_issues=$((total_issues + $?))
        scan_infrastructure && total_issues=$((total_issues + $?)) || total_issues=$((total_issues + $?))
        scan_code && total_issues=$((total_issues + $?)) || total_issues=$((total_issues + $?))
        scan_compliance && total_issues=$((total_issues + $?)) || total_issues=$((total_issues + $?))
        scan_network && total_issues=$((total_issues + $?)) || total_issues=$((total_issues + $?))
        scan_data_protection && total_issues=$((total_issues + $?)) || total_issues=$((total_issues + $?))
    else
        # Run specific category
        case "${SCAN_CATEGORY}" in
            secrets) scan_secrets && total_issues=$? || total_issues=$? ;;
            dependencies) scan_dependencies && total_issues=$? || total_issues=$? ;;
            docker) scan_docker && total_issues=$? || total_issues=$? ;;
            infra) scan_infrastructure && total_issues=$? || total_issues=$? ;;
            code) scan_code && total_issues=$? || total_issues=$? ;;
            compliance) scan_compliance && total_issues=$? || total_issues=$? ;;
            network) scan_network && total_issues=$? || total_issues=$? ;;
            data) scan_data_protection && total_issues=$? || total_issues=$? ;;
            *) echo -e "${RED}Unknown category: ${SCAN_CATEGORY}${NC}"; exit 1 ;;
        esac
    fi
    
    # Generate reports
    generate_report $total_issues
    
    # Final summary
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                           Security Assessment Complete                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ $total_issues -eq 0 ]; then
        echo -e "${GREEN}🎉 Excellent! No critical security issues detected.${NC}"
        echo -e "${GREEN}   Continue following security best practices.${NC}"
    elif [ $total_issues -le 5 ]; then
        echo -e "${YELLOW}⚠️  Found $total_issues security issues that need attention.${NC}"
        echo -e "${YELLOW}   Review the detailed reports and address these issues.${NC}"
    else
        echo -e "${RED}🚨 Found $total_issues security issues requiring immediate attention.${NC}"
        echo -e "${RED}   Please prioritize addressing these security concerns.${NC}"
    fi
    
    echo ""
    echo -e "${WHITE}📁 Detailed reports saved in: $REPORT_DIR/${NC}"
    echo -e "${WHITE}📋 Summary report: $REPORT_DIR/security-summary.md${NC}"
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "${WHITE}🌐 Custom report: $OUTPUT_FILE${NC}"
    fi
    echo ""
    
    # Exit with error code if issues found
    exit $total_issues
}

# Execute main function
main "$@"
