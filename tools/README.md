# CoPPA Tools Directory

This directory contains comprehensive security and validation tools for the CoPPA (Coppa Police Partnership Application) project.

## �️ Security Tools Overview

### Comprehensive Security Suite

- **security-setup.sh**: Complete security configuration and tool installation
- **security-scan.sh**: Multi-layered security vulnerability scanner  
- **dependency-security.sh**: Dependency vulnerability monitoring
- **setup-git-hooks.sh**: Automated Git security hooks installation
- **security-config.yaml**: Security policies and configuration

### ARM Template Validation

- **arm-ttk/**: Microsoft's official ARM Template Toolkit for validating Azure Resource Manager templates
- **validate-templates.sh**: Comprehensive validation wrapper with PDS compliance mode
- **run-arm-ttk.sh**: Simple ARM TTK runner for quick validation

## 🔒 Security Components

### 1. Comprehensive Security Scanner (`security-scan.sh`)

Multi-category security scanning with PDS compliance:

**Security Categories:**
- **Secrets Detection**: Hardcoded credentials and API keys
- **Dependency Scanning**: Vulnerable packages and libraries
- **Container Security**: Docker and image vulnerabilities  
- **Infrastructure Analysis**: ARM template and configuration security
- **Static Code Analysis**: Code vulnerability patterns
- **PDS Compliance**: Police data security requirements
- **Network Security**: CORS, TLS, and network configurations
- **Data Protection**: Encryption and privacy controls

**Usage Examples:**
```bash
# Full comprehensive scan
./security-scan.sh

# Quick scan (essential checks only)
./security-scan.sh -q

# PDS compliance focused scan
./security-scan.sh -p

# Generate HTML report
./security-scan.sh -o security-report.html

# Scan specific category
./security-scan.sh -c secrets
```

### 2. Dependency Security Monitor (`dependency-security.sh`)

Monitors and updates dependencies for security vulnerabilities:

**Features:**
- Python package vulnerability scanning (safety, trivy)
- Node.js dependency auditing (npm audit, trivy)  
- Automated vulnerability fixing
- Outdated package detection
- Comprehensive reporting

**Usage Examples:**
```bash
# Check all dependencies
./dependency-security.sh

# Auto-fix vulnerabilities
./dependency-security.sh -f

# Python dependencies only
./dependency-security.sh -p

# Generate report only
./dependency-security.sh -r
```

### 3. Security Setup (`security-setup.sh`)

One-command comprehensive security configuration:

**Setup Components:**
- Security tools installation (gitleaks, trivy, safety, hadolint)
- Git security hooks (pre-commit, pre-push)
- Security configuration validation
- Initial security assessment
- Documentation generation
- CI/CD integration templates

**Usage Examples:**
```bash
# Standard security setup
./security-setup.sh

# Full setup with all features
./security-setup.sh -f

# Quick development setup
./security-setup.sh -q

# PDS compliance setup
./security-setup.sh -p
```

### 4. Git Security Hooks (`setup-git-hooks.sh`)

Automated security checks in Git workflow:

**Pre-commit Hooks:**
- Secret detection in staged files
- Debug statement detection
- TODO/FIXME checks in security files

**Pre-push Hooks:**
- Comprehensive security scan
- ARM template validation
- Vulnerability assessment

### 5. ARM Template Validation Tools

**Features:**
- 200+ validation rules covering security, best practices, and compliance
- PDS compliance mode for police data security
- Multiple output formats (JSON, HTML, JUnit, CSV)
- API version management and updates
- Resource configuration validation

**Usage Examples:**
```bash
# PDS compliance validation
./validate-templates.sh --pds

# Security-focused validation  
./validate-templates.sh --security

# JSON output for automation
./validate-templates.sh --format json --output results.json
```

## � Security Tools Installed

When using the security setup, the following tools are automatically installed:

| Tool | Purpose | Category |
|------|---------|----------|
| **gitleaks** | Secret detection and prevention | Secrets |
| **Trivy** | Vulnerability scanning (containers, dependencies) | Vulnerabilities |
| **Safety** | Python dependency security | Dependencies |
| **Hadolint** | Dockerfile security best practices | Containers |
| **npm audit** | Node.js dependency vulnerabilities | Dependencies |
| **ARM TTK** | Azure template validation | Infrastructure |

## 📋 Security Workflows

### Daily Security Tasks
1. **Automated Scans**: Git hooks run on commit/push
2. **Security Alerts**: Monitor automated scan results
3. **Authentication Review**: Check failed login attempts

### Weekly Security Tasks  
1. **Dependency Scan**: `./dependency-security.sh`
2. **Security Log Review**: Analyze security events
3. **Access Review**: Verify permissions and access

### Monthly Security Tasks
1. **Comprehensive Scan**: `./security-scan.sh`
2. **Configuration Review**: Validate security settings
3. **Incident Response Testing**: Test security procedures

## 🛡️ PDS Compliance Features

### Police Data Security (PDS) Requirements

When run in PDS mode (`-p` flag), tools include enhanced checks for:

- **Data Classification**: Required tagging for sensitive police data
- **Audit Logging**: Comprehensive logging for compliance
- **Encryption Standards**: End-to-end encryption requirements
- **Access Controls**: Multi-factor authentication and RBAC
- **Data Retention**: Policy compliance and lifecycle management
- **Incident Response**: Security event monitoring and response

### Compliance Frameworks Supported

- **PDS (Police Data Security)**: UK police data security standards
- **ISO 27001**: Information security management alignment
- **Microsoft Security Baseline**: Azure security best practices

## 🚀 Quick Start

### Initial Security Setup
```bash
# Complete security setup for CoPPA
./security-setup.sh -p
```

### Regular Security Monitoring
```bash
# Daily quick check
./security-scan.sh -q

# Weekly comprehensive assessment  
./security-scan.sh -p

# Dependency monitoring
./dependency-security.sh
```

### CI/CD Integration
```bash
# Integrate into GitHub Actions
./security-setup.sh -f  # Creates .github/workflows/security-scan.yml
```

## 📊 Reporting and Documentation

### Report Types Generated

- **HTML Reports**: Visual security dashboards
- **JSON Reports**: Machine-readable for automation
- **Markdown Summaries**: Human-readable documentation
- **CSV Exports**: Spreadsheet analysis

### Documentation Generated

- `docs/security/SECURITY_SETUP.md`: Setup and maintenance guide
- `docs/security/INCIDENT_RESPONSE.md`: Security incident procedures
- `security-reports/`: Detailed scan results and analysis

## � Troubleshooting

### Common Issues

1. **Tools not installed**: Run `./security-setup.sh --install-tools`
2. **Permission denied**: Ensure scripts are executable (`chmod +x`)
3. **PowerShell required**: Install PowerShell 7+ for ARM TTK
4. **Network connectivity**: Check firewall for tool downloads

### Debug and Validation

```bash
# Validate security configuration
./security-setup.sh --setup-only

# Test individual components
./security-scan.sh -c secrets  # Test secrets detection
./dependency-security.sh --install-tools  # Install missing tools
```

## 📚 Additional Resources

- [Microsoft ARM Template Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)
- [Police Data Security Standards](https://www.gov.uk/government/publications/police-data-security-standards)
- [OWASP Security Guidelines](https://owasp.org/www-project-top-ten/)

---

🛡️ **Security First**: All tools prioritize the protection of sensitive police data and compliance with security standards.
