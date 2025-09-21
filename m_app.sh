#!/bin/bash

# This script assists with the new install of AllStarLink version 3.
# It installs SkywarnPlus, AllScan Dashboard, DVSwitch Server, and Supermon 7.4+.
#
# Copyright (C) 2024 Freddie Mac - KD5FMU 
# Copyright (C) 2024 Allan - OCW3AW
# Copyright (C) 2024-2025 Jory A. Pratt - W5GLE
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Configuration
CONF_FILE="/etc/asterisk/rpt.conf"
LOG_FILE="/var/log/m_app_install.log"
TEMP_DIR="/tmp/m_app_install"
DRY_RUN=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        DEBUG)
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}[DEBUG]${NC} $message"
            fi
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Error handling function
error_exit() {
    log ERROR "$1"
    exit 1
}

# Check if root
if [ "$(id -u)" -ne 0 ]; then
    error_exit "This script must be run as root or with sudo"
fi

# Create temp directory and log file
mkdir -p "$TEMP_DIR"
touch "$LOG_FILE"

log INFO "Starting M-Apps installation script"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a package is installed
package_installed() {
    dpkg -l "$1" >/dev/null 2>&1
}

# Function to safely download files
safe_download() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if wget --no-verbose --timeout=30 --tries=3 -O "$output" "$url"; then
            log DEBUG "Successfully downloaded $url"
            return 0
        else
            retry_count=$((retry_count + 1))
            log WARN "Download failed for $url (attempt $retry_count/$max_retries)"
            [ $retry_count -lt $max_retries ] && sleep 2
        fi
    done
    
    error_exit "Failed to download $url after $max_retries attempts"
}

# Function to backup configuration file
backup_config() {
    local backup_suffix="$1"
    if [ -f "$CONF_FILE" ]; then
        cp "$CONF_FILE" "${CONF_FILE}.bak-${backup_suffix}"
        log INFO "Configuration backed up to ${CONF_FILE}.bak-${backup_suffix}"
    else
        log WARN "Configuration file $CONF_FILE not found"
    fi
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  -a    Install allscan
  -s    Install supermon
  -w    Install skywarnplus
  -d    Install dvswitch
  -v    Verbose output
  -t    Dry run (test mode)
  -h    Display this help message

You can combine options to install multiple software (e.g., $0 -a -s -w).
EOF
}

# Functions to install each software package
install_allscan() {
    log INFO "Installing AllScan..."
    
    if [ "$DRY_RUN" = true ]; then
        log INFO "[DRY RUN] Would install AllScan"
        return 0
    fi
    
    # Check dependencies
    local deps=("php" "unzip")
    for dep in "${deps[@]}"; do
        if ! package_installed "$dep"; then
            log INFO "Installing dependency: $dep"
            apt install -y "$dep" || error_exit "Failed to install $dep"
        fi
    done
    
    cd "$TEMP_DIR" || error_exit "Failed to change to temp directory"
    
    local installer="AllScanInstallUpdate.php"
    safe_download "https://raw.githubusercontent.com/davidgsd/AllScan/main/AllScanInstallUpdate.php" "$installer"
    chmod 755 "$installer"
    
    log INFO "Running AllScan installer..."
    if ./"$installer"; then
        log INFO "AllScan installation completed successfully"
    else
        error_exit "AllScan installation failed"
    fi
    
    rm -f "$installer"
}

