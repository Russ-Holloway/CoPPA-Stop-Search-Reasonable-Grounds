# CoPPA Development Helper Script
# This script helps with routine development tasks on the dev-test branch

param(
    [string]$Action = "help",
    [string]$Message = ""
)

function Write-Status {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Get-CurrentBranch {
    return (git rev-parse --abbrev-ref HEAD)
}

function Show-Status {
    Write-Info "=== CoPPA Repository Status ==="
    Write-Host ""
    
    $currentBranch = Get-CurrentBranch
    Write-Host "Current branch: " -NoNewline
    Write-Host $currentBranch -ForegroundColor Yellow
    Write-Host ""
    
    # Check for uncommitted changes
    $status = git status --porcelain
    if ($status) {
        Write-Warning "You have uncommitted changes:"
        git status --short
    } else {
        Write-Status "Working directory is clean"
    }
    Write-Host ""
    
    Write-Info "Recent commits on current branch:"
    git log --oneline -5
    Write-Host ""
    
    Write-Info "Branch comparison (dev-test vs main):"
    Write-Host "Commits in dev-test not in main:"
    git log --oneline dev-test..main 2>$null
    Write-Host "Commits in main not in dev-test:"
    git log --oneline main..dev-test 2>$null
    Write-Host ""
    
    Write-Info "Remote branch status:"
    git remote show origin | Select-String "dev-test\|main"
}

function Commit-Changes {
    param([string]$CommitMessage)
    
    if (-not $CommitMessage) {
        Write-Error "Please provide a commit message using -Message parameter"
        Write-Host "Example: .\dev-helper.ps1 -Action commit -Message 'Add new feature'"
        return
    }
    
    $currentBranch = Get-CurrentBranch
    if ($currentBranch -ne "dev-test") {
        Write-Error "You must be on dev-test branch to commit changes"
        Write-Host "Current branch: $currentBranch"
        Write-Host "Switch to dev-test: git checkout dev-test"
        return
    }
    
    # Check if there are changes to commit
    $status = git status --porcelain
    if (-not $status) {
        Write-Warning "No changes to commit"
        return
    }
    
    Write-Info "Staging all changes..."
    git add .
    
    Write-Info "Committing changes..."
    git commit -m $CommitMessage
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to commit changes"
        return
    }
    
    Write-Info "Pushing to origin/dev-test..."
    git push origin dev-test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push to origin/dev-test"
        return
    }
    
    Write-Status "Changes committed and pushed to dev-test successfully!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "1. Go to: https://github.com/Russ-Holloway/CoPPA"
    Write-Host "2. Create a pull request from dev-test to main"
    Write-Host "3. Review and merge the pull request"
    Write-Host "4. Run: .\dev-helper.ps1 -Action sync-after-merge"
}

function Sync-After-Merge {
    Write-Info "Syncing dev-test with main after pull request merge..."
    
    $currentBranch = Get-CurrentBranch
    if ($currentBranch -ne "dev-test") {
        Write-Info "Switching to dev-test branch..."
        git checkout dev-test
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to switch to dev-test branch"
            return
        }
    }
    
    Write-Info "Switching to main branch..."
    git checkout main
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to switch to main branch"
        return
    }
    
    Write-Info "Pulling latest changes from origin/main..."
    git pull origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to pull from origin/main"
        return
    }
    
    Write-Info "Switching back to dev-test..."
    git checkout dev-test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to switch back to dev-test branch"
        return
    }
    
    Write-Info "Merging main into dev-test..."
    git merge main
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to merge main into dev-test"
        Write-Warning "You may need to resolve merge conflicts"
        return
    }
    
    Write-Info "Pushing updated dev-test to origin..."
    git push origin dev-test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push dev-test to origin"
        return
    }
    
    Write-Status "Successfully synced dev-test with main!"
    Write-Info "Both branches are now synchronized."
}

function Pull-Latest {
    $currentBranch = Get-CurrentBranch
    
    Write-Info "Pulling latest changes for $currentBranch..."
    git pull origin $currentBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to pull latest changes"
        return
    }
    
    Write-Status "Successfully pulled latest changes for $currentBranch"
}

function Show-Help {
    Write-Host "=== CoPPA Development Helper ===" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Usage: .\dev-helper.ps1 -Action <action> [options]" -ForegroundColor Green
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Cyan
    Write-Host "  status              Show current repository status"
    Write-Host "  commit              Commit and push changes to dev-test"
    Write-Host "  sync-after-merge    Sync dev-test with main after PR merge"
    Write-Host "  pull                Pull latest changes for current branch"
    Write-Host "  help                Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\dev-helper.ps1 -Action status"
    Write-Host "  .\dev-helper.ps1 -Action commit -Message 'Add new feature'"
    Write-Host "  .\dev-helper.ps1 -Action sync-after-merge"
    Write-Host "  .\dev-helper.ps1 -Action pull"
    Write-Host ""
    Write-Host "Workflow:" -ForegroundColor Green
    Write-Host "1. Work on dev-test branch"
    Write-Host "2. Use 'commit' to save and push changes"
    Write-Host "3. Create pull request on GitHub (dev-test → main)"
    Write-Host "4. After PR merge, use 'sync-after-merge'"
    Write-Host "5. Use 'status' to check current state anytime"
    Write-Host ""
    Write-Host "Branch Protection:" -ForegroundColor Yellow
    Write-Host "Your main branch is protected and requires pull requests."
    Write-Host "This script respects that protection and guides you through the proper workflow."
}

# Main script logic
switch ($Action.ToLower()) {
    "status" {
        Show-Status
    }
    "commit" {
        Commit-Changes -CommitMessage $Message
    }
    "sync-after-merge" {
        Sync-After-Merge
    }
    "pull" {
        Pull-Latest
    }
    "help" {
        Show-Help
    }
    default {
        Write-Error "Unknown action: $Action"
        Write-Host ""
        Show-Help
    }
}
