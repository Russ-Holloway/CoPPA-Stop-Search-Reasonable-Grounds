#!/bin/bash

# ARM Template Toolkit (TTK) Validation Script for CoPPA
# This script validates Azure ARM templates and deployment files using Microsoft's official ARM TTK

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARM_TTK_DIR="$SCRIPT_DIR/arm-ttk"

echo -e "${BLUE}🛡️  CoPPA ARM Template Validation${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"

# Function to print usage
print_usage() {
    echo -e "${WHITE}Usage:${NC}"
    echo -e "  $0 [OPTIONS] [TEMPLATE_PATH]"
    echo ""
    echo -e "${WHITE}OPTIONS:${NC}"
    echo -e "  -h, --help              Show this help message"
    echo -e "  -v, --verbose           Enable verbose output"
    echo -e "  -f, --format FORMAT     Output format (Text, JSON, CSV) [default: Text]"
    echo -e "  -s, --skip TESTS        Comma-separated list of tests to skip"
    echo -e "  -o, --output FILE       Save results to file"
    echo -e "  --pds                   Run PDS-specific validation checks"
    echo -e "  --security              Focus on security-related tests only"
    echo ""
    echo -e "${WHITE}TEMPLATE_PATH:${NC}"
    echo -e "  Path to ARM template file or directory to validate"
    echo -e "  If not specified, validates common deployment locations:"
    echo -e "    - infrastructure/deployment.json"
    echo -e "    - infra/main.bicep"
    echo -e "    - infra/*.json"
    echo ""
    echo -e "${WHITE}Examples:${NC}"
    echo -e "  $0                                    # Validate default deployment files"
    echo -e "  $0 infrastructure/deployment.json     # Validate specific file"
    echo -e "  $0 --security infra/                  # Security-focused validation"
    echo -e "  $0 --pds --output results.json        # PDS compliance with JSON output"
}

# Parse command line arguments
VERBOSE=false
OUTPUT_FORMAT="Text"
SKIP_TESTS=""
OUTPUT_FILE=""
PDS_MODE=false
SECURITY_MODE=false
TEMPLATE_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -s|--skip)
            SKIP_TESTS="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --pds)
            PDS_MODE=true
            shift
            ;;
        --security)
            SECURITY_MODE=true
            shift
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
        *)
            TEMPLATE_PATH="$1"
            shift
            ;;
    esac
done

# Function to check if ARM TTK is available
check_arm_ttk() {
    if [ ! -d "$ARM_TTK_DIR" ] || [ ! -f "$ARM_TTK_DIR/arm-ttk/arm-ttk.psd1" ]; then
        echo -e "${RED}❌ ARM TTK not found at $ARM_TTK_DIR${NC}"
        echo -e "${YELLOW}💡 Run the installation script first${NC}"
        exit 1
    fi
    
    if ! command -v pwsh &> /dev/null; then
        echo -e "${RED}❌ PowerShell (pwsh) is not installed${NC}"
        echo -e "${YELLOW}💡 Please install PowerShell first${NC}"
        exit 1
    fi
}

