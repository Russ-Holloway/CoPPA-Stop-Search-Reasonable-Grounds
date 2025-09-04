# CoPPA ARM Template Validation Setup

This directory contains validation tools for the CoPPA Stop & Search Azure deployment templates.

## 🛠️ Installed Tools

### 1. ARM Template Toolkit (TTK)
- **Location**: `arm-ttk/`
- **Purpose**: Microsoft's official ARM template testing framework
- **Tests**: 200+ validation rules for ARM templates and Bicep files

### 2. MCP Validation Server  
- **Location**: `mcp-server/`
- **Purpose**: Custom Model Context Protocol server for CoPPA-specific validations
- **Features**: PDS compliance, security baselines, Well-Architected Framework

### 3. Template Validation Script
- **File**: `validate-templates.sh`
- **Purpose**: Wrapper script for easy ARM TTK usage with CoPPA templates
- **Features**: PDS mode, security focus, multiple output formats

## 🚀 Quick Start

### Validate All Templates
```bash
./tools/validate-templates.sh
```

### PDS Compliance Validation
```bash
./tools/validate-templates.sh --pds
```

### Security-Focused Validation
```bash
./tools/validate-templates.sh --security --verbose
```

### Save Results to File
```bash
./tools/validate-templates.sh --pds --format JSON --output validation-results.json
```

## 📁 What Gets Validated

The tools automatically find and validate:
- `infrastructure/deployment.json`
- `infra/main.bicep` 
- `infra/*.json`
- Any ARM/Bicep templates in standard locations

## 🛡️ Police Data Security (PDS) Focus

When using `--pds` mode, validation focuses on:
- Data encryption and protection
- Network security configurations  
- Key Vault integration
- Audit logging requirements
- Access control (RBAC)
- Data classification tags
- Compliance with police data standards

## 📊 Validation Results

- **✅ PASS**: Test passed successfully
- **❌ FAIL**: Critical issue requiring immediate fix
- **⚠️ WARN**: Best practice recommendation

## 🔧 Advanced Usage

See the ARM TTK README for comprehensive documentation:
- [ARM TTK Documentation](arm-ttk/README.md)
- [Validation Script Help](./validate-templates.sh --help)

## 📚 Integration

### VS Code Tasks
Use Ctrl+Shift+P → "Tasks: Run Task" → "Validate ARM Templates"

### CI/CD Pipeline
Add template validation to your deployment pipeline:
```yaml
- name: Validate Templates
  run: ./tools/validate-templates.sh --pds --format JSON
```

### Pre-commit Hook
Validate templates before committing:
```bash
#!/bin/sh
./tools/validate-templates.sh --pds
```

---

*Ensuring CoPPA deployment templates meet security and compliance standards.*
