# Post-Deployment Authentication Configuration Script
# Run this after deploying the Azure resources to configure authentication

param(
    [string]$EnvironmentName,
    [string]$AppServiceUrl
)

Write-Host "🔧 Configuring authentication for deployed application..." -ForegroundColor Blue

# Check if required environment variables are set
if (-not $EnvironmentName) {
    $EnvironmentName = $env:AZURE_ENV_NAME
}

if (-not $EnvironmentName) {
    Write-Host "❌ Error: AZURE_ENV_NAME environment variable is required or pass -EnvironmentName parameter" -ForegroundColor Red
    exit 1
}

# Source environment variables if they exist
$envFile = ".\.azure\$EnvironmentName\.env"
if (Test-Path $envFile) {
    Write-Host "📋 Loading environment variables from $envFile" -ForegroundColor Green
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
}

# Check if we have the web app URL
if (-not $AppServiceUrl) {
    $AppServiceUrl = $env:AZURE_APP_SERVICE_URL
}

if (-not $AppServiceUrl) {
    Write-Host "⚠️  AZURE_APP_SERVICE_URL not found. Attempting to retrieve from Azure..." -ForegroundColor Yellow
    
    # Get the app service URL from Azure CLI
    if (Get-Command az -ErrorAction SilentlyContinue) {
        try {
            $resourceGroup = az group list --query "[?tags.`"azd-env-name`"=='$EnvironmentName'].name" -o tsv
            if ($resourceGroup) {
                $appName = az webapp list --resource-group $resourceGroup --query "[0].name" -o tsv
                if ($appName) {
                    $AppServiceUrl = "https://$appName.azurewebsites.net"
                    $env:AZURE_APP_SERVICE_URL = $AppServiceUrl
                    Write-Host "✅ Found app service URL: $AppServiceUrl" -ForegroundColor Green
                }
            }
        }
        catch {
            Write-Host "⚠️  Could not retrieve app service URL from Azure CLI" -ForegroundColor Yellow
        }
    }
    
    if (-not $AppServiceUrl) {
        Write-Host "❌ Could not determine app service URL. Please set AZURE_APP_SERVICE_URL manually or pass -AppServiceUrl parameter." -ForegroundColor Red
        exit 1
    }
}

Write-Host "🔐 Initializing Azure AD application..." -ForegroundColor Blue
$authAppId = if ($env:AUTH_APP_ID) { $env:AUTH_APP_ID } else { "" }
python .\scripts\auth_init.py --appid $authAppId

Write-Host "🔄 Updating Azure AD application configuration..." -ForegroundColor Blue
python .\scripts\auth_update.py

Write-Host "✅ Authentication configuration completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. The Azure AD application has been created/updated" -ForegroundColor White
Write-Host "2. Authentication is now configured for your web app" -ForegroundColor White
Write-Host "3. Users can now sign in using Azure AD" -ForegroundColor White
Write-Host ""
Write-Host "Important: Make sure to update your app service configuration with the new AUTH_CLIENT_ID and AUTH_CLIENT_SECRET values." -ForegroundColor Yellow
