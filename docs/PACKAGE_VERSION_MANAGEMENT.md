# Package Version Management Guide

## Recent Deployment Issues Fixed

### Issue Summary
Users deploying with the "Deploy to Azure" button encountered dependency resolution failures due to non-existent package versions in `requirements.txt`.

### Specific Problems Identified:
1. **uvicorn==0.35.1** ❌ (Latest available: 0.35.0)
2. **gunicorn==23.1.0** ❌ (Latest available: 23.0.0)

### Solution Implemented
Updated `requirements.txt` to use version ranges instead of exact versions for packages prone to rapid updates:

```python
# Before (problematic):
uvicorn[standard]==0.35.1  # Version doesn't exist
gunicorn==23.1.0          # Version doesn't exist
openai==1.55.3            # Becomes outdated quickly
aiohttp==3.12.14          # Becomes outdated quickly

# After (robust):
uvicorn[standard]>=0.35.0,<0.36.0  # Flexible within minor version
gunicorn>=23.0.0,<24.0.0           # Flexible within major version
openai>=1.55.3,<2.0.0              # Allows updates, prevents breaking changes
aiohttp>=3.12.14,<4.0.0            # Allows updates, prevents breaking changes
```

## Version Management Strategy

### Use Exact Versions For:
- **Azure packages** (azure-identity, azure-storage-blob, azure-cosmos)
  - Reason: Stable, tested integration with Azure services
  - Example: `azure-identity==1.24.0`

- **Framework core packages** (Flask, quart)
  - Reason: Application architecture depends on specific features
  - Example: `Flask[async]==3.1.2`

### Use Version Ranges For:
- **Rapidly updating packages** (openai, aiohttp)
  - Pattern: `>=current.version,<next.major.0`
  - Example: `openai>=1.55.3,<2.0.0`

- **Server/ASGI packages** (uvicorn, gunicorn)
  - Pattern: `>=current.major.minor,<next.major.0`
  - Example: `uvicorn[standard]>=0.35.0,<0.36.0`

- **Utility packages** (python-dotenv, bleach, werkzeug)
  - Pattern: `>=current.version,<next.major.0`
  - Example: `python-dotenv>=1.0.1,<2.0.0`

### Keep Flexible For Security:
- **Security packages** (cryptography)
  - Pattern: `>=minimum.secure.version`
  - Example: `cryptography>=41.0.0`

## Testing Package Versions

### Before Deployment:
```bash
# Test if all requirements can be resolved
python -m pip install --dry-run -r requirements.txt

# Check for conflicting dependencies
python -m pip check
```

### Verify Specific Package Versions:
```bash
# Check available versions for a package
pip index versions <package-name>

# Example:
pip index versions gunicorn
pip index versions uvicorn
```

## Maintenance Schedule

### Monthly:
- Review and test all package versions
- Update version ranges if new stable releases are available
- Check for security updates in dependencies

### Before Major Deployments:
- Run full dependency resolution test
- Verify no version conflicts exist
- Test deployment in staging environment

## Emergency Fix Procedure

If deployment fails due to version issues:

1. **Identify the problematic package:**
   ```bash
   pip index versions <package-name>
   ```

2. **Update requirements.txt with correct version:**
   - Use latest available version within compatibility range
   - Prefer version ranges over exact versions

3. **Test locally:**
   ```bash
   python -m pip install --dry-run -r requirements.txt
   ```

4. **Deploy fix via pull request**

## Prevention Checklist

- [ ] Use version ranges for rapidly updating packages
- [ ] Test requirements resolution before deployment
- [ ] Check package availability in PyPI before specifying versions
- [ ] Use exact versions only for critical, stable dependencies
- [ ] Document reasons for exact version constraints
- [ ] Regular maintenance schedule for dependency updates

## Contact for Issues

If you encounter package version issues during deployment:
- Create an issue in the repository with the full error message
- Include the package name and version that failed
- The development team will provide a fix within 24 hours

---
**Last Updated:** September 11, 2025  
**Next Review:** October 11, 2025
