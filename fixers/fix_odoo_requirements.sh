#!/bin/bash

################################################################################
# Odoo Requirements.txt Architecture Fixer
# Fixes requirements.txt for specific CPU architectures (ARM64/AMD64)
# Removes/comments out win32 packages and generates alternative requirements
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

################################################################################
# FUNCTIONS
################################################################################

print_header() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

show_usage() {
    cat << EOF
Usage: $0 --path <ODOO_PATH> [OPTIONS]

Required Arguments:
    --path <ODOO_PATH>      Path to Odoo installation directory

Optional Arguments:
    --arch <ARCHITECTURE>   Target architecture: arm64, amd64, auto (default: auto)
    --backup                Create backup of original requirements.txt (default: yes)
    --no-backup             Skip backup creation
    --output-suffix <NAME>  Custom suffix for alternative requirements file
                           (default: "requirements_arch")
    --help                  Show this help message

Examples:
    $0 --path /opt/odoo
    $0 --path /opt/odoo --arch arm64
    $0 --path /opt/odoo --arch amd64 --output-suffix requirements_ubuntu
    
EOF
}

detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        aarch64)
            echo "arm64"
            ;;
        x86_64)
            echo "amd64"
            ;;
        armv7l|armv6l)
            echo "armhf"
            ;;
        *)
            print_warning "Unknown architecture: $arch, defaulting to amd64"
            echo "amd64"
            ;;
    esac
}

validate_odoo_path() {
    local path="$1"
    
    if [[ ! -d "$path" ]]; then
        print_error "Odoo path does not exist: $path"
        return 1
    fi
    
    if [[ ! -f "$path/requirements.txt" ]]; then
        print_error "requirements.txt not found in: $path"
        return 1
    fi
    
    return 0
}

get_win32_packages() {
    # List of known Windows-specific packages to comment out
    cat << 'EOF'
pywin32
winreg
wmi
pythoncom
pywintypes
win-inet-pton
colorama
pypiwin32
psutil.*win
winreg
python-dotenv
comtypes
EOF
}

get_architecture_specific_alternatives() {
    local arch="$1"
    
    cat << 'EOF'
# Architecture-specific alternatives for win32 packages
# These are pre-installed alternatives for Linux ARM64/AMD64

# Replacement for pywin32 functionality (file system operations)
pathlib2; python_version < '3.4'

# For colored output (colorama alternative)
termcolor>=1.1.0
click>=7.0

# For system information (cross-platform)
distro>=1.4.0

# Additional recommended packages for stability
six>=1.16.0
EOF
}

backup_requirements() {
    local req_file="$1"
    local backup_file="${req_file}.backup_${TIMESTAMP}"
    
    if cp "$req_file" "$backup_file"; then
        print_success "Backup created: $backup_file"
        return 0
    else
        print_error "Failed to create backup"
        return 1
    fi
}

