#!/bin/bash

# This Script file was created to assist with a new install of AllStarLink version 3. 
# Once you have applied your node setup you can run this file to Install SkywarnPlus, Apache2, AllScan Dashboard
# DVSwitch Server, Supermon 7.4+ Fresh Install and Upgradeable Install version of Supermon 7.4+ 

# This file created by Freddie Mac - KD5FMU with the help of ChatGPT with help from Allan - WA3WCO

#
# check if root
#
SUDO=""
if [[ $EUID != 0 ]]; then
    SUDO="sudo"
    SUDO_EUID=$(${SUDO} id -u)
    if [[ ${SUDO_EUID} -ne 0 ]]; then
        echo "This script must be run as root or with sudo"
        exit 1
    fi
fi

# Install package dependencies for DVSwitch
echo "Package Depend for DVSwitch..."
sudo apt install php-cgi libapache2-mod-php8.2
echo "Apache2 for DVSwitch Installed..."

# Install SkywarnPlus
echo "Installing SkywarnPlus..."
cd ~
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Mason10198/SkywarnPlus/main/swp-install)"
echo "SkywarnPlus installed."

# Install the AllScan dashboard
echo "Installing AllScan..."
cd ~
sudo wget 'https://raw.githubusercontent.com/davidgsd/AllScan/main/AllScanInstallUpdate.php'
sudo chmod 755 AllScanInstallUpdate.php
sudo ./AllScanInstallUpdate.php
echo "AllScan installed."

# Install DVSwitch Server
echo "Installing DVSwitch Server..."
cd ~
sudo wget dvswitch.org/bookworm
sudo chmod +x bookworm
sudo ./bookworm
sudo apt update
sudo apt install -y dvswitch-server
echo "DVSwitch Server installed."

# Install Supermon 7.4
echo "Installing Supermon 7.4..."
cd /usr/local/sbin
sudo wget "http://2577.asnode.org:43856/supermonASL_fresh_install" -O supermonASL_fresh_install
sudo chmod +x supermonASL_fresh_install
hash
sudo ./supermonASL_fresh_install
echo "Supermon 7.4 installed."

# Install Supermon 7.4 Upgradeable
echo "Installing Upgradeable Supermon 7.4..."
cd /usr/local/sbin
sudo wget "http://2577.asnode.org:43856/supermonASL_latest_update" -O supermonASL_latest_update
sudo chmod +x supermonASL_latest_update
hash
sudo ./supermonASL_latest_update
echo "Upgradeable Supermon 7.4 installed."

# Path to the rpt.conf file
CONF_FILE="/etc/asterisk/rpt.conf"

# Backup the original configuration file
cp $CONF_FILE ${CONF_FILE}.bak

# Add line to rpt.conf
echo "Updating rpt.conf..."
sudo sed -i '/\[functions\]/a SMUPDATE=cmd,/usr/local/sbin/supermonASL_latest_update' /etc/asterisk/rpt.conf
echo "rpt.conf updated."

# Add line to rpt.conf for SkywarnPlus
echo "Updating rpt.conf..."
sudo sed -i '/\[functions\]/a ;SkyControl DTMF commands' /etc/asterisk/rpt.conf
echo "rpt.conf updated."

# Update rpt.conf to add SkywarnPlus control commands
echo "Updating rpt.conf with SkywarnPlus commands..."
sudo sed -i '/\[functions\]/a \
831 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py enable toggle ; Toggles SkywarnPlus\n\
832 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py sayalert toggle ; Toggles SayAlert\n\
833 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py sayallclear toggle ; Toggles SayAllClear\n\
834 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py tailmessage toggle ; Toggles TailMessage\n\
835 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py courtesytone toggle ; Toggles CourtesyTone\n\
836 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py alertscript toggle ; Toggles AlertScript\n\
837 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py idchange toggle ; Toggles IDChange\n\
838 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py changect normal ; Forces CT to "normal" mode\n\
839 = cmd,/usr/local/bin/SkywarnPlus/SkyControl.py changeid normal ; Forces ID to "normal" mode' /etc/asterisk/rpt.conf
echo "rpt.conf updated with SkywarnPlus commands."

# Add SkyDescribe DTMF commands to rpt.conf
echo "Adding SkyDescribe DTMF commands to rpt.conf..."
sudo sed -i '/\[functions\]/a \
841 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 1 ; SkyDescribe the 1st alert\n\
842 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 2 ; SkyDescribe the 2nd alert\n\
843 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 3 ; SkyDescribe the 3rd alert\n\
844 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 4 ; SkyDescribe the 4th alert\n\
845 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 5 ; SkyDescribe the 5th alert\n\
846 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 6 ; SkyDescribe the 6th alert\n\
847 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 7 ; SkyDescribe the 7th alert\n\
848 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 8 ; SkyDescribe the 8th alert\n\
849 = cmd,/usr/local/bin/SkywarnPlus/SkyDescribe.py 9 ; SkyDescribe the 9th alert' /etc/asterisk/rpt.conf
echo "SkyDescribe DTMF commands added to rpt.conf."

# Uncomment and change tailmessagetime and tailsquashedtime
sed -i '/tailmessagetime=/s/^#//; s/tailmessagetime=.*/tailmessagetime=600000/' $CONF_FILE
sed -i '/tailsquashedtime=/s/^#//; s/tailsquashedtime=.*/tailsquashedtime=30000/' $CONF_FILE

# Insert tailmessagelist line before tailsquashedtime
awk '/tailsquashedtime=30000/ { print "tailmessagelist = /tmp/SkywarnPlus/wx-tail"; } { print }' $CONF_FILE > ${CONF_FILE}.tmp && mv ${CONF_FILE}.tmp $CONF_FILE
echo "Modifications applied successfully."

# Must allow apache2 to access /tmp for info to be displayed properly on dvswitch dashboard
sudo cp /lib/systemd/system/apache2.service /etc/systemd/system/
sudo sed -i 's/true/false/g' /etc/systemd/system/apache2.service
sudo systemctl restart apache2

# Add cron job
# echo "Setting up cron job..."
# (sudo crontab -l 2>/dev/null; echo "0 3 * * * /var/www/html/supermon/astdb.php cron") | sudo crontab -
# echo "Cron job set."

# Define the cron job and its preceding comment
echo "Setting up cron job..."
CRON_COMMENT="# Supermon 7.4 updater crontab entry"
CRON_JOB="0 3 * * * /var/www/html/supermon/astdb.php cron"

# Add the cron job and comment to the root user's crontab
(sudo crontab -l 2>/dev/null; echo "$CRON_COMMENT"; echo "$CRON_JOB") | sudo crontab -

# Print the current crontab to verify
echo "Current crontab for root:"
sudo crontab -l



echo "All installations and configurations are completed."
