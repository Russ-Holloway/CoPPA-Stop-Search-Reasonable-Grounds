# CoPA Validation MCP Server

A comprehensive Model Context Protocol (MCP) server for validating Azure deployment configurations and ensuring security best practices for the CoPA (College of Policing Assistant) for Stop Search application.

## 🎯 Overview

This MCP server provides specialized tools for:
- **Azure ARM Template Validation**: Comprehensive validation of `deployment.json` and related Azure infrastructure files
- **Security Best Practices**: Microsoft Security Baseline compliance checking
- **PDS Compliance**: Police Data Security standards validation for sensitive law enforcement data
- **Well-Architected Framework**: Azure WAF pillar assessment and recommendations
- **Compliance Reporting**: Executive, technical, and audit-ready reports

## 🔧 Features

### Validation Tools
- `validate-deployment-json` - Complete ARM template security and structure validation
- `check-well-architected` - Azure Well-Architected Framework compliance assessment
- `validate-pds-compliance` - Police Data Security compliance verification
- `compare-microsoft-best-practices` - Comparison against Microsoft security baselines
- `generate-security-recommendations` - Actionable security improvement suggestions
- `generate-compliance-report` - Comprehensive compliance documentation

### Security Checks
- ✅ **No plaintext secrets** in configuration files
- ✅ **HTTPS-only storage accounts** enforcement
- ✅ **TLS 1.2+ requirements** for all web services
- ✅ **Key Vault integration** for secret management
- ✅ **Network Security Group** restrictive rules
- ✅ **Data classification tagging** for sensitive information
- ✅ **Comprehensive audit logging** configuration
- ✅ **Multi-factor authentication** requirements

### Compliance Standards
- **Microsoft Security Baseline** (General, Government, Financial, Healthcare)
- **Azure Well-Architected Framework** (5 pillars)
- **Police Data Security (PDS)** standards
- **ISO 27001** alignment checks
- **GDPR** data protection considerations

## 🚀 Getting Started

### Prerequisites
- Node.js 16+ (18+ recommended)
- TypeScript knowledge for customization
- Access to Azure deployment files

### Installation

