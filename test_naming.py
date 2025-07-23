#!/usr/bin/env python3
"""
Test ARM template variable resolution with sample resource group name
"""

import json

def test_naming_convention():
    """Test how variables resolve with sample resource group names"""
    
    print("🧪 Testing Naming Convention...")
    print("=" * 50)
    
    # Sample resource group names to test
    test_rg_names = [
        "rg-west-test-02",
        "rg-avon-prod-01", 
        "rg-met-dev-03",
        "rg-gmp-staging-02"
    ]
    
    # Template variables logic
    environment_suffix = "prod"
    service_suffix = "coppa"
    instance_number = "02"
    
    for rg_name in test_rg_names:
        print(f"\n📍 Resource Group: {rg_name}")
        
        # Extract ForceCode (assumes rg-{forcecode}-{env}-{number} format)
        try:
            force_code = rg_name.split('-')[1]
            print(f"   Force Code: {force_code}")
            
            # Generate sample resource names
            resources = {
                "Web App": f"app-{force_code}-{environment_suffix}-{service_suffix}-{instance_number}",
                "Storage Account": f"st{force_code}{environment_suffix}{service_suffix}{instance_number}",
                "Cosmos DB": f"db-app-{force_code}-coppa",
                "Search Service": f"srch-{force_code}-{environment_suffix}-{service_suffix}-{instance_number}",
                "OpenAI Resource": f"cog-{force_code}-{environment_suffix}-{service_suffix}-{instance_number}"
            }
            
            for name, value in resources.items():
                print(f"   {name:15}: {value}")
                
                # Check for common naming issues
                if len(value) > 24 and name == "Storage Account":
                    print(f"      ⚠️  WARNING: Storage account name too long ({len(value)} chars)")
                elif len(value) <= 24 or name != "Storage Account":
                    print(f"      ✅ Length OK ({len(value)} chars)")
                    
        except IndexError:
            print(f"   ❌ Invalid resource group format")
    
    print(f"\n" + "=" * 50)
    print("✅ Naming convention test completed")

if __name__ == "__main__":
    test_naming_convention()