# Function to find template files
find_templates() {
    local templates=()
    
    if [ -n "$TEMPLATE_PATH" ]; then
        if [ -f "$TEMPLATE_PATH" ]; then
            templates=("$TEMPLATE_PATH")
        elif [ -d "$TEMPLATE_PATH" ]; then
            while IFS= read -r -d '' file; do
                templates+=("$file")
            done < <(find "$TEMPLATE_PATH" -name "*.json" -o -name "*.bicep" -print0)
        else
            echo -e "${RED}❌ Template path not found: $TEMPLATE_PATH${NC}"
            exit 1
        fi
    else
        # Default locations
        local default_paths=(
            "infrastructure/deployment.json"
            "infrastructure/azuredeploy.json"
            "infra/main.bicep"
            "infra/azuredeploy.json"
            "templates/azuredeploy.json"
        )
        
        for path in "${default_paths[@]}"; do
            local full_path="$PROJECT_ROOT/$path"
            if [ -f "$full_path" ]; then
                templates+=("$full_path")
            fi
        done
        
        # Also search for any JSON files in infra directories
        if [ -d "$PROJECT_ROOT/infra" ]; then
            while IFS= read -r -d '' file; do
                if [[ "$file" == *.json ]]; then
                    templates+=("$file")
                fi
            done < <(find "$PROJECT_ROOT/infra" -name "*.json" -print0)
        fi
        
        if [ -d "$PROJECT_ROOT/infrastructure" ]; then
            while IFS= read -r -d '' file; do
                if [[ "$file" == *.json ]]; then
                    templates+=("$file")
                fi
            done < <(find "$PROJECT_ROOT/infrastructure" -name "*.json" -print0)
        fi
    fi
    
    # Remove duplicates
    local unique_templates=()
    for template in "${templates[@]}"; do
        local found=false
        for unique in "${unique_templates[@]}"; do
            if [ "$template" = "$unique" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            unique_templates+=("$template")
        fi
    done
    
    printf '%s\n' "${unique_templates[@]}"
}

# Function to build PowerShell command
build_ps_command() {
    local template_file="$1"
    local ps_cmd="Import-Module '$ARM_TTK_DIR/arm-ttk/arm-ttk.psd1'; "
    
    # Build Test-AzTemplate command
    ps_cmd+="Test-AzTemplate -TemplatePath '$template_file'"
    
    # Add skip tests if specified
    if [ -n "$SKIP_TESTS" ]; then
        ps_cmd+=" -Skip @('$SKIP_TESTS' -replace ',', \"', '\")"
    fi
    
    # Add PDS-specific skips for irrelevant tests
    if [ "$PDS_MODE" = true ]; then
        local pds_skips="DeploymentTemplate Should Not Contain Blanks,Location Should Not Be Hardcoded,Min And Max Value Are Numbers,Outputs Must Not Contain Secrets"
        if [ -n "$SKIP_TESTS" ]; then
            ps_cmd+=" -Skip @('$SKIP_TESTS,$pds_skips' -replace ',', \"', '\")"
        else
            ps_cmd+=" -Skip @('$pds_skips' -replace ',', \"', '\")"
        fi
    fi
    
    # Add security-focused tests
    if [ "$SECURITY_MODE" = true ]; then
        local security_tests="apiVersions Should Be Recent,Outputs Must Not Contain Secrets,Secure String Parameters Cannot Have Default,SecureString Parameters Must Not Have Default,Variables Must Be Referenced"
        ps_cmd+=" -Test @('$security_tests' -replace ',', \"', '\")"
    fi
    
    echo "$ps_cmd"
}

# Function to validate single template
validate_template() {
    local template_file="$1"
    local relative_path="${template_file#$PROJECT_ROOT/}"
    
    echo -e "${CYAN}📋 Validating: ${WHITE}$relative_path${NC}"
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${PURPLE}   File: $template_file${NC}"
    fi
    
    local ps_command=$(build_ps_command "$template_file")
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${PURPLE}   Command: pwsh -c \"$ps_command\"${NC}"
    fi
    
    # Run the validation
    local temp_output="/tmp/arm_ttk_$$.json"
    local validation_result=0
    
    if pwsh -c "$ps_command" > "$temp_output" 2>&1; then
        validation_result=0
    else
        validation_result=$?
    fi
    
    # Process and display results
    local output_content=$(cat "$temp_output")
    
    if [ "$OUTPUT_FORMAT" = "JSON" ]; then
        if [ -n "$OUTPUT_FILE" ]; then
            echo "$output_content" >> "$OUTPUT_FILE"
        else
            echo "$output_content"
        fi
    else
        # Parse and format the output
        echo -e "${WHITE}   Results:${NC}"
        
        # Count passed/failed tests
        local passed_count=$(echo "$output_content" | grep -c "PASS" || echo "0")
        local failed_count=$(echo "$output_content" | grep -c "FAIL" || echo "0")
        local warning_count=$(echo "$output_content" | grep -c "WARN" || echo "0")
        
        if [ "$failed_count" -gt 0 ]; then
            echo -e "   ${RED}❌ Failed: $failed_count${NC}"
            echo "$output_content" | grep "FAIL" | while read -r line; do
                echo -e "      ${RED}• $line${NC}"
            done
        fi
        
        if [ "$warning_count" -gt 0 ]; then
            echo -e "   ${YELLOW}⚠️  Warnings: $warning_count${NC}"
            echo "$output_content" | grep "WARN" | while read -r line; do
                echo -e "      ${YELLOW}• $line${NC}"
            done
        fi
        
        if [ "$passed_count" -gt 0 ]; then
            echo -e "   ${GREEN}✅ Passed: $passed_count${NC}"
        fi
        
        # Save full output if requested
        if [ -n "$OUTPUT_FILE" ]; then
            echo "=== Validation Results for $relative_path ===" >> "$OUTPUT_FILE"
            echo "$output_content" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    fi
    
    rm -f "$temp_output"
    return $validation_result
}

# Main execution
main() {
    echo -e "${WHITE}🔍 ARM Template Toolkit Validation${NC}"
    
    # Check prerequisites
    check_arm_ttk
    
    # Find templates to validate
    local templates=($(find_templates))
    
    if [ ${#templates[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No ARM templates found to validate${NC}"
        echo -e "${WHITE}💡 Searched in:${NC}"
        echo -e "   • infrastructure/deployment.json"
        echo -e "   • infra/main.bicep"
        echo -e "   • infra/*.json"
        echo -e "   • infrastructure/*.json"
        exit 1
    fi
    
    echo -e "${WHITE}📁 Found ${#templates[@]} template(s) to validate${NC}"
    
    if [ "$PDS_MODE" = true ]; then
        echo -e "${PURPLE}🛡️  PDS Compliance Mode Enabled${NC}"
    fi
    
    if [ "$SECURITY_MODE" = true ]; then
        echo -e "${RED}🔒 Security-Focused Validation${NC}"
    fi
    
    echo ""
    
    # Initialize output file
    if [ -n "$OUTPUT_FILE" ]; then
        echo "CoPPA ARM Template Validation Results" > "$OUTPUT_FILE"
        echo "Generated: $(date)" >> "$OUTPUT_FILE"
        echo "PDS Mode: $PDS_MODE" >> "$OUTPUT_FILE"
        echo "Security Mode: $SECURITY_MODE" >> "$OUTPUT_FILE"
        echo "=================================" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
    
    # Validate each template
    local overall_result=0
    for template in "${templates[@]}"; do
        if ! validate_template "$template"; then
            overall_result=1
        fi
        echo ""
    done
    
    # Final summary
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    if [ $overall_result -eq 0 ]; then
        echo -e "${GREEN}🎉 All validations completed successfully!${NC}"
    else
        echo -e "${RED}❌ Some validations failed. Please review the results above.${NC}"
    fi
    
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "${WHITE}📄 Detailed results saved to: $OUTPUT_FILE${NC}"
    fi
    
    exit $overall_result
}

# Run main function
main "$@"
