#!/bin/bash

# UnQ GUI Setup Script - Enhanced Version with AI IDEs
# Repository: https://github.com/UnQOfficial/ubuntu

# Color Definitions
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"
RESET="$(printf '\033[0m')"

# System Variables
arch=$(uname -m)
username=$(getent group sudo | awk -F ':' '{print $4}' | cut -d ',' -f1)

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

# Root Check
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${R}╔══════════════════════════════════════════════════════════════╗${W}"
        echo -e "${R}║                    ⚠️  ROOT ACCESS REQUIRED                   ║${W}"
        echo -e "${R}╚══════════════════════════════════════════════════════════════╝${W}"
        echo -e "${R}This script must be run as root!${W}"
        echo -e "${Y}Run: sudo bash gui.sh${W}\n"
        exit 1
    fi
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
    echo -e "${C}║${Y}                       GUI INSTALLER                        ${C}║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G}     A modded GUI version of Ubuntu for Termux${W}"
    echo -e "${C}     Repository: ${Y}https://github.com/UnQOfficial/ubuntu${W}\n"
}

# Success Note
installation_note() {
    unq_banner
    echo -e "${G}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${G}║                    🎉 INSTALLATION COMPLETE                  ║${W}"
    echo -e "${G}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G} ✓ GUI Desktop successfully installed${W}"
    echo -e "${G} ✓ All selected components configured${W}\n"
    
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                       USAGE INSTRUCTIONS                     ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${W} • Start VNC: ${G}vncstart${W}"
    echo -e "${W} • Stop VNC: ${G}vncstop${W}"
    echo -e "${W} • Install VNC VIEWER app on your device"
    echo -e "${W} • Connect to: ${G}localhost:1${W}"
    echo -e "${W} • Set Picture Quality to High for better experience"
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                         ENJOY! 🎉                           ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
}

# Package Installation
install_packages() {
    unq_banner
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   📦 INSTALLING PACKAGES                     ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    echo -e "${C}Updating package repositories...${W}"
    show_progress 3 "Refreshing package lists"
    apt-get update -y &>/dev/null
    
    # Fix udisks2 issue
    echo -e "${C}Configuring udisks2...${W}"
    apt install udisks2 -y &>/dev/null
    rm -f /var/lib/dpkg/info/udisks2.postinst
    echo "" > /var/lib/dpkg/info/udisks2.postinst
    dpkg --configure -a &>/dev/null
    apt-mark hold udisks2 &>/dev/null
    
    # Essential packages
    packages=(sudo gnupg2 curl nano git xz-utils at-spi2-core xfce4 xfce4-goodies xfce4-terminal librsvg2-common menu inetutils-tools dialog exo-utils tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11 fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf apt-transport-https)
    
    local total=${#packages[@]}
    local current=0
    
    for package in "${packages[@]}"; do
        ((current++))
        if ! command -v "$package" &>/dev/null; then
            echo -e "\n${C}[$current/$total] Installing: ${Y}$package${W}"
            show_progress 2 "Installing $package"
            apt-get install "$package" -y --no-install-recommends &>/dev/null || {
                echo -e "${R}⚠ Warning: Failed to install $package${W}"
            }
        else
            echo -e "${G}✓ $package already installed${W}"
        fi
    done
    
    echo -e "\n${C}Upgrading system packages...${W}"
    show_progress 4 "Upgrading system"
    apt-get update -y &>/dev/null
    apt-get upgrade -y &>/dev/null
}

# Generic APT Installer
install_apt_package() {
    for pkg in "$@"; do
        if command -v "$pkg" &>/dev/null; then
            echo -e "${Y}✓ $pkg is already installed${W}"
        else
            echo -e "${G}Installing ${Y}$pkg${W}"
            show_progress 3 "Installing $pkg"
            apt install -y "$pkg" &>/dev/null || {
                echo -e "${R}✗ Failed to install $pkg${W}"
            }
        fi
    done
}

# VSCode Installation
install_vscode() {
    if command -v code &>/dev/null; then
        echo -e "${Y}✓ VSCode is already installed${W}"
        return 0
    fi
    
    echo -e "${G}Installing ${Y}Visual Studio Code${W}"
    show_progress 8 "Installing VSCode"
    
    # Add Microsoft GPG key
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg 2>/dev/null
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ 2>/dev/null
    
    # Add repository
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
    
    # Install VSCode
    apt update -y &>/dev/null
    apt install code -y &>/dev/null
    
    # Apply patch for better compatibility
    echo -e "${C}Applying compatibility patch...${W}"
    curl -fsSL https://raw.githubusercontent.com/UnQOfficial/ubuntu/master/patches/code.desktop > /usr/share/applications/code.desktop 2>/dev/null
    
    echo -e "${G}✓ Visual Studio Code installed successfully${W}\n"
}

# Sublime Text Installation
install_sublime() {
    if command -v subl &>/dev/null; then
        echo -e "${Y}✓ Sublime Text is already installed${W}"
        return 0
    fi
    
    echo -e "${G}Installing ${Y}Sublime Text${W}"
    show_progress 6 "Installing Sublime Text"
    
    apt install gnupg2 software-properties-common --no-install-recommends -y &>/dev/null
    echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list &>/dev/null
    curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/sublime.gpg 2>/dev/null
    apt update -y &>/dev/null
    apt install sublime-text -y &>/dev/null
    
    echo -e "${G}✓ Sublime Text installed successfully${W}\n"
}

# Cursor AI IDE Installation
install_cursor() {
    if command -v cursor &>/dev/null; then
        echo -e "${Y}✓ Cursor AI IDE is already installed${W}"
        return 0
    fi
    
    echo -e "${G}Installing ${Y}Cursor AI IDE${W}"
    show_progress 10 "Installing Cursor AI Editor"
    
    # Download and install Cursor
    if curl -fsSL https://raw.githubusercontent.com/UnQOfficial/cursor/refs/heads/main/cursor.sh | bash -s -- -a &>/dev/null; then
        echo -e "${G}✓ Cursor AI IDE installed successfully${W}\n"
    else
        echo -e "${R}✗ Failed to install Cursor AI IDE${W}\n"
    fi
}

# Void AI Editor Installation
install_void() {
    if command -v void &>/dev/null; then
        echo -e "${Y}✓ Void AI Editor is already installed${W}"
        return 0
    fi
    
    echo -e "${G}Installing ${Y}Void AI Editor${W}"
    show_progress 12 "Installing Void AI Editor"
    
    # Check architecture compatibility
    case "$arch" in
        "aarch64"|"arm64"|"x86_64"|"armv7l"|"armv6l")
            echo -e "${C}Architecture ${arch} is supported${W}"
            ;;
        *)
            echo -e "${Y}⚠ Architecture ${arch} may have limited support${W}"
            ;;
    esac
    
    # Download and install Void
    if curl -fsSL https://raw.githubusercontent.com/UnQOfficial/void/main/void.sh | bash -s -- -a &>/dev/null; then
        echo -e "${G}✓ Void AI Editor installed successfully${W}\n"
    else
        echo -e "${R}✗ Failed to install Void AI Editor${W}\n"
    fi
}

