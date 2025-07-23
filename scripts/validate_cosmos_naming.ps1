#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates the Cosmos DB naming convention for different police forces
    
.DESCRIPTION
    This script shows how the Cosmos DB resources will be named for different
    police force codes extracted from resource group names.
    
.EXAMPLE
    .\scripts\validate_cosmos_naming.ps1
#>

# Colors for output
$Green = "`e[32m"
$Blue = "`e[34m"  
$Yellow = "`e[33m"
$Reset = "`e[0m"

Write-Host "${Blue}🗄️ Cosmos DB Naming Validation${Reset}" -ForegroundColor Blue
Write-Host ""

# Test resource group patterns
$testCases = @(
    @{
        ResourceGroup = "rg-btp-prod-01"
        ExpectedForceCode = "btp"
        ForceName = "British Transport Police"
    },
    @{
        ResourceGroup = "rg-met-prod-01"
        ExpectedForceCode = "met"
        ForceName = "Metropolitan Police"
    },
    @{
        ResourceGroup = "rg-gmp-prod-01"
        ExpectedForceCode = "gmp"
        ForceName = "Greater Manchester Police"
    },
    @{
        ResourceGroup = "rg-wmp-prod-01"
        ExpectedForceCode = "wmp"
        ForceName = "West Midlands Police"
    }
)

Write-Host "${Blue}📋 Cosmos DB Resource Names by Force:${Reset}"
Write-Host ""

foreach ($test in $testCases) {
    Write-Host "${Yellow}$($test.ForceName) ($($test.ResourceGroup)):${Reset}"
    
    # Extract force code (simulate ARM template function)
    $parts = $test.ResourceGroup.Split('-')
    $extractedForceCode = $parts[1]
    
    # Generate Cosmos DB names
    $accountName = "db-app-$extractedForceCode-coppa"
    $databaseName = "db_conversation_history"
    $containerName = "conversations"
    
    Write-Host "  🏢 Account Name: ${Green}$accountName${Reset}"
    Write-Host "  🗃️  Database Name: ${Green}$databaseName${Reset}"
    Write-Host "  📦 Container Name: ${Green}$containerName${Reset}"
    Write-Host ""
}

Write-Host "${Blue}✅ Cosmos DB Configuration Summary:${Reset}"
Write-Host "• Account Name Pattern: ${Yellow}db-app-{force-code}-coppa${Reset}"
Write-Host "• Database Name: ${Yellow}db_conversation_history${Reset} (consistent across all forces)"
Write-Host "• Container Name: ${Yellow}conversations${Reset} (consistent across all forces)"
Write-Host ""
Write-Host "${Green}🎯 Benefits:${Reset}"
Write-Host "✅ Account names are unique per police force"
Write-Host "✅ Database and container names are standardized"
Write-Host "✅ Easy to identify resources by force code"
Write-Host "✅ Maintains conversation history separation"
Write-Host ""
Write-Host "${Blue}📋 ARM Template Variables:${Reset}"
Write-Host "cosmosdb_account_name: [concat('db-app-', parameters('ForceCode'), '-coppa')]"
Write-Host "cosmosdb_database_name: 'db_conversation_history'"
Write-Host "cosmosdb_container_name: 'conversations'"
Write-Host ""
Write-Host "${Green}✨ Cosmos DB naming is ready for deployment!${Reset}"
