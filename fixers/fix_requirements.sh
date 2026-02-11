#!/bin/bash

################################################################################
# Odoo Requirements.txt Architecture-Aware Fixer with Alternatives
# Intelligently comments out packages incompatible with target architecture
# Generates alternative requirements file with suitable replacements
# Handles platform markers: sys_platform == 'win32', sys_platform != 'win32', etc.
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;37m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

################################################################################
# FUNCTIONS
################################################################################

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${GRAY}ℹ${NC} $1"
}

print_alt() {
    echo -e "${CYAN}→${NC} $1"
}

show_usage() {
    cat << 'EOF'
Usage: ./fix_requirements.sh --input <INPUT_FILE> --output <OUTPUT_FILE> [OPTIONS]

Required Arguments:
    --input <FILE>          Path to original requirements.txt
    --output <FILE>         Path to processed requirements.txt

Optional Arguments:
    --arch <ARCH>           Target architecture: arm64, amd64, armhf (default: auto-detect)
    --backup                Create backup of input file (default: yes)
    --no-backup             Skip backup creation
    --install-alternatives  Automatically install alternatives after processing
    --help                  Show this help message

Examples:
    ./fix_requirements.sh --input requirements.txt --output requirements_arm64.txt
    ./fix_requirements.sh --input requirements.txt --output requirements_arm64.txt --install-alternatives
    ./fix_requirements.sh --input requirements.txt --output requirements_clean.txt --arch amd64

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

validate_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    return 0
}

# Define alternative packages for Windows-specific packages
get_alternatives_for_package() {
    local package="$1"
    
    case "$package" in
        psycopg2)
            # PostgreSQL adapter - use native package (usually pre-installed on Linux)
            cat << 'EOF'
# psycopg2 alternatives (Linux/Unix)
# psycopg2 is used for PostgreSQL database connections
# Install system package instead: sudo apt-get install python3-psycopg2
# Or use pre-compiled wheel: pip install psycopg2-binary
psycopg2-binary>=2.9.0; python_version >= '3.8'
EOF
            ;;
        pypiwin32)
            # Windows Python bindings - not needed on Linux
            cat << 'EOF'
# pypiwin32 alternatives (Linux/Unix)
# pypiwin32 provides Windows API access
# Linux/Unix systems don't need this - system APIs are accessed directly
# No replacement needed - functionality provided by standard Python libraries
EOF
            ;;
        rl-renderPM)
            # ReportLab rendering engine - platform-specific
            cat << 'EOF'
# rl-renderPM alternatives (Linux/Unix)
# rl-renderPM is included in reportlab package on Linux systems
# Install reportlab which includes renderPM support:
reportlab>=3.5.59
EOF
            ;;
        *)
            echo "# $package - Windows-specific package, no direct alternative"
            ;;
    esac
}

# Evaluate if a platform marker applies to the target architecture
# Returns 0 if line should be KEPT, 1 if it should be COMMENTED OUT
should_keep_line() {
    local line="$1"
    local target_arch="$2"
    
    # If no platform marker, keep the line
    if [[ ! "$line" =~ \; ]]; then
        return 0
    fi
    
    # Extract the marker part (after the semicolon)
    local marker="${line##*;}"
    marker=$(echo "$marker" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') # Trim whitespace safely
    
    # Evaluate based on target architecture
    case "$target_arch" in
        arm64|amd64|armhf)
            # For Linux architectures (arm64, amd64, armhf):
            # - Comment out if marker contains "sys_platform == 'win32'" (explicitly Windows-only)
            # - Keep if marker contains "sys_platform != 'win32'" (explicitly not Windows)
            # - Keep by default for Python version conditions without explicit win32 marker
            
            # Check for explicit Windows-only marker: sys_platform == 'win32'
            if echo "$marker" | grep -q "sys_platform.*==.*['\"]win32['\"]"; then
                return 1  # Comment out - this is for Windows only
            fi
            
            # Keep everything else (non-Windows platforms and Python version conditions)
            return 0
            ;;
        *)
            return 0  # Keep by default for unknown architectures
            ;;
    esac
}

# Extract package name from a requirement line
get_package_name() {
    local line="$1"
    # Remove everything after ;, [, <, >, =, !, spaces
    local pkg=$(echo "$line" | sed -E 's/[[:space:]]*[\[;#<>=!].*//')
    echo "$pkg" | xargs
}

