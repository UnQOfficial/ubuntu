#!/bin/bash

# UnQ User Setup Script - Enhanced UX Version
# Repository: https://github.com/UnQOfficial/ubuntu

# Color Definitions
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"
RESET="$(printf '\033[0m')"

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

# Enhanced UnQ Banner
banner() {
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
    echo -e "${C}║${Y}                      USER SETUP                            ${C}║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G}     A modded GUI version of Ubuntu for Termux${W}"
    echo -e "${C}     Repository: ${Y}https://github.com/UnQOfficial/ubuntu${W}\n"
}

# Enhanced Sudo Installation
sudo() {
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   📦 INSTALLING PACKAGES                     ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    echo -e "${R} [${W}-${R}]${C} Installing Sudo and dependencies...${W}"
    show_progress 4 "Updating package repositories"
    apt update -y &>/dev/null
    
    show_progress 6 "Installing sudo and essential packages"
    apt install sudo -y &>/dev/null
    apt install wget apt-utils locales-all dialog tzdata -y &>/dev/null
    
    echo -e "${R} [${W}-${R}]${G} ✓ Sudo successfully installed!${W}\n"
}

# Enhanced Login Setup
login() {
    banner
    
    echo -e "${Y}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${Y}║                    👤 USER ACCOUNT SETUP                     ║${W}"
    echo -e "${Y}╚══════════════════════════════════════════════════════════════╝${W}"
    
    # Username input with validation
    while true; do
        read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Username [Lowercase]: \e[0m\e[1;96m' user
        echo -e "${W}"
        
        if [[ -n "$user" && "$user" =~ ^[a-z0-9._-]+$ ]]; then
            echo -e "${G}✓ Username '${user}' is valid${W}"
            break
        else
            echo -e "${R}✗ Invalid username. Use lowercase letters, numbers, dots, or dashes only.${W}"
            echo
        fi
    done
    
    # Password input with masking
    while true; do
        read -s -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Password: \e[0m\e[1;96m' pass
        echo -e "${W}"
        
        if [[ -n "$pass" ]]; then
            echo -e "${G}✓ Password set successfully${W}"
            break
        else
            echo -e "${R}✗ Password cannot be empty${W}"
            echo
        fi
    done
    
    echo
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                   ⚙️  CONFIGURING USER                       ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    
    show_progress 3 "Creating user account"
    useradd -m -s $(which bash) ${user}
    usermod -aG sudo ${user}
    echo "${user}:${pass}" | chpasswd
    echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
    
    show_progress 2 "Setting up Ubuntu login command"
    echo "proot-distro login --user $user ubuntu --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports" > /data/data/com.termux/files/usr/bin/ubuntu
    
    echo -e "${C}Downloading GUI setup script...${W}"
    if [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh' ]]; then
        echo -e "${G}✓ Using local GUI script${W}"
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    else
        show_progress 4 "Downloading GUI script from repository"
        wget -q --show-progress https://raw.githubusercontent.com/UnQOfficial/ubuntu/master/distro/gui.sh
        mv gui.sh /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    fi
    
    clear
    banner
    
    echo -e "${G}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${G}║                    🎉 SETUP COMPLETE                         ║${W}"
    echo -e "${G}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${G} ✓ User '${user}' created successfully${W}"
    echo -e "${G} ✓ Sudo privileges configured${W}"
    echo -e "${G} ✓ GUI script installed${W}\n"
    
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                      📋 NEXT STEPS                           ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo -e "${R} [${W}1${R}]${G} Restart your Termux app${W}"
    echo -e "${R} [${W}2${R}]${G} Type: ${C}ubuntu${W}"
    echo -e "${R} [${W}3${R}]${G} Then type: ${C}sudo bash gui.sh${W}"
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${W}"
    echo -e "${C}║                        ENJOY! 🚀                            ║${W}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${W}"
    echo
}

# Execute functions
banner
sudo
login
