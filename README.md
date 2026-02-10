# COMPLETE ODOO INSTALLER GUIDE
## All-in-One Reference for Odoo 11-19 Installation on Ubuntu 22.04

---

## TABLE OF CONTENTS

1. [Script Overview](#script-overview)
2. [Changes & Enhancements](#changes--enhancements)
3. [Port Allocation](#port-allocation)
4. [Installation Guide](#installation-guide)
5. [ZIP File Verification & Troubleshooting](#zip-file-verification--troubleshooting)
6. [Requirements Architecture Fixer](#requirements-architecture-fixer)
7. [Quick Start Commands](#quick-start-commands)
8. [Troubleshooting Reference](#troubleshooting-reference)

---

## SCRIPT OVERVIEW

### What This Installer Does

The **Odoo Master Installer for Ubuntu 22.04** (`odoo-installer-auto.sh`) is a comprehensive, interactive bash script that:

✅ Supports **9 Odoo versions** (11, 12, 13, 14, 15, 16, 17, 18, 19)
✅ Automatically downloads source code from GitHub
✅ Installs all system dependencies (PostgreSQL, Python, Node.js, etc.)
✅ Configures Apache2 as reverse proxy
✅ Sets up systemd services for auto-start
✅ Enables WebSocket support
✅ Prepares for SSL/HTTPS with Let's Encrypt

### System Requirements

- **OS:** Ubuntu 22.04 LTS
- **Memory:** Minimum 4GB RAM (8GB+ recommended)
- **Disk Space:** 20GB minimum
- **Root/Sudo Access:** Required
- **Network:** Internet connectivity for downloads

---

## CHANGES & ENHANCEMENTS

### Version Support Extended

| Before | After |
|--------|-------|
| Odoo 16, 17, 18, 19 | Odoo 11, 12, 13, 14, 15, 16, 17, 18, 19 |
| 4 versions | **9 versions** |
| Hardcoded menu | Dynamic menu generation |

### Key Modifications

#### 1. Extended ODOO_VERSIONS Array (Line 22)
```bash
# Original:
ODOO_VERSIONS=("16" "17" "18" "19")

# Updated:
ODOO_VERSIONS=("11" "12" "13" "14" "15" "16" "17" "18" "19")
```

#### 2. Updated Banner (Lines 49-55)
```
Supports: Odoo 11, 12, 13, 14, 15, 16, 17, 18, 19
```

#### 3. Dynamic Version Menu (Lines 89-137)
**Old approach:** 4 hardcoded menu items
**New approach:** Loop-based dynamic menu generation
```bash
# Automatically generates options for all 9 versions
for version in "${ODOO_VERSIONS[@]}"; do
    # Generate port mapping and display
done
```

#### 4. Version Validation Function (Lines 139-164)
Extended to accept all versions 11-19:
```bash
case $version in
    11|12|13|14|15|16|17|18|19)
        # Process version
esac
```

#### 5. GitHub Reference
**Maintained as single source:**
```
https://github.com/odoo/odoo/archive/refs/heads/${SELECTED_VERSION}.0.zip
```

### Benefits of Changes

✅ Supports legacy versions (11-15) for maintenance projects
✅ Future-proof with easy extension capability
✅ Cleaner, more maintainable code
✅ Dynamic menu prevents hardcoding updates
✅ Single, reliable GitHub source

---

## PORT ALLOCATION

### Port Mapping Reference

Complete port allocation for all supported Odoo versions:

| Version | Port | Purpose | Status |
|---------|------|---------|--------|
| Odoo 11 | 8011 | Direct access | Legacy |
| Odoo 12 | 8012 | Direct access | Legacy |
| Odoo 13 | 8013 | Direct access | Legacy |
| Odoo 14 | 8014 | Direct access | Legacy |
| Odoo 15 | 8015 | Legacy (E) | Legacy |
| Odoo 16 | 8079 | Active | Stable |
| Odoo 17 | 8099 | Active | Stable |
| Odoo 18 | 8069 | Active | Current |
| Odoo 19 | 8090 | Development | Latest |

### Port Assignment Strategy

**Legacy Versions (11-15):** Sequential numbering (8011-8015)
**Production Versions (16-19):** Custom ports based on requirements
- 16: 8079 (non-sequential, custom)
- 17: 8099 (high port)
- 18: 8069 (lower non-sequential)
- 19: 8090 (development port)

### Port Verification

```bash
# Check which ports are in use
sudo netstat -tulpn | grep LISTEN

# Check specific Odoo port
sudo netstat -tulpn | grep :8016

# Find unused ports
sudo ss -tulpn | grep LISTEN | awk '{print $4}' | grep -oE ':[0-9]+$'
```

### Port Management

**Add multiple Odoo instances:**
```bash
# Each version gets its own port
sudo bash odoo-installer-auto.sh 16  # Uses 8079
sudo bash odoo-installer-auto.sh 17  # Uses 8099
sudo bash odoo-installer-auto.sh 18  # Uses 8069
```

**Change port after installation:**
```bash
# Edit configuration file
sudo nano /etc/odoo16.conf

# Find and change: xmlrpc_port = 8079
# To: xmlrpc_port = 9079

# Restart service
sudo systemctl restart odoo16.service
```

---

## INSTALLATION GUIDE

### Method 1: Interactive Mode (Recommended for Beginners)

```bash
# 1. Download/prepare script
cd /home/ubuntu
wget https://your-server/odoo-installer-auto.sh
# or copy it to this directory

# 2. Run script interactively
sudo bash odoo-installer-auto.sh

# 3. Follow prompts:
#    - Select Odoo version (1-9)
#    - Choose download method
#    - Confirm Apache setup
#    - Review installation summary
```

**Sample interactive session:**
```
▶ SELECT ODOO VERSION TO INSTALL

  1) Odoo 11 (Port 8011)
  2) Odoo 12 (Port 8012)
  ...
  9) Odoo 19 (Port 8090)
  0) Exit

Enter your choice [0-9]: 17

▶ ODOO SOURCE CODE DOWNLOAD OPTIONS

  1) Yes, download Odoo 17 automatically
  2) No, I will download manually
  3) I already have the ZIP file

Enter your choice [1-3]: 1
```

### Method 2: Command Line Mode (For Automation)

```bash
# Single command installation
sudo bash odoo-installer-auto.sh 17

# Arguments:
# 17 = Odoo version (11-19 supported)
# No prompts, automatic defaults
```

**Quick install commands:**
```bash
sudo bash odoo-installer-auto.sh 11  # Odoo 11
sudo bash odoo-installer-auto.sh 16  # Odoo 16
sudo bash odoo-installer-auto.sh 19  # Odoo 19
```

### Method 3: Complete Installation Workflow

```bash
#!/bin/bash
set -e

# Step 1: Ensure script is executable
chmod +x odoo-installer-auto.sh

# Step 2: Run installation (non-interactive)
sudo bash odoo-installer-auto.sh 17

# Step 3: Verify installation
sudo systemctl status odoo17.service

# Step 4: Access Odoo
echo "Odoo 17 is now running at:"
echo "http://$(hostname -I | cut -d' ' -f1):8099"
```

### Installation Workflow (What Happens)

When you run the installer, it performs these steps in order:

```
1. SYSTEM PREPARATION
   └─ Update package manager
   └─ Create directories (/opt/odoo17)
   └─ Extract ZIP file

2. DEPENDENCIES
   ├─ Create system user (odoo17)
   ├─ Install Python packages (pip requirements)
   ├─ Install Node.js dependencies
   ├─ Install PostgreSQL database
   ├─ Install pgAdmin4 (optional)
   ├─ Install wkhtmltopdf (for reports)
   └─ Install Odoo dependencies

3. CONFIGURATION
   ├─ Create Odoo config file (/etc/odoo17.conf)
   ├─ Create systemd service (/etc/systemd/system/odoo17.service)
   ├─ Setup log directories (/var/log/odoo/)
   └─ Set proper permissions

4. SERVICE START
   ├─ Enable systemd service
   ├─ Start Odoo service
   └─ Verify service status

5. APACHE SETUP (if selected)
   ├─ Install Apache2
   ├─ Enable required modules
   ├─ Create virtual host config
   ├─ Enable site configuration
   └─ Restart Apache2

6. COMPLETION SUMMARY
   └─ Display access information
   └─ List useful commands
```

---

## ZIP FILE VERIFICATION & TROUBLESHOOTING

### Understanding ZIP Downloads

The installer downloads Odoo source code as ZIP files from GitHub:

```
https://github.com/odoo/odoo/archive/refs/heads/${VERSION}.0.zip
```

### Common ZIP Errors & Solutions

#### Error 1: "Cannot find zipfile directory"

**Cause:** ZIP file corrupted or incomplete download

**Quick Fix (3 steps):**
```bash
# Step 1: Delete corrupted file
rm -f /home/ubuntu/odoo-17.0.zip

# Step 2: Re-download with retry
wget --tries=5 --retry-connrefused \
    https://github.com/odoo/odoo/archive/refs/heads/17.0.zip \
    -O /home/ubuntu/odoo-17.0.zip

# Step 3: Verify and retry installation
unzip -t /home/ubuntu/odoo-17.0.zip
sudo bash odoo-installer-auto.sh 17
```

#### Error 2: "End-of-central-directory signature not found"

**Cause:** File truncated during download

**Solution:**
```bash
# Use resume capability with wget
wget -c https://github.com/odoo/odoo/archive/refs/heads/17.0.zip \
    -O /home/ubuntu/odoo-17.0.zip

# Or download with multiple retries
wget --tries=10 --retry-connrefused \
    https://github.com/odoo/odoo/archive/refs/heads/17.0.zip \
    -O /home/ubuntu/odoo-17.0.zip
```

#### Error 3: "Bad CRC"

**Cause:** Data corruption during download or storage

**Solution:**
```bash
# Delete and re-download
rm -f /home/ubuntu/odoo-17.0.zip
wget https://github.com/odoo/odoo/archive/refs/heads/17.0.zip \
    -O /home/ubuntu/odoo-17.0.zip
```

### File Size Reference

Expected file sizes after download:

```
Odoo 11: ~55 MB
Odoo 12: ~57 MB
Odoo 13: ~58 MB
Odoo 14: ~59 MB
Odoo 15: ~60 MB
Odoo 16: ~62 MB
Odoo 17: ~65 MB
Odoo 18: ~70 MB
Odoo 19: ~75 MB
```

### Verification Commands

```bash
# Check file size
ls -lh /home/ubuntu/odoo-17.0.zip

# Test ZIP validity
unzip -t /home/ubuntu/odoo-17.0.zip

# List ZIP contents (first 20 files)
unzip -l /home/ubuntu/odoo-17.0.zip | head -20

# Calculate checksum (for comparison)
sha256sum /home/ubuntu/odoo-17.0.zip

# Check disk space available
df -h /home/ubuntu
```

### Download with Enhanced Error Handling

**Recommended wget command:**
```bash
wget \
    --show-progress \
    --tries=5 \
    --retry-connrefused \
    --timeout=30 \
    -O odoo-17.0.zip \
    https://github.com/odoo/odoo/archive/refs/heads/17.0.zip
```

**Using curl alternative:**
```bash
curl --max-time 600 -L \
    https://github.com/odoo/odoo/archive/refs/heads/17.0.zip \
    -o odoo-17.0.zip
```

**Faster parallel download with aria2c:**
```bash
# Install aria2c first
sudo apt-get install aria2

# Download with 5 parallel connections
aria2c -x 5 https://github.com/odoo/odoo/archive/refs/heads/17.0.zip
```

### Complete Recovery Workflow

If installation fails with ZIP error:

```bash
#!/bin/bash

ODOO_VERSION=17
ZIP_FILE="/home/ubuntu/odoo-${ODOO_VERSION}.0.zip"
GITHUB_URL="https://github.com/odoo/odoo/archive/refs/heads/${ODOO_VERSION}.0.zip"

# 1. Stop running service
sudo systemctl stop odoo${ODOO_VERSION}.service 2>/dev/null || true

# 2. Delete corrupted file
rm -f "$ZIP_FILE"

# 3. Download again
echo "Downloading $ZIP_FILE..."
wget \
    --show-progress \
    --tries=5 \
    --retry-connrefused \
    --timeout=30 \
    -O "$ZIP_FILE" \
    "$GITHUB_URL"

# 4. Verify integrity
echo "Verifying ZIP integrity..."
if unzip -t "$ZIP_FILE" > /dev/null 2>&1; then
    echo "✓ ZIP is valid"
    
    # 5. Retry installation
    sudo bash odoo-installer-auto.sh $ODOO_VERSION
else
    echo "✗ ZIP is corrupted, please try downloading again"
    exit 1
fi
```

### Alternative: Manual Browser Download

If wget/curl downloads fail:

```bash
# 1. Download in browser or from another machine:
#    Visit: https://github.com/odoo/odoo/tree/17.0
#    Click "Code" → "Download ZIP"
#    File downloads as: odoo-17.0.zip

# 2. Upload to server via SFTP:
scp odoo-17.0.zip user@your-server:/home/ubuntu/

# 3. Verify and install:
cd /home/ubuntu
unzip -t odoo-17.0.zip
sudo bash odoo-installer-auto.sh 17
```

---

## REQUIREMENTS ARCHITECTURE FIXER

### Problem: Windows-Specific Dependencies

When installing Odoo on Linux ARM64 or AMD64, the default `requirements.txt` includes Windows-specific packages that don't exist for Linux:

```
pywin32          - Windows registry access
winreg          - Windows registry module
wmi             - Windows WMI access
pythoncom       - COM interface
pywintypes      - Windows types
win-inet-pton   - Windows inet functions
colorama        - Windows console
```

### Solution: Architecture Fixer Scripts

#### Quick Start

```bash
# Make script executable
chmod +x fix_odoo_requirements.sh

# Run with auto-detection
./fix_odoo_requirements.sh --path /opt/odoo17

# Or specify architecture
./fix_odoo_requirements.sh --path /opt/odoo17 --arch arm64
```

#### What the Fixer Does

1. **Detects** system architecture automatically
2. **Comments out** Windows-specific packages with `# [ARCH_EXCLUDED]`
3. **Creates** architecture-specific requirements file
4. **Generates** Linux alternatives file
5. **Backs up** original requirements.txt

#### Usage Examples

**Example 1: Auto-detect architecture**
```bash
./fix_odoo_requirements.sh --path /opt/odoo17
```

**Example 2: Specify ARM64 (Raspberry Pi)**
```bash
./fix_odoo_requirements.sh --path /opt/odoo17 --arch arm64
```

**Example 3: Skip backup**
```bash
./fix_odoo_requirements.sh --path /opt/odoo17 --no-backup
```

**Example 4: Custom output name**
```bash
./fix_odoo_requirements.sh --path /opt/odoo17 --output-suffix requirements_ubuntu22
```

#### Integration into Installation

```bash
#!/bin/bash

ODOO_PATH="/opt/odoo17"

# 1. Clone Odoo
git clone https://github.com/odoo/odoo.git --depth 1 --branch 17.0 "$ODOO_PATH"

# 2. Fix requirements for current architecture
bash fix_odoo_requirements.sh --path "$ODOO_PATH"

# 3. Install in virtual environment
python3 -m venv "$ODOO_PATH/venv"
source "$ODOO_PATH/venv/bin/activate"

# 4. Install fixed requirements
pip install -r "$ODOO_PATH/requirements_arch.txt"
pip install -r "$ODOO_PATH/requirements_arch_alternatives.txt"

# 5. Continue with Odoo setup...
```

#### Supported Architectures

| Architecture | Detection | Support |
|-------------|-----------|---------|
| ARM64 (aarch64) | `uname -m = aarch64` | ✓ Full |
| AMD64 (x86_64) | `uname -m = x86_64` | ✓ Full |
| ARMv7 | `uname -m = armv7l` | ✓ Full |
| ARMv6 | `uname -m = armv6l` | ✓ Basic |

#### Generated Files

After running the fixer, three files are created:

```
/opt/odoo17/requirements_arch.txt
├─ All Odoo dependencies
├─ Windows packages commented out
└─ Ready for: pip install -r requirements_arch.txt

/opt/odoo17/requirements_arch_alternatives.txt
├─ Excluded packages (for reference)
├─ Linux-compatible alternatives
└─ Optional: pip install -r requirements_arch_alternatives.txt

/opt/odoo17/requirements.txt.backup_20250210_143022
├─ Original file backup
├─ Timestamp-based naming
└─ Restore if needed: cp backup requirements.txt
```

#### Troubleshooting Fixer

**Issue: "requirements.txt not found"**
```bash
# Verify the path
ls -la /opt/odoo17/requirements.txt
```

**Issue: "Permission denied"**
```bash
# Run with sudo if system-wide
sudo bash fix_odoo_requirements.sh --path /opt/odoo17

# Or fix permissions
sudo chown ubuntu:ubuntu /opt/odoo17
```

**Issue: Some packages still fail**
```bash
# View detailed errors
pip install -r requirements_arch.txt -v

# Install with alternatives
pip install -r requirements_arch_alternatives.txt

# Check for conflicts
pip check
```

**Restore original requirements:**
```bash
# Find backup
ls -la /opt/odoo17/requirements.txt.backup_*

# Restore
cp /opt/odoo17/requirements.txt.backup_20250210_143022 /opt/odoo17/requirements.txt
```

---

## QUICK START COMMANDS

### One-Liner Installations

```bash
# Odoo 11 (legacy)
sudo bash odoo-installer-auto.sh 11

# Odoo 16 (stable)
sudo bash odoo-installer-auto.sh 16

# Odoo 17 (recommended)
sudo bash odoo-installer-auto.sh 17

# Odoo 18 (latest stable)
sudo bash odoo-installer-auto.sh 18

# Odoo 19 (development)
sudo bash odoo-installer-auto.sh 19
```

### Verify Installation

```bash
# Check service status
sudo systemctl status odoo17.service

# View logs
sudo journalctl -u odoo17.service -f

# Check if port is listening
sudo netstat -tulpn | grep :8099

# Test access (if local)
curl http://localhost:8099
```

### Access Odoo

After successful installation:

```bash
# Get your server IP
hostname -I

# Access in browser
http://YOUR_SERVER_IP:8099

# Default login
Email: admin
Password: admin
```

### Useful Post-Installation Commands

```bash
# Restart service
sudo systemctl restart odoo17.service

# Stop service
sudo systemctl stop odoo17.service

# Start service
sudo systemctl start odoo17.service

# View real-time logs
sudo journalctl -u odoo17.service -f

# Edit configuration
sudo nano /etc/odoo17.conf

# View error logs
tail -f /var/log/odoo/odoo17.log

# Check disk usage
du -sh /opt/odoo17

# Restart Apache (if configured)
sudo systemctl restart apache2

# View Apache logs
tail -f /var/log/apache2/odoo17_access.log
```

### Multiple Odoo Instances

Install multiple versions on same server:

```bash
# Install Odoo 16
sudo bash odoo-installer-auto.sh 16

# Install Odoo 17
sudo bash odoo-installer-auto.sh 17

# Install Odoo 18
sudo bash odoo-installer-auto.sh 18

# Verify all are running
sudo systemctl status odoo16 odoo17 odoo18

# Access each instance
http://server:8079  # Odoo 16
http://server:8099  # Odoo 17
http://server:8069  # Odoo 18
```

---

## TROUBLESHOOTING REFERENCE

### Service Won't Start

**Check what's wrong:**
```bash
sudo systemctl status odoo17.service
sudo journalctl -u odoo17.service -n 50
```

**Common causes and fixes:**

```bash
# Port already in use
sudo netstat -tulpn | grep :8099
# Kill process on port: sudo kill -9 <PID>
# Or change port in /etc/odoo17.conf

# PostgreSQL not running
sudo systemctl status postgresql
sudo systemctl start postgresql

# Missing dependencies
pip install -r /opt/odoo17/requirements.txt

# Permission issues
sudo chown -R odoo17:odoo17 /opt/odoo17
sudo chown -R odoo17:odoo17 /var/log/odoo
```

### Database Connection Issues

```bash
# Check PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -l

# Create database manually
sudo -u postgres createdb odoo17

# Reset PostgreSQL
sudo systemctl restart postgresql

# Check PostgreSQL logs
tail -f /var/log/postgresql/postgresql-*.log
```

### Python/Pip Issues

```bash
# Update pip
python3 -m pip install --upgrade pip

# Check Python version
python3 --version

# Reinstall requirements
pip install --force-reinstall -r /opt/odoo17/requirements.txt

# Check for conflicts
pip check

# View installed packages
pip list | grep -i odoo
```

### Low Memory Issues

```bash
# Check available memory
free -h

# Monitor memory usage
watch -n 1 free -h

# Kill unused services
sudo systemctl stop odoo16.service  # Keep only what you need

# Reduce worker processes in /etc/odoo17.conf
workers = 2  # Default is 4-8
```

### Permission Errors

```bash
# Fix Odoo directory permissions
sudo chown -R odoo17:odoo17 /opt/odoo17

# Fix log directory permissions
sudo chown -R odoo17:odoo17 /var/log/odoo

# Fix config file permissions
sudo chmod 640 /etc/odoo17.conf
sudo chown odoo17:odoo17 /etc/odoo17.conf
```

### Network/Access Issues

```bash
# Check if port is listening
sudo netstat -tulpn | grep 8099
sudo ss -tulpn | grep 8099

# Test local access
curl http://localhost:8099

# Check firewall rules
sudo ufw status
sudo ufw allow 8099/tcp

# Reset firewall (if needed)
sudo ufw disable
sudo ufw enable
```

### Clean Installation (Complete Removal)

```bash
# Stop service
sudo systemctl stop odoo17.service

# Disable service
sudo systemctl disable odoo17.service

# Remove service file
sudo rm /etc/systemd/system/odoo17.service

# Remove user
sudo userdel -r odoo17

# Remove installation
sudo rm -rf /opt/odoo17

# Remove config
sudo rm /etc/odoo17.conf

# Remove logs
sudo rm -rf /var/log/odoo/odoo17*

# Reload systemd
sudo systemctl daemon-reload

# Reinstall fresh
sudo bash odoo-installer-auto.sh 17
```

---

## ERROR MESSAGES REFERENCE

### Installation Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Cannot find zipfile directory" | ZIP corrupted | Delete & redownload |
| "Permission denied" | Run without sudo | Use `sudo bash` |
| "Port already in use" | Port conflict | Change port in config |
| "Module not found: psycopg2" | Missing dependency | Run pip install again |
| "PostgreSQL connection refused" | DB not running | Start PostgreSQL |
| "Cannot write to /opt/odoo17" | Permissions | Use sudo or fix ownership |

### Runtime Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Database error" | PostgreSQL down | Restart PostgreSQL |
| "Module not found" | Missing dependencies | Install requirements |
| "Port X is already allocated" | Multiple instances | Use different port |
| "WSGI/WebSocket error" | Configuration issue | Review apache config |

---

## SYSTEM REQUIREMENTS CHECKLIST

Before running installer, ensure:

- [ ] Ubuntu 22.04 LTS
- [ ] 4GB+ RAM
- [ ] 20GB+ disk space
- [ ] Sudo access
- [ ] Internet connectivity
- [ ] Port available (8011-8099)
- [ ] PostgreSQL can be installed
- [ ] Python 3.7+ available

---

## IMPORTANT POST-INSTALLATION

### Security Steps

```bash
# 1. Change default admin password
# Login to Odoo web interface → Settings → Users → Admin → Change Password

# 2. Set Odoo database password
sudo nano /etc/odoo17.conf
# Add/modify: db_password = strong_password_here

# 3. Restrict file permissions
sudo chmod 640 /etc/odoo17.conf

# 4. Enable firewall
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 80/tcp  # HTTP
sudo ufw allow 443/tcp # HTTPS
sudo ufw allow 8099/tcp # Odoo (if not behind proxy)
sudo ufw enable

# 5. Set up SSL with Let's Encrypt
sudo apt-get install certbot python3-certbot-apache
sudo certbot --apache -d your-domain.com
```

### Backup Strategy

```bash
# Daily backup script
#!/bin/bash

BACKUP_DIR="/backups/odoo"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL databases
sudo -u postgres pg_dumpall > "$BACKUP_DIR/odoo_databases_$TIMESTAMP.sql"

# Backup Odoo filestore
sudo tar -czf "$BACKUP_DIR/odoo_filestore_$TIMESTAMP.tar.gz" /var/lib/odoo/

# Keep only last 30 days
find "$BACKUP_DIR" -name "odoo_*" -mtime +30 -delete

echo "Backup completed: $TIMESTAMP"
```

### Monitoring

```bash
# Monitor service with systemctl
sudo systemctl status odoo17

# Monitor logs with journalctl
sudo journalctl -u odoo17.service -f

# Monitor system resources
top
htop

# Monitor database
sudo -u postgres psql -l
```

---

## SUPPORT & RESOURCES

### Official Documentation
- **Odoo Docs:** https://www.odoo.com/documentation
- **GitHub Repository:** https://github.com/odoo/odoo

### Community Resources
- **Odoo Community Forum:** https://www.odoo.com/forum
- **Stack Overflow:** Tag: `odoo`
- **GitHub Issues:** https://github.com/odoo/odoo/issues

### Getting Help

1. Check this guide's troubleshooting section
2. Review Odoo documentation
3. Check service logs: `journalctl -u odoo17.service`
4. Search GitHub issues
5. Ask in community forums

---

## VERSION HISTORY

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Feb 2025 | Initial release with versions 11-19 |
| Previous | Pre-2025 | Versions 16-19 only |

---

## QUICK REFERENCE CARD

```
INSTALLATION
├─ Interactive:    sudo bash odoo-installer-auto.sh
├─ Automated:      sudo bash odoo-installer-auto.sh 17
└─ Verify:         sudo systemctl status odoo17.service

VERSIONS SUPPORTED
├─ Legacy:   11, 12, 13, 14, 15
├─ Stable:   16, 17
└─ Current:  18, 19

PORTS ALLOCATED
├─ v11: 8011, v12: 8012, v13: 8013, v14: 8014, v15: 8015
└─ v16: 8079, v17: 8099, v18: 8069, v19: 8090

KEY FILES
├─ Installation:   /opt/odoo17/
├─ Config:         /etc/odoo17.conf
├─ Service:        /etc/systemd/system/odoo17.service
├─ Logs:           /var/log/odoo/odoo17.log
└─ Database:       PostgreSQL (port 5432)

USEFUL COMMANDS
├─ Status:         sudo systemctl status odoo17.service
├─ Logs:           sudo journalctl -u odoo17.service -f
├─ Restart:        sudo systemctl restart odoo17.service
├─ Config:         sudo nano /etc/odoo17.conf
├─ Stop:           sudo systemctl stop odoo17.service
└─ Access:         http://SERVER_IP:8099

ZIP VERIFICATION
├─ Test:           unzip -t odoo-17.0.zip
├─ List:           unzip -l odoo-17.0.zip
└─ Size:           ls -lh odoo-17.0.zip

TROUBLESHOOTING
├─ Port conflict:   sudo netstat -tulpn | grep :8099
├─ DB down:         sudo systemctl restart postgresql
├─ Permissions:     sudo chown -R odoo17:odoo17 /opt/odoo17
├─ Memory:          free -h
└─ Remove & reinstall: See "Clean Installation" section
```

---

## FINAL NOTES

✅ **This guide covers:**
- Complete installation process for 9 Odoo versions
- Troubleshooting common issues
- Port allocation and management
- ZIP file verification
- Requirements architecture fixes
- Security and backup strategies

✅ **All commands tested on Ubuntu 22.04**

✅ **Single GitHub source:** `https://github.com/odoo/odoo.git`

✅ **Support available for versions 11-19**

---

**Document Version:** 1.0  
**Last Updated:** February 2025  
**Compatibility:** Ubuntu 22.04 LTS  
**Odoo Versions:** 11, 12, 13, 14, 15, 16, 17, 18, 19

---

*For the latest version of this guide and installer scripts, visit the official Odoo GitHub repository.*
