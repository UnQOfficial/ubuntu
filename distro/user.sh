#!/bin/bash

# Color codes
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

# Log file
log_file="/data/data/com.termux/files/home/script_log.txt"
exec > >(tee -a "$log_file") 2>&1

# Banner function
banner() {
    clear
    printf "\033[33m    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  \033[0m\n"
    printf "\033[36m    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ \033[0m\n"
    printf "\033[32m    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ \033[0m\n"
    printf "\033[0m\n"
    printf "     \033[32mA modded GUI version of Ubuntu for Termux\033[0m\n"
    printf "\033[0m\n"
}

# Function to install dependencies
install_dependencies() {
    local dependencies=("sudo" "wget" "apt-utils" "locales-all" "dialog" "tzdata")
    echo -e "\n${R} [${W}-${R}]${C} Installing dependencies...${W}"
    for dep in "${dependencies[@]}"; do
        if ! dpkg -s "$dep" &> /dev/null; then
            if ! apt install -y "$dep"; then
                echo -e "${R} [${W}-${R}]${C} Failed to install $dep. Exiting...${W}"
                exit 1
            fi
        fi
    done
    echo -e "\n${R} [${W}-${R}]${G} Dependencies successfully installed!${W}"
}

# Function to setup tools.sh
setup_tools() {
    echo -e "\n${R} [${W}-${R}]${C} Setting up tools.sh...${W}"
    if [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/tools.sh' ]]; then
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/tools.sh "/home/$user/tools.sh"
    else
        wget -q --show-progress "https://raw.githubusercontent.com/Midohajhouj/modded-ubuntu/refs/heads/master/distro/tools.sh" -O "/home/$user/tools.sh"
    fi
    chmod +x "/home/$user/tools.sh"
    echo -e "\n${R} [${W}-${R}]${G} tools.sh successfully set up!${W}"
}

# Function to setup gui.sh
setup_gui() {
    echo -e "\n${R} [${W}-${R}]${C} Setting up gui.sh...${W}"
    if [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh' ]]; then
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh "/home/$user/gui.sh"
    else
        wget -q --show-progress "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/gui.sh" -O "/home/$user/gui.sh"
    fi
    chmod +x "/home/$user/gui.sh"
    echo -e "\n${R} [${W}-${R}]${G} gui.sh successfully set up!${W}"
}

# Function to create user and set up environment
login() {
    banner
    while true; do
        read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Username [Lowercase] : \e[0m\e[1;96m' user
        if [[ "$user" =~ ^[a-z]+$ ]]; then
            break
        else
            echo -e "${R} [${W}-${R}]${C} Username must be lowercase. Try again.${W}"
        fi
    done

    echo -e "${W}"
    read -sp $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Password : \e[0m\e[1;96m' pass
    echo -e "${W}"

    if ! useradd -m -s $(which bash) "$user"; then
        echo -e "${R} [${W}-${R}]${C} Failed to create user. Exiting...${W}"
        exit 1
    fi

    usermod -aG sudo "$user"
    echo "$user:$pass" | chpasswd
    echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

    # Create the ubuntu command for proot-distro
    echo "proot-distro login --user $user ubuntu --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports" > /data/data/com.termux/files/usr/bin/ubuntu
    chmod +x /data/data/com.termux/files/usr/bin/ubuntu

    setup_tools
    setup_gui

    clear
    echo
    echo -e "\n${R} [${W}-${R}]${G} Restart your Termux & Type ${C}ubuntu${W}"
    echo -e "\n${R} [${W}-${R}]${G} for Kali linux tools Type ${C}sudo bash tools.sh${W}"
    echo -e "\n${R} [${W}-${R}]${G} Skip to graphical user interface with ${C}sudo bash gui.sh${W}"
    echo
}

# Main script execution
banner
install_dependencies
login
