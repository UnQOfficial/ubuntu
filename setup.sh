#!/bin/bash

# Colors for output
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"

# Directories
CURR_DIR=$(realpath "$(dirname "$BASH_SOURCE")")
UBUNTU_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
LOG_FILE="$CURR_DIR/setup.log"

# Logging function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    log "${R}Error: $1${W}"
    exit 1
}

# Banner function
banner() {
    clear
    cat <<- EOF
        ${Y}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  
        ${C}    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ 
        ${G}    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ 
	EOF
    echo -e "${G}     A modded gui version of ubuntu for Termux\n\n${W}"
}

# Package installation function
package() {
    banner
    log "${C}Checking required packages...${W}"
    
    if [ ! -d '/data/data/com.termux/files/home/storage' ]; then
        log "${C}Setting up Storage...${W}"
        termux-setup-storage || handle_error "Failed to set up storage."
    fi

    if [[ $(command -v pulseaudio) && $(command -v proot-distro) ]]; then
        log "${G}Packages already installed.${W}"
    else
        log "${C}Upgrading packages...${W}"
        yes | pkg upgrade || handle_error "Failed to upgrade packages."
        
        packs=(pulseaudio proot-distro)
        for x in "${packs[@]}"; do
            type -p "$x" &>/dev/null || {
                log "${G}Installing package: ${Y}$x${C}${W}"
                yes | pkg install "$x" || handle_error "Failed to install package: $x"
            }
        done
    fi
}

# Distro installation function
distro() {
    log "${C}Checking for Distro...${W}"
    termux-reload-settings
    
    if [[ -d "$UBUNTU_DIR" ]]; then
        log "${G}Distro already installed.${W}"
        return 0
    else
        log "${C}Installing Ubuntu Distro...${W}"
        proot-distro install ubuntu || handle_error "Error installing Distro!"
        termux-reload-settings
    fi
    
    if [[ -d "$UBUNTU_DIR" ]]; then
        log "${G}Installed Successfully!!${W}"
    else
        handle_error "Error installing Distro!"
    fi
}

# Sound setup function
sound() {
    log "${C}Fixing Sound Problem...${W}"
    [ ! -e "$HOME/.sound" ] && touch "$HOME/.sound"
    echo "pacmd load-module module-aaudio-sink" >> "$HOME/.sound"
    echo "pulseaudio --start --exit-idle-time=-1" >> "$HOME/.sound"
    echo "pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> "$HOME/.sound"
}

# Downloader function
downloader() {
    path="$1"
    [ -e "$path" ] && rm -rf "$path"
    log "Downloading $(basename $1)..."
    curl --progress-bar --insecure --fail \
         --retry-connrefused --retry 3 --retry-delay 2 \
         --location --output "${path}" "$2" || {
        handle_error "Failed to download $(basename $1)!"
    }
    echo
}

# VNC setup function
setup_vnc() {
    if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/vncstart" ]]; then
        cp -f "$CURR_DIR/distro/vncstart" "$UBUNTU_DIR/usr/local/bin/vncstart"
    else
        downloader "$CURR_DIR/vncstart" "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/vncstart"
        mv -f "$CURR_DIR/vncstart" "$UBUNTU_DIR/usr/local/bin/vncstart"
    fi

    if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/vncstop" ]]; then
        cp -f "$CURR_DIR/distro/vncstop" "$UBUNTU_DIR/usr/local/bin/vncstop"
    else
        downloader "$CURR_DIR/vncstop" "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/vncstop"
        mv -f "$CURR_DIR/vncstop" "$UBUNTU_DIR/usr/local/bin/vncstop"
    fi
    chmod +x "$UBUNTU_DIR/usr/local/bin/vncstart"
    chmod +x "$UBUNTU_DIR/usr/local/bin/vncstop"
}

# Permission setup function
permission() {
    banner
    log "${C}Setting up Environment...${W}"

    # Setup user.sh
    if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/user.sh" ]]; then
        cp -f "$CURR_DIR/distro/user.sh" "$UBUNTU_DIR/root/user.sh"
    else
        downloader "$CURR_DIR/user.sh" "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/user.sh"
        mv -f "$CURR_DIR/user.sh" "$UBUNTU_DIR/root/user.sh"
    fi
    chmod +x "$UBUNTU_DIR/root/user.sh"

    setup_vnc
    echo "$(getprop persist.sys.timezone)" > "$UBUNTU_DIR/etc/timezone"
    echo "proot-distro login ubuntu" > "$PREFIX/bin/ubuntu"
    chmod +x "$PREFIX/bin/ubuntu"
    termux-reload-settings

    if [[ -e "$PREFIX/bin/ubuntu" ]]; then
        banner
        cat <<- EOF
            ${R} [${W}-${R}]${G} Ubuntu-22.04 (CLI) is now Installed on your Termux
            ${R} [${W}-${R}]${G} Restart your Termux to Prevent Some Issues.
            ${R} [${W}-${R}]${G} Type ${C}ubuntu${G} to run Ubuntu CLI.
            ${R} [${W}-${R}]${G} If you Want to Use UBUNTU in GUI MODE then ,
            ${R} [${W}-${R}]${G} Run ${C}ubuntu${G} first & then type ${C}bash user.sh${W}
            ${R} [${W}-${R}]${G} For additional kali linux tools, type ${C}bash tools.sh${W}
        EOF
        { echo; sleep 2; exit 0; }
    else
        handle_error "Error Installing Distro!"
    fi
}

# Main execution
package
distro
sound
permission