process_requirements_file() {
    local input_file="$1"
    local output_file="$2"
    local arch="$3"
    
    print_header "Processing requirements.txt for $arch architecture"
    
    # Create temporary files
    local temp_main=$(mktemp)
    local temp_arch=$(mktemp)
    local win32_patterns=$(mktemp)
    
    # Get Windows package patterns
    get_win32_packages > "$win32_patterns"
    
    > "$temp_main"
    > "$temp_arch"
    
    local line_num=0
    local commented_count=0
    local total_lines=0
    
    # Process the input file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        ((total_lines++))
        
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            echo "$line" >> "$temp_main"
            continue
        fi
        
        # Extract package name (before any spaces, brackets, or semicolons)
        local package_name=$(echo "$line" | sed 's/[[:space:]]*\[.*//' | sed 's/[[:space:]]*;.*//' | sed 's/[[:space:]]*[<>=].*//')
        package_name=$(echo "$package_name" | xargs) # Trim whitespace
        
        # Check if this is a win32 package
        local is_win32=0
        while IFS= read -r pattern; do
            [[ -z "$pattern" ]] && continue
            if [[ "$package_name" =~ $pattern ]]; then
                is_win32=1
                break
            fi
        done < "$win32_patterns"
        
        if [[ $is_win32 -eq 1 ]]; then
            # Comment out the line and add it to arch file
            echo "# [ARCH_EXCLUDED] $line" >> "$temp_main"
            echo "$line  # Excluded for Linux $arch" >> "$temp_arch"
            ((commented_count++))
        else
            echo "$line" >> "$temp_main"
        fi
        
    done < "$input_file"
    
    # Copy processed main requirements
    cp "$temp_main" "$output_file"
    
    # Create alternative requirements file
    local alt_output_file=$(dirname "$output_file")/$(basename "$output_file" .txt)_alternatives.txt
    {
        echo "# Generated: $TIMESTAMP"
        echo "# Architecture: $arch"
        echo "# Alternative requirements for Linux $arch architecture"
        echo "# These packages are replacements/alternatives for excluded Windows-specific packages"
        echo ""
        cat "$temp_arch"
        echo ""
        echo "# Additional architecture-specific optimizations"
        get_architecture_specific_alternatives "$arch"
    } > "$alt_output_file"
    
    # Cleanup
    rm -f "$temp_main" "$temp_arch" "$win32_patterns"
    
    # Print statistics
    print_success "Processed $total_lines total lines"
    print_success "Commented out $commented_count Windows-specific packages"
    print_success "Main requirements: $output_file"
    print_success "Alternative requirements: $alt_output_file"
    
    return 0
}

################################################################################
# MAIN SCRIPT
################################################################################

main() {
    local odoo_path=""
    local architecture="auto"
    local do_backup=true
    local output_suffix="requirements_arch"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --path)
                odoo_path="$2"
                shift 2
                ;;
            --arch)
                architecture="$2"
                shift 2
                ;;
            --backup)
                do_backup=true
                shift
                ;;
            --no-backup)
                do_backup=false
                shift
                ;;
            --output-suffix)
                output_suffix="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$odoo_path" ]]; then
        print_error "Missing required argument: --path"
        show_usage
        exit 1
    fi
    
    # Validate Odoo path
    if ! validate_odoo_path "$odoo_path"; then
        exit 1
    fi
    
    # Detect architecture if auto
    if [[ "$architecture" == "auto" ]]; then
        architecture=$(detect_architecture)
        print_success "Auto-detected architecture: $architecture"
    fi
    
    # Validate architecture
    case "$architecture" in
        arm64|amd64|armhf)
            print_success "Target architecture: $architecture"
            ;;
        *)
            print_error "Invalid architecture: $architecture"
            print_error "Supported: arm64, amd64, armhf"
            exit 1
            ;;
    esac
    
    print_header "Odoo Requirements Fixer"
    echo "Odoo Path: $odoo_path"
    echo "Architecture: $architecture"
    echo "Backup: $([[ $do_backup == true ]] && echo 'Yes' || echo 'No')"
    echo ""
    
    local req_file="$odoo_path/requirements.txt"
    local output_file="$odoo_path/${output_suffix}.txt"
    
    # Backup original if requested
    if [[ $do_backup == true ]]; then
        if ! backup_requirements "$req_file"; then
            exit 1
        fi
    fi
    
    # Process requirements file
    if process_requirements_file "$req_file" "$output_file" "$architecture"; then
        print_header "Success!"
        echo ""
        echo "Next steps:"
        echo "1. Review the changes in: $output_file"
        echo "2. Install main requirements: pip install -r $output_file"
        echo "3. Install alternatives: pip install -r ${output_file%.txt}_alternatives.txt"
        echo ""
        echo "To revert to original:"
        echo "  cp ${req_file}.backup_${TIMESTAMP} $req_file"
        exit 0
    else
        print_error "Failed to process requirements.txt"
        exit 1
    fi
}

# Run main function
main "$@"