# Chromium Installation
install_chromium() {
    if command -v chromium &>/dev/null; then
        echo -e "${Y}✓ Chromium is already installed${W}\n"
        return 0
    fi
    
    echo -e "${G}Installing ${Y}Chromium${W}"
    show_progress 8 "Installing Chromium browser"
    
    apt purge chromium* chromium-browser* snapd -y &>/dev/null
    apt install gnupg2 software-properties-common --no-install-recommends -y &>/dev/null
    
    # Add Debian repositories for Chromium
    echo -e "deb http://ftp.debian.org/debian buster main\ndeb http://ftp.debian.org/debian buster-updates main" >> /etc/apt/sources.list
    
    # Add required keys
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DCC9EFBF77E11517 &>/dev/null
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138 &>/dev/null
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50 &>/dev/null
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 112695A0E562B32A &>/dev/null
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32 &>/dev/null
    
    apt update -y &>/dev/null
    apt install chromium -y &>/dev/null
    
    # Fix sandbox issue
    sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop 2>/dev/null
    
    echo -e "${G}✓ Chromium installed successfully${W}\n"
}

# Firefox Installation
install_firefox() {
    if command -v firefox &>/dev/null; then
        echo -e "${Y}✓ Firefox is already installed${W}\n"
        return 0
    fi
    
    echo -e "${G}Installing ${Y}Firefox${W}"
    show_progress 8 "Installing Firefox browser"
    
    if bash <(curl -fsSL "https://raw.githubusercontent.com/UnQOfficial/ubuntu/master/distro/firefox.sh") &>/dev/null; then
        echo -e "${G}✓ Firefox installed successfully${W}\n"
    else
        echo -e "${R}✗ Failed to install Firefox${W}\n"
    fi
}