install_supermon() {
    log INFO "Installing Supermon..."
    
    if [ "$DRY_RUN" = true ]; then
        log INFO "[DRY RUN] Would install Supermon"
        return 0
    fi
    
    # Install dependencies
    local deps=("apache2" "php" "libapache2-mod-php" "libcgi-session-perl" "bc")
    for dep in "${deps[@]}"; do
        if ! package_installed "$dep"; then
            log INFO "Installing dependency: $dep"
            apt install -y "$dep" || error_exit "Failed to install $dep"
        fi
    done
    
    cd "$TEMP_DIR" || error_exit "Failed to change to temp directory"
    
    # Download and run fresh install
    safe_download "http://2577.asnode.org:43856/supermonASL_fresh_install" "supermonASL_fresh_install"
    chmod +x supermonASL_fresh_install
    
    log INFO "Running Supermon fresh install..."
    if ./supermonASL_fresh_install; then
        log INFO "Supermon 7.4+ fresh installation completed"
    else
        error_exit "Supermon fresh installation failed"
    fi
    
    # Download and run latest update
    safe_download "http://2577.asnode.org:43856/supermonASL_latest_update" "supermonASL_latest_update"
    chmod +x supermonASL_latest_update
    
    log INFO "Running Supermon latest update..."
    if ./supermonASL_latest_update; then
        log INFO "Supermon 7.4+ update completed"
    else
        error_exit "Supermon update failed"
    fi
    
    # Cleanup
    rm -f supermonASL_fresh_install supermonASL_latest_update
    
    # Backup and modify configuration
    backup_config "supermon"
    
    if [ -f "$CONF_FILE" ]; then
        # Add SMUPDATE function if not already present
        if ! grep -q "SMUPDATE=" "$CONF_FILE"; then
            sed -i '/\[functions\]/a SMUPDATE=cmd,/usr/local/sbin/supermonASL_latest_update' "$CONF_FILE"
            log INFO "Added SMUPDATE function to configuration"
        fi
    fi
    
    # Setup cron job
    log INFO "Setting up cron job..."
    local disable_mail="MAILTO=\"\""
    local cron_comment="# Supermon 7.4 updater crontab entry"
    local cron_job="0 3 * * * /var/www/html/supermon/astdb.php cron"
    
    # Check if cron job already exists
    if ! crontab -l 2>/dev/null | grep -q "astdb.php cron"; then
        ( crontab -l 2>/dev/null; echo "$disable_mail"; echo "$cron_comment"; echo "$cron_job" ) | crontab -
        log INFO "Cron job added successfully"
    else
        log INFO "Cron job already exists, skipping"
    fi
    
    log INFO "Supermon installation completed successfully"
}


install_skywarnplus() {
    log INFO "Installing SkywarnPlus..."
    
    if [ "$DRY_RUN" = true ]; then
        log INFO "[DRY RUN] Would install SkywarnPlus"
        return 0
    fi
    
    # Install dependencies
    local deps=("unzip" "python3" "python3-pip" "ffmpeg" "python3-ruamel.yaml" "python3-requests" "python3-dateutil" "python3-pydub")
    for dep in "${deps[@]}"; do
        if ! package_installed "$dep"; then
            log INFO "Installing dependency: $dep"
            apt install -y "$dep" || error_exit "Failed to install $dep"
        fi
    done
    
    cd "$TEMP_DIR" || error_exit "Failed to change to temp directory"
    
    log INFO "Running SkywarnPlus installer..."
    if bash -c "$(curl -fsSL https://raw.githubusercontent.com/Mason10198/SkywarnPlus/main/swp-install)"; then
        log INFO "SkywarnPlus installation completed"
    else
        error_exit "SkywarnPlus installation failed"
    fi
    
    # Backup and modify configuration
    backup_config "skywarn"
    
    if [ -f "$CONF_FILE" ]; then
        # Add SkywarnPlus functions if not already present
        if ! grep -q "SkywarnPlus/SkyControl.py" "$CONF_FILE"; then
            # Insert SkywarnPlus functions after the [functions] stanza
            sed -i '/\[functions\]/a \
831 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py enable toggle ; Toggles SkywarnPlus\
832 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py sayalert toggle ; Toggles SayAlert\
833 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py sayallclear toggle ; Toggles SayAllClear\
834 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py tailmessage toggle ; Toggles TailMessage\
835 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py courtesytone toggle ; Toggles CourtesyTone\
836 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py alertscript toggle ; Toggles AlertScript\
837 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py idchange toggle ; Toggles IDChange\
838 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py changect normal ; Forces CT to "normal" mode\
839 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py changeid normal ; Forces ID to "normal" mode\
841 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 1 ; SkyDescribe the 1st alert\
842 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 2 ; SkyDescribe the 2nd alert\
843 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 3 ; SkyDescribe the 3rd alert\
844 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 4 ; SkyDescribe the 4th alert\
845 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 5 ; SkyDescribe the 5th alert\
846 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 6 ; SkyDescribe the 6th alert\
847 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 7 ; SkyDescribe the 7th alert\
848 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 8 ; SkyDescribe the 8th alert\
849 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 9 ; SkyDescribe the 9th alert' "$CONF_FILE"
            log INFO "Added SkywarnPlus functions to [functions] stanza"
        fi
        
        # Update configuration settings
        sed -i '/tailmessagetime=/s/^#//; s/tailmessagetime=.*/tailmessagetime=600000/' "$CONF_FILE"
        sed -i '/tailsquashedtime=/s/^#//; s/tailsquashedtime=.*/tailsquashedtime=30000/' "$CONF_FILE"
        
        # Add tailmessagelist if not present
        if ! grep -q "tailmessagelist.*SkywarnPlus" "$CONF_FILE"; then
            awk '/tailsquashedtime=30000/ { print "tailmessagelist = /tmp/SkywarnPlus/wx-tail"; } { print }' "$CONF_FILE" > "${CONF_FILE}.tmp" && mv "${CONF_FILE}.tmp" "$CONF_FILE"
            log INFO "Added tailmessagelist configuration"
        fi
    fi
    
    log INFO "SkywarnPlus installation completed successfully"
}