backup_file() {
    local file="$1"
    local backup_file="${file}.backup_${TIMESTAMP}"
    
    if cp "$file" "$backup_file"; then
        print_success "Backup created: $backup_file"
        return 0
    else
        print_error "Failed to create backup"
        return 1
    fi
}

process_requirements() {
    local input_file="$1"
    local output_file="$2"
    local target_arch="$3"
    
    print_header "Processing Requirements for $target_arch"
    
    local temp_file=$(mktemp)
    local line_num=0
    local kept_lines=0
    local commented_lines=0
    local empty_lines=0
    local windows_only_packages=()
    
    > "$temp_file"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        # Handle empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            echo "$line" >> "$temp_file"
            ((empty_lines++))
            continue
        fi
        
        # Check if line should be kept
        if should_keep_line "$line" "$target_arch"; then
            echo "$line" >> "$temp_file"
            ((kept_lines++))
        else
            # Comment out the line by placing # at the beginning
            local pkg_name=$(get_package_name "$line")
            echo "# $line" >> "$temp_file"
            ((commented_lines++))
            windows_only_packages+=("$pkg_name")
        fi
        
    done < "$input_file"
    
    # Write to output file
    cp "$temp_file" "$output_file"
    rm -f "$temp_file"
    
    # Print summary
    echo ""
    print_success "Processing complete"
    print_info "Total lines processed: $line_num"
    print_info "Lines kept: $kept_lines"
    print_info "Lines commented out: $commented_lines"
    print_info "Empty/comment lines: $empty_lines"
    
    if [[ $commented_lines -gt 0 ]]; then
        echo ""
        print_warning "Excluded Windows-only packages:"
        printf '%s\n' "${windows_only_packages[@]}" | sed 's/^/  - /'
    fi
    
    echo ""
    print_success "Output file: $output_file"
    
    # Generate alternatives file
    generate_alternatives_file "$output_file" "${windows_only_packages[@]}"
    
    return 0
}