# Software Selection Menu
install_softwares() {
    unq_banner
    
    # Browser Selection
    echo -e "${Y}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${Y}║                    🌐 SELECT BROWSER                         ║${W}"
    echo -e "${Y}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${C} [${W}1${C}] 🦊 Firefox (Default)"
    echo -e "${C} [${W}2${C}] 🔵 Chromium"
    echo -e "${C} [${W}3${C}] 🌐 Both (Firefox + Chromium)"
    echo -e -n "${R} [${G}~${R}]${Y} Select an Option: ${G}"
    
    if [[ "$AUTO_INSTALL" == "false" ]]; then
        read -n1 BROWSER_OPTION
    else
        BROWSER_OPTION=1
        echo "1 (Auto-selected)"
    fi
    
    unq_banner
    
    # IDE Selection (Enhanced with AI IDEs)
    if [[ "$arch" != 'armhf' && "$arch" != *'armv7'* ]]; then
        echo -e "${Y}╔══════════════════════════════════════════════════════════════╗${W}"
        echo -e "${Y}║                     💻 SELECT IDE                           ║${W}"
        echo -e "${Y}╚══════════════════════════════════════════════════════════════╝${W}"
        echo -e "${C} [${W}1${C}] 📝 Traditional IDEs (Sublime + VSCode)"
        echo -e "${C} [${W}2${C}] 🤖 AI-Powered IDEs (Cursor + Void) ✨${W}"
        echo -e "${C} [${W}3${C}] 📚 All Traditional IDEs"
        echo -e "${C} [${W}4${C}] 🚀 All AI IDEs" 
        echo -e "${C} [${W}5${C}] 🎯 Complete Suite (All IDEs)"
        echo -e "${C} [${W}6${C}] 🔧 Custom Selection"
        echo -e "${C} [${W}7${C}] ⏭️  Skip (Default)"
        echo -e -n "${R} [${G}~${R}]${Y} Select an Option: ${G}"
        
        if [[ "$AUTO_INSTALL" == "false" ]]; then
            read -n1 IDE_OPTION
        else
            IDE_OPTION=7
            echo "7 (Auto-selected)"
        fi
        unq_banner
    fi
    
    # Media Player Selection
    echo -e "${Y}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${Y}║                   🎵 SELECT MEDIA PLAYER                     ║${W}"
    echo -e "${Y}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${C} [${W}1${C}] 🎬 MPV Media Player (Recommended)"
    echo -e "${C} [${W}2${C}] 📺 VLC Media Player"
    echo -e "${C} [${W}3${C}] 🎭 Both (MPV + VLC)"
    echo -e "${C} [${W}4${C}] ⏭️  Skip (Default)"
    echo -e -n "${R} [${G}~${R}]${Y} Select an Option: ${G}"
    
    if [[ "$AUTO_INSTALL" == "false" ]]; then
        read -n1 PLAYER_OPTION
    else
        PLAYER_OPTION=4
        echo "4 (Auto-selected)"
    fi
    
    { unq_banner; sleep 1; }
    
    # Install Selected Browsers
    case $BROWSER_OPTION in
        2) install_chromium ;;
        3) install_firefox; install_chromium ;;
        *) install_firefox ;;
    esac
    
    # Install Selected IDEs
    if [[ "$arch" != 'armhf' && "$arch" != *'armv7'* ]]; then
        case $IDE_OPTION in
            1) 
                install_sublime
                install_vscode
                ;;
            2)
                install_cursor
                install_void
                ;;
            3)
                install_sublime
                install_vscode
                ;;
            4)
                install_cursor
                install_void
                ;;
            5)
                install_sublime
                install_vscode
                install_cursor
                install_void
                ;;
            6)
                # Custom Selection Submenu
                unq_banner
                echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
                echo -e "${C}║                   🔧 CUSTOM IDE SELECTION                    ║${W}"
                echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
                echo -e "${W}Select IDEs to install (y/n for each):"
                
                echo -e -n "${G}Install Sublime Text? [Y/n]: ${W}"
                read -r sublime_choice
                [[ ! "$sublime_choice" =~ ^[Nn]$ ]] && install_sublime
                
                echo -e -n "${G}Install VSCode? [Y/n]: ${W}"
                read -r vscode_choice
                [[ ! "$vscode_choice" =~ ^[Nn]$ ]] && install_vscode
                
                echo -e -n "${G}Install Cursor AI? [Y/n]: ${W}"
                read -r cursor_choice
                [[ ! "$cursor_choice" =~ ^[Nn]$ ]] && install_cursor
                
                echo -e -n "${G}Install Void AI? [Y/n]: ${W}"
                read -r void_choice
                [[ ! "$void_choice" =~ ^[Nn]$ ]] && install_void
                ;;
            *)
                echo -e "${Y}⏭️ Skipping IDE Installation${W}\n"
                sleep 1
                ;;
        esac
    fi
    
    # Install Selected Media Players
    case $PLAYER_OPTION in
        1) install_apt_package "mpv" ;;
        2) install_apt_package "vlc" ;;
        3) install_apt_package "mpv" "vlc" ;;
        *) echo -e "${Y}⏭️ Skipping Media Player Installation${W}\n"; sleep 1 ;;
    esac
}

