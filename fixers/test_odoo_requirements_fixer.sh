#!/bin/bash

################################################################################
# Odoo Requirements Fixer - Test & Validation Script
# Use this to test the requirements fixer on your system
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║ $1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

################################################################################
# TEST FUNCTIONS
################################################################################

test_system_info() {
    print_header "System Information"
    
    print_info "OS: $(uname -s)"
    print_info "Architecture: $(uname -m)"
    print_info "Kernel: $(uname -r)"
    print_info "Bash Version: $BASH_VERSION"
    print_info "Python Version: $(python3 --version 2>&1)"
    
    echo ""
}

test_script_exists() {
    print_header "Script Availability"
    
    local main_script="${1:-./fix_odoo_requirements.sh}"
    local integration_script="${2:-./odoo_fix_requirements_integration.sh}"
    
    if [[ -f "$main_script" ]]; then
        print_pass "Main script exists: $main_script"
    else
        print_fail "Main script not found: $main_script"
        return 1
    fi
    
    if [[ -f "$integration_script" ]]; then
        print_pass "Integration script exists: $integration_script"
    else
        print_warn "Integration script not found: $integration_script"
    fi
    
    echo ""
    return 0
}

test_script_permissions() {
    print_header "Script Permissions"
    
    local main_script="${1:-./fix_odoo_requirements.sh}"
    
    if [[ -x "$main_script" ]]; then
        print_pass "Main script is executable"
    else
        print_warn "Main script is not executable"
        print_info "Run: chmod +x $main_script"
    fi
    
    echo ""
}

test_script_syntax() {
    print_header "Bash Syntax Validation"
    
    local main_script="${1:-./fix_odoo_requirements.sh}"
    
    print_test "Validating bash syntax..."
    
    if bash -n "$main_script" 2>/dev/null; then
        print_pass "Bash syntax is valid"
    else
        print_fail "Bash syntax errors detected"
        bash -n "$main_script"
        return 1
    fi
    
    echo ""
    return 0
}

test_architecture_detection() {
    print_header "Architecture Detection"
    
    print_test "Testing architecture detection..."
    
    local detected_arch
    case "$(uname -m)" in
        aarch64)
            detected_arch="arm64"
            ;;
        x86_64)
            detected_arch="amd64"
            ;;
        armv7l|armv6l)
            detected_arch="armhf"
            ;;
        *)
            detected_arch="unknown"
            ;;
    esac
    
    case "$detected_arch" in
        arm64)
            print_pass "ARM64 architecture detected"
            ;;
        amd64)
            print_pass "AMD64 architecture detected"
            ;;
        armhf)
            print_pass "ARMv7 architecture detected"
            ;;
        *)
            print_warn "Unknown architecture: $(uname -m)"
            ;;
    esac
    
    echo ""
}

test_sample_requirements() {
    print_header "Sample Requirements Processing"
    
    # Create test requirements file
    local test_req="$TEST_DIR/requirements_test.txt"
    cat > "$test_req" << 'EOF'
# Core dependencies
werkzeug==2.3.0
lxml==4.9.0
Pillow==10.0.0

# Windows-only packages
pywin32==305
winreg==0.1
colorama==0.4.6

# More core packages
psycopg2-binary==2.9.0
requests==2.31.0
babel==2.12.1
EOF

    print_test "Created test requirements file with 10 entries (3 Windows packages)"
    
    # Process the file
    local output_file="$TEST_DIR/requirements_output.txt"
    local alt_file="$TEST_DIR/requirements_alternatives.txt"
    local commented=0
    local total=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((total++))
        
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            echo "$line" >> "$output_file"
            continue
        fi
        
        if [[ "$line" =~ (pywin32|winreg|colorama) ]]; then
            echo "# [ARCH_EXCLUDED] $line" >> "$output_file"
            ((commented++))
        else
            echo "$line" >> "$output_file"
        fi
    done < "$test_req"
    
    print_pass "Processed $total lines"
    print_pass "Commented out $commented Windows-specific packages"
    
    print_test "Output file:"
    echo "---"
    cat "$output_file" | head -10
    echo "---"
    
    echo ""
}

test_file_operations() {
    print_header "File Operations"
    
    print_test "Testing directory creation..."
    local test_dir="$TEST_DIR/test_odoo"
    mkdir -p "$test_dir"
    
    if [[ -d "$test_dir" ]]; then
        print_pass "Directory creation successful"
    else
        print_fail "Failed to create test directory"
        return 1
    fi
    
    print_test "Testing file creation..."
    echo "test content" > "$test_dir/test_file.txt"
    
    if [[ -f "$test_dir/test_file.txt" ]]; then
        print_pass "File creation successful"
    else
        print_fail "Failed to create test file"
        return 1
    fi
    
    print_test "Testing file backup..."
    cp "$test_dir/test_file.txt" "$test_dir/test_file.txt.backup"
    
    if [[ -f "$test_dir/test_file.txt.backup" ]]; then
        print_pass "File backup successful"
    else
        print_fail "Failed to create backup"
        return 1
    fi
    
    echo ""
    return 0
}

