# CoPA Branch Synchronization Workflow

## Repository Setup
Your repository has branch protection rules that require pull requests for changes to the `main` branch. This is a **good practice** for maintaining code quality and change tracking.

## Current Status
- **dev-test branch**: Your working branch where you make changes
- **main branch**: Protected branch requiring pull requests
- **Sync script**: `sync-branches.ps1` available for automation

## Recommended Workflow

### 1. Daily Development Work
```powershell
# Make sure you're on dev-test branch
git checkout dev-test

# Pull latest changes
git pull origin dev-test

# Make your changes to files
# ... edit files ...

# Stage and commit your changes
git add .
git commit -m "Your descriptive commit message"

# Push to dev-test branch
git push origin dev-test
```

### 2. Sync dev-test to main (Use GitHub Pull Request)
When you're ready to sync your changes from `dev-test` to `main`:

#### Option A: GitHub Web Interface (Recommended)
1. Go to your GitHub repository: https://github.com/Russ-Holloway/CoPA
2. Click "Pull requests" tab
3. Click "New pull request"
4. Set:
   - Base: `main`
   - Compare: `dev-test`
5. Add a title and description
6. Click "Create pull request"
7. Review the changes and click "Merge pull request"
8. Choose "Merge" or "Squash and merge"
9. Delete the temporary branch if created

#### Option B: Command Line with GitHub CLI (if installed)
```powershell
# Create pull request from dev-test to main
gh pr create --title "Sync dev-test to main" --body "Regular sync of development changes" --base main --head dev-test

# View pull request
gh pr view

# Merge pull request (if you're the owner)
gh pr merge --merge  # or --squash
```

### 3. Keep dev-test in sync with main
After merging to main, update your dev-test branch:

```powershell
# Switch to main and pull latest
git checkout main
git pull origin main

# Switch back to dev-test and merge main
git checkout dev-test
git merge main

# Push updated dev-test
git push origin dev-test
```

### 4. Using the Sync Script
The `sync-branches.ps1` script can help with routine tasks:

```powershell
# Check current status
powershell -ExecutionPolicy Bypass -File sync-branches.ps1 -Action status

# Commit and push changes to dev-test
powershell -ExecutionPolicy Bypass -File sync-branches.ps1 -Action commit -Message "Your commit message"

# Note: The sync action won't work due to branch protection, use pull requests instead
```

## Best Practices

1. **Always work on dev-test**: Never commit directly to main
2. **Regular commits**: Make small, focused commits with clear messages
3. **Pull requests**: Use pull requests for all changes to main
4. **Stay in sync**: Regularly sync dev-test with main after merges
5. **Clean history**: Use squash and merge for cleaner history

## Quick Reference Commands

```powershell
# Status check
git status
git log --oneline -5

# Switch branches
git checkout dev-test
git checkout main

# Sync dev-test with main after PR merge
git checkout main && git pull origin main && git checkout dev-test && git merge main && git push origin dev-test
```

## Troubleshooting

### "Repository rule violations" error
This is expected! It means your repository is properly protected. Use pull requests instead of direct pushes to main.

### Branches out of sync
1. Check which branch has what changes: `git log --oneline dev-test..main` and `git log --oneline main..dev-test`
2. Use pull requests to sync changes
3. After PR merge, sync dev-test with main using the commands above

### Merge conflicts
1. Pull latest changes to both branches
2. Resolve conflicts in your IDE or text editor
3. Test the changes
4. Create pull request

## Summary
- **Work on**: `dev-test` branch
- **Sync to main**: Use GitHub pull requests
- **Keep in sync**: Merge main back to dev-test after PR merges
- **Automation**: Use the sync script for routine dev-test operations

This workflow ensures clean history, proper review, and maintains synchronization between branches while respecting repository protection rules.
