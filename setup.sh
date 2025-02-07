#!/bin/bash

# Colors
R="\033[1;31m"
G="\033[1;32m"
Y="\033[1;33m"
C="\033[1;36m"
W="\033[1;37m"

CURR_DIR=$(realpath "$(dirname "$BASH_SOURCE")")
UBUNTU_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

# Banner Function
banner() {
	clear
	cat <<- EOF
		${Y}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  
		${C}    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ 
		${G}    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ 

	EOF
	echo -e "${G}     A modded GUI version of Ubuntu for Termux\n\n${W}"
}

# Install Required Packages
install_packages() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages...${W}"
	
	if [ ! -d "$HOME/storage" ]; then
		echo -e "${R} [${W}-${R}]${C} Setting up storage...${W}"
		termux-setup-storage
	fi

	if command -v pulseaudio >/dev/null && command -v proot-distro >/dev/null; then
		echo -e "${R} [${W}-${R}]${G} All packages are already installed.${W}"
	else
		pkg upgrade -y
		for pkg in pulseaudio proot-distro; do
			if ! command -v "$pkg" >/dev/null; then
				echo -e "${R} [${W}-${R}]${G} Installing: ${Y}$pkg${W}"
				pkg install -y "$pkg"
			fi
		done
	fi
}

# Install Ubuntu Distro
install_distro() {
	echo -e "${R} [${W}-${R}]${C} Checking for Ubuntu distro...${W}"
	termux-reload-settings

	if [ -d "$UBUNTU_DIR" ]; then
		echo -e "${R} [${W}-${R}]${G} Ubuntu distro is already installed.${W}"
	else
		proot-distro install ubuntu
		termux-reload-settings
		[ -d "$UBUNTU_DIR" ] && echo -e "${R} [${W}-${R}]${G} Ubuntu installed successfully!${W}" || {
			echo -e "${R} [${W}-${R}]${C} Failed to install Ubuntu.${W}"
			exit 1
		}
	fi
}

# Configure Sound
configure_sound() {
	echo -e "${R} [${W}-${R}]${C} Configuring sound settings...${W}"
	SOUND_FILE="$HOME/.sound"

	[ -e "$SOUND_FILE" ] || touch "$SOUND_FILE"

	cat <<- EOF > "$SOUND_FILE"
		pacmd load-module module-aaudio-sink
		pulseaudio --start --exit-idle-time=-1
		pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
	EOF
}

# Download Helper Function
download_file() {
	local path="$1"
	local url="$2"
	[ -e "$path" ] && rm -f "$path"
	echo -e "${R} [${W}-${R}]${C} Downloading: $(basename "$path")${W}"
	curl --progress-bar --insecure --fail \
		 --retry 3 --retry-connrefused --retry-delay 2 \
		 --location --output "$path" "$url"
}

# Set Up VNC
setup_vnc() {
	for file in vncstart vncstop; do
		if [ -f "$CURR_DIR/distro/$file" ]; then
			cp -f "$CURR_DIR/distro/$file" "$UBUNTU_DIR/usr/local/bin/$file"
		else
			download_file "$CURR_DIR/$file" "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/$file"
			mv -f "$CURR_DIR/$file" "$UBUNTU_DIR/usr/local/bin/$file"
		fi
		chmod +x "$UBUNTU_DIR/usr/local/bin/$file"
	done
}

# Set Up Environment
setup_environment() {
	banner
	echo -e "${R} [${W}-${R}]${C} Setting up environment...${W}"

	if [ -f "$CURR_DIR/distro/user.sh" ]; then
		cp -f "$CURR_DIR/distro/user.sh" "$UBUNTU_DIR/root/user.sh"
	else
		download_file "$CURR_DIR/user.sh" "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/user.sh"
		mv -f "$CURR_DIR/user.sh" "$UBUNTU_DIR/root/user.sh"
	fi
	chmod +x "$UBUNTU_DIR/root/user.sh"

	setup_vnc
	echo "$(getprop persist.sys.timezone)" > "$UBUNTU_DIR/etc/timezone"
	echo "proot-distro login ubuntu" > "$PREFIX/bin/ubuntu"
	chmod +x "$PREFIX/bin/ubuntu"
	termux-reload-settings

	if [ -x "$PREFIX/bin/ubuntu" ]; then
		banner
		cat <<- EOF
			${R} [${W}-${R}]${G} Ubuntu-22.04 (CLI) is now installed in Termux!
			${R} [${W}-${R}]${G} Restart Termux to avoid potential issues.
			${R} [${W}-${R}]${G} Run ${C}ubuntu${G} to start Ubuntu CLI.
			${R} [${W}-${R}]${G} To use GUI mode, run ${C}ubuntu${G} first and execute ${C}bash user.sh${W}
		EOF
	else
		echo -e "${R} [${W}-${R}]${C} Failed to set up Ubuntu.${W}"
		exit 1
	fi
}

# Execute Functions
install_packages
install_distro
configure_sound
setup_environment