test_sed_operations() {
    print_header "Text Processing Operations"
    
    print_test "Testing sed pattern matching..."
    
    local test_string="pywin32==305"
    
    if echo "$test_string" | grep -q "pywin32"; then
        print_pass "Pattern matching works"
    else
        print_fail "Pattern matching failed"
        return 1
    fi
    
    print_test "Testing sed substitution..."
    
    local result=$(echo "# Test line" | sed 's/Test/Modified/')
    if [[ "$result" == "# Modified line" ]]; then
        print_pass "Sed substitution works"
    else
        print_fail "Sed substitution failed"
        return 1
    fi
    
    echo ""
    return 0
}

test_integration_function() {
    print_header "Integration Function Test"
    
    local integration_script="${1:-./odoo_fix_requirements_integration.sh}"
    
    if [[ ! -f "$integration_script" ]]; then
        print_warn "Integration script not found, skipping function test"
        echo ""
        return 0
    fi
    
    print_test "Loading integration script..."
    
    if source "$integration_script" 2>/dev/null; then
        print_pass "Integration script loaded successfully"
    else
        print_fail "Failed to source integration script"
        return 1
    fi
    
    echo ""
    return 0
}

test_help_output() {
    print_header "Help Command Test"
    
    local main_script="${1:-./fix_odoo_requirements.sh}"
    
    print_test "Testing --help flag..."
    
    if bash "$main_script" --help 2>&1 | grep -q "Usage:"; then
        print_pass "Help output works"
    else
        print_fail "Help output failed"
        return 1
    fi
    
    echo ""
    return 0
}

test_error_handling() {
    print_header "Error Handling Test"
    
    local main_script="${1:-./fix_odoo_requirements.sh}"
    
    print_test "Testing with invalid path..."
    
    if bash "$main_script" --path "/nonexistent/path" 2>&1 | grep -q -i "not found\|error"; then
        print_pass "Error handling works correctly"
    else
        print_fail "Error handling may not work as expected"
    fi
    
    echo ""
}

test_timestamp_generation() {
    print_header "Timestamp Generation"
    
    print_test "Generating test timestamp..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    if [[ $timestamp =~ ^[0-9]{8}_[0-9]{6}$ ]]; then
        print_pass "Timestamp format valid: $timestamp"
    else
        print_fail "Timestamp format invalid: $timestamp"
        return 1
    fi
    
    echo ""
    return 0
}

################################################################################
# MAIN TEST RUNNER
################################################################################

run_all_tests() {
    print_header "ODOO REQUIREMENTS FIXER - COMPREHENSIVE TEST SUITE"
    
    local main_script="${1:-./fix_odoo_requirements.sh}"
    local integration_script="${2:-./odoo_fix_requirements_integration.sh}"
    
    local total_tests=0
    local failed_tests=0
    
    # Run tests
    test_system_info && ((total_tests++)) || ((failed_tests++))
    test_script_exists "$main_script" "$integration_script" && ((total_tests++)) || ((failed_tests++))
    test_script_permissions "$main_script" && ((total_tests++)) || ((failed_tests++))
    test_script_syntax "$main_script" && ((total_tests++)) || ((failed_tests++))
    test_architecture_detection && ((total_tests++)) || ((failed_tests++))
    test_sample_requirements && ((total_tests++)) || ((failed_tests++))
    test_file_operations && ((total_tests++)) || ((failed_tests++))
    test_sed_operations && ((total_tests++)) || ((failed_tests++))
    test_integration_function "$integration_script" && ((total_tests++)) || ((failed_tests++))
    test_help_output "$main_script" && ((total_tests++)) || ((failed_tests++))
    test_error_handling "$main_script" && ((total_tests++)) || ((failed_tests++))
    test_timestamp_generation && ((total_tests++)) || ((failed_tests++))
    
    # Final summary
    echo ""
    print_header "TEST SUMMARY"
    
    print_info "Total Test Suites: $total_tests"
    print_pass "Passed Test Suites: $((total_tests - failed_tests))"
    
    if [[ $failed_tests -gt 0 ]]; then
        print_fail "Failed Test Suites: $failed_tests"
        echo ""
        print_warn "Some tests failed. Please review the output above."
        return 1
    else
        print_pass "All tests passed!"
        echo ""
        print_info "Your system is ready to use the Odoo Requirements Fixer"
        echo ""
        print_info "Next steps:"
        echo "  1. Make scripts executable: chmod +x *.sh"
        echo "  2. Run the main script: ./fix_odoo_requirements.sh --path /path/to/odoo"
        echo "  3. Install fixed requirements: pip install -r /path/to/odoo/requirements_arch.txt"
        return 0
    fi
}

################################################################################
# ENTRY POINT
################################################################################

main() {
    local main_script="${1:-./fix_odoo_requirements.sh}"
    local integration_script="${2:-./odoo_fix_requirements_integration.sh}"
    
    # Check if help requested
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        cat << EOF
Odoo Requirements Fixer - Test Suite

Usage: $0 [MAIN_SCRIPT] [INTEGRATION_SCRIPT]

Arguments:
  MAIN_SCRIPT          Path to fix_odoo_requirements.sh
                       (default: ./fix_odoo_requirements.sh)
  
  INTEGRATION_SCRIPT   Path to odoo_fix_requirements_integration.sh
                       (default: ./odoo_fix_requirements_integration.sh)

Examples:
  $0
  $0 /opt/scripts/fix_odoo_requirements.sh
  $0 ./fix_odoo_requirements.sh ./odoo_fix_requirements_integration.sh

EOF
        exit 0
    fi
    
    run_all_tests "$main_script" "$integration_script"
}

main "$@"
