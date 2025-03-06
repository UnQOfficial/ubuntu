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
    printf "     \033[32mA modded GUI version of Ubuntu for Termux\033[0m\n"
    printf "\033[0m\n"
}

install_sudo() {
    echo -e "\n${R} [${W}-${R}]${C} Installing Sudo..."${W}
    apt update -y
    apt install sudo -y
    apt install wget apt-utils locales-all dialog tzdata -y
    echo -e "\n${R} [${W}-${R}]${G} Sudo Successfully Installed!${W}"
}

login() {
    banner
    read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Username [Lowercase] : \e[0m\e[1;96m' user
    echo -e "${W}"
    read -sp $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Password : \e[0m\e[1;96m' pass
    echo -e "${W}"
    useradd -m -s $(which bash) ${user}
    usermod -aG sudo ${user}
    echo "${user}:${pass}" | chpasswd
    echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

    # Create the ubuntu command for proot-distro
    echo "proot-distro login --user $user ubuntu --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports" > /data/data/com.termux/files/usr/bin/ubuntu
    chmod +x /data/data/com.termux/files/usr/bin/ubuntu

    
    # Setup tools.sh (place it in the user's directory)
if [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/tools.sh' ]]; then
    cp /data/data/com.termux/files/home/modded-ubuntu/distro/tools.sh "/home/$user/tools.sh"
    chmod +x "/home/$user/tools.sh"
else
    wget -q --show-progress "https://raw.githubusercontent.com/Midohajhouj/modded-ubuntu/refs/heads/master/distro/tools.sh" -O "/home/$user/tools.sh"
    chmod +x "/home/$user/tools.sh"
fi

# Download and set up the GUI script
if [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh' ]]; then
    cp /data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh "/home/$user/gui.sh"
    chmod +x "/home/$user/gui.sh"
else
    wget -q --show-progress "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/gui.sh" -O "/home/$user/gui.sh"
    chmod +x "/home/$user/gui.sh"
fi


    clear
    echo
    echo -e "\n${R} [${W}-${R}]${G} Restart your Termux & Type ${C}ubuntu${W}"
    echo -e "\n${R} [${W}-${R}]${G} Then Type ${C}sudo bash gui.sh${W}"
    echo
}

# Main script execution
banner
install_sudo
login
