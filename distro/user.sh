#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

banner() {
    clear
    printf "\033[33m    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  \033[0m\n"
    printf "\033[36m    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ \033[0m\n"
    printf "\033[32m    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ \033[0m\n"
    printf "\033[0m\n"
    printf "     \033[32mA modded gui version of ubuntu for Termux\033[0m\n"
    printf "\033[0m\n"
}

sudo_install() {
    echo -e "\n${R} [${W}-${R}]${C} Installing Sudo..."${W}
    apt update -y
    apt install sudo -y
    apt install wget apt-utils locales-all dialog tzdata -y
    echo -e "\n${R} [${W}-${R}]${G} Sudo Successfully Installed !"${W}
}

login() {
    banner
    read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Username [Lowercase] : \e[0m\e[1;96m\en' user
    echo -e "${W}"
    read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Password : \e[0m\e[1;96m\en' pass
    echo -e "${W}"
    
    if id "$user" &>/dev/null; then
        echo -e "\n${R} User already exists. Skipping user creation...${W}"
    else
        useradd -m -s $(which bash) ${user}
        echo "${user}:${pass}" | chpasswd
    fi
    
    usermod -aG sudo ${user}
    echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

    echo "proot-distro login --user $user ubuntu --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports" > /data/data/com.termux/files/usr/bin/ubuntu
    #chmod +x /data/data/com.termux/files/usr/bin/ubuntu 
    
    if [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh' ]];then
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    else
        wget -q --show-progress https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/gui.sh
        mv -vf gui.sh /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    fi
}

# Linux Tools Installation Script
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

# Install a package with the detected package manager
install_package() {
  local package=$1
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
NETWORK_TOOLS="nmap ncat ndiff zenmap wireshark tshark tcpdump netcat-traditional ettercap-common arpwatch"
for tool in $NETWORK_TOOLS; do
  install_package "$tool"
done

# Web Application Testing Tools
WEB_TOOLS="gobuster ffuf wpscan nikto"
for tool in $WEB_TOOLS; do
  install_package "$tool"
done

# Penetration Testing Frameworks
PEN_TEST_TOOLS="metasploit-framework aircrack-ng bettercap beef-xss"
for tool in $PEN_TEST_TOOLS; do
  install_package "$tool"
done

# Vulnerability Analysis Tools
VULN_TOOLS="hydra sqlmap rkhunter chkrootkit lynis"
for tool in $VULN_TOOLS; do
  install_package "$tool"
done

# Information Gathering Tools
INFO_TOOLS="theharvester cewl dnsrecon dnsenum amass subfinder"
for tool in $INFO_TOOLS; do
  install_package "$tool"
done

# Password Cracking Tools
PASSWORD_TOOLS="john hashcat crunch"
for tool in $PASSWORD_TOOLS; do
  install_package "$tool"
done

# Exploitation Tools
EXPLOIT_TOOLS="responder evil-winrm mimikatz powershell-empire"
for tool in $EXPLOIT_TOOLS; do
  install_package "$tool"
done

# Miscellaneous Tools
MISC_TOOLS="burpsuite yara fcrackzip dirbuster spiderfoot masscan"
for tool in $MISC_TOOLS; do
  install_package "$tool"
done

# Additional Tools
ADDITIONAL_TOOLS="recon-ng maltego sublist3r massdns dirsearch scapy feroxbuster wfuzz"
for tool in $ADDITIONAL_TOOLS; do
  install_package "$tool"
done

# Install Metasploit Framework via external script
if command -v curl &>/dev/null; then
  echo "[+] Installing Metasploit Framework..."
  curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
  chmod 755 msfinstall && ./msfinstall
else
  echo "[-] curl is not installed. Skipping Metasploit installation."
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
clear
echo
echo -e "\n${R} [${W}-${R}]${G} Restart your Termux & Type ${C}ubuntu"${W}
echo -e "\n${R} [${W}-${R}]${G} Then Type ${C}sudo bash gui.sh "${W}
echo
}

banner
sudo_install
login
