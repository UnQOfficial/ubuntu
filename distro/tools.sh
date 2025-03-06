#!/bin/bash
# coded by LIONMAD
# Linux Tools Installation Script

# Display a banner
display_banner() {
  echo "============================================="
  echo "  Linux Tools Installation Script            "
  echo "        Coded by LIONMAD                     "
  echo "      Credit to BDhackers009                "
  echo "============================================="
  echo ""
}

# Display the banner
display_banner

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo to run the script."
  exit 1
fi

# Detect Linux Distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    echo "$DISTRIB_ID"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  elif [ -f /etc/redhat-release ]; then
    echo "rhel"
  elif [ -f /etc/arch-release ]; then
    echo "arch"
  else
    echo "unknown"
  fi
}

# Detect Package Manager Based on Distro
detect_package_manager() {
  local distro=$1
  case $distro in
    ubuntu | debian | kali)
      echo "apt"
      ;;
    arch | manjaro)
      echo "pacman"
      ;;
    fedora | centos | rhel | rocky | alma)
      if command -v dnf &>/dev/null; then
        echo "dnf"
      else
        echo "yum"
      fi
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

DISTRO=$(detect_distro)
PACKAGE_MANAGER=$(detect_package_manager "$DISTRO")

if [ "$PACKAGE_MANAGER" == "unknown" ]; then
  echo "Unsupported Linux distribution. Exiting..."
  exit 1
fi

echo "[+] Detected Distribution: $DISTRO"
echo "[+] Using Package Manager: $PACKAGE_MANAGER"

# Update system packages
update_system() {
  case $PACKAGE_MANAGER in
    apt)
      apt update && apt upgrade -y
      ;;
    pacman)
      pacman -Syu --noconfirm
      ;;
    yum)
      yum update -y
      ;;
    dnf)
      dnf update -y
      ;;
  esac
}

# Function to check if a package is available in the default repositories
is_package_available() {
  local package=$1
  case $PACKAGE_MANAGER in
    apt)
      apt-cache show "$package" &>/dev/null
      return $?
      ;;
    pacman)
      pacman -Si "$package" &>/dev/null
      return $?
      ;;
    yum | dnf)
      yum info "$package" &>/dev/null
      return $?
      ;;
  esac
}

# Function to add Kali Linux repositories temporarily
add_kali_repos() {
  echo "[+] Adding Kali Linux repositories temporarily..."
  echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" | sudo tee /etc/apt/sources.list.d/kali.list
  wget -q -O - https://archive.kali.org/archive-key.asc | sudo apt-key add -
  apt update
}

# Function to remove Kali Linux repositories
remove_kali_repos() {
  echo "[+] Removing Kali Linux repositories..."
  rm -f /etc/apt/sources.list.d/kali.list
  apt-key del "Archive Key"
  apt update
}

# Install a package with the detected package manager
install_package() {
  local package=$1
  if is_package_available "$package"; then
    case $PACKAGE_MANAGER in
      apt)
        apt install -y "$package" || echo "[-] Failed to install $package via apt."
        ;;
      pacman)
        pacman -S --noconfirm "$package" || echo "[-] Failed to install $package via pacman."
        ;;
      yum)
        yum install -y "$package" || echo "[-] Failed to install $package via yum."
        ;;
      dnf)
        dnf install -y "$package" || echo "[-] Failed to install $package via dnf."
        ;;
    esac
  else
    if [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "ubuntu" ]; then
      add_kali_repos
      apt install -y "$package" || echo "[-] Failed to install $package via Kali repositories."
      remove_kali_repos
    else
      echo "[-] Package $package not found in default repositories and Kali repositories are not supported on $DISTRO."
    fi
  fi
}

# Update and upgrade system packages
echo "[+] Updating system packages..."
update_system

# Essential dependencies
ESSENTIAL_PACKAGES="build-essential python3-pip python3-dev git curl wget"
for pkg in $ESSENTIAL_PACKAGES; do
  install_package "$pkg"
done

# Network Scanning and Analysis Tools
NETWORK_TOOLS="nmap ncat ndiff tshark tcpdump netcat-traditional arpwatch"
for tool in $NETWORK_TOOLS; do
  install_package "$tool"
done

# Web Application Testing Tools
WEB_TOOLS="gobuster ffuf wpscan nikto"
for tool in $WEB_TOOLS; do
  install_package "$tool"
done

# Penetration Testing Frameworks
PEN_TEST_TOOLS="beef-xss"
for tool in $PEN_TEST_TOOLS; do
  install_package "$tool"
done

# Vulnerability Analysis Tools
VULN_TOOLS="hydra sqlmap rkhunter chkrootkit lynis"
for tool in $VULN_TOOLS; do
  install_package "$tool"
done

# Information Gathering Tools
INFO_TOOLS="cewl dnsrecon dnsenum amass subfinder"
for tool in $INFO_TOOLS; do
  install_package "$tool"
done

# Password Cracking Tools
PASSWORD_TOOLS="john hashcat crunch"
for tool in $PASSWORD_TOOLS; do
  install_package "$tool"
done

# Exploitation Tools
EXPLOIT_TOOLS="responder binwalk"
for tool in $EXPLOIT_TOOLS; do
  install_package "$tool"
done

# Miscellaneous Tools
MISC_TOOLS="fcrackzip dirbuster spiderfoot dirb masscan"
for tool in $MISC_TOOLS; do
  install_package "$tool"
done

# Additional Tools and Services to install
ADDITIONAL_TOOLS="recon-ng sublist3r massdns dirsearch ssh apache2 telnetd scapy wfuzz"

# Install additional tools
for tool in $ADDITIONAL_TOOLS; do
  install_package "$tool"
done

# Install Metasploit Framework via external script
if command -v curl &>/dev/null; then
  echo "[+] Installing/Updating Metasploit Framework..."

  # Download the Metasploit installation script
  curl -fsSL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb -o msfinstall

  # Check if the download was successful
  if [ -f msfinstall ]; then
    chmod +x msfinstall && sudo ./msfinstall
    echo "[+] Ensuring the latest version of Metasploit Framework is installed..."

    # Ensure Metasploit is up-to-date
    sudo msfupdate
  else
    echo "[-] Failed to download msfinstall script."
  fi
else
  echo "[-] curl is not installed. Please install curl to proceed with Metasploit installation."
fi

# Install Visual Studio Code via external script
if command -v curl &>/dev/null; then
  echo "[+] Installing Visual Studio Code..."

  # Download the Visual Studio Code installation script for Ubuntu/Debian
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
  curl -fsSL https://packages.microsoft.com/repos/ms-teams stable main | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

  # Update package list and install Visual Studio Code
  sudo apt-get update
  sudo apt-get install -y code
  echo "[+] Visual Studio Code has been installed successfully!"
else
  echo "[-] curl is not installed. Please install curl to proceed with Visual Studio Code installation."
fi

# Cleanup unnecessary packages
echo "[+] Cleaning up unnecessary packages..."
case $PACKAGE_MANAGER in
  apt)
    apt autoremove -y
    ;;
  pacman)
    pacman -Rns $(pacman -Qdtq) --noconfirm
    ;;
  yum | dnf)
    echo "[+] Skipping cleanup for $PACKAGE_MANAGER as it doesn't require additional commands."
    ;;
esac

# Final message
echo "[+] Installation complete! All tools are installed successfully."
echo "[+] You may want to restart your system for all changes to take effect."
