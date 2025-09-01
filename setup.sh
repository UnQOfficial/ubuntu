#!/bin/bash

# UnQ Ubuntu Installation Script - Enhanced Version
# Repository: https://github.com/UnQOfficial/ubuntu

# Color Definitions
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"
RESET="$(printf '\033[0m')"

# Directory Variables
CURR_DIR=$(realpath "$(dirname "$BASH_SOURCE")")
UBUNTU_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

# Auto-install flag
AUTO_INSTALL=false
[[ "$1" == "-a" || "$1" == "--auto" ]] && AUTO_INSTALL=true

# Progress Bar Function
show_progress() {
    local duration=$1
    local message=$2
    local progress=0
    local bar_length=30
    
    echo -e "${C}${message}${W}"
    while [ $progress -le 100 ]; do
        local filled=$((progress * bar_length / 100))
        local empty=$((bar_length - filled))
        
        printf "\r${G}["
        printf "%*s" $filled | tr ' ' '█'
        printf "%*s" $empty | tr ' ' '░'
        printf "] ${Y}%d%%${W}" $progress
        
        sleep $(echo "scale=2; $duration/100" | bc -l 2>/dev/null || echo "0.05")
        ((progress += 2))
    done
    echo
}

# UnQ Banner
unq_banner() {
    clear
    cat <<- 'EOF'
	
	╔══════════════════════════════════════════════════════════════╗
	║                                                              ║
	║    ██    ██ ███    ██  ██████                                ║
	║    ██    ██ ████   ██ ██    ██                               ║
	║    ██    ██ ██ ██  ██ ██    ██                               ║
	║    ██    ██ ██  ██ ██ ██ ▄▄ ██                               ║
	║     ██████  ██   ████  ██████                                ║
	║                           ▀▀                                 ║
	╚══════════════════════════════════════════════════════════════╝
	
	EOF
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║${Y}                     UBUNTU INSTALLER                       ${C}║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G}     A modded GUI version of Ubuntu for Termux${W}"
    echo -e "${C}     Repository: ${Y}https://github.com/UnQOfficial/ubuntu${W}\n"
}

# Quick Installation Menu
quick_install_menu() {
    if [[ "$AUTO_INSTALL" == "false" ]]; then
        unq_banner
        echo -e "${Y}╔══════════════════════════════════════════════════════════════╗${W}"
        echo -e "${Y}║                    🚀 INSTALLATION OPTIONS                   ║${W}"
        echo -e "${Y}╚══════════════════════════════════════════════════════════════╝${W}"
        echo -e "${G} [1]${W} 📋 Standard Installation (Interactive)"
        echo -e "${G} [2]${W} ⚡ Quick Installation (Auto)"
        echo -e "${G} [3]${W} ❌ Exit"
        echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
        echo -e -n "${C}║${W} Select option ${G}[1-3]${W}: "
        
        read -r choice
        case $choice in
            1) echo -e "${G}Starting Interactive Installation...${W}\n" ;;
            2) AUTO_INSTALL=true; echo -e "${Y}Starting Quick Installation...${W}\n" ;;
            3) echo -e "${R}Installation cancelled.${W}"; exit 0 ;;
            *) echo -e "${R}Invalid option. Starting Interactive Installation...${W}\n" ;;
        esac
    fi
}

# Confirmation Prompt
confirm_action() {
    if [[ "$AUTO_INSTALL" == "false" ]]; then
        echo -e -n "${Y}$1 ${G}[Y/n]${W}: "
        read -r response
        [[ "$response" =~ ^[Nn]$ ]] && { echo -e "${R}Action cancelled.${W}"; exit 0; }
    fi
}