install_dvswitch() {
    log INFO "Installing DVSwitch Server..."
    
    if [ "$DRY_RUN" = true ]; then
        log INFO "[DRY RUN] Would install DVSwitch Server"
        return 0
    fi
    
    # Install dependencies
    local deps=("php-cgi" "libapache2-mod-php8.2")
    
    # Check if PHP 8.2 is available
    if ! apt list --installed | grep -q "php8.2" && ! apt list --available | grep -q "php8.2"; then
        log ERROR "PHP 8.2 is required for DVSwitch but not available in package repositories"
        log INFO "Please ensure PHP 8.2 is available before installing DVSwitch"
        return 1
    fi
    
    for dep in "${deps[@]}"; do
        if ! package_installed "$dep"; then
            log INFO "Installing dependency: $dep"
            apt install -y "$dep" || error_exit "Failed to install $dep"
        fi
    done
    
    cd "$TEMP_DIR" || error_exit "Failed to change to temp directory"
    
    safe_download "dvswitch.org/bookworm" "bookworm"
    chmod +x bookworm
    
    log INFO "Running DVSwitch installer..."
    if ./bookworm; then
        log INFO "DVSwitch installer completed"
    else
        error_exit "DVSwitch installer failed"
    fi
    
    rm -f bookworm
    
    # Update package list and install DVSwitch server
    apt update
    apt install -y dvswitch-server || error_exit "Failed to install dvswitch-server"
    
    # Update USRP port configuration
    local config_file="/usr/share/dvswitch/include/config.php"
    if [ -f "$config_file" ]; then
        if sed -i 's/31001/34001/' "$config_file"; then
            log INFO "Updated USRP port from 31001 to 34001"
        else
            log WARN "Failed to update USRP port configuration"
        fi
    else
        log WARN "DVSwitch config file not found: $config_file"
    fi
    
    log INFO "DVSwitch Server installation completed successfully"
}

# Parse command-line arguments
while getopts "aswdhtv" opt; do
    case $opt in
        a)
            install_allscan_flag=true
            ;;
        s)
            install_supermon_flag=true
            ;;
        w)
            install_skywarnplus_flag=true
            ;;
        d)
            install_dvswitch_flag=true
            ;;
        t)
            DRY_RUN=true
            log INFO "Dry run mode enabled"
            ;;
        v)
            VERBOSE=true
            log INFO "Verbose mode enabled"
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# If no options are provided, show usage and exit
if [ "$OPTIND" -eq 1 ]; then
    usage
    exit 1
fi

# Check if configuration file exists
if [ ! -f "$CONF_FILE" ]; then
    log WARN "Configuration file $CONF_FILE not found. Some installations may fail."
fi

# Perform the installations based on flags
[ "$install_allscan_flag" ] && install_allscan
[ "$install_supermon_flag" ] && install_supermon
[ "$install_skywarnplus_flag" ] && install_skywarnplus
[ "$install_dvswitch_flag" ] && install_dvswitch

# Cleanup
if [ "$DRY_RUN" = false ]; then
    rm -rf "$TEMP_DIR"
    log INFO "Installation completed. Log file: $LOG_FILE"
else
    log INFO "Dry run completed. No changes were made."
fi
