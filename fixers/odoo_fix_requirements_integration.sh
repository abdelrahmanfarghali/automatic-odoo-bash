#!/bin/bash

################################################################################
# Odoo Requirements Fixer - Integration Wrapper
# Use this in your main installation script
# Example: source odoo_fix_requirements.sh "$ODOO_PATH"
################################################################################

# Source this script or call it directly from your installation script

fix_odoo_requirements() {
    local ODOO_PATH="${1:-.}"
    local ARCH="${2:-auto}"
    local BACKUP="${3:-true}"
    
    # Validate inputs
    if [[ ! -d "$ODOO_PATH" ]]; then
        echo "[ERROR] Odoo path not found: $ODOO_PATH" >&2
        return 1
    fi
    
    if [[ ! -f "$ODOO_PATH/requirements.txt" ]]; then
        echo "[ERROR] requirements.txt not found in $ODOO_PATH" >&2
        return 1
    fi
    
    # Auto-detect architecture
    if [[ "$ARCH" == "auto" ]]; then
        case "$(uname -m)" in
            aarch64) ARCH="arm64" ;;
            x86_64)  ARCH="amd64" ;;
            armv7l)  ARCH="armhf" ;;
            *)       ARCH="amd64" ;;
        esac
    fi
    
    echo "[INFO] Fixing Odoo requirements for $ARCH architecture..."
    
    local REQ_FILE="$ODOO_PATH/requirements.txt"
    local OUTPUT_FILE="$ODOO_PATH/requirements_${ARCH}.txt"
    local ALT_OUTPUT_FILE="$ODOO_PATH/requirements_${ARCH}_alternatives.txt"
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    # Backup original
    if [[ "$BACKUP" == "true" ]]; then
        cp "$REQ_FILE" "${REQ_FILE}.backup_${TIMESTAMP}" || {
            echo "[ERROR] Failed to backup requirements.txt" >&2
            return 1
        }
        echo "[OK] Backup created: ${REQ_FILE}.backup_${TIMESTAMP}"
    fi
    
    # Windows-specific packages pattern
    local WIN32_PACKAGES=(
        "pywin32"
        "winreg"
        "wmi"
        "pythoncom"
        "pywintypes"
        "win-inet-pton"
        "colorama"
        "pypiwin32"
        "comtypes"
        "psutil.*win"
    )
    
    local COMMENTED=0
    local TOTAL=0
    
    # Process requirements file
    {
        while IFS= read -r line || [[ -n "$line" ]]; do
            ((TOTAL++))
            
            # Skip empty lines and existing comments
            if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
                echo "$line"
                continue
            fi
            
            # Check for Windows packages
            local is_win32=0
            for pattern in "${WIN32_PACKAGES[@]}"; do
                if [[ "$line" =~ $pattern ]]; then
                    is_win32=1
                    break
                fi
            done
            
            if [[ $is_win32 -eq 1 ]]; then
                echo "# [ARCH_EXCLUDED] $line"
                ((COMMENTED++))
            else
                echo "$line"
            fi
        done < "$REQ_FILE"
    } > "$OUTPUT_FILE"
    
    # Create alternatives file
    {
        echo "# Generated: $TIMESTAMP"
        echo "# Architecture: $ARCH"
        echo "# Alternative requirements for $ARCH Linux"
        echo ""
        
        # List excluded packages
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ $line =~ \[ARCH_EXCLUDED\] ]]; then
                echo "${line#*ARCH_EXCLUDED] }"
            fi
        done < "$OUTPUT_FILE"
        
        echo ""
        echo "# Cross-platform alternatives"
        echo "termcolor>=1.1.0"
        echo "click>=7.0"
        echo "distro>=1.4.0"
    } > "$ALT_OUTPUT_FILE"
    
    echo "[OK] Processed $TOTAL lines, commented out $COMMENTED Windows packages"
    echo "[OK] Main requirements: $OUTPUT_FILE"
    echo "[OK] Alternatives: $ALT_OUTPUT_FILE"
    
    return 0
}

################################################################################
# If executed directly (not sourced)
################################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    fix_odoo_requirements "$@"
fi
