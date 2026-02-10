#!/usr/bin/env bash

# Odoo Requirements Fixer - QUICK START GUIDE
# Copy and paste these commands to get started immediately

################################################################################
# OPTION 1: Direct Usage (Recommended for beginners)
################################################################################

# Step 1: Make the script executable
chmod +x fix_odoo_requirements.sh

# Step 2: Run it on your Odoo installation
export ODOO_PATH="/opt/odoo"  # Change to your Odoo path
bash fix_odoo_requirements.sh --path "$ODOO_PATH"

# Step 3: Install the fixed requirements
pip install -r "$ODOO_PATH/requirements_arch.txt"
pip install -r "$ODOO_PATH/requirements_arch_alternatives.txt"


################################################################################
# OPTION 2: Integration into Existing Script
################################################################################

#!/bin/bash
# Add this to your existing installation script

ODOO_PATH="/opt/odoo"
ARCH="auto"  # or specify: arm64, amd64, armhf

# 1. Run prerequisite fixes
sudo bash prereq_fix.sh --path "$ODOO_PATH"

# 2. Fix requirements for architecture
bash fix_odoo_requirements.sh --path "$ODOO_PATH" --arch "$ARCH" --backup

# 3. Install requirements
pip install -r "$ODOO_PATH/requirements_arch.txt"
pip install -r "$ODOO_PATH/requirements_arch_alternatives.txt"


################################################################################
# OPTION 3: Docker Usage
################################################################################

# In your Dockerfile:
# FROM arm64v8/ubuntu:22.04
# 
# WORKDIR /opt/odoo
# COPY fix_odoo_requirements.sh .
# 
# RUN git clone https://github.com/odoo/odoo.git --depth 1 --branch 17.0 .
# RUN bash fix_odoo_requirements.sh --path /opt/odoo
# RUN pip install -r /opt/odoo/requirements_arch.txt


################################################################################
# COMMON COMMANDS
################################################################################

# Auto-detect architecture (recommended)
bash fix_odoo_requirements.sh --path /opt/odoo

# Specific architecture
bash fix_odoo_requirements.sh --path /opt/odoo --arch arm64

# Without backup (use with caution)
bash fix_odoo_requirements.sh --path /opt/odoo --no-backup

# Custom output filename
bash fix_odoo_requirements.sh --path /opt/odoo --output-suffix requirements_ubuntu

# Show help
bash fix_odoo_requirements.sh --help


################################################################################
# TROUBLESHOOTING QUICK FIXES
################################################################################

# If permission denied
sudo bash fix_odoo_requirements.sh --path /opt/odoo

# If requirements.txt not found
ls -la /opt/odoo/requirements.txt

# If pip install fails, check conflicts
pip check

# Restore original file
cp /opt/odoo/requirements.txt.backup_* /opt/odoo/requirements.txt

# Check your architecture
uname -m


################################################################################
# WHAT EACH FILE DOES
################################################################################

# requirements_arch.txt
# → Fixed version with Windows packages commented out
# → Install with: pip install -r requirements_arch.txt

# requirements_arch_alternatives.txt
# → Linux alternatives for excluded Windows packages
# → Install with: pip install -r requirements_arch_alternatives.txt

# requirements.txt.backup_[TIMESTAMP]
# → Backup of your original file
# → Restore with: cp requirements.txt.backup_* requirements.txt


################################################################################
# REAL-WORLD EXAMPLE: Complete ARM64 Installation
################################################################################

#!/bin/bash
set -e

ODOO_PATH="/opt/odoo"
ODOO_USER="odoo"

echo "Installing Odoo 17 on ARM64..."

# 1. Clone Odoo
git clone https://github.com/odoo/odoo.git --depth 1 --branch 17.0 "$ODOO_PATH"

# 2. Fix requirements
bash fix_odoo_requirements.sh --path "$ODOO_PATH" --arch arm64

# 3. Create virtual environment
python3 -m venv "$ODOO_PATH/venv"
source "$ODOO_PATH/venv/bin/activate"

# 4. Upgrade pip
pip install --upgrade pip setuptools wheel

# 5. Install dependencies
pip install -r "$ODOO_PATH/requirements_arch.txt"
pip install -r "$ODOO_PATH/requirements_arch_alternatives.txt"

# 6. Set permissions
sudo chown -R "$ODOO_USER:$ODOO_USER" "$ODOO_PATH"

# 7. Done!
echo "Installation complete!"


################################################################################
# FOR MULTIPLE ODOO VERSIONS
################################################################################

#!/bin/bash

# Fix requirements for multiple Odoo installations

VERSIONS=(
    "/opt/odoo17:17.0"
    "/opt/odoo16:16.0"
    "/opt/odoo15:15.0"
)

for version in "${VERSIONS[@]}"; do
    IFS=':' read -r path branch <<< "$version"
    
    echo "Processing $path (branch $branch)..."
    bash fix_odoo_requirements.sh --path "$path" --arch auto
    
    echo "Installing requirements for $path..."
    pip install -r "$path/requirements_arch.txt"
done


################################################################################
# VERIFY INSTALLATION
################################################################################

# After installation, verify everything is working:

# 1. Check dependencies
pip check

# 2. Import Odoo modules
python3 -c "import odoo; print(odoo.__version__)"

# 3. Run Odoo help
python3 -m odoo --help


################################################################################
# TIPS & TRICKS
################################################################################

# Faster installation with cached packages
pip install -r requirements_arch.txt --cache-dir /tmp/pip-cache

# Parallel installation (faster)
pip install -r requirements_arch.txt -v --compile

# See what's being installed
pip install -r requirements_arch.txt -v

# Only show what would be installed
pip install -r requirements_arch.txt --dry-run

# Save installation report
pip install -r requirements_arch.txt -q | tee install_log.txt


################################################################################
# SUPPORT
################################################################################

# If something goes wrong:
# 1. Check Troubleshooting section in README
# 2. Run test suite: bash test_odoo_requirements_fixer.sh
# 3. Review Odoo documentation: https://www.odoo.com/documentation

# Questions? Check the comprehensive README_ODOO_REQUIREMENTS_FIXER.md file
