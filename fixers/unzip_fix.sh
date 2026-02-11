#!/bin/bash

# QUICK FIX FOR CORRUPTED ODOO ZIP FILES

VERSION=""
SCRIPT_DIR=""
ZIP_FILE=""
ODOO_PATH=""
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           ODOO ZIP FILE - QUICK FIX                           ║"
echo "║                                                                ║"
echo "║  This script fixes corrupted Odoo ZIP files by               ║"
echo "║  deleting the bad file and downloading a fresh copy          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BLUE}Target: Odoo ${VERSION}${NC}"
echo -e "${BLUE}File: $ZIP_FILE${NC}"
echo -e "${BLUE}URL: $GITHUB_URL${NC}"
echo ""



while [[ $# -gt 0 ]]; do
    case $1 in
        --zipped-file|-zf)
            ZIP_FILE="$2"
            shift 2
            ;;
        --version-info|-v)
            VERSION="$2"
            shift 2
            ;;
        --script-root|-sr)
            SCRIPT_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "kindly please use argument --connection-summary | -cs for your currently installed odoo version information summary"
            exit 1
            ;;
    esac
done


main() {
    # Check if file exists
    if [ ! -f "$ZIP_FILE" ]; then
        echo -e "${YELLOW}⚠ File not found: $ZIP_FILE${NC}"
    fi

    # Verify file
    SIZE=$(stat -f%z "$ZIP_FILE" 2>/dev/null || stat -c%s "$ZIP_FILE" 2>/dev/null)
    SIZE_MB=$((SIZE / 1024 / 1024))
    echo "  Size: ${SIZE_MB}MB"

    echo ""
    echo -e "${BLUE}Verifying ZIP integrity...${NC}"

    if unzip -t "$ZIP_FILE" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ ZIP file is valid and complete${NC}"
        echo ""
        echo -e "${BLUE}Extracting to /opt/odoo$VERSION...${NC}"
        
        # Create the specific directory and unzip directly into it
        sudo mkdir -p "/opt/odoo$VERSION"
        sudo unzip -o "$ZIP_FILE" -d "/opt/odoo$VERSION/"
        
        echo -e "${GREEN}✓ Extraction successful${NC}"
        echo -e "${BLUE}Running installer...${NC}"

        exit 0
    else
        echo -e "${RED}✗ ZIP file is still corrupted${NC}"
        echo ""
        echo "Try downloading again:"
        echo "  bash $0 $VERSION"
        exit 1
    fi
}