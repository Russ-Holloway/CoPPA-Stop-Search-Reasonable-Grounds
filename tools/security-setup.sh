#!/bin/bash

# =============================================================================
# CoPA Security Setup Script
# =============================================================================
# Comprehensive security setup and validation for the CoPA application

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
FULL_SETUP=false
QUICK_SETUP=false
PDS_MODE=false
INSTALL_TOOLS=true
SETUP_HOOKS=true
RUN_INITIAL_SCAN=true

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

CoPA Security Setup - Complete security configuration for police data applications

OPTIONS:
    -h, --help              Show this help message
    -f, --full              Full security setup (all features)
    -q, --quick             Quick setup (essential security only)
    -p, --pds               Enable PDS compliance mode
    --no-tools              Skip security tools installation
    --no-hooks              Skip Git hooks setup
    --no-scan               Skip initial security scan
    --setup-only            Setup only, don't run validation

SETUP COMPONENTS:
    • Security tools installation (gitleaks, trivy, safety, hadolint)
    • Git security hooks (pre-commit, pre-push)
    • Security configuration validation
    • Initial comprehensive security scan
    • Security documentation generation
    • CI/CD security integration templates

EXAMPLES:
    $0                      # Standard security setup
    $0 -f                   # Full security setup with all features
    $0 -q                   # Quick setup for development
    $0 -p                   # PDS compliance focused setup

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
            -f|--full)
                FULL_SETUP=true
                shift
                ;;
            -q|--quick)
                QUICK_SETUP=true
                shift
                ;;
            -p|--pds)
                PDS_MODE=true
                shift
                ;;
            --no-tools)
                INSTALL_TOOLS=false
                shift
                ;;
            --no-hooks)
                SETUP_HOOKS=false
                shift
                ;;
            --no-scan)
                RUN_INITIAL_SCAN=false
                shift
                ;;
            --setup-only)
                RUN_INITIAL_SCAN=false
                shift
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Print header
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                           CoPA Security Setup v2.0                           ║${NC}"
    echo -e "${BLUE}║                    Comprehensive Security Configuration                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}🔒 Configuring security for police data application...${NC}"
    
    if [ "$PDS_MODE" = true ]; then
        echo -e "${PURPLE}🛡️  PDS Compliance Mode: Enhanced police data security${NC}"
    fi
    
    if [ "$FULL_SETUP" = true ]; then
        echo -e "${CYAN}⚡ Full Setup Mode: All security features enabled${NC}"
    elif [ "$QUICK_SETUP" = true ]; then
        echo -e "${YELLOW}🚀 Quick Setup Mode: Essential security only${NC}"
    fi
    
    echo ""
}

# Check system requirements
check_requirements() {
    echo -e "${CYAN}🔍 Checking system requirements...${NC}"
    
    local missing_deps=()
    
    # Check for required system tools
    local required_tools=("git" "curl" "wget" "jq" "python3" "pip3" "node" "npm")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_deps+=("$tool")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing required dependencies: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}   Please install missing dependencies before proceeding.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ System requirements satisfied${NC}"
    return 0
}