generate_alternatives_file() {
    local output_file="$1"
    shift
    local windows_packages=("$@")
    
    local base_name="${output_file%.txt}"
    local alt_file="${base_name}_alternatives.txt"
    
    {
        echo "# Generated: $TIMESTAMP"
        echo "# Alternative packages for Windows-excluded packages"
        echo "# These are replacements/additions for packages commented out"
        echo "# Install after main requirements: pip install -r $alt_file"
        echo ""
        echo "##############################################################################"
        echo "# ALTERNATIVES FOR EXCLUDED WINDOWS-SPECIFIC PACKAGES"
        echo "##############################################################################"
        echo ""
        
        if [[ ${#windows_packages[@]} -eq 0 ]]; then
            echo "# No Windows packages were excluded - no alternatives needed"
        else
            for pkg in "${windows_packages[@]}"; do
                echo "# ─────────────────────────────────────────────────────────────────"
                echo "# Package: $pkg"
                echo "# ─────────────────────────────────────────────────────────────────"
                get_alternatives_for_package "$pkg"
                echo ""
            done
        fi
        
        echo "##############################################################################"
        echo "# ADDITIONAL SYSTEM RECOMMENDATIONS"
        echo "##############################################################################"
        echo ""
        echo "# For production Odoo installations on Linux, also ensure you have:"
        echo ""
        echo "# 1. PostgreSQL client libraries (if using PostgreSQL database):"
        echo "#    Ubuntu/Debian: sudo apt-get install libpq-dev"
        echo "#    RedHat/CentOS: sudo yum install libpq-devel"
        echo ""
        echo "# 2. LDAP development libraries (if using LDAP authentication):"
        echo "#    Ubuntu/Debian: sudo apt-get install libldap2-dev libsasl2-dev"
        echo "#    RedHat/CentOS: sudo yum install openldap-devel"
        echo ""
        echo "# 3. Python development headers:"
        echo "#    Ubuntu/Debian: sudo apt-get install python3-dev"
        echo "#    RedHat/CentOS: sudo yum install python3-devel"
        echo ""
        echo "# 4. Image processing libraries (for Pillow):"
        echo "#    Ubuntu/Debian: sudo apt-get install libjpeg-dev zlib1g-dev"
        echo "#    RedHat/CentOS: sudo yum install libjpeg-turbo-devel zlib-devel"
        echo ""
        
    } > "$alt_file"
    
    print_success "Alternatives file: $alt_file"
}

install_alternatives() {
    local base_name="$1"
    local alt_file="${base_name}_alternatives.txt"
    
    if [[ ! -f "$alt_file" ]]; then
        print_warning "Alternatives file not found: $alt_file"
        return 1
    fi
    
    echo ""
    print_header "Installing Alternative Packages"
    echo ""
    print_info "Installing from: $alt_file"
    echo ""
    
    # Extract non-comment lines from alternatives file
    local temp_alt=$(mktemp)
    grep -v "^#" "$alt_file" | grep -v "^$" > "$temp_alt" || true
    
    if [[ -s "$temp_alt" ]]; then
        print_info "Found alternative packages to install:"
        cat "$temp_alt" | sed 's/^/  /'
        echo ""
        
        if pip install -r "$temp_alt"; then
            print_success "Alternative packages installed successfully"
            rm -f "$temp_alt"
            return 0
        else
            print_error "Failed to install some alternative packages"
            print_info "Manual installation available in: $alt_file"
            rm -f "$temp_alt"
            return 1
        fi
    else
        print_info "No pip-installable alternatives found (some require system packages)"
        print_info "See $alt_file for system package recommendations"
        rm -f "$temp_alt"
        return 0
    fi
}

################################################################################
# MAIN SCRIPT
################################################################################

main() {
    local input_file=""
    local output_file=""
    local target_arch="auto"
    local do_backup=true
    local install_alts=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --input)
                input_file="$2"
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            --arch)
                target_arch="$2"
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
            --install-alternatives)
                install_alts=true
                shift
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
    if [[ -z "$input_file" || -z "$output_file" ]]; then
        print_error "Missing required arguments"
        show_usage
        exit 1
    fi
    
    # Validate input file
    if ! validate_file "$input_file"; then
        exit 1
    fi
    
    # Auto-detect architecture if needed
    if [[ "$target_arch" == "auto" ]]; then
        target_arch=$(detect_architecture)
        print_success "Auto-detected architecture: $target_arch"
    fi
    
    # Validate architecture
    case "$target_arch" in
        arm64|amd64|armhf)
            print_success "Target architecture: $target_arch"
            ;;
        *)
            print_error "Invalid architecture: $target_arch"
            print_error "Supported: arm64, amd64, armhf"
            exit 1
            ;;
    esac
    
    echo ""
    print_header "Odoo Requirements Fixer with Alternatives"
    print_info "Input file: $input_file"
    print_info "Output file: $output_file"
    print_info "Architecture: $target_arch"
    print_info "Create backup: $([[ $do_backup == true ]] && echo 'Yes' || echo 'No')"
    print_info "Install alternatives: $([[ $install_alts == true ]] && echo 'Yes' || echo 'No')"
    
    # Backup original if requested
    if [[ $do_backup == true ]]; then
        echo ""
        if ! backup_file "$input_file"; then
            exit 1
        fi
    fi
    
    # Process requirements file
    echo ""
    if process_requirements "$input_file" "$output_file" "$target_arch"; then
        
        # Install alternatives if requested
        if [[ $install_alts == true ]]; then
            local base_name="${output_file%.txt}"
            if install_alternatives "$base_name"; then
                print_header "✓ Complete Setup Successful!"
                echo ""
                echo "Your Odoo installation is ready:"
                echo "  Main packages:   pip install -r $output_file"
                echo "  Alternatives:    pip install -r ${base_name}_alternatives.txt"
                echo ""
                sudo pip3 install -r $output_file -r ${base_name}_alternatives.txt --no-build-isolation
            else
                print_header "✓ Processing Successful (with warnings)"
                echo ""
                echo "Main requirements processed successfully."
                echo "Some alternatives require manual installation."
                echo "See ${base_name}_alternatives.txt for details."
                echo ""
            fi
        else
            print_header "✓ Processing Successful!"
            echo ""
            local base_name="${output_file%.txt}"
            echo "Next steps:"
            echo "  1. Install main packages:"
            echo "     pip install -r $output_file"
            echo ""
            echo "  2. Install alternatives (optional):"
            echo "     pip install -r ${base_name}_alternatives.txt"
            echo ""
            echo "  3. Or install both in one command:"
            echo "     pip install -r $output_file -r ${base_name}_alternatives.txt"
            echo ""
            sudo pip3 install -r $output_file -r ${base_name}_alternatives.txt --no-build-isolation
        fi
        
        if [[ $do_backup == true ]]; then
            echo "To revert to original:"
            echo "  cp ${input_file}.backup_${TIMESTAMP} $input_file"
            echo ""
        fi
        
        exit 0
    else
        print_error "Failed to process requirements file"
        exit 1
    fi
}

# Run main function
main "$@"