1. **Navigate to the MCP server directory**:
   ```bash
   cd tools/mcp-server
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Build the server**:
   ```bash
   npm run build
   ```

4. **Test the server**:
   ```bash
   npm start
   ```

### VS Code Integration

The MCP server is configured for VS Code debugging:

1. **MCP Configuration**: Located in `.vscode/mcp.json`
2. **Server Command**: `node tools/mcp-server/dist/index.js`
3. **Transport**: stdio (standard input/output)

You can now debug the MCP server directly in VS Code using the MCP Inspector or compatible MCP clients.

## 🛠️ Usage Examples

### Basic Deployment Validation
```typescript
// Validate the main deployment.json file
{
  "tool": "validate-deployment-json",
  "arguments": {
    "includeWarnings": true,
    "checkPdsCompliance": true
  }
}
```

### Security Baseline Comparison
```typescript
// Compare against government security baseline
{
  "tool": "compare-microsoft-best-practices",
  "arguments": {
    "baseline": "government",
    "includeLinks": true
  }
}
```

### Generate Executive Report
```typescript
// Create executive summary for leadership
{
  "tool": "generate-compliance-report",
  "arguments": {
    "format": "executive",
    "includeRecommendations": true
  }
}
```

## 📊 Validation Rules

### Critical Security Rules
1. **ARM_CONTENT_VERSION** - ARM templates must specify contentVersion
2. **NO_PLAINTEXT_SECRETS** - No hardcoded secrets in deployment files
3. **HTTPS_ONLY_STORAGE** - Storage accounts must enforce HTTPS only
4. **TLS_VERSION** - Web services must use TLS 1.2 or higher
5. **KEYVAULT_REFERENCE** - Secrets must use Key Vault references
6. **DATA_CLASSIFICATION** - Resources must be tagged for data sensitivity
7. **AUDIT_LOGGING** - Comprehensive logging must be configured

### PDS Compliance Categories
- **Data Classification**: Sensitive data tagging and handling
- **Encryption**: End-to-end encryption requirements
- **Access Control**: Multi-factor and role-based access
- **Audit Logging**: Activity and security event monitoring

### Well-Architected Pillars
- **🛡️ Security**: Identity, data protection, network security
- **⚡ Reliability**: Availability, backup, health monitoring
- **💰 Cost Optimization**: Resource sizing, scaling, efficiency
- **🔧 Operational Excellence**: Monitoring, alerting, automation
- **🚀 Performance Efficiency**: Resource allocation, caching, CDN

## 🎛️ Configuration

### Environment Variables
The server automatically detects:
- **WORKSPACE_ROOT**: Project root directory (auto-detected)
- **DEPLOYMENT_JSON_PATH**: Location of main deployment file
- **BICEP_MAIN_PATH**: Location of main Bicep file

### File Locations
Default paths (relative to project root):
- `infrastructure/deployment.json` - Main ARM template
- `infra/main.bicep` - Main Bicep template
- `infra/main.parameters.json` - Bicep parameters

## 🔍 Advanced Features

### Custom Validation Rules
The server supports extensible validation rules. Add new security checks by modifying:

```typescript
const SECURITY_VALIDATION_RULES = {
  // Add custom regex patterns
  CUSTOM_RULE: /your-pattern-here/gi
};
```

### Report Formats
Multiple output formats supported:
- **Markdown**: Rich formatted reports with icons and structure
- **JSON**: Machine-readable format for automation
- **Checklist**: Task-oriented format for implementation teams

### Severity Levels
- **Error** ❌: Must be fixed before deployment
- **Warning** ⚠️: Should be addressed for best practices
- **Info** ℹ️: Informational recommendations

## 🧪 Testing

### Manual Testing
```bash
# Test specific validation
echo '{"method": "tools/call", "params": {"name": "validate-deployment-json", "arguments": {}}}' | npm start
```

### Automated Testing
Integration with the main project test suite:
```bash
npm run test
```

## 📚 Documentation Links

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/azure/architecture/framework/)
- [Microsoft Security Baseline](https://docs.microsoft.com/security/benchmark/azure/)
- [Police Data Security Standards](https://www.gov.uk/government/publications/police-data-security-standards)

## 🤝 Contributing

### Development Workflow
1. Make changes to TypeScript source files in `src/`
2. Build: `npm run build`
3. Test: `npm run dev`
4. Debug: Use VS Code MCP debugging

### Adding New Tools
1. Define the tool schema in `server.registerTool()`
2. Implement validation logic
3. Add appropriate error handling
4. Update documentation

### Code Style
- TypeScript with strict mode disabled for compatibility
- Descriptive variable names and comments
- Error handling with user-friendly messages
- Comprehensive logging for debugging

## 🐛 Troubleshooting

### Common Issues

**Node.js Version Warnings**:
- The server works with Node 16+ but 18+ is recommended
- Warnings are harmless and can be ignored

**TypeScript Compilation Errors**:
- Run `npm run build` to check for syntax issues
- Check `tsconfig.json` for configuration problems

**File Not Found Errors**:
- Ensure deployment files exist in expected locations
- Check file permissions and paths

**MCP Connection Issues**:
- Verify the server starts without errors: `npm start`
- Check VS Code MCP configuration in `.vscode/mcp.json`

### Debug Logging
Enable verbose logging by setting environment variables:
```bash
DEBUG=mcp:* npm start
```

## 📋 Roadmap

### Planned Features
- [ ] **Bicep Template Support**: Direct validation of Bicep files
- [ ] **Azure Policy Integration**: Automatic policy compliance checking
- [ ] **CI/CD Integration**: GitHub Actions workflow integration
- [ ] **Custom Rule Engine**: User-defined validation rules
- [ ] **Real-time Monitoring**: Live configuration drift detection
- [ ] **Multi-tenant Support**: Organization-wide compliance tracking

### Version History
- **v1.0.0**: Initial release with core validation tools
- **v1.1.0**: Enhanced PDS compliance checks (planned)
- **v1.2.0**: Bicep template support (planned)

## 📄 License

MIT License - see LICENSE file for details

## 📞 Support

For technical support or questions:
- Create an issue in the project repository
- Contact the CoPA development team
- Refer to MCP SDK documentation for protocol questions

---

*This MCP server is specifically designed for the CoPA (College of Policing Assistant) for Stop Search application but can be adapted for other Azure projects requiring comprehensive security validation.*
