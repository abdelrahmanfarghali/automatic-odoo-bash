#!/bin/bash

################################################################################
# Example: Complete Odoo Installation Script with Requirements Fixer
# This shows how to integrate the requirements fixer into your existing script
################################################################################

set -euo pipefail

# Configuration
ODOO_PATH="${ODOO_PATH:-.}"
ODOO_USER="${ODOO_USER:-odoo}"
ODOO_GROUP="${ODOO_GROUP:-odoo}"
ARCH="${ARCH:-auto}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
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
################################################################################
# MAIN INSTALLATION SCRIPT
################################################################################

main() {

    local odoo_path=""
    local architecture="auto"
    local do_backup=true
    local output_suffix="requirements_arch"

    print_step "Starting Odoo Installation Process"
    
    # Step 1: Prerequisites (your existing script: DO NOT ENABLE)
    #print_step "Running prerequisite fixes..."
    #if [[ -f "prereq_fix.sh" ]]; then
    #    bash prereq_fix.sh --path "$ODOO_PATH" || {
    #        print_error "Prerequisite fixes failed"
    #        exit 1
    #    }
    #fi
    #print_success "Prerequisites completed"
    
    # Step 2: Fix Odoo requirements for architecture
    print_step "Fixing Odoo requirements for detected architecture..."
    if [[ -f "fix_odoo_requirements.sh" ]]; then
        bash fix_odoo_requirements.sh --path "$ODOO_PATH" --arch "$ARCH" --backup || {
            print_error "Requirements fixing failed"
            exit 1
        }
    else
        print_error "fix_odoo_requirements.sh not found"
        exit 1
    fi
    print_success "Requirements fixed"
    
    # Step 3: Install main requirements
    print_step "Installing main Odoo requirements..."
    
    # Detect which requirements file to use
    local req_file="$ODOO_PATH/requirements_arch.txt"
    if [[ ! -f "$req_file" ]]; then
        req_file="$ODOO_PATH/requirements.txt"
    fi
    
    if pip install -r "$req_file" --upgrade; then
        print_success "Main requirements installed"
    else
        print_error "Failed to install main requirements"
        exit 1
    fi
    
    # Step 4: Install alternative/supplementary requirements
    print_step "Installing supplementary packages..."
    sudo pip3 install -r $ODOO_PATH/requirements.txt --no-build-isolation
    local alt_file="${req_file%.txt}_alternatives.txt"
    
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
    
    if [[ -f "$alt_file" ]]; then
        if pip install -r "$alt_file" --upgrade --no-build-isolation; then
            print_success "Supplementary packages installed"
        else
            print_warning "Some supplementary packages failed (non-critical)"
        fi
    fi
    
    # Step 5: Additional setup (your existing logic)
    print_step "Setting up Odoo environment..."
    # Add your additional setup here
    
    # Example: Set permissions
    if id "$ODOO_USER" &>/dev/null; then
        chown -R "$ODOO_USER:$ODOO_GROUP" "$ODOO_PATH"
        print_success "Permissions configured"
    fi
    
    # Step 6: Verify installation
    print_step "Verifying installation..."
    if python3 -m pip check &>/dev/null; then
        print_success "All dependencies satisfied"
    else
        print_warning "Some dependency conflicts detected (review with pip check)"
        python3 -m pip check || true
    fi
    
    print_step "Installation complete!"
    echo ""
    echo "Summary:"
    echo "  Odoo Path: $ODOO_PATH"
    echo "  Architecture: $ARCH"
    echo "  Requirements: $req_file"
    echo "  Alternatives: $alt_file"
}

# Run main
main "$@"