# Package Installation
install_packages() {
    unq_banner
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   📦 PACKAGE MANAGEMENT                      ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    # Storage Setup
    if [[ ! -d '/data/data/com.termux/files/home/storage' ]]; then
        echo -e "${Y}Setting up storage permissions...${W}"
        show_progress 2 "Configuring storage access"
        termux-setup-storage
    fi

    # Check required packages
    if [[ $(command -v pulseaudio) && $(command -v proot-distro) ]]; then
        echo -e "${G}✓ All required packages are already installed${W}\n"
        return 0
    fi

    confirm_action "Install required packages (pulseaudio, proot-distro)?"

    echo -e "${C}Updating package repositories...${W}"
    show_progress 3 "Updating packages"
    yes | pkg upgrade &>/dev/null

    packages=(pulseaudio proot-distro)
    local total=${#packages[@]}
    local current=0

    for package in "${packages[@]}"; do
        ((current++))
        if ! command -v "$package" &>/dev/null; then
            echo -e "\n${C}[$current/$total] Installing: ${Y}$package${W}"
            show_progress 4 "Installing $package"
            yes | pkg install "$package" &>/dev/null || {
                echo -e "${R}✗ Failed to install $package${W}"
                exit 1
            }
            echo -e "${G}✓ $package installed successfully${W}"
        else
            echo -e "${G}✓ $package already installed${W}"
        fi
    done
}

# Distro Installation
install_distro() {
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                    🐧 UBUNTU INSTALLATION                    ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    termux-reload-settings
    
    if [[ -d "$UBUNTU_DIR" ]]; then
        echo -e "${G}✓ Ubuntu distro already installed${W}"
        return 0
    fi

    confirm_action "Install Ubuntu 22.04 distribution?"

    echo -e "${C}Installing Ubuntu 22.04...${W}"
    show_progress 15 "Downloading and installing Ubuntu"
    
    proot-distro install ubuntu || {
        echo -e "\n${R}✗ Failed to install Ubuntu distro${W}"
        exit 1
    }
    
    termux-reload-settings
    
    if [[ -d "$UBUNTU_DIR" ]]; then
        echo -e "${G}✓ Ubuntu installed successfully!${W}"
    else
        echo -e "${R}✗ Ubuntu installation verification failed${W}"
        exit 1
    fi
}

# Audio Configuration
configure_audio() {
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                     🔊 AUDIO CONFIGURATION                   ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    echo -e "${C}Configuring audio system...${W}"
    show_progress 3 "Setting up PulseAudio"
    
    [[ ! -e "$HOME/.sound" ]] && touch "$HOME/.sound"
    
    cat > "$HOME/.sound" << 'EOF'
pacmd load-module module-aaudio-sink
pulseaudio --start --exit-idle-time=-1
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
EOF
    
    echo -e "${G}✓ Audio configuration completed${W}"
}

# Enhanced Downloader
download_file() {
    local path="$1"
    local url="$2"
    local filename=$(basename "$path")
    
    [[ -e "$path" ]] && rm -rf "$path"
    
    echo -e "${C}Downloading ${Y}$filename${C}...${W}"
    
    if curl --progress-bar --insecure --fail \
           --retry-connrefused --retry 3 --retry-delay 2 \
           --location --output "$path" "$url"; then
        echo -e "${G}✓ Downloaded $filename successfully${W}"
        return 0
    else
        echo -e "${R}✗ Failed to download $filename${W}"
        return 1
    fi
}

# VNC Setup
setup_vnc() {
    echo -e "${C}Setting up VNC scripts...${W}"
    
    local base_url="https://raw.githubusercontent.com/UnQOfficial/ubuntu/master/distro"
    
    # VNC Start Script
    if [[ -f "$CURR_DIR/distro/vncstart" ]]; then
        cp -f "$CURR_DIR/distro/vncstart" "$UBUNTU_DIR/usr/local/bin/vncstart"
    else
        download_file "$CURR_DIR/vncstart" "$base_url/vncstart" || exit 1
        mv -f "$CURR_DIR/vncstart" "$UBUNTU_DIR/usr/local/bin/vncstart"
    fi

    # VNC Stop Script
    if [[ -f "$CURR_DIR/distro/vncstop" ]]; then
        cp -f "$CURR_DIR/distro/vncstop" "$UBUNTU_DIR/usr/local/bin/vncstop"
    else
        download_file "$CURR_DIR/vncstop" "$base_url/vncstop" || exit 1
        mv -f "$CURR_DIR/vncstop" "$UBUNTU_DIR/usr/local/bin/vncstop"
    fi
    
    chmod +x "$UBUNTU_DIR/usr/local/bin/vncstart"
    chmod +x "$UBUNTU_DIR/usr/local/bin/vncstop"
    
    echo -e "${G}✓ VNC scripts configured${W}"
}

# Environment Setup
setup_environment() {
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   ⚙️  ENVIRONMENT SETUP                      ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    show_progress 5 "Configuring environment"

    # User Setup Script
    local base_url="https://raw.githubusercontent.com/UnQOfficial/ubuntu/master/distro"
    
    if [[ -f "$CURR_DIR/distro/user.sh" ]]; then
        cp -f "$CURR_DIR/distro/user.sh" "$UBUNTU_DIR/root/user.sh"
    else
        download_file "$CURR_DIR/user.sh" "$base_url/user.sh" || exit 1
        mv -f "$CURR_DIR/user.sh" "$UBUNTU_DIR/root/user.sh"
    fi
    chmod +x "$UBUNTU_DIR/root/user.sh"

    # Setup VNC
    setup_vnc

    # Configure timezone
    echo "$(getprop persist.sys.timezone)" > "$UBUNTU_DIR/etc/timezone"
    
    # Create Ubuntu command
    echo "proot-distro login ubuntu" > "$PREFIX/bin/ubuntu"
    chmod +x "$PREFIX/bin/ubuntu"
    
    termux-reload-settings
    
    # Verify installation
    if [[ -e "$PREFIX/bin/ubuntu" ]]; then
        echo -e "${G}✓ Environment setup completed${W}"
        return 0
    else
        echo -e "${R}✗ Environment setup failed${W}"
        exit 1
    fi
}

# Installation Complete
installation_complete() {
    unq_banner
    echo -e "${G}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${G}║                    🎉 INSTALLATION COMPLETE                  ║${W}"
    echo -e "${G}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G} ✓ Ubuntu 22.04 CLI successfully installed${W}"
    echo -e "${G} ✓ All components configured${W}"
    echo -e "${Y} ⚠️  Please restart Termux to prevent issues${W}\n"
    
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                       USAGE INSTRUCTIONS                     ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${W} • Type ${G}ubuntu${W} to start Ubuntu CLI"
    echo -e "${W} • For GUI mode: Run ${G}ubuntu${W} then ${G}bash user.sh${W}"
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║  🚀 Quick Install Command:                                   ║${W}"
    echo -e "${Y}║  curl -fsSL https://raw.githubusercontent.com/UnQOfficial/   ║${W}"
    echo -e "${Y}║  ubuntu/master/install.sh | sudo bash -s -- -a              ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
}

# Main Installation Flow
main() {
    # Check if running as root in proot
    if [[ -n "$PROOT_DISTRO" ]]; then
        echo -e "${R}This script should be run from Termux, not inside Ubuntu${W}"
        exit 1
    fi

    quick_install_menu
    install_packages
    install_distro  
    configure_audio
    setup_environment
    installation_complete
}

# Error Handler
trap 'echo -e "\n${R}Installation interrupted${W}"; exit 1' INT TERM

# Execute Main Function
main "$@"
