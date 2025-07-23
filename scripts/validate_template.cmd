@echo off
echo.
echo ================================================
echo Policing Assistant - ARM Template Validation
echo ================================================
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell is not available. Please install PowerShell.
    pause
    exit /b 1
)

REM Check if template file exists
if not exist "..\infrastructure\deployment.json" (
    echo ERROR: Template file not found: ..\infrastructure\deployment.json
    pause
    exit /b 1
)

echo Checking JSON syntax...
powershell -Command "try { Get-Content '..\infrastructure\deployment.json' -Raw | ConvertFrom-Json | Out-Null; Write-Host 'SUCCESS: JSON syntax is valid' -ForegroundColor Green } catch { Write-Host 'ERROR: JSON syntax error -' $_.Exception.Message -ForegroundColor Red }"

echo.
echo Checking Azure PowerShell module...
powershell -Command "try { Import-Module Az -ErrorAction Stop; Write-Host 'SUCCESS: Azure PowerShell module found' -ForegroundColor Green } catch { Write-Host 'WARNING: Azure PowerShell module not found. Install with: Install-Module Az' -ForegroundColor Yellow }"

echo.
echo Checking Azure login status...
powershell -Command "try { $context = Get-AzContext; if ($null -eq $context) { Write-Host 'WARNING: Not logged into Azure. Run: Connect-AzAccount' -ForegroundColor Yellow } else { Write-Host ('SUCCESS: Logged into Azure as: ' + $context.Account.Id) -ForegroundColor Green } } catch { Write-Host 'INFO: Run Connect-AzAccount to login to Azure' -ForegroundColor Cyan }"

echo.
echo ================================================
echo Validation Complete
echo ================================================
echo.
echo Next steps:
echo 1. If Azure PowerShell is not installed: Install-Module Az
echo 2. If not logged in: Connect-AzAccount
echo 3. Run ARM validation: Test-AzResourceGroupDeployment
echo 4. See ARM_TEMPLATE_VALIDATION_GUIDE.md for detailed instructions
echo.
pause
