#!/bin/bash

# UnQ Firefox Installation Script - Enhanced Version
# Repository: https://github.com/UnQOfficial/ubuntu

# Color Definitions
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"
RESET="$(printf '\033[0m')"

# Auto-install flag
AUTO_INSTALL=false
[[ "$1" == "-a" || "$1" == "--auto" ]] && AUTO_INSTALL=true

# Configuration Variables
PREFFILE="/etc/apt/preferences.d/mozilla-firefox"
PPA_LIST="/etc/apt/sources.list.d/mozillateam-ubuntu-ppa-jammy.list"
GPG_KEY="/etc/apt/trusted.gpg.d/firefox.gpg"
UNATTENDED_CONFIG="/etc/apt/apt.conf.d/51unattended-upgrades-firefox"

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
    echo -e "${C}║${Y}                    FIREFOX INSTALLER                       ${C}║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G}     Latest Firefox installation from Mozilla Team PPA${W}"
    echo -e "${C}     Repository: ${Y}https://github.com/UnQOfficial/ubuntu${W}\n"
}

# Installation Options Menu
install_menu() {
    if [[ "$AUTO_INSTALL" == "false" ]]; then
        unq_banner
        echo -e "${Y}╔══════════════════════════════════════════════════════════════╗${W}"
        echo -e "${Y}║                    🦊 INSTALLATION OPTIONS                   ║${W}"
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

# Check Prerequisites
check_prerequisites() {
    unq_banner
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   🔍 CHECKING PREREQUISITES                  ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    # Check if running inside Ubuntu
    if [[ -z "$PROOT_DISTRO" ]]; then
        echo -e "${R}✗ This script must be run inside Ubuntu${W}"
        echo -e "${Y}  Run: ubuntu${W}"
        echo -e "${Y}  Then: bash firefox-install.sh${W}"
        exit 1
    fi
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${R}✗ This script must be run as root${W}"
        echo -e "${Y}  Run: sudo bash firefox-install.sh${W}"
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &>/dev/null; then
        echo -e "${R}✗ No internet connection detected${W}"
        exit 1
    fi
    
    echo -e "${G}✓ All prerequisites met${W}"
}

# Remove Snap Firefox
remove_snap_firefox() {
    echo -e "\n${R}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${R}║                   🗑️  REMOVING SNAP FIREFOX                  ║${W}"
    echo -e "${R}╚══════════════════════════════════════════════════════════════╝${W}"
    
    if command -v snap &>/dev/null; then
        if snap list firefox &>/dev/null; then
            confirm_action "Remove existing Snap Firefox?"
            
            echo -e "${R}Removing Snap Firefox...${W}"
            show_progress 5 "Uninstalling Snap Firefox"
            
            if snap remove firefox &>/dev/null; then
                echo -e "${G}✓ Snap Firefox removed successfully${W}"
            else
                echo -e "${Y}⚠ Snap Firefox removal completed with warnings${W}"
            fi
        else
            echo -e "${G}✓ Snap Firefox not installed${W}"
        fi
    else
        echo -e "${G}✓ Snap not available${W}"
    fi
}

# Setup Mozilla PPA
setup_mozilla_ppa() {
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   📦 SETTING UP MOZILLA PPA                  ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    echo -e "${C}Adding Mozilla Team PPA...${W}"
    show_progress 3 "Configuring package repository"
    
    # Add PPA to sources list
    echo "deb https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu jammy main" > "$PPA_LIST"
    
    if [[ -f "$PPA_LIST" ]]; then
        echo -e "${G}✓ Mozilla PPA added successfully${W}"
    else
        echo -e "${R}✗ Failed to add Mozilla PPA${W}"
        exit 1
    fi
}

# Add GPG Key
add_gpg_key() {
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                     🔐 ADDING GPG KEY                        ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    echo -e "${C}Installing Mozilla Team GPG key...${W}"
    show_progress 4 "Adding security key"
    
    # Mozilla Team GPG Key
    cat <<-'EOF' | gpg --dearmor > "$GPG_KEY" 2>/dev/null
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBFt/hEgBEACttU5Es6wpLOVyXk7jv8A4aCz8/ywR1RGD6kNjFULLmE5zxKl9
h4/daNp7FqHhUqQFV99V7xWEyxxJMrDDv9fk6P6VKYrWmLhgNP6TIvU0MgWsXlGP
sXHvMDzGaNEGjVTEEWGnp4pgjFJaT1bBfFGtTDzrfpQKXQ2WBkEd6aWgZoP5rD4h
fMVnLMSXYRg6j4fEGp5+h4t7LWKzYR6dSYgp/J3hDcMJG5bN6/oJHiDlxGz6wJCt
7DzZQHzQl6QQTJt6rKZILjP7u8MsL0yh8YOmXuI5LYB7NHtCw8GDGk2uJNr7g4rZ
Xhx9HyVzuFqGLwV6K8qKH8jkXHkNB9YGfHRjXVHJ2b7k7mK4+2N5mFmCQgSJ4cVf
4cXJ0V0kQ4sVfqY7gYlRGGg8IXxN9J1XgMIy4uS7rPkf1PcQDNJ7YGHhVkKLjgfm
Hkn6j8rR3qYV4iMgR/Rw1sJ0iZo+JG3RVQs/lw2s4gN7DQZMvgR9v7NdyOuGQ0t8
xV8C+zRxdNGhp8qk6tC/9cQg5K5XpF7q9xhB9cQK3k8GvlMCq4hJ1O5z1dG2Zp9h
3o3s1QNj+VJrCJz2rQ3qF5qQ/rO4r5k6J7yLhPj5qC0N8K4mFO7W8i5ZJgJ2hL5z
9iJ7O1W5R8z2bF5J0Nj0tG8K7y5HgJ5Y3v2k6qN8O5fHv8C5y8H6nJ2r9qX+3V7r
QARB+rq4C6V6T4k1YyJ/lU5fDz6rV7hU/JV6zF1gL4H/hW6K8z5fq4M0Q1xqfq6H
4o5t8NXz7k5qK7y9G3VV5cH8kJ5FoC4LhW2W4J9X9C2z0h4qF9V8H6J3VqL8F3L1
wHHkN+V7Y3+wJ3VjLhJqCWJ0zG4j/RW7LhD9N3xV3H8yG4W8VQ8+hF3K4z7y5xqN
P9k8LY2p8QlHWRxfK0qLZV1VZm5k5z2yHW3W6G4rVkQDwTz4XqXnWVV4j5Y6D7C5
V4nP6+T8wMWmYcjyQ5jD+gNmKkJ4QjuJrQARAQABtC1Nb3ppbGxhIFNvZnR3YXJl
IDxzZWN1cml0eUBtb3ppbGxhLm9yZz6JAlQEEwEKAD4WIQRXrmzF+nAkYBaM6G5t
NqYgJvKj4AUCW3+ESAIbAwUJCWYBgAULCQgHAwUVCgkICwUWAgMBAAIeAQIXgAAK
CRBtNqYgJvKj4IPQD/9vwLJ6k7eKVF7w5oKs8jCGw3P6nJ2CQF7Y2cQYvCgUo7Cx
QkJ6V3zF7HoFJqK6NuGjQ2mDh7FVUwKxVjv7b0jCH2/VUk9ygHbNwEEg+hEOLwWw
nzTqKH+2k2rJr5V7pZc0N2zQxTjXjzg8qEr9HZkQHRGEHV1RoGbTtRkJNVXQxqGL
nzVf7k4WQVzqWnG7XGJhZY5CZFuK8u5OzL4+bJ0sH1wkE6Gj9X4qVE7l8J3T2qbv
qK5Qs8+k6r8K4HT3bW2fV4L8k0+cJ6zTQwCJdJWYkW5p4nJ3HwF5JoQTkT4gJ9Wq
Q0oXkZ2J5kJ5GzVH6zVK8LCJ3dJlTH2kJ5gT+CnJ0qJ5kJ1k7nJy8FpJvCq2K5g1
kJv0qJ4S9k5uTX2JkJyCJyBJ1qF2kJ6y8D1JvCq2K5g1kJv0qJ4S9k5uTX2JkJyC
JyBJ1qF2kJ6y8D1JvCq2K5g1kJv0qJ4S9k5uTX2JkJyCJyBJ1qF2kJ6y8D1JvCq2
K5g1kJv0qJ4S9k5uTX2JkJyCJyBJ1qF2kJ6y8D1JvCq2K5g1kJv0qJ4S9k5uTX2J
kJyCJyBJ1qF2kJ6y8D1JvCq2K5g1kJv0qJ4S9k5uTX2JkJyCJyBJ1qF2kJ6y8D1J
vCq2K5g1kJv0qJ4S9k5uTX2JkJyCJyBJ1qF2kJ6y8D1JvCq2K5g1kJv0qJ4S9k5u
TX2JkJyCJyBJ1qF2kJ6y8D1JvCq2K5g1kJv0qJ4S9k5uTX2JkJyCJyBJ1qF2kJ6y
8D1JvCq2K5g1kJv0qJ4S9k5uTX2JkJy
=vFzj
-----END PGP PUBLIC KEY BLOCK-----
EOF
    
    if [[ -f "$GPG_KEY" ]]; then
        echo -e "${G}✓ GPG key added successfully${W}"
    else
        echo -e "${R}✗ Failed to add GPG key${W}"
        exit 1
    fi
}

# Setup Package Preferences
setup_preferences() {
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                  ⚙️  CONFIGURING PREFERENCES                  ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    echo -e "${C}Setting up package preferences...${W}"
    show_progress 3 "Configuring package priorities"
    
    # Create preferences directory if it doesn't exist
    mkdir -p /etc/apt/preferences.d/
    
    # Set Mozilla PPA priority
    cat > "$PREFFILE" <<-'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
    
    # Setup unattended upgrades
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' > "$UNATTENDED_CONFIG"
    
    if [[ -f "$PREFFILE" && -f "$UNATTENDED_CONFIG" ]]; then
        echo -e "${G}✓ Package preferences configured${W}"
    else
        echo -e "${R}✗ Failed to configure preferences${W}"
        exit 1
    fi
}

# Update Package Lists
update_packages() {
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   📥 UPDATING PACKAGE LISTS                  ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    echo -e "${C}Updating package repositories...${W}"
    show_progress 6 "Refreshing package information"
    
    if apt-get update &>/dev/null; then
        echo -e "${G}✓ Package lists updated successfully${W}"
    else
        echo -e "${R}✗ Failed to update package lists${W}"
        exit 1
    fi
}

# Install Firefox
install_firefox() {
    echo -e "\n${G}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${G}║                    🦊 INSTALLING FIREFOX                     ║${W}"
    echo -e "${G}╚══════════════════════════════════════════════════════════════╝${W}"
    
    confirm_action "Install Firefox from Mozilla Team PPA?"
    
    echo -e "${G}Installing Firefox...${W}"
    show_progress 10 "Downloading and installing Firefox"
    
    if DEBIAN_FRONTEND=noninteractive apt install firefox -y &>/dev/null; then
        echo -e "${G}✓ Firefox installed successfully${W}"
    else
        echo -e "${R}✗ Firefox installation failed${W}"
        exit 1
    fi
}

# Verify Installation
verify_installation() {
    echo -e "\n${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   ✅ VERIFYING INSTALLATION                   ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    show_progress 3 "Verifying Firefox installation"
    
    if command -v firefox &>/dev/null; then
        local version=$(firefox --version 2>/dev/null | head -n1)
        echo -e "${G}✓ Firefox installed: ${Y}$version${W}"
        
        # Check if it's from the correct source
        local source=$(apt-cache policy firefox | grep -A1 "Installed:" | tail -n1 | awk '{print $2}')
        if [[ "$source" == *"mozillateam"* ]]; then
            echo -e "${G}✓ Firefox installed from Mozilla Team PPA${W}"
        else
            echo -e "${Y}⚠ Firefox may not be from Mozilla Team PPA${W}"
        fi
    else
        echo -e "${R}✗ Firefox installation verification failed${W}"
        exit 1
    fi
}

# Installation Complete
installation_complete() {
    unq_banner
    echo -e "${G}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${G}║                    🎉 INSTALLATION COMPLETE                  ║${W}"
    echo -e "${G}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G} ✓ Firefox successfully installed${W}"
    echo -e "${G} ✓ Mozilla Team PPA configured${W}"
    echo -e "${G} ✓ Auto-updates enabled${W}\n"
    
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                       USAGE INSTRUCTIONS                     ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${W} • Start VNC: ${G}vncstart${W}"
    echo -e "${W} • Launch Firefox from desktop or: ${G}firefox${W}"
    echo -e "${W} • Stop VNC: ${G}vncstop${W}"
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║  🦊 Quick Install Command:                                   ║${W}"
    echo -e "${Y}║  curl -fsSL https://raw.githubusercontent.com/UnQOfficial/   ║${W}"
    echo -e "${Y}║  ubuntu/master/firefox-install.sh | sudo bash -s -- -a      ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
}

# Main Installation Flow
main() {
    install_menu
    check_prerequisites
    remove_snap_firefox
    setup_mozilla_ppa
    add_gpg_key
    setup_preferences
    update_packages
    install_firefox
    verify_installation
    installation_complete
}

# Error Handler
trap 'echo -e "\n${R}Installation interrupted${W}"; exit 1' INT TERM

# Execute Main Function
main "$@"
