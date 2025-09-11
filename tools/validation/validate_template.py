#!/usr/bin/env python3
"""
ARM Template Validation Script
Validates key aspects of the deployment.json template
"""

import json
import sys
from pathlib import Path

def validate_arm_template(template_path):
    """Validate ARM template structure and common issues"""
    
    print("🔍 Validating ARM Template...")
    print("=" * 50)
    
    errors = []
    warnings = []
    
    try:
        with open(template_path, 'r') as f:
            template = json.load(f)
    except Exception as e:
        print(f"❌ Failed to load template: {e}")
        return False
    
    # 1. Check required top-level properties
    required_props = ['$schema', 'contentVersion', 'parameters', 'variables', 'resources']
    for prop in required_props:
        if prop not in template:
            errors.append(f"Missing required property: {prop}")
        else:
            print(f"✅ Found required property: {prop}")
    
    # 2. Validate schema
    if template.get('$schema'):
        if '2019-04-01' in template['$schema'] or '2018-05-01' in template['$schema']:
            print("✅ Valid ARM template schema")
        else:
            warnings.append(f"Unusual schema version: {template['$schema']}")
    
    # 3. Check parameters
    params = template.get('parameters', {})
    print(f"✅ Found {len(params)} parameters: {list(params.keys())}")
    
    # 4. Check variables
    variables = template.get('variables', {})
    print(f"✅ Found {len(variables)} variables")
    
    # 5. Check resources
    resources = template.get('resources', [])
    print(f"✅ Found {len(resources)} resources")
    
    # 6. Validate resource types
    resource_types = [r.get('type') for r in resources if 'type' in r]
    print("\n📋 Resource Types:")
    for rt in set(resource_types):
        count = resource_types.count(rt)
        print(f"   - {rt} ({count})")
    
    # 7. Check for potential Cosmos DB issues
    cosmos_resources = [r for r in resources if r.get('type') == 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments']
    if cosmos_resources:
        print(f"\n🔍 Analyzing {len(cosmos_resources)} Cosmos DB role assignment(s)...")
        for resource in cosmos_resources:
            props = resource.get('properties', {})
            role_def_id = props.get('roleDefinitionId', '')
            
            if 'concat(' in role_def_id and 'resourceId(' in role_def_id:
                print("✅ Role definition uses proper concat + resourceId construction")
            elif 'resourceId(' in role_def_id and 'split(' in role_def_id:
                warnings.append("Role definition uses complex split() construction - might cause issues")
            else:
                warnings.append("Role definition format might be incorrect")
    
    # 8. Check for missing dependencies
    print(f"\n🔗 Checking dependencies...")
    for resource in resources:
        if 'dependsOn' in resource:
            deps = resource['dependsOn']
            print(f"   - {resource.get('type', 'Unknown')}: {len(deps)} dependencies")
    
    # 9. Validate variable usage
    print(f"\n🔍 Checking variable references...")
    template_str = json.dumps(template)
    unused_vars = []
    for var_name in variables.keys():
        if f"variables('{var_name}')" not in template_str:
            unused_vars.append(var_name)
    
    if unused_vars:
        warnings.append(f"Unused variables: {', '.join(unused_vars)}")
    else:
        print("✅ All variables are referenced")
    
    # Print results
    print("\n" + "=" * 50)
    print("📊 VALIDATION RESULTS")
    print("=" * 50)
    
    if errors:
        print("❌ ERRORS:")
        for error in errors:
            print(f"   - {error}")
    
    if warnings:
        print("⚠️  WARNINGS:")
        for warning in warnings:
            print(f"   - {warning}")
    
    if not errors and not warnings:
        print("🎉 Template validation passed with no issues!")
    elif not errors:
        print("✅ Template validation passed with warnings")
    else:
        print("❌ Template validation failed")
        return False
    
    return True

if __name__ == "__main__":
    template_path = "/workspaces/CoPA-Stop-Search-Reasonable-Grounds/infrastructure/deployment.json"
    
    if not Path(template_path).exists():
        print(f"❌ Template file not found: {template_path}")
        sys.exit(1)
    
    success = validate_arm_template(template_path)
    sys.exit(0 if success else 1)
