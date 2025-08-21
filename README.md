![MAPI Logo](https://github.com/KD5FMU/ASL3_Multi_App_Install/blob/main/MAIS.png)

# AllStarLink Multiple Application Install Script
This is an enhanced script file that will help install AllScan, DvSwitch Server, SkywarnPlus, Supermon 7.4 Fresh Install and the Upgradable Version. I mostly utilize this script to install these Apps once I setup a new ASL3 Install.

You now have the option to install SkywarnPlus, DVSwitch Server, AllScan and Supermon 7.4+ Upgrade version onto your AllStarLink version 3 node. As of this date (1/11/2025) This has been tested on the Raspberry Pi Appliance version of ASL 3.

This has also been tested on Debian 12 versions.

## 🚀 New Features & Improvements

The script has been significantly enhanced with:
- **Error handling & robustness** - Comprehensive error checking and retry logic
- **Logging system** - Detailed logs saved to `/var/log/m_app_install.log`
- **Dry-run mode** - Test installations without making changes (`-t` flag)
- **Verbose output** - Detailed debugging information (`-v` flag)
- **Smart dependency management** - Only installs missing packages
- **Configuration backups** - Automatic backups before modifications
- **Better user feedback** - Colored output and progress indicators

## 📋 Prerequisites

- AllStarLink version 3 installed and configured
- Root or sudo access
- Internet connection for downloads
- For DVSwitch: PHP 8.2 must be available in your package repositories

## 🛠️ Installation

Once you have done a basic setup of the new ASL 3 node install you can now safely download and run the script file. Go to the root directory by executing the following command:

```bash
cd
```

Then we can download the script file with this command:

```bash
wget https://raw.githubusercontent.com/KD5FMU/ASL3_Multi_App_Install/refs/heads/main/m_app.sh
```

Then once the download has finished we need to make the newly downloaded script file executable. We can do this with the following command:

```bash
chmod +x m_app.sh
```

## 📖 Usage

You now have options that can be passed to the script to install the applications that you desire.

```bash
Usage: ./m_app.sh [OPTIONS]

Options:
  -a    Install allscan
  -s    Install supermon
  -n    Install supermon-ng
  -w    Install skywarnplus
  -d    Install dvswitch
  -v    Verbose output
  -t    Dry run (test mode)
  -h    Display this help message

You can combine options to install multiple software (e.g., ./m_app.sh -a -s -n).
```

## 🔧 Examples

**Test mode** - See what would be installed without making changes:
```bash
sudo ./m_app.sh -t -a -s -w
```

**Verbose installation** - Get detailed output during installation:
```bash
sudo ./m_app.sh -v -a -s -n -w -d
```

**Normal installation** - Install all applications:
```bash
sudo ./m_app.sh -asnwd
```

**Install specific applications** - Choose only what you need:
```bash
sudo ./m_app.sh -w -s  # Install only SkywarnPlus and Supermon
```

## 📝 What Gets Installed

This script will install:
- **AllScan** - Dashboard for AllStarLink monitoring
- **DVSwitch Server** - Digital Voice switching (requires PHP 8.2)
- **SkywarnPlus** - Weather alert integration
- **Supermon 7.4+** - Enhanced monitoring interface
- **Supermon-NG** - Next generation monitoring (alternative to Supermon)

## 🔍 Logging & Troubleshooting

- **Log file**: `/var/log/m_app_install.log`
- **Configuration backups**: Stored as `.bak-*` files
- **Temporary files**: Automatically cleaned up after installation

## ⚠️ Important Notes

- The script must be run as root or with sudo
- DVSwitch requires PHP 8.2 specifically
- Configuration files are automatically backed up before modification
- Use dry-run mode (`-t`) to test before actual installation
- Check the log file for detailed installation information

## 🤝 Contributing

This script has been enhanced with community feedback and continues to be improved. If you encounter issues or have suggestions, please report them through the GitHub repository.

---

It is my wish that you find this enhanced script file useful.

73 DE KD5FMU

"Ham On Y'all" 