# Install security tools
install_security_tools() {
    if [ "$INSTALL_TOOLS" = false ]; then
        echo -e "${YELLOW}⏭️  Skipping security tools installation${NC}"
        return 0
    fi
    
    echo -e "${CYAN}🛠️  Installing security tools...${NC}"
    
    # Install gitleaks for secret detection
    if ! command -v gitleaks &> /dev/null; then
        echo "• Installing gitleaks..."
        local gitleaks_version="8.18.0"
        local gitleaks_url="https://github.com/gitleaks/gitleaks/releases/download/v${gitleaks_version}/gitleaks_${gitleaks_version}_linux_x64.tar.gz"
        
        curl -sL "$gitleaks_url" | tar -xz -C /tmp/
        sudo mv /tmp/gitleaks /usr/local/bin/
        echo -e "${GREEN}  ✅ gitleaks installed${NC}"
    else
        echo -e "${GREEN}• gitleaks already available${NC}"
    fi
    
    # Install Trivy for vulnerability scanning
    if ! command -v trivy &> /dev/null; then
        echo "• Installing Trivy..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq wget apt-transport-https gnupg lsb-release
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update -qq && sudo apt-get install -y -qq trivy
        echo -e "${GREEN}  ✅ Trivy installed${NC}"
    else
        echo -e "${GREEN}• Trivy already available${NC}"
    fi
    
    # Install Hadolint for Dockerfile security
    if ! command -v hadolint &> /dev/null; then
        echo "• Installing Hadolint..."
        local hadolint_version="2.12.0"
        local hadolint_url="https://github.com/hadolint/hadolint/releases/download/v${hadolint_version}/hadolint-Linux-x86_64"
        
        curl -sL "$hadolint_url" -o /tmp/hadolint
        chmod +x /tmp/hadolint
        sudo mv /tmp/hadolint /usr/local/bin/
        echo -e "${GREEN}  ✅ Hadolint installed${NC}"
    else
        echo -e "${GREEN}• Hadolint already available${NC}"
    fi
    
    # Install Python security tools
    echo "• Installing Python security tools..."
    pip3 install --user --upgrade safety bandit semgrep 2>/dev/null || echo -e "${YELLOW}  ⚠️  Some Python tools failed to install${NC}"
    
    # Install Node.js security tools
    if command -v npm &> /dev/null; then
        echo "• Installing Node.js security tools..."
        npm install -g npm-check-updates @npmcli/arborist 2>/dev/null || echo -e "${YELLOW}  ⚠️  Some Node.js tools failed to install${NC}"
    fi
    
    echo -e "${GREEN}✅ Security tools installation completed${NC}"
    echo ""
}

# Setup Git security hooks
setup_git_hooks() {
    if [ "$SETUP_HOOKS" = false ]; then
        echo -e "${YELLOW}⏭️  Skipping Git hooks setup${NC}"
        return 0
    fi
    
    echo -e "${CYAN}🔗 Setting up Git security hooks...${NC}"
    
    if [ -f "$SCRIPT_DIR/setup-git-hooks.sh" ]; then
        "$SCRIPT_DIR/setup-git-hooks.sh"
    else
        echo -e "${YELLOW}⚠️  Git hooks setup script not found${NC}"
    fi
    
    echo ""
}

# Validate security configuration
validate_configuration() {
    echo -e "${CYAN}⚙️  Validating security configuration...${NC}"
    
    local config_file="$SCRIPT_DIR/security-config.yaml"
    local issues=0
    
    # Check if configuration file exists
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ Security configuration file missing: $config_file${NC}"
        issues=$((issues + 1))
    else
        echo -e "${GREEN}✅ Security configuration file found${NC}"
    fi
    
    # Validate environment variables for security
    echo "• Checking environment variables..."
    local env_issues=0
    
    # Check for common insecure environment variables
    if env | grep -i -E '(password|secret|key)=' | grep -v 'PATH\|HOME\|USER' | head -5; then
        echo -e "${YELLOW}  ⚠️  Potential secrets in environment variables${NC}"
        env_issues=$((env_issues + 1))
    fi
    
    if [ $env_issues -eq 0 ]; then
        echo -e "${GREEN}  ✅ Environment variables look secure${NC}"
    fi
    
    # Check security tools availability
    echo "• Verifying security tools..."
    local tools=("gitleaks" "trivy" "hadolint")
    local missing_tools=0
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}  ✅ $tool available${NC}"
        else
            echo -e "${RED}  ❌ $tool missing${NC}"
            missing_tools=$((missing_tools + 1))
        fi
    done
    
    issues=$((issues + missing_tools))
    
    # Check file permissions
    echo "• Checking critical file permissions..."
    local perm_issues=0
    
    # Check for world-writable files (security risk)
    if find "$PROJECT_ROOT" -type f -perm -o+w 2>/dev/null | grep -v '.git/' | head -5; then
        echo -e "${YELLOW}  ⚠️  World-writable files found${NC}"
        perm_issues=$((perm_issues + 1))
    else
        echo -e "${GREEN}  ✅ File permissions look secure${NC}"
    fi
    
    issues=$((issues + perm_issues))
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}✅ Security configuration validation passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Found $issues configuration issues${NC}"
    fi
    
    echo ""
    return $issues
}

