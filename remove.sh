#!/bin/bash

# UnQ Ubuntu Removal Script - Enhanced Version
# Repository: https://github.com/UnQOfficial/ubuntu

# Color Definitions
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"
RESET="$(printf '\033[0m')"

# Auto-removal flag
AUTO_REMOVE=false
[[ "$1" == "-a" || "$1" == "--auto" ]] && AUTO_REMOVE=true

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
        
        printf "\r${R}["
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
    echo -e "${R}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${R}║${Y}                     UBUNTU UNINSTALLER                     ${R}║${W}"
    echo -e "${R}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G}     Complete removal of Ubuntu installation from Termux${W}"
    echo -e "${C}     Repository: ${Y}https://github.com/UnQOfficial/ubuntu${W}\n"
}

# Removal Options Menu
removal_menu() {
    if [[ "$AUTO_REMOVE" == "false" ]]; then
        unq_banner
        echo -e "${Y}╔══════════════════════════════════════════════════════════════╗${W}"
        echo -e "${Y}║                    🗑️  REMOVAL OPTIONS                       ║${W}"
        echo -e "${Y}╚══════════════════════════════════════════════════════════════╝${W}"
        echo -e "${R} [1]${W} 📋 Standard Removal (Interactive)"
        echo -e "${R} [2]${W} ⚡ Quick Removal (Auto)"
        echo -e "${R} [3]${W} 🔄 Keep Packages (Remove Ubuntu only)"
        echo -e "${G} [4]${W} ❌ Cancel"
        echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
        echo -e -n "${C}║${W} Select option ${G}[1-4]${W}: "
        
        read -r choice
        case $choice in
            1) echo -e "${R}Starting Interactive Removal...${W}\n" ;;
            2) AUTO_REMOVE=true; echo -e "${Y}Starting Quick Removal...${W}\n" ;;
            3) KEEP_PACKAGES=true; echo -e "${C}Starting Ubuntu-only Removal...${W}\n" ;;
            4) echo -e "${G}Removal cancelled.${W}"; exit 0 ;;
            *) echo -e "${R}Invalid option. Starting Interactive Removal...${W}\n" ;;
        esac
    fi
}

# Confirmation Prompt
confirm_action() {
    if [[ "$AUTO_REMOVE" == "false" ]]; then
        echo -e -n "${R}$1 ${Y}[y/N]${W}: "
        read -r response
        [[ ! "$response" =~ ^[Yy]$ ]] && { echo -e "${G}Action cancelled.${W}"; exit 0; }
    fi
}

# Check Installation Status
check_installation() {
    unq_banner
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   🔍 CHECKING INSTALLATION                   ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    local ubuntu_installed=false
    local ubuntu_command=false
    
    # Check if Ubuntu distro exists
    if [[ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]]; then
        ubuntu_installed=true
        echo -e "${R}✓ Ubuntu distro found${W}"
    else
        echo -e "${G}✗ Ubuntu distro not found${W}"
    fi
    
    # Check if ubuntu command exists
    if [[ -e "$PREFIX/bin/ubuntu" ]]; then
        ubuntu_command=true
        echo -e "${R}✓ Ubuntu command found${W}"
    else
        echo -e "${G}✗ Ubuntu command not found${W}"
    fi
    
    # Check sound configuration
    if [[ -e "$HOME/.sound" ]] && grep -q "pulseaudio\|pacmd" "$HOME/.sound"; then
        echo -e "${R}✓ Audio configuration found${W}"
    else
        echo -e "${G}✗ Audio configuration not found${W}"
    fi
    
    if [[ "$ubuntu_installed" == "false" && "$ubuntu_command" == "false" ]]; then
        echo -e "\n${G}╔══════════════════════════════════════════════════════════════╗${W}"
        echo -e "${G}║                   ✓ ALREADY CLEAN                           ║${W}"
        echo -e "${G}╚══════════════════════════════════════════════════════════════╝${W}"
        echo -e "${G}Ubuntu is not installed. Nothing to remove.${W}"
        exit 0
    fi
    
    return 0
}

# Remove Ubuntu Distro
remove_distro() {
    echo -e "\n${R}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${R}║                    🐧 REMOVING UBUNTU                        ║${W}"
    echo -e "${R}╚══════════════════════════════════════════════════════════════╝${W}"
    
    if [[ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]]; then
        confirm_action "Remove Ubuntu distro and all its data?"
        
        echo -e "${R}Removing Ubuntu distro...${W}"
        show_progress 8 "Uninstalling Ubuntu distribution"
        
        if proot-distro remove ubuntu &>/dev/null; then
            echo -e "${G}✓ Ubuntu distro removed successfully${W}"
        else
            echo -e "${Y}⚠ Ubuntu distro removal completed with warnings${W}"
        fi
        
        echo -e "${R}Clearing cache...${W}"
        show_progress 3 "Clearing installation cache"
        proot-distro clear-cache &>/dev/null
        echo -e "${G}✓ Cache cleared${W}"
    else
        echo -e "${G}✓ Ubuntu distro not found (already removed)${W}"
    fi
}

