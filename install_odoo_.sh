#!/bin/bash

################################################################################
#                   ODOO MASTER INSTALLER FOR UBUNTU 22.04                    #
#              WITH AUTOMATIC PACKAGE DOWNLOAD CAPABILITY                     #
#                                                                              #
# Description: Interactive installer with automatic Odoo source download      #
# Features: Version selection, auto-download, Apache2 proxy, WebSocket        #
# Usage: sudo bash odoo-installer-auto.sh [version]                          #
#        sudo bash odoo-installer-auto.sh                    # Interactive    #
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
ODOO_VERSIONS=("11" "12" "13" "14" "15" "16" "17" "18" "19")
SELECTED_VERSION=""
PORT=""
ODOO_PATH=""
CONF=""
SERV=""
LOG="/var/log/odoo"
USR=""
INSTALL_APACHE=0
DOMAIN=""
AUTO_DOWNLOAD=1
SCRIPT_DIR=$(dirname "$(realpath "$0")")
ZIP_FILE=""
GITHUB_URL=""
UNZIP_FIX="unzip_fix.sh"
REQ_FIX="fix_requirements.sh"
COPYCHECKER="check_file_fix.sh"
VMIP=$(hostname -I | cut -d' ' -f1)

chmod +x ${SCRIPT_DIR}/fixers/*.sh
################################################################################
#                              UTILITY FUNCTIONS                              #
################################################################################

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                   ODOO MASTER INSTALLER FOR UBUNTU 22.04                    ║
║                                                                              ║
║   With Automatic Package Download Support                                  ║
║   Supports: Odoo 11, 12, 13, 14, 15, 16, 17, 18, 19                        ║
║   Features: Auto-download, Apache2 proxy, WebSocket, SSL support           ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_header() {
    echo -e "${BLUE}▶ $1${NC}"
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

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

pause_script() {
    echo ""
    read -p "Press ENTER to continue..."
}

################################################################################
#                           VERSION SELECTION MENU                            #
################################################################################

show_version_menu() {
    print_banner
    print_header "SELECT ODOO VERSION TO INSTALL"
    echo ""
    
    # Generate menu dynamically
    local option_num=1
    for version in "${ODOO_VERSIONS[@]}"; do
        case $version in
            11) port="8011" ;;
            12) port="8012" ;;
            13) port="8013" ;;
            14) port="8014" ;;
            15) port="8015" ;;
            16) port="8079" ;;
            17) port="8099" ;;
            18) port="8069" ;;
            19) port="8090" ;;
        esac
        printf "  %d) Odoo %s (Port %s)\n" "$option_num" "$version" "$port"
        option_num=$((option_num + 1))
    done
    
    echo "  0) Exit"
    echo ""
    read -p "Enter your choice [0-$((option_num-1))]: " choice

    case $choice in
        1) SELECTED_VERSION="11"; PORT="8011" ;;
        2) SELECTED_VERSION="12"; PORT="8012" ;;
        3) SELECTED_VERSION="13"; PORT="8013" ;;
        4) SELECTED_VERSION="14"; PORT="8014" ;;
        5) SELECTED_VERSION="15"; PORT="8015" ;;
        6) SELECTED_VERSION="16"; PORT="8079" ;;
        7) SELECTED_VERSION="17"; PORT="8099" ;;
        8) SELECTED_VERSION="18"; PORT="8069" ;;
        9) SELECTED_VERSION="19"; PORT="8090" ;;
        0) 
            print_info "Installation cancelled."
            exit 0
            ;;
        *) 
            print_error "Invalid option. Please try again."
            pause_script
            show_version_menu
            ;;
    esac

}

validate_version_argument() {
    local version=$1
    
    case $version in
        11|12|13|14|15|16|17|18|19)
            SELECTED_VERSION=$version
            case $version in
                11) PORT="8011" ;;
                12) PORT="8012" ;;
                13) PORT="8013" ;;
                14) PORT="8014" ;;
                15) PORT="8015" ;;
                16) PORT="8079" ;;
                17) PORT="8099" ;;
                18) PORT="8069" ;;
                19) PORT="8090" ;;
            esac
            return 0
            ;;
        *)
            print_error "Invalid version: $version"
            echo "Supported versions: 11, 12, 13, 14, 15, 16, 17, 18, 19"
            exit 1
            ;;
    esac
}

################################################################################
#                       DOWNLOAD MANAGEMENT FUNCTIONS                         #
################################################################################

check_internet_connection() {
    print_header "Checking Internet Connection"
    
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "Internet connection available"
        return 0
    else
        print_warning "No internet connection detected"
        return 1
    fi
}


show_download_menu() {
    echo ""
    print_header "ODOO SOURCE CODE DOWNLOAD OPTIONS"
    echo ""
    echo "The installer can automatically download Odoo ${SELECTED_VERSION} for you."
    echo ""
    echo "  1) Yes, download Odoo ${SELECTED_VERSION} automatically"
    echo "  2) No, I will download manually (using wget or browser)"
    echo "  3) I already have the ZIP file in this directory"
    echo "  4) Clone the Git repository directly to a directory"
    echo ""
    read -p "Enter your choice [1-4]: " download_choice

    sudo apt update
    sudo apt install git unzip -y
    case $download_choice in
        1)
            AUTO_DOWNLOAD=1
            echo ""
            echo -e "${BLUE}Downloading fresh copy...${NC}"
            echo ""

            ZIP_FILE="$SCRIPT_DIR/odoo-${SELECTED_VERSION}.0.zip"
            GITHUB_URL="https://github.com/odoo/odoo/archive/refs/heads/${SELECTED_VERSION}.0.zip"
            
            # Download with progress and retry
            wget \
                --show-progress \
                --tries=5 \
                --retry-connrefused \
                --timeout=30 \
                -c -O "$ZIP_FILE" \
                "$GITHUB_URL"
            if [ $? -ne 0 ]; then
                echo -e "${RED}✗ Download failed!${NC}"
                echo ""
                echo "Possible solutions:"
                echo "1. Check internet connection"
                echo "2. Try downloading manually:"
                echo "   wget '$GITHUB_URL' -O '$ZIP_FILE'"
                echo "3. Use curl instead:"
                echo "   curl -L '$GITHUB_URL' -o '$ZIP_FILE'"
                exit 1
            fi

            echo ""
            echo -e "${GREEN}✓ Download complete${NC}"
            ;;
        2)
            AUTO_DOWNLOAD=0
            echo ""
            print_header "MANUAL DOWNLOAD INSTRUCTIONS"
            echo ""
            echo "Please download Odoo ${SELECTED_VERSION} source code using one of these methods:"
            echo ""
            echo "METHOD 1: Using wget (recommended)"
            echo "  wget https://github.com/odoo/odoo/archive/refs/heads/${SELECTED_VERSION}.0.zip -O odoo-${SELECTED_VERSION}.0.zip"
            echo ""
            echo "METHOD 2: Using curl"
            echo "  curl -L https://github.com/odoo/odoo/archive/refs/heads/${SELECTED_VERSION}.0.zip -o odoo-${SELECTED_VERSION}.0.zip"
            echo ""
            echo "METHOD 3: Browser download"
            echo "  1. Visit: https://github.com/odoo/odoo/tree/${SELECTED_VERSION}.0"
            echo "  2. Click 'Code' → 'Download ZIP'"
            echo "  3. Rename to: odoo-${SELECTED_VERSION}.0.zip"
            echo ""
            echo "After downloading, place the file in the current directory (where this script is)"
            echo "Then run this script again."
            echo ""
            pause_script
            exit 0
            ;;
        3)
            AUTO_DOWNLOAD=0
            echo ""
            print_info "Proceeding with assumption that odoo-${SELECTED_VERSION}.0.zip is present"
            echo ""
            ;;
        4)
            AUTO_DOWNLOAD=0
            print_header "Creating Directories"
            setup_paths
            CLONE_URL="https://github.com/odoo/odoo.git"

            if [[ ! -d "$ODOO" ]]; then
                sudo mkdir -p $ODOO
                print_success "Created $ODOO"
                if [[ ! -d "$ODOO_PATH" ]]; then
                    sudo mkdir -p $ODOO_PATH
                    print_success "Created $ODOO_PATH"
                fi
            fi
            
            sudo chown ubuntu:root $ODOO
            sudo chown $USR:root $ODOO_PATH

            sudo git clone --branch ${SELECTED_VERSION}.0 --depth 1 ${CLONE_URL} $ODOO_PATH
            ;;
        *)
            print_error "Invalid option"
            show_download_menu
            ;;
    esac
}

################################################################################
#                         CONFIGURATION SETUP                                 #
################################################################################

setup_paths() {
    ODOO="/opt/odoo${SELECTED_VERSION}"
    ODOO_PATH="/opt/odoo${SELECTED_VERSION}/odoo-${SELECTED_VERSION}.0"
    CONF="/etc/odoo${SELECTED_VERSION}.conf"
    SERV="/etc/systemd/system/odoo${SELECTED_VERSION}.service"
    USR="odoo${SELECTED_VERSION}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run with sudo privileges"
        exit 1
    fi
    print_success "Running with sudo privileges"
    
    # Check Ubuntu version
    if grep -q "22.04" /etc/lsb-release; then
        print_success "Ubuntu 22.04 detected"
    else
        print_warning "This script is optimized for Ubuntu 22.04"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check disk space
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 20000000 ]; then
        print_error "Insufficient disk space. At least 20GB required."
        exit 1
    fi
    print_success "Sufficient disk space available"
    
    # Check for required files
    if [ ! -f "odoo-${SELECTED_VERSION}.0.zip" && ! -d "$ODOO" ]]; then
        print_error "odoo-${SELECTED_VERSION}.0.zip nor ${ODOO} was not found in current directory"
        echo ""
        show_download_menu
    fi
    print_success "Odoo ${SELECTED_VERSION} source file found"
    
    # Check if Odoo already installed
    if [ -d "$ODOO" ]; then
        print_warning "Odoo ${SELECTED_VERSION} already exists at $ODOO"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Removing existing installation..."
            sudo systemctl stop ${USR}.service 2>/dev/null || true
            sudo bash ${SCRIPT_DIR}/fixers/${COPYCHECKER} ${ZIP_FILE}
            sudo bash ${SCRIPT_DIR}/fixers/${UNZIP_FIX} --zipped-file ${ZIP_FILE} --version-info ${SELECTED_VERSION} --script-root ${SCRIPT_DIR}
        else
            print_info "Installation cancelled."
            exit 0
        fi
    fi
    
    echo ""
}

apache_menu() {
    echo ""
    print_header "APACHE2 REVERSE PROXY SETUP"
    echo ""
    echo "Would you like to install and configure Apache2 reverse proxy?"
    echo "This allows access via domain name instead of port number"
    echo ""
    echo "  1) Yes, install Apache2 and configure reverse proxy"
    echo "  2) No, skip Apache2 setup (direct port access only)"
    echo ""
    read -p "Enter your choice [1-2]: " apache_choice

    case $apache_choice in
        1)
            INSTALL_APACHE=1
            read -p "Enter your domain name (e.g., odoo.example.com): " DOMAIN
            if [ -z "$DOMAIN" ]; then
                print_error "Domain cannot be empty. Skipping Apache setup."
                INSTALL_APACHE=0
            fi
            ;;
        2)
            INSTALL_APACHE=0
            ;;
        *)
            print_error "Invalid option."
            apache_menu
            ;;
    esac
}

show_summary() {
    echo ""
    print_header "INSTALLATION SUMMARY"
    echo ""
    echo "  Version:         Odoo ${SELECTED_VERSION}"
    echo "  Port:            ${PORT}"
    echo "  Location:        ${ODOO}"
    echo "  User:            ${USR}"
    echo "  Config:          ${CONF}"
    echo "  Service:         ${SERV}"
    echo "  Logs:            ${LOG}"
    
    if [ $INSTALL_APACHE -eq 1 ]; then
        echo "  Apache2:         Yes (Domain: ${DOMAIN})"
    else
        echo "  Apache2:         No"
    fi
    
    echo ""
    read -p "Continue with installation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
}

################################################################################
#                         SYSTEM PREPARATION                                  #
################################################################################

update_system() {
    print_header "Updating System Packages"
    sudo apt-get update
    sudo apt-get upgrade -y
    print_success "System updated"
}

create_directories() {
    print_header "Creating Directories"
    if [[ ! -d $ODOO ]]; then
        sudo mkdir -p $ODOO
    fi
    sudo chown ubuntu $ODOO
    print_success "Created $ODOO"
    
    sudo mkdir -p $LOG
    print_success "Created log directory"
}


################################################################################
#                        DEPENDENCIES INSTALLATION                            #
################################################################################

create_system_user() {
    print_header "Creating System User"
    
    # Check if user exists
    if id "$USR" &>/dev/null; then
        print_warning "User $USR already exists"
    else
        sudo adduser --system --home=$ODOO --group $USR
        print_success "Created system user: $USR"
    fi
    
    sudo chown -R $USR:$USR $ODOO
    sudo chmod 755 $ODOO
    print_success "Set directory permissions"
}

install_python_dependencies() {
    print_header "Installing Python and Dependencies"
    
    local deps=(
        "python2.7-dev" "python3-dev" "python3-pip" "libxml2-dev" "libxslt1-dev"
        "zlib1g-dev" "libsasl2-dev" "libldap2-dev"
        "build-essential" "libssl-dev" "libffi-dev"
        "libmysqlclient-dev" "libjpeg-dev" "libpq-dev"
        "libjpeg8-dev" "liblcms2-dev" "libblas-dev"
        "libatlas-base-dev" "python3-cffi"
    )
    
    sudo apt-get install -y "${deps[@]}"
    print_success "Python dependencies installed"
}

install_nodejs_dependencies() {
    print_header "Installing Node.js and npm"
    
    sudo apt-get install -y npm nodejs
    print_success "Node.js and npm installed"
    
    sudo npm install -g less less-plugin-clean-css
    print_success "Less CSS compiler installed"
}

install_postgresql() {
    print_header "Installing PostgreSQL"
    
    # Check if PostgreSQL is already installed
    if command -v psql &> /dev/null; then
        print_warning "PostgreSQL is already installed"
    else
        sudo apt-get install -y postgresql postgresql-contrib
        print_success "PostgreSQL installed"
    fi
    
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    print_success "PostgreSQL started and enabled"
    
    # Create database user for Odoo
    sudo -u postgres createuser -s $USR 2>/dev/null || print_warning "Database user $USR already exists"
    print_success "Database user configured"
}

install_pgadmin4() {
    print_header "Installing pgAdmin4 (Optional)"
    
    read -p "Install pgAdmin4 for database management? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | \
            sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg 2>/dev/null || true

        sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] \
            https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) \
            pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update' 2>/dev/null || true

        sudo apt-get install -y pgadmin4 pgadmin4-web 2>/dev/null || print_warning "pgAdmin4 installation skipped"
        print_success "pgAdmin4 installed (optional)"
    fi
}

install_wkhtmltopdf() {
    print_header "Installing wkhtmltopdf"
    
    sudo apt-get install -y wkhtmltopdf
    print_success "wkhtmltopdf installed"
}

install_odoo_dependencies() {
    print_header "Installing Odoo Python Dependencies"

    cd $ODOO_PATH || exit 1
    sudo bash ${SCRIPT_DIR}/fixers/${REQ_FIX} --input ${ODOO_PATH}/requirements.txt --output requirement_arch.txt --arch ${ARCH:-auto}
    
    if [ $? -eq 0 ]; then
        print_success "Odoo requirements installed"
    else
        print_error "Failed to install Odoo requirements"
        exit 1
    fi
    
    sudo pip3 install odoo-test-helper
    print_success "Test helper installed"
}

################################################################################
#                         CONFIGURATION FILES                                 #
################################################################################

create_odoo_config() {
    print_header "Creating Odoo Configuration File"
    
    sudo mkdir -p /opt/odoo${SELECTED_VERSION}/addons
    
    sudo tee $CONF > /dev/null <<EOF
[options]
; This is the password that allows database operations:
admin_passwd = admin
db_host = False
db_port = False
db_user = $USR
db_password = False
addons_path = /opt/odoo${SELECTED_VERSION}/odoo-${SELECTED_VERSION}.0/addons, /opt/odoo${SELECTED_VERSION}/addons
logfile = /var/log/odoo/odoo${SELECTED_VERSION}.log
http_port = $PORT
limit_request = 8196
limit_time_cpu = 60
limit_time_real = 120
EOF

    sudo chown $USR:$USR $CONF
    sudo chmod 640 $CONF
    print_success "Configuration file created at $CONF"
}

create_systemd_service() {
    print_header "Creating Systemd Service File"
    
    sudo tee $SERV > /dev/null <<EOF
[Unit]
Description=Odoo ${SELECTED_VERSION}
Documentation=https://www.odoo.com/documentation/${SELECTED_VERSION}.0/
After=network.target postgresql.service

[Service]
Type=simple
User=$USR
Group=$USR
ExecStart=$ODOO_PATH/odoo-bin -c $CONF
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=odoo${SELECTED_VERSION}

[Install]
WantedBy=multi-user.target
EOF

    sudo chmod 755 $SERV
    sudo chown root:root $SERV
    print_success "Systemd service file created at $SERV"
}

setup_logs() {
    print_header "Setting Up Log Directory"
    
    sudo mkdir -p $LOG
    sudo chown $USR:root $LOG
    sudo chmod 770 $LOG
    print_success "Log directory configured"
}

################################################################################
#                         SERVICE MANAGEMENT                                  #
################################################################################

start_odoo_service() {
    print_header "Starting Odoo Service"
    
    sudo systemctl daemon-reload
    sudo systemctl enable odoo${SELECTED_VERSION}.service
    sudo systemctl start odoo${SELECTED_VERSION}.service
    
    # Wait for service to start
    sleep 3
    
    if sudo systemctl is-active --quiet odoo${SELECTED_VERSION}.service; then
        print_success "Odoo ${SELECTED_VERSION} service started successfully"
    else
        print_error "Failed to start Odoo service"
        echo "Checking service status..."
        sudo systemctl status odoo${SELECTED_VERSION}.service --no-pager
        exit 1
    fi
}

################################################################################
#                         APACHE2 SETUP                                       #
################################################################################

install_apache2() {
    print_header "Installing Apache2"
    
    if command -v apache2 &> /dev/null; then
        print_warning "Apache2 is already installed"
    else
        sudo apt-get update
        sudo apt-get install -y apache2
        print_success "Apache2 installed"
    fi
}

enable_apache_modules() {
    print_header "Enabling Apache Modules"
    
    local modules=("proxy" "proxy_http" "rewrite" "ssl" "proxy_wstunnel" "headers" "deflate")
    
    for module in "${modules[@]}"; do
        sudo a2enmod $module 2>/dev/null
        print_success "Module enabled: mod_$module"
    done
}

create_apache_config() {
    print_header "Creating Apache Virtual Host Configuration"
    
    sudo tee /etc/apache2/sites-available/odoo${SELECTED_VERSION}.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    ServerAdmin admin@$DOMAIN

    # Redirect HTTP to HTTPS (uncomment after setting up SSL)
    # Redirect permanent / https://$DOMAIN/

    # ====== PROXY CONFIGURATION ======
    <Proxy *>
        Order allow,deny
        Allow all
    </Proxy>

    ProxyPreserveHost On
    
    ProxyPass / http://127.0.0.1:${PORT}/ \\
        timeout=2400 \\
        upgrade=websocket \\
        keepalive=On
    
    ProxyPassReverse / http://127.0.0.1:${PORT}/ \\
        upgrade=websocket

    # WebSocket support
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) "http://127.0.0.1:${PORT}/\$1" [P,L]

    # ====== LOGGING ======
    ErrorLog \${APACHE_LOG_DIR}/odoo${SELECTED_VERSION}_error.log
    CustomLog \${APACHE_LOG_DIR}/odoo${SELECTED_VERSION}_access.log combined
    LogLevel warn

    # ====== SECURITY HEADERS ======
    Header set X-Frame-Options "SAMEORIGIN"
    Header set X-Content-Type-Options "nosniff"
    Header set X-XSS-Protection "1; mode=block"
    Header set Referrer-Policy "same-origin"

    # ====== COMPRESSION ======
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css
        AddOutputFilterByType DEFLATE text/javascript application/javascript
        AddOutputFilterByType DEFLATE application/json
    </IfModule>

    # ====== PERFORMANCE ======
    TimeOut 2400
    KeepAlive On
    KeepAliveTimeout 5

</VirtualHost>

# ====== HTTPS CONFIGURATION (Uncomment and configure for SSL) ======
# <VirtualHost *:443>
#     ServerName $DOMAIN
#     ServerAlias www.$DOMAIN
#     ServerAdmin admin@$DOMAIN
#
#     SSLEngine on
#     SSLCertificateFile /etc/letsencrypt/live/$DOMAIN/fullchain.pem
#     SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN/privkey.pem
#     SSLCertificateChainFile /etc/letsencrypt/live/$DOMAIN/chain.pem
#
#     # Strong SSL configuration
#     SSLProtocol -all +TLSv1.2 +TLSv1.3
#     SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
#     SSLHonorCipherOrder on
#     SSLCompression off
#
#     # [Include same proxy and header configuration as HTTP]
#
# </VirtualHost>
#
# ====== HTTP to HTTPS REDIRECT ======
# <VirtualHost *:80>
#     ServerName $DOMAIN
#     ServerAlias www.$DOMAIN
#     Redirect permanent / https://$DOMAIN/
# </VirtualHost>
EOF

    print_success "Apache configuration created at /etc/apache2/sites-available/odoo${SELECTED_VERSION}.conf"
}

enable_apache_site() {
    print_header "Enabling Apache Virtual Host"
    
    # Disable default site if needed
    sudo a2dissite 000-default.conf 2>/dev/null || true
    
    # Enable Odoo site
    sudo a2ensite odoo${SELECTED_VERSION}.conf
    
    # Test configuration
    if sudo apache2ctl configtest &>/dev/null; then
        print_success "Apache configuration is valid"
    else
        print_error "Apache configuration has errors"
        sudo apache2ctl configtest
        exit 1
    fi
}

start_apache() {
    print_header "Restarting Apache2"
    
    sudo systemctl restart apache2
    
    if sudo systemctl is-active --quiet apache2; then
        print_success "Apache2 restarted successfully"
    else
        print_error "Failed to restart Apache2"
        exit 1
    fi
}

setup_ssl_instructions() {
    echo ""
    print_header "SSL/HTTPS SETUP INSTRUCTIONS"
    echo ""
    echo "To enable HTTPS with Let's Encrypt SSL certificate:"
    echo ""
    echo "  1. Install Certbot:"
    echo "     sudo apt-get install certbot python3-certbot-apache"
    echo ""
    echo "  2. Obtain SSL certificate:"
    echo "     sudo certbot --apache -d $DOMAIN -d www.$DOMAIN"
    echo ""
    echo "  3. Certbot will automatically update Apache configuration"
    echo ""
    echo "  4. Enable automatic renewal:"
    echo "     sudo systemctl enable certbot.timer"
    echo ""
    echo "  5. Test renewal:"
    echo "     sudo certbot renew --dry-run"
    echo ""
}

################################################################################
#                         INSTALLATION COMPLETE                               #
################################################################################

show_completion_summary() {
    echo ""
    print_banner
    print_header "INSTALLATION COMPLETED SUCCESSFULLY!"
    echo ""
    echo "Odoo ${SELECTED_VERSION} has been installed and configured."
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                         ACCESS INFORMATION                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Direct Access (via port):"
    echo "    URL: http://${VMIP}:${PORT}"
    echo ""
    sed -i "18i local host_port=\"${PORT}\"\nlocal SELECTED_VERSION=\"${SELECTED_VERSION}\"" ${SCRIPT_DIR}/fixers/summary_.sh
    if [ $INSTALL_APACHE -eq 1 ]; then
        echo "  Domain Access (via Apache reverse proxy):"
        echo "    URL: http://$DOMAIN"
        echo ""
        echo "  Note: DNS must be configured to point to this server's IP"
        echo ""
    fi
    
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                     CONFIGURATION INFORMATION                         ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Installation Directory:    $ODOO"
    echo "  Configuration File:        $CONF"
    echo "  Service Name:              odoo${SELECTED_VERSION}.service"
    echo "  System User:               $USR"
    echo "  Log File:                  /var/log/odoo/odoo${SELECTED_VERSION}.log"
    echo "  Database Port:             5432 (PostgreSQL)"
    echo ""
    
    if [ $INSTALL_APACHE -eq 1 ]; then
        echo "  Apache Config:             /etc/apache2/sites-available/odoo${SELECTED_VERSION}.conf"
        echo "  Apache Logs:               /var/log/apache2/odoo${SELECTED_VERSION}_*.log"
        echo ""
    fi
    
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                        USEFUL COMMANDS                                ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  View Service Status:"
    echo "    sudo systemctl status odoo${SELECTED_VERSION}.service"
    echo ""
    echo "  View Live Logs:"
    echo "    sudo journalctl -u odoo${SELECTED_VERSION}.service -f"
    echo ""
    echo "  Restart Service:"
    echo "    sudo systemctl restart odoo${SELECTED_VERSION}.service"
    echo ""
    echo "  Stop Service:"
    echo "    sudo systemctl stop odoo${SELECTED_VERSION}.service"
    echo ""
    echo "  Edit Configuration:"
    echo "    sudo nano $CONF"
    echo ""
    
    if [ $INSTALL_APACHE -eq 1 ]; then
        echo "  Edit Apache Config:"
        echo "    sudo nano /etc/apache2/sites-available/odoo${SELECTED_VERSION}.conf"
        echo ""
        echo "  Restart Apache:"
        echo "    sudo systemctl restart apache2"
        echo ""
    fi
    
    echo "  View Error Logs:"
    echo "    tail -f /var/log/odoo/odoo${SELECTED_VERSION}.log"
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                      INITIAL LOGIN CREDENTIALS                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Email:    admin"
    echo "  Password: admin"
    echo ""
    echo "  ⚠️  IMPORTANT: Change the default password immediately in production!"
    echo ""
    
    if [ $INSTALL_APACHE -eq 1 ]; then
        setup_ssl_instructions
    fi
    
    echo ""
    print_success "Installation script completed. Odoo ${SELECTED_VERSION} is ready!"
    echo ""
}

################################################################################
#                         MAIN EXECUTION FLOW                                 #
################################################################################

main() {
    # Check if version argument is provided
    if [ $# -gt 0 ]; then
        validate_version_argument $1
        setup_paths
    else
        # Interactive mode
        show_version_menu
        setup_paths
    fi
    
    # Show download menu if ZIP file doesn't exist
    if [ ! -f "odoo-${SELECTED_VERSION}.0.zip" ]; then
        show_download_menu
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Ask about Apache setup
    apache_menu
    
    # Show installation summary
    show_summary
    
    # SYSTEM PREPARATION
    update_system
    create_directories
    extract_odoo
    
    # DEPENDENCIES
    create_system_user
    install_python_dependencies
    install_nodejs_dependencies
    install_postgresql
    install_pgadmin4
    install_wkhtmltopdf
    install_odoo_dependencies
    
    # CONFIGURATION
    create_odoo_config
    create_systemd_service
    setup_logs
    
    # START SERVICE
    start_odoo_service
    
    # APACHE2 SETUP (if requested)
    if [ $INSTALL_APACHE -eq 1 ]; then
        install_apache2
        enable_apache_modules
        create_apache_config
        enable_apache_site
        start_apache
    fi
    # COMPLETION
    show_completion_summary
}

# Trap errors
trap 'print_error "Installation failed!"; exit 1' ERR

# Run main function
main "$@"
