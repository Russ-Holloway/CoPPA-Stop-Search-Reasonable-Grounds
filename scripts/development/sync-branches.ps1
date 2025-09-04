# CoPPA Branch Synchronization Script
# This script helps maintain synchronization between dev-test and main branches

param(
    [string]$Action = "sync",
    [string]$Message = ""
)

function Write-Status {
    param([string]$Message, [string]$Color = "Green")
    Write-Host "✓ $Message" -ForegroundColor $Color
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Get-CurrentBranch {
    return (git rev-parse --abbrev-ref HEAD)
}

function Sync-Branches {
    Write-Info "Starting branch synchronization..."
    
    # Get current branch
    $currentBranch = Get-CurrentBranch
    Write-Info "Current branch: $currentBranch"
    
    # Check if we have uncommitted changes
    $status = git status --porcelain
    if ($status) {
        Write-Error "You have uncommitted changes. Please commit or stash them first."
        git status
        return
    }
    
    # Switch to dev-test and pull latest
    Write-Info "Switching to dev-test branch..."
    git checkout dev-test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to switch to dev-test branch"
        return
    }
    
    Write-Info "Pulling latest changes from origin/dev-test..."
    git pull origin dev-test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to pull from origin/dev-test"
        return
    }
    
    # Switch to main and merge dev-test
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
    
    Write-Info "Merging dev-test into main..."
    git merge dev-test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to merge dev-test into main"
        return
    }
    
    # Push main to origin
    Write-Info "Pushing main to origin..."
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push main to origin"
        return
    }
    
    # Switch back to dev-test
    Write-Info "Switching back to dev-test branch..."
    git checkout dev-test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to switch back to dev-test branch"
        return
    }
    
    Write-Status "Branch synchronization completed successfully!"
    Write-Info "Both dev-test and main are now synchronized."
}

function Commit-And-Push {
    param([string]$CommitMessage)
    
    if (-not $CommitMessage) {
        Write-Error "Please provide a commit message using -Message parameter"
        return
    }
    
    $currentBranch = Get-CurrentBranch
    if ($currentBranch -ne "dev-test") {
        Write-Error "Please switch to dev-test branch before committing"
        return
    }
    
    Write-Info "Adding changes to staging..."
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
    
    Write-Status "Changes committed and pushed to dev-test!"
}

function Show-Status {
    Write-Info "Current Repository Status:"
    Write-Host ""
    
    $currentBranch = Get-CurrentBranch
    Write-Host "Current branch: " -NoNewline
    Write-Host $currentBranch -ForegroundColor Yellow
    Write-Host ""
    
    Write-Info "Git status:"
    git status
    Write-Host ""
    
    Write-Info "Recent commits on current branch:"
    git log --oneline -5
    Write-Host ""
    
    Write-Info "Branch comparison:"
    Write-Host "dev-test vs main:"
    git log --oneline dev-test..main
    Write-Host "main vs dev-test:"
    git log --oneline main..dev-test
}

# Main script logic
switch ($Action.ToLower()) {
    "sync" {
        Sync-Branches
    }
    "commit" {
        Commit-And-Push -CommitMessage $Message
    }
    "status" {
        Show-Status
    }
    default {
        Write-Host "CoPPA Branch Synchronization Script" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Usage:"
        Write-Host "  .\sync-branches.ps1 -Action sync              # Sync dev-test to main"
        Write-Host "  .\sync-branches.ps1 -Action commit -Message 'Your commit message'"
        Write-Host "  .\sync-branches.ps1 -Action status            # Show current status"
        Write-Host ""
        Write-Host "Workflow:"
        Write-Host "1. Work on dev-test branch"
        Write-Host "2. Use 'commit' action to commit and push changes"
        Write-Host "3. Use 'sync' action to merge dev-test into main"
        Write-Host "4. Use 'status' action to check current state"
    }
}