# Remove Ubuntu Command
remove_command() {
    echo -e "\n${R}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${R}║                   🗑️  REMOVING COMMANDS                      ║${W}"
    echo -e "${R}╚══════════════════════════════════════════════════════════════╝${W}"
    
    echo -e "${R}Removing ubuntu command...${W}"
    show_progress 2 "Cleaning up commands"
    
    if [[ -e "$PREFIX/bin/ubuntu" ]]; then
        rm -f "$PREFIX/bin/ubuntu" && echo -e "${G}✓ Ubuntu command removed${W}"
    else
        echo -e "${G}✓ Ubuntu command not found (already removed)${W}"
    fi
}

# Clean Audio Configuration
clean_audio() {
    echo -e "\n${R}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${R}║                   🔊 CLEANING AUDIO CONFIG                   ║${W}"
    echo -e "${R}╚══════════════════════════════════════════════════════════════╝${W}"
    
    echo -e "${R}Cleaning audio configuration...${W}"
    show_progress 3 "Removing audio settings"
    
    if [[ -e "$HOME/.sound" ]]; then
        # Remove specific Ubuntu-related audio lines
        sed -i '/pulseaudio --start --exit-idle-time=-1/d' "$HOME/.sound" 2>/dev/null
        sed -i '/pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1/d' "$HOME/.sound" 2>/dev/null
        sed -i '/pacmd load-module module-aaudio-sink/d' "$HOME/.sound" 2>/dev/null
        
        # Remove empty .sound file if it exists and is empty
        if [[ ! -s "$HOME/.sound" ]]; then
            rm -f "$HOME/.sound"
            echo -e "${G}✓ Empty audio configuration file removed${W}"
        else
            echo -e "${Y}✓ Ubuntu audio settings removed (keeping other settings)${W}"
        fi
    else
        echo -e "${G}✓ Audio configuration not found (already clean)${W}"
    fi
}

# Optional Package Removal
remove_packages() {
    if [[ "$KEEP_PACKAGES" == "true" ]]; then
        echo -e "\n${Y}⚠ Keeping packages as requested${W}"
        return 0
    fi
    
    echo -e "\n${R}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${R}║                   📦 REMOVING PACKAGES                       ║${W}"
    echo -e "${R}╚══════════════════════════════════════════════════════════════╝${W}"
    
    confirm_action "Remove proot-distro and pulseaudio packages?"
    
    packages_to_remove=()
    
    if command -v proot-distro &>/dev/null; then
        packages_to_remove+=("proot-distro")
    fi
    
    if command -v pulseaudio &>/dev/null; then
        packages_to_remove+=("pulseaudio")
    fi
    
    if [[ ${#packages_to_remove[@]} -eq 0 ]]; then
        echo -e "${G}✓ No packages to remove${W}"
        return 0
    fi
    
    local total=${#packages_to_remove[@]}
    local current=0
    
    for package in "${packages_to_remove[@]}"; do
        ((current++))
        echo -e "\n${R}[$current/$total] Removing: ${Y}$package${W}"
        show_progress 4 "Uninstalling $package"
        
        if yes | pkg uninstall "$package" &>/dev/null; then
            echo -e "${G}✓ $package removed successfully${W}"
        else
            echo -e "${Y}⚠ $package removal completed with warnings${W}"
        fi
    done
}

# Cleanup Verification
verify_cleanup() {
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   ✅ VERIFYING CLEANUP                       ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    show_progress 3 "Verifying removal"
    
    local issues_found=false
    
    # Check distro removal
    if [[ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]]; then
        echo -e "${R}⚠ Ubuntu distro directory still exists${W}"
        issues_found=true
    else
        echo -e "${G}✓ Ubuntu distro completely removed${W}"
    fi
    
    # Check command removal
    if [[ -e "$PREFIX/bin/ubuntu" ]]; then
        echo -e "${R}⚠ Ubuntu command still exists${W}"
        issues_found=true
    else
        echo -e "${G}✓ Ubuntu command removed${W}"
    fi
    
    if [[ "$issues_found" == "false" ]]; then
        echo -e "${G}✓ Cleanup verification passed${W}"
    else
        echo -e "${Y}⚠ Some items may require manual cleanup${W}"
    fi
}

# Removal Complete
removal_complete() {
    unq_banner
    echo -e "${G}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${G}║                    ✅ REMOVAL COMPLETE                       ║${W}"
    echo -e "${G}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G} ✓ Ubuntu successfully removed from Termux${W}"
    echo -e "${G} ✓ All components cleaned up${W}"
    echo -e "${Y} ⚠️  You may want to restart Termux${W}\n"
    
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                    REINSTALLATION INFO                       ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${W} • To reinstall: Run ${G}setup.sh${W}"
    echo -e "${W} • Quick install: ${G}bash setup.sh -a${W}"
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║  🗑️ Quick Remove Command:                                    ║${W}"
    echo -e "${R}║  curl -fsSL https://raw.githubusercontent.com/UnQOfficial/   ║${W}"
    echo -e "${R}║  ubuntu/master/remove.sh | bash -s -- -a                    ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
}

# Main Removal Flow
main() {
    # Check if running as root in proot
    if [[ -n "$PROOT_DISTRO" ]]; then
        echo -e "${R}This script should be run from Termux, not inside Ubuntu${W}"
        exit 1
    fi

    removal_menu
    check_installation
    remove_distro
    remove_command
    clean_audio
    
    if [[ "$KEEP_PACKAGES" != "true" ]]; then
        remove_packages
    fi
    
    verify_cleanup
    removal_complete
}

# Error Handler
trap 'echo -e "\n${R}Removal interrupted${W}"; exit 1' INT TERM

# Execute Main Function
main "$@"