# Enhanced Downloader
downloader() {
    local path="$1"
    local url="$2"
    local filename=$(basename "$path")
    
    [[ -e "$path" ]] && rm -rf "$path"
    
    echo -e "${C}Downloading ${Y}$filename${W}"
    
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

# Audio Configuration
sound_fix() {
    echo -e "${C}Configuring audio system...${W}"
    echo "$(echo "bash ~/.sound" | cat - /data/data/com.termux/files/usr/bin/ubuntu)" > /data/data/com.termux/files/usr/bin/ubuntu
    echo "export DISPLAY=\":1\"" >> /etc/profile
    echo "export PULSE_SERVER=127.0.0.1" >> /etc/profile 
    source /etc/profile
}

# Theme Cleanup
cleanup_themes() {
    echo -e "${C}Cleaning unnecessary themes...${W}"
    themes=(Bright Daloa Emacs Moheli Retro Smoke)
    for theme in "${themes[@]}"; do
        [[ -d "/usr/share/themes/$theme" ]] && rm -rf "/usr/share/themes/$theme"
    done
}

# Icon Cleanup
cleanup_icons() {
    echo -e "${C}Cleaning unnecessary icons...${W}"
    icons=(hicolor LoginIcons ubuntu-mono-light)
    for icon in "${icons[@]}"; do
        [[ -d "/usr/share/icons/$icon" ]] && rm -rf "/usr/share/icons/$icon"
    done
}

# System Configuration
configure_system() {
    unq_banner
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   ⚙️  SYSTEM CONFIGURATION                   ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    sound_fix
    
    # Update system
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32 &>/dev/null
    echo -e "${C}Upgrading system packages...${W}"
    show_progress 4 "System upgrade in progress"
    apt upgrade -y &>/dev/null
    apt install gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape libglib2.0-dev-bin -y &>/dev/null
    
    # Backup original wallpaper
    [[ -f "/usr/share/backgrounds/xfce/xfce-verticals.png" ]] && \
        mv "/usr/share/backgrounds/xfce/xfce-verticals.png" "/usr/share/backgrounds/xfce/xfceverticals-old.png"
    
    # Create temporary folder
    temp_folder=$(mktemp -d -p "$HOME")
    cd "$temp_folder" || exit 1
    
    echo -e "\n${R}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${R}║                   📥 DOWNLOADING THEMES                      ║${W}"
    echo -e "${R}╚══════════════════════════════════════════════════════════════╝${W}"
    
    # Download theme files with updated URLs
    base_url="https://github.com/UnQOfficial/ubuntu/releases/download/config"
    
    downloader "fonts.tar.gz" "$base_url/fonts.tar.gz" || exit 1
    downloader "icons.tar.gz" "$base_url/icons.tar.gz" || exit 1
    downloader "wallpaper.tar.gz" "$base_url/wallpaper.tar.gz" || exit 1
    downloader "gtk-themes.tar.gz" "$base_url/gtk-themes.tar.gz" || exit 1
    downloader "ubuntu-settings.tar.gz" "$base_url/ubuntu-settings.tar.gz" || exit 1
    
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                    📦 EXTRACTING FILES                       ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    show_progress 6 "Extracting theme files"
    tar -xzf fonts.tar.gz -C "/usr/local/share/fonts/" &>/dev/null
    tar -xzf icons.tar.gz -C "/usr/share/icons/" &>/dev/null
    tar -xzf wallpaper.tar.gz -C "/usr/share/backgrounds/xfce/" &>/dev/null
    tar -xzf gtk-themes.tar.gz -C "/usr/share/themes/" &>/dev/null
    tar -xzf ubuntu-settings.tar.gz -C "/home/$username/" &>/dev/null
    
    # Cleanup
    rm -rf "$temp_folder"
    
    echo -e "${C}Optimizing system...${W}"
    cleanup_themes
    cleanup_icons
    
    echo -e "${C}Rebuilding font cache...${W}"
    show_progress 3 "Rebuilding fonts"
    fc-cache -fv &>/dev/null
    
    echo -e "${C}Final system update...${W}"
    show_progress 3 "Final optimization"
    apt update &>/dev/null
    apt upgrade -y &>/dev/null
    apt clean &>/dev/null
    apt autoremove -y &>/dev/null
    
    echo -e "${G}✓ System configuration completed${W}\n"
}

# Main Installation Flow
main() {
    check_root
    install_packages
    install_softwares
    configure_system
    installation_note
}

# Error Handler
trap 'echo -e "\n${R}Installation interrupted${W}"; exit 1' INT TERM

# Execute Main Function
main "$@"