# Run initial security scan
run_initial_scan() {
    if [ "$RUN_INITIAL_SCAN" = false ]; then
        echo -e "${YELLOW}⏭️  Skipping initial security scan${NC}"
        return 0
    fi
    
    echo -e "${CYAN}🔍 Running initial security scan...${NC}"
    
    if [ -f "$SCRIPT_DIR/security-scan.sh" ]; then
        local scan_args=()
        
        if [ "$QUICK_SETUP" = true ]; then
            scan_args+=("-q")
        fi
        
        if [ "$PDS_MODE" = true ]; then
            scan_args+=("-p")
        fi
        
        # Run security scan
        if "$SCRIPT_DIR/security-scan.sh" "${scan_args[@]}" -o "initial-security-report.html"; then
            echo -e "${GREEN}✅ Initial security scan completed successfully${NC}"
        else
            local exit_code=$?
            if [ $exit_code -le 5 ]; then
                echo -e "${YELLOW}⚠️  Security scan found some issues (see report)${NC}"
            else
                echo -e "${RED}❌ Security scan found significant issues requiring attention${NC}"
            fi
            return $exit_code
        fi
    else
        echo -e "${YELLOW}⚠️  Security scan script not found${NC}"
    fi
    
    echo ""
}

# Generate security documentation
generate_documentation() {
    echo -e "${CYAN}📚 Generating security documentation...${NC}"
    
    local docs_dir="$PROJECT_ROOT/docs/security"
    mkdir -p "$docs_dir"
    
    # Create security setup guide
    cat > "$docs_dir/SECURITY_SETUP.md" << EOF
# CoPA Security Setup Guide

This document provides comprehensive security setup instructions for the CoPA application.

## Overview

The CoPA application implements multiple layers of security to protect sensitive police data:

- **Secret Detection**: Automated scanning for hardcoded credentials
- **Vulnerability Scanning**: Regular dependency and container security checks  
- **Infrastructure Security**: ARM template validation and compliance checks
- **Code Security**: Static analysis for security vulnerabilities
- **Compliance Monitoring**: PDS and regulatory compliance verification

## Security Tools Installed

$(if command -v gitleaks &> /dev/null; then echo "- ✅ **Gitleaks**: Secret detection and prevention"; else echo "- ❌ **Gitleaks**: Not installed"; fi)
$(if command -v trivy &> /dev/null; then echo "- ✅ **Trivy**: Vulnerability scanning for containers and dependencies"; else echo "- ❌ **Trivy**: Not installed"; fi)
$(if command -v hadolint &> /dev/null; then echo "- ✅ **Hadolint**: Dockerfile security best practices"; else echo "- ❌ **Hadolint**: Not installed"; fi)
$(if command -v safety &> /dev/null; then echo "- ✅ **Safety**: Python dependency vulnerability scanning"; else echo "- ❌ **Safety**: Not installed"; fi)

## Daily Security Tasks

1. **Review Security Alerts**: Check automated scan results
2. **Monitor Failed Authentication**: Review authentication logs  
3. **System Health Check**: Verify all security tools are functioning

## Weekly Security Tasks

1. **Dependency Scan**: Run \`./tools/dependency-security.sh\`
2. **Security Log Review**: Analyze security events and patterns
3. **Access Review**: Verify user permissions and access patterns

## Monthly Security Tasks

1. **Comprehensive Security Scan**: Run \`./tools/security-scan.sh\`
2. **Security Configuration Review**: Validate security settings
3. **Incident Response Testing**: Test security incident procedures

## Emergency Contacts

- **Security Team**: [Contact information]
- **Incident Response**: [Emergency contact]
- **Compliance Officer**: [Compliance contact]

## Quick Commands

\`\`\`bash
# Run comprehensive security scan
./tools/security-scan.sh

# Quick security check
./tools/security-scan.sh -q

# PDS compliance scan
./tools/security-scan.sh -p

# Dependency security check
./tools/dependency-security.sh

# ARM template validation
./tools/validate-templates.sh
\`\`\`

---
*Generated by CoPA Security Setup on $(date)*
EOF

    # Create incident response playbook
    cat > "$docs_dir/INCIDENT_RESPONSE.md" << EOF
# Security Incident Response Playbook

## Incident Classification

### Critical (P0)
- Data breach or unauthorized access to police data
- System compromise or malware infection
- Complete service outage affecting operations

**Response Time**: Immediate (within 15 minutes)

### High (P1)  
- Significant security vulnerability discovered
- Suspected unauthorized access attempt
- Partial service degradation

**Response Time**: Within 1 hour

### Medium (P2)
- Security configuration issues
- Moderate vulnerability findings
- Performance degradation

**Response Time**: Within 4 hours

### Low (P3)
- Minor security policy violations
- Low-risk vulnerabilities
- Documentation issues

**Response Time**: Within 24 hours

## Response Procedures

### Immediate Response (First 15 minutes)

1. **Assess and Classify**: Determine incident severity
2. **Contain**: Isolate affected systems if needed
3. **Notify**: Alert security team and management
4. **Document**: Begin incident log with timestamps

### Investigation Phase (First hour)

1. **Preserve Evidence**: Take system snapshots, preserve logs
2. **Analyze Impact**: Determine scope of potential compromise
3. **Communication**: Notify stakeholders per communication plan
4. **Initial Containment**: Implement immediate protective measures

### Recovery Phase

1. **Eradication**: Remove threat and vulnerabilities
2. **Recovery**: Restore systems to normal operations
3. **Monitoring**: Enhanced monitoring for recurring issues
4. **Validation**: Confirm systems are secure and functional

### Post-Incident

1. **Lessons Learned**: Document findings and improvements
2. **Policy Updates**: Update security policies if needed
3. **Training**: Additional training if required
4. **Follow-up**: Ensure all remediation is complete

## Contact Information

- **Security Team**: [Contact details]
- **Emergency Response**: [Emergency number]
- **Management**: [Management contacts]
- **Legal**: [Legal team contact]
- **IT Support**: [IT support contact]

---
*Last Updated: $(date)*
EOF

    echo -e "${GREEN}✅ Security documentation generated in docs/security/${NC}"
    echo ""
}

# Create CI/CD security integration templates
create_cicd_templates() {
    if [ "$FULL_SETUP" = false ]; then
        return 0
    fi
    
    echo -e "${CYAN}⚙️  Creating CI/CD security integration templates...${NC}"
    
    local cicd_dir="$PROJECT_ROOT/.github/workflows"
    mkdir -p "$cicd_dir"
    
    # Create security workflow
    cat > "$cicd_dir/security-scan.yml" << EOF
name: Security Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    # Run security scan daily at 2 AM UTC
    - cron: '0 2 * * *'

jobs:
  security-scan:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
    
    - name: Install security tools
      run: |
        # Install gitleaks
        wget -q https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
        tar -xzf gitleaks_8.18.0_linux_x64.tar.gz
        sudo mv gitleaks /usr/local/bin/
        
        # Install Trivy
        sudo apt-get update
        sudo apt-get install -y wget apt-transport-https gnupg lsb-release
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb \$(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update && sudo apt-get install -y trivy
        
        # Install Python security tools
        pip install safety
    
    - name: Run comprehensive security scan
      run: |
        chmod +x ./tools/security-scan.sh
        ./tools/security-scan.sh -q -o security-report.html
    
    - name: Upload security report
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: security-report
        path: security-reports/
        retention-days: 30
    
    - name: Check security scan results
      run: |
        # Fail the build if critical security issues are found
        if [ -f "security-reports/security-summary.md" ]; then
          if grep -q "critical\|high" security-reports/security-summary.md; then
            echo "Critical security issues found. Please review and fix."
            exit 1
          fi
        fi

  dependency-scan:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Set up Node.js  
      uses: actions/setup-node@v4
      with:
        node-version: '20'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        cd frontend && npm ci
    
    - name: Run dependency security scan
      run: |
        chmod +x ./tools/dependency-security.sh
        ./tools/dependency-security.sh
    
    - name: Upload dependency report
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: dependency-report
        path: security-reports/dependency-security-report.md
        retention-days: 30
EOF

    echo -e "${GREEN}✅ CI/CD security templates created${NC}"
    echo ""
}

# Final security validation
final_validation() {
    echo -e "${CYAN}🔍 Running final security validation...${NC}"
    
    local validation_issues=0
    
    # Check that all security scripts are executable
    local scripts=("security-scan.sh" "dependency-security.sh" "validate-templates.sh" "setup-git-hooks.sh")
    
    for script in "${scripts[@]}"; do
        local script_path="$SCRIPT_DIR/$script"
        if [ -f "$script_path" ]; then
            if [ -x "$script_path" ]; then
                echo -e "${GREEN}✅ $script is executable${NC}"
            else
                echo -e "${RED}❌ $script is not executable${NC}"
                validation_issues=$((validation_issues + 1))
            fi
        else
            echo -e "${YELLOW}⚠️  $script not found${NC}"
            validation_issues=$((validation_issues + 1))
        fi
    done
    
    # Check Git hooks installation
    if [ -f "$PROJECT_ROOT/.git/hooks/pre-commit" ] && [ -x "$PROJECT_ROOT/.git/hooks/pre-commit" ]; then
        echo -e "${GREEN}✅ Git pre-commit hook installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Git pre-commit hook not installed${NC}"
        validation_issues=$((validation_issues + 1))
    fi
    
    # Check security tools availability
    local required_tools=("gitleaks" "trivy")
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}✅ $tool available${NC}"
        else
            echo -e "${RED}❌ $tool not available${NC}"
            validation_issues=$((validation_issues + 1))
        fi
    done
    
    echo ""
    return $validation_issues
}

# Print completion summary
print_summary() {
    local setup_issues=$1
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                          Security Setup Complete                              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ $setup_issues -eq 0 ]; then
        echo -e "${GREEN}🎉 Security setup completed successfully!${NC}"
        echo -e "${GREEN}   Your CoPA application is now secured with comprehensive protection.${NC}"
    elif [ $setup_issues -le 3 ]; then
        echo -e "${YELLOW}⚠️  Security setup completed with $setup_issues minor issues.${NC}"
        echo -e "${YELLOW}   Please review and address the issues above.${NC}"
    else
        echo -e "${RED}🚨 Security setup completed with $setup_issues issues requiring attention.${NC}"
        echo -e "${RED}   Please resolve these issues before proceeding with deployment.${NC}"
    fi
    
    echo ""
    echo -e "${WHITE}🛡️  Security Components Configured:${NC}"
    echo "   • Secret detection and prevention (gitleaks)"
    echo "   • Vulnerability scanning (trivy, safety)"
    echo "   • Docker security (hadolint)"
    echo "   • Infrastructure validation (ARM TTK)"
    echo "   • Git security hooks (pre-commit, pre-push)"
    echo "   • Security configuration and policies"
    echo "   • Incident response procedures"
    
    if [ "$FULL_SETUP" = true ]; then
        echo "   • CI/CD security integration"
        echo "   • Comprehensive documentation"
    fi
    
    echo ""
    echo -e "${WHITE}📋 Next Steps:${NC}"
    echo "   1. Review security reports in security-reports/ directory"
    echo "   2. Address any security issues found during setup"
    echo "   3. Run regular security scans: ./tools/security-scan.sh"
    echo "   4. Monitor dependency vulnerabilities: ./tools/dependency-security.sh"
    echo "   5. Keep security tools updated"
    
    if [ "$PDS_MODE" = true ]; then
        echo ""
        echo -e "${PURPLE}🛡️  PDS Compliance Notes:${NC}"
        echo "   • Data classification tags are required for all resources"
        echo "   • Audit logging must be enabled and monitored"
        echo "   • Regular compliance scans should be performed"
        echo "   • Incident response procedures must be tested quarterly"
    fi
    
    echo ""
    echo -e "${WHITE}🔗 Quick Commands:${NC}"
    echo "   ./tools/security-scan.sh           # Comprehensive security scan"
    echo "   ./tools/dependency-security.sh     # Check dependency vulnerabilities"
    echo "   ./tools/validate-templates.sh      # Validate ARM templates"
    
    echo ""
    echo -e "${CYAN}📚 Documentation: docs/security/${NC}"
    echo ""
}

# Main execution
main() {
    parse_args "$@"
    
    print_header
    
    local total_issues=0
    
    # Pre-flight checks
    if ! check_requirements; then
        exit 1
    fi
    
    # Core setup steps
    install_security_tools
    setup_git_hooks
    
    # Configuration and validation
    validate_configuration || total_issues=$((total_issues + $?))
    
    # Generate documentation
    generate_documentation
    
    # Full setup additional features
    if [ "$FULL_SETUP" = true ]; then
        create_cicd_templates
    fi
    
    # Run initial security assessment
    run_initial_scan || total_issues=$((total_issues + $?))
    
    # Final validation
    final_validation || total_issues=$((total_issues + $?))
    
    # Summary
    print_summary $total_issues
    
    exit $total_issues
}

# Execute main function
main "$@"
