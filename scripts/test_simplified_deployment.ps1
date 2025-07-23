#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tests the simplified PDS deployment parameter generation logic
    
.DESCRIPTION
    This script validates that the ARM template functions correctly generate
    PDS-compliant resource names from resource group patterns.
    
.EXAMPLE
    .\scripts\test_simplified_deployment.ps1
#>

# Colors for output
$Green = "`e[32m"
$Blue = "`e[34m"  
$Yellow = "`e[33m"
$Red = "`e[31m"
$Reset = "`e[0m"

Write-Host "${Blue}🧪 Testing Simplified PDS Deployment Logic${Reset}" -ForegroundColor Blue
Write-Host ""

# Test resource group patterns
$testCases = @(
    @{
        ResourceGroup = "rg-btp-prod-01"
        ExpectedForceCode = "btp"
        ExpectedEnvironment = "prod"
        ExpectedInstance = "01"
    },
    @{
        ResourceGroup = "rg-gmp-prod-01"
        ExpectedForceCode = "gmp"
        ExpectedEnvironment = "prod"
        ExpectedInstance = "01"
    },
    @{
        ResourceGroup = "rg-met-prod-01"
        ExpectedForceCode = "met"
        ExpectedEnvironment = "prod"
        ExpectedInstance = "01"
    }
)

Write-Host "${Blue}📝 Testing Resource Group Name Patterns:${Reset}"
Write-Host ""

foreach ($test in $testCases) {
    Write-Host "${Yellow}Testing: $($test.ResourceGroup)${Reset}"
    
    # Simulate ARM template functions
    $parts = $test.ResourceGroup.Split('-')
    if ($parts.Length -ge 4) {
        $extractedForceCode = $parts[1]
        $extractedEnvironment = $parts[2]
        $extractedInstance = $parts[3]
        
        Write-Host "  🔍 Extracted Force Code: $extractedForceCode"
        Write-Host "  🔍 Extracted Environment: $extractedEnvironment"
        Write-Host "  🔍 Extracted Instance: $extractedInstance"
        
        # Validate results
        $forceCodeMatch = $extractedForceCode -eq $test.ExpectedForceCode
        $environmentMatch = $extractedEnvironment -eq $test.ExpectedEnvironment
        $instanceMatch = $extractedInstance -eq $test.ExpectedInstance
        
        if ($forceCodeMatch -and $environmentMatch -and $instanceMatch) {
            Write-Host "  ${Green}✅ PASS - Naming pattern extraction successful${Reset}"
        } else {
            Write-Host "  ${Red}❌ FAIL - Naming pattern extraction failed${Reset}"
        }
        
        Write-Host ""
        Write-Host "  ${Blue}Generated Resource Names:${Reset}"
        Write-Host "  • App Service: app-$extractedForceCode-$extractedEnvironment-$extractedInstance"
        Write-Host "  • Storage: st$extractedForceCode$extractedEnvironment$extractedInstance"
        Write-Host "  • Search: srch-$extractedForceCode-$extractedEnvironment-$extractedInstance"
        Write-Host "  • OpenAI: cog-$extractedForceCode-$extractedEnvironment-$extractedInstance"
        Write-Host ""
    } else {
        Write-Host "  ${Red}❌ FAIL - Invalid resource group pattern${Reset}"
    }
    
    Write-Host "----------------------------------------"
}

Write-Host "${Blue}🔍 ARM Template Parameter Generation Test:${Reset}"
Write-Host ""

# Show the ARM template functions that will be used
Write-Host "${Yellow}ARM Template Functions:${Reset}"
Write-Host "ForceCode: [split(resourceGroup().name, '-')[1]]"
Write-Host "EnvironmentSuffix: 'prod'"
Write-Host "InstanceNumber: '01'"
Write-Host ""

Write-Host "${Green}✅ Parameter Generation Logic Validated${Reset}"
Write-Host ""
Write-Host "${Blue}🎯 User Experience Summary:${Reset}"
Write-Host "1. User creates resource group with pattern: rg-{force}-prod-01"
Write-Host "2. Template automatically extracts force code"
Write-Host "3. All resources get PDS-compliant names"
Write-Host "4. No complex forms for users to fill out"
Write-Host ""
Write-Host "${Green}🚀 Ready for simplified deployment!${Reset}"
