# Repository Cleanup - v2

This document tracks the major cleanup performed on the repository.

## Files Removed

### Log and Temporary Files
- `app.log`, `build.log`, `frontend/build.log`
- `*.tmp`, `*.cache` files

### Test and Development Artifacts
- `banner-preview.html`
- `layout-preview.html` 
- `simple-test.html`
- `test-*.html` files
- `test_naming.py`
- `start.cmd`, `startup.sh`
- `version.json`, `package-lock.json` (root level)

### Virtual Environment
- `venv/` directory (should be created locally, not in source control)

### Notebooks
- `notebooks/` directory with single example file

## Files Reorganized

### Documentation (`docs/`)
- **`docs/archive/`**: Historical implementation docs (ACCESSIBILITY_*, CITATION_*, COPPA_*, etc.)
- **`docs/deployment/`**: Deployment and Azure setup guides  
- **`docs/security/`**: Security assessment and configuration docs

### Scripts (`scripts/`)
- **`scripts/deployment/`**: Deployment scripts (deploy.*, configure-auth.*, upload_template.*)
- **`scripts/development/`**: Development utilities (dev-helper.ps1, sync-branches.ps1)

### Tools (`tools/`)
- **`tools/validation/`**: Utility scripts (debug_backend_config.py, check_config.py, validate_template.py)

## Retained Core Files

### Application Core
- `app.py` - Main Flask application
- `azure_startup.py` - Azure startup configuration
- `gunicorn.conf.py` - Production server configuration
- `start.sh` - Application startup script

### Configuration
- `azure.yaml` - Azure Developer CLI configuration
- `azure-pipelines-deployment.yml` - CI/CD pipeline
- `requirements.txt`, `requirements-dev.txt` - Python dependencies
- `WebApp.Dockerfile`, `WebApp.dockerignore` - Container configuration

### Essential Documentation
- `README.md` - Main project documentation
- `README_azd.md` - Azure Developer CLI setup
- `LICENSE` - Project license
- `CODE_OF_CONDUCT.md` - Community guidelines
- `SUPPORT.md` - Support information

## Directory Structure After Cleanup

```
/
├── backend/          # Backend Python modules
├── data/            # Data directory (with security guidelines)
├── docs/            # Organized documentation
│   ├── archive/     # Historical docs
│   ├── deployment/  # Deployment guides
│   └── security/    # Security docs
├── frontend/        # React TypeScript frontend
├── infra/          # Infrastructure as Code
├── infrastructure/ # Additional infrastructure configs
├── scripts/        # Organized utility scripts
│   ├── deployment/ # Deployment scripts
│   └── development/ # Development utilities
├── security-reports/ # Security assessment results
├── static/         # Static web assets
├── tests/          # Test files
└── tools/          # Development tools
    └── validation/ # Utility scripts
```

This cleanup significantly reduces repository size and improves organization while maintaining all essential functionality.
