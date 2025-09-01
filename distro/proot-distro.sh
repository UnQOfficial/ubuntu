#!/usr/bin/env bash

# UnQ Proot-Distro Manager - Enhanced Version
# Repository: https://github.com/UnQOfficial/ubuntu
# Original Source: https://github.com/termux/proot-distro

PROGRAM_VERSION="3.5.0-UnQ"

set -e -u

PROGRAM_NAME="proot-distro"
DISTRO_PLUGINS_DIR="@TERMUX_PREFIX@/etc/proot-distro"
RUNTIME_DIR="@TERMUX_PREFIX@/var/lib/proot-distro"
DOWNLOAD_CACHE_DIR="${RUNTIME_DIR}/dlcache"
INSTALLED_ROOTFS_DIR="${RUNTIME_DIR}/installed-rootfs"

# Color Definitions
if [ -n "$(command -v tput)" ] && [ $(tput colors) -ge 8 ] && [ -z "${PROOT_DISTRO_FORCE_NO_COLORS-}" ]; then
    RST="$(tput sgr0)"
    RED="${RST}$(tput setaf 1)"
    BRED="${RST}$(tput bold)$(tput setaf 1)"
    GREEN="${RST}$(tput setaf 2)"
    YELLOW="${RST}$(tput setaf 3)"
    BYELLOW="${RST}$(tput bold)$(tput setaf 3)"
    BLUE="${RST}$(tput setaf 4)"
    CYAN="${RST}$(tput setaf 6)"
    BCYAN="${RST}$(tput bold)$(tput setaf 6)"
    ICYAN="${RST}$(tput sitm)$(tput setaf 6)"
    W="$(tput bold)$(tput setaf 7)"
else
    RED="" BRED="" GREEN="" YELLOW="" BYELLOW="" BLUE="" CYAN="" BCYAN="" ICYAN="" RST="" W=""
fi

unset LD_PRELOAD

# Progress Bar Function
show_progress() {
    local duration=$1
    local message=$2
    local progress=0
    local bar_length=30
    
    echo -e "${CYAN}${message}${RST}" >&2
    while [ $progress -le 100 ]; do
        local filled=$((progress * bar_length / 100))
        local empty=$((bar_length - filled))
        
        printf "\r${GREEN}[" >&2
        printf "%*s" $filled | tr ' ' '█' >&2
        printf "%*s" $empty | tr ' ' '░' >&2
        printf "] ${YELLOW}%d%%${RST}" $progress >&2
        
        sleep $(echo "scale=2; $duration/100" | bc -l 2>/dev/null || echo "0.05")
        ((progress += 2))
    done
    echo >&2
}

# UnQ Banner
unq_banner() {
    clear
    cat <<- 'EOF' >&2
	
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
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RST}" >&2
    echo -e "${CYAN}║${YELLOW}                   PROOT-DISTRO MANAGER                     ${CYAN}║${RST}" >&2
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RST}" >&2
    echo -e "${GREEN}     Professional Linux distribution management for Termux${RST}" >&2
    echo -e "${CYAN}     Repository: ${YELLOW}https://github.com/UnQOfficial/ubuntu${RST}" >&2
    echo >&2
}

# Enhanced Message Function
msg() {
    echo -e "$@" >&2
}

# Anti-Root Protection
if [ "$(id -u)" = "0" ]; then
    unq_banner
    msg "${BRED}Error: '${YELLOW}${PROGRAM_NAME}${BRED}' should not be used as root.${RST}"
    msg "${CYAN}Run as regular user inside Termux environment.${RST}"
    exit 1
fi

# Distribution Installation Check
is_distro_installed() {
    [ -e "${INSTALLED_ROOTFS_DIR}/${1}/bin" ]
}

# Enhanced Installation Function
command_install() {
    local distro_name override_alias distro_plugin_script
    
    while (($# >= 1)); do
        case "$1" in
            --) shift 1; break ;;
            --help) command_install_help; return 0 ;;
            --override-alias)
                if [ $# -ge 2 ]; then
                    shift 1
                    if [ -z "$1" ]; then
                        msg "${BRED}Error: argument to '${YELLOW}--override-alias${BRED}' should not be empty.${RST}"
                        return 1
                    fi
                    if ! grep -qP '^[a-z0-9._+][a-z0-9._+-]+$' <<< "$1"; then
                        msg "${BRED}Error: invalid alias format.${RST}"
                        return 1
                    fi
                    override_alias="$1"
                else
                    msg "${BRED}Error: option '${YELLOW}$1${BRED}' requires an argument.${RST}"
                    return 1
                fi
                ;;
            -*) msg "${BRED}Error: unknown option '${YELLOW}${1}${BRED}'.${RST}"; return 1 ;;
            *)
                if [ -z "${distro_name-}" ]; then
                    distro_name="$1"
                else
                    msg "${BRED}Error: distribution already set as '${YELLOW}${distro_name}${BRED}'.${RST}"
                    return 1
                fi
                ;;
        esac
        shift 1
    done

    if [ -z "${distro_name-}" ]; then
        msg "${BRED}Error: distribution alias not specified.${RST}"
        command_install_help
        return 1
    fi

    if [ -z "${SUPPORTED_DISTRIBUTIONS["$distro_name"]+x}" ]; then
        msg "${BRED}Error: unknown distribution '${YELLOW}${distro_name}${BRED}'.${RST}"
        msg "${CYAN}Run '${GREEN}${PROGRAM_NAME} list${CYAN}' to see supported distributions.${RST}"
        return 1
    fi

    if [ -n "${override_alias-}" ]; then
        if [ ! -e "${DISTRO_PLUGINS_DIR}/${override_alias}.sh" ] && [ ! -e "${DISTRO_PLUGINS_DIR}/${override_alias}.override.sh" ]; then
            distro_plugin_script="${DISTRO_PLUGINS_DIR}/${override_alias}.override.sh"
            cp "${DISTRO_PLUGINS_DIR}/${distro_name}.sh" "${distro_plugin_script}"
            sed -i "s/^\(DISTRO_NAME=\)\(.*\)\$/\1\"${SUPPORTED_DISTRIBUTIONS["$distro_name"]} - ${override_alias}\"/g" "${distro_plugin_script}"
            SUPPORTED_DISTRIBUTIONS["${override_alias}"]="${SUPPORTED_DISTRIBUTIONS["$distro_name"]}"
            distro_name="${override_alias}"
        else
            msg "${BRED}Error: cannot use '${YELLOW}${override_alias}${BRED}' as alias override.${RST}"
            return 1
        fi
    else
        distro_plugin_script="${DISTRO_PLUGINS_DIR}/${distro_name}.sh"
        [ ! -f "${distro_plugin_script}" ] && distro_plugin_script="${DISTRO_PLUGINS_DIR}/${distro_name}.override.sh"
    fi

    if is_distro_installed "$distro_name"; then
        msg "${BRED}Error: distribution '${YELLOW}${distro_name}${BRED}' already installed.${RST}"
        msg "${CYAN}Login: ${GREEN}${PROGRAM_NAME} login ${distro_name}${RST}"
        msg "${CYAN}Reinstall: ${GREEN}${PROGRAM_NAME} reset ${distro_name}${RST}"
        msg "${CYAN}Uninstall: ${GREEN}${PROGRAM_NAME} remove ${distro_name}${RST}"
        return 1
    fi

    if [ -f "${distro_plugin_script}" ]; then
        unq_banner
        
        if ! grep -q 'tar (GNU tar)' <(tar --version 2>/dev/null | head -n 1); then
            msg "${BRED}Warning: Non-GNU tar detected. You may experience issues.${RST}"
        fi

        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RST}" >&2
        echo -e "${CYAN}║                    📦 INSTALLING DISTRIBUTION                ║${RST}" >&2
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RST}" >&2
        msg "${BLUE}[${GREEN}*${BLUE}] ${CYAN}Installing ${YELLOW}${SUPPORTED_DISTRIBUTIONS["$distro_name"]}${CYAN}...${RST}"

        if [ ! -d "${INSTALLED_ROOTFS_DIR}/${distro_name}" ]; then
            show_progress 2 "Creating installation directory"
            mkdir -m 755 -p "${INSTALLED_ROOTFS_DIR}/${distro_name}"
        fi

        export PROOT_L2S_DIR="${INSTALLED_ROOTFS_DIR}/${distro_name}/.l2s"
        [ ! -d "$PROOT_L2S_DIR" ] && mkdir -p "$PROOT_L2S_DIR"

        # Initialize tarball arrays
        TARBALL_URL["aarch64"]="" TARBALL_URL["arm"]="" TARBALL_URL["i686"]="" TARBALL_URL["x86_64"]=""
        TARBALL_SHA256["aarch64"]="" TARBALL_SHA256["arm"]="" TARBALL_SHA256["i686"]="" TARBALL_SHA256["x86_64"]=""
        TARBALL_STRIP_OPT=1

        source "${distro_plugin_script}"

        if [ -z "${TARBALL_URL["$DISTRO_ARCH"]}" ]; then
            msg "${BLUE}[${RED}!${BLUE}] ${CYAN}Download URL not defined for CPU architecture '$DISTRO_ARCH'.${RST}"
            return 1
        fi

        if ! grep -qP '^[0-9a-fA-F]+$' <<< "${TARBALL_SHA256["$DISTRO_ARCH"]}"; then
            msg "${BRED}Error: malformed SHA-256 from ${distro_plugin_script}${RST}"
            return 1
        fi

        [ ! -d "$DOWNLOAD_CACHE_DIR" ] && mkdir -p "$DOWNLOAD_CACHE_DIR"

        local tarball_name
        tarball_name=$(basename "${TARBALL_URL["$DISTRO_ARCH"]}")

        if [ ! -f "${DOWNLOAD_CACHE_DIR}/${tarball_name}" ]; then
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RST}" >&2
            echo -e "${CYAN}║                     ⬇️  DOWNLOADING ROOTFS                   ║${RST}" >&2
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RST}" >&2
            show_progress 8 "Downloading rootfs tarball"

            rm -f "${DOWNLOAD_CACHE_DIR}/${tarball_name}.tmp"
            if ! curl --fail --retry 5 --retry-connrefused --retry-delay 5 --location \
                --output "${DOWNLOAD_CACHE_DIR}/${tarball_name}.tmp" "${TARBALL_URL["$DISTRO_ARCH"]}"; then
                msg "${BLUE}[${RED}!${BLUE}] ${CYAN}Download failed. Check network connection.${RST}"
                rm -f "${DOWNLOAD_CACHE_DIR}/${tarball_name}.tmp"
                return 1
            fi
            mv "${DOWNLOAD_CACHE_DIR}/${tarball_name}.tmp" "${DOWNLOAD_CACHE_DIR}/${tarball_name}"
        else
            msg "${BLUE}[${GREEN}*${BLUE}] ${CYAN}Using cached rootfs tarball${RST}"
        fi

        if [ -n "${TARBALL_SHA256["$DISTRO_ARCH"]}" ]; then
            show_progress 3 "Verifying tarball integrity"
            local actual_sha256
            actual_sha256=$(sha256sum "${DOWNLOAD_CACHE_DIR}/${tarball_name}" | awk '{ print $1}')
            if [ "${TARBALL_SHA256["$DISTRO_ARCH"]}" != "${actual_sha256}" ]; then
                msg "${BLUE}[${RED}!${BLUE}] ${CYAN}Integrity check failed. Retry installation.${RST}"
                rm -f "${DOWNLOAD_CACHE_DIR}/${tarball_name}"
                return 1
            fi
        else
            msg "${BLUE}[${RED}!${BLUE}] ${CYAN}Integrity checking disabled.${RST}"
        fi

        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${RST}" >&2
        echo -e "${GREEN}║                     📁 EXTRACTING ROOTFS                    ║${RST}" >&2
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${RST}" >&2
        show_progress 12 "Extracting rootfs archive"

        set +e
        proot --link2symlink \
            tar -C "${INSTALLED_ROOTFS_DIR}/${distro_name}" --warning=no-unknown-keyword \
            --delay-directory-restore --preserve-permissions --strip="$TARBALL_STRIP_OPT" \
            -xf "${DOWNLOAD_CACHE_DIR}/${tarball_name}" --exclude='dev' |& grep -v "/linkerconfig/" >&2
        set -e

        # Write environment configuration
        local profile_script
        if [ -d "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/profile.d" ]; then
            profile_script="${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/profile.d/termux-proot.sh"
        else
            chmod u+rw "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/profile" >/dev/null 2>&1 || true
            profile_script="${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/profile"
        fi

        show_progress 4 "Configuring environment"
        cat << EOF >> "$profile_script"
export ANDROID_ART_ROOT=${ANDROID_ART_ROOT-}
export ANDROID_DATA=${ANDROID_DATA-}
export ANDROID_I18N_ROOT=${ANDROID_I18N_ROOT-}
export ANDROID_ROOT=${ANDROID_ROOT-}
export ANDROID_RUNTIME_ROOT=${ANDROID_RUNTIME_ROOT-}
export ANDROID_TZDATA_ROOT=${ANDROID_TZDATA_ROOT-}
export BOOTCLASSPATH=${BOOTCLASSPATH-}
export COLORTERM=${COLORTERM-}
export DEX2OATBOOTCLASSPATH=${DEX2OATBOOTCLASSPATH-}
export EXTERNAL_STORAGE=${EXTERNAL_STORAGE-}
[ -z "\$LANG" ] && export LANG=C.UTF-8
export PATH=\${PATH}:@TERMUX_PREFIX@/bin:/system/bin:/system/xbin
export TERM=${TERM-xterm-256color}
export TMPDIR=/tmp
export PULSE_SERVER=127.0.0.1
export MOZ_FAKE_NO_SANDBOX=1
EOF

        # Configure DNS
        show_progress 2 "Configuring DNS"
        rm -f "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/resolv.conf"
        cat << EOF > "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/resolv.conf"
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

        # Configure hosts
        chmod u+rw "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/hosts" >/dev/null 2>&1 || true
        cat << EOF > "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/hosts"
127.0.0.1 localhost.localdomain localhost
::1 localhost.localdomain localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF

        # Register Android UIDs/GIDs
        show_progress 3 "Registering Android UIDs/GIDs"
        chmod u+rw "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/passwd" \
            "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/shadow" \
            "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/group" \
            "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/gshadow" >/dev/null 2>&1 || true

        echo "aid_$(id -un):x:$(id -u):$(id -g):Android user:/:/sbin/nologin" >> \
            "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/passwd"
        echo "aid_$(id -un):*:18446:0:99999:7:::" >> \
            "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/shadow"

        local group_name group_id
        while read -r group_name group_id; do
            echo "aid_${group_name}:x:${group_id}:root,aid_$(id -un)" >> \
                "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/group"
            if [ -f "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/gshadow" ]; then
                echo "aid_${group_name}:*::root,aid_$(id -un)" >> \
                    "${INSTALLED_ROOTFS_DIR}/${distro_name}/etc/gshadow"
            fi
        done < <(paste <(id -Gn | tr ' ' '\n') <(id -G | tr ' ' '\n'))

        setup_fake_proc

        # Run distribution-specific setup
        if declare -f -F distro_setup >/dev/null 2>&1; then
            show_progress 5 "Running distribution-specific setup"
            (cd "${INSTALLED_ROOTFS_DIR}/${distro_name}"; distro_setup)
        fi

        unq_banner
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${RST}" >&2
        echo -e "${GREEN}║                    🎉 INSTALLATION COMPLETE                  ║${RST}" >&2
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${RST}" >&2
        msg "${GREEN}✓ ${YELLOW}${SUPPORTED_DISTRIBUTIONS["$distro_name"]}${GREEN} installed successfully${RST}"
        msg "${CYAN}Login: ${GREEN}$PROGRAM_NAME login $distro_name${RST}"
        return 0
    else
        msg "${BLUE}[${RED}!${BLUE}] ${CYAN}Cannot find plugin: '${distro_plugin_script}'${RST}"
        return 1
    fi
}

# Enhanced Removal Function
command_remove() {
    local distro_name
    if [ $# -ge 1 ]; then
        case "$1" in
            -h|--help) command_remove_help; return 0 ;;
            *) distro_name="$1" ;;
        esac
    else
        msg "${BRED}Error: distribution alias not specified.${RST}"
        return 1
    fi

    if [ -z "${SUPPORTED_DISTRIBUTIONS["$distro_name"]+x}" ]; then
        msg "${BRED}Error: unknown distribution '${YELLOW}${distro_name}${BRED}'.${RST}"
        return 1
    fi

    if [ ! -d "${INSTALLED_ROOTFS_DIR}/${distro_name}" ]; then
        msg "${BRED}Error: distribution '${YELLOW}${distro_name}${BRED}' not installed.${RST}"
        return 1
    fi

    unq_banner
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${RST}" >&2
    echo -e "${RED}║                    🗑️  REMOVING DISTRIBUTION                  ║${RST}" >&2
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${RST}" >&2

    if [ "${CMD_REMOVE_REQUESTED_RESET-false}" = "false" ] && [ -e "${DISTRO_PLUGINS_DIR}/${distro_name}.override.sh" ]; then
        msg "${BLUE}[${GREEN}*${BLUE}] ${CYAN}Removing override plugin...${RST}"
        rm -f "${DISTRO_PLUGINS_DIR}/${distro_name}.override.sh"
    fi

    show_progress 8 "Removing ${SUPPORTED_DISTRIBUTIONS["$distro_name"]}"
    chmod u+rwx -R "${INSTALLED_ROOTFS_DIR}/${distro_name}" >/dev/null 2>&1 || true
    
    if rm -rf "${INSTALLED_ROOTFS_DIR:?}/${distro_name:?}"; then
        msg "${GREEN}✓ Distribution removed successfully${RST}"
        return 0
    else
        msg "${BLUE}[${RED}!${BLUE}] ${CYAN}Removal completed with errors.${RST}"
        return 1
    fi
}

# Enhanced Login Function (simplified key parts)
command_login() {
    local isolated_environment=false use_termux_home=false no_link2symlink=false
    local no_sysvipc=false no_kill_on_exit=false fix_low_ports=true make_host_tmp_shared=true
    local distro_name="" login_user="root" kernel_release="5.4.0-pro"
    local -a custom_fs_bindings need_qemu=false

    # Parse arguments (simplified)
    while (($# >= 1)); do
        case "$1" in
            --) shift 1; break ;;
            --help) command_login_help; return 0 ;;
            --isolated) isolated_environment=true ;;
            --termux-home) use_termux_home=true ;;
            --user) shift 1; login_user="$1" ;;
            --kernel) shift 1; kernel_release="$1" ;;
            --bind) shift 1; custom_fs_bindings+=("$1") ;;
            --no-link2symlink) no_link2symlink=true ;;
            --no-sysvipc) no_sysvipc=true ;;
            --no-kill-on-exit) no_kill_on_exit=true ;;
            --fix-low-ports) fix_low_ports=true ;;
            --shared-tmp) make_host_tmp_shared=true ;;
            -*) msg "${BRED}Error: unknown option '${YELLOW}${1}${BRED}'.${RST}"; return 1 ;;
            *) 
                if [ -z "$distro_name" ]; then
                    distro_name="$1"
                else
                    msg "${BRED}Error: distribution already set as '${YELLOW}${distro_name}${BRED}'.${RST}"
                    return 1
                fi
                ;;
        esac
        shift 1
    done

    if [ -z "$distro_name" ]; then
        msg "${BRED}Error: distribution not specified.${RST}"
        return 1
    fi

    if is_distro_installed "$distro_name"; then
        [ -d "${INSTALLED_ROOTFS_DIR}/${distro_name}/.l2s" ] && export PROOT_L2S_DIR="${INSTALLED_ROOTFS_DIR}/${distro_name}/.l2s"

        # Setup command execution
        if [ $# -ge 1 ]; then
            local -a shell_command_args
            for i in "$@"; do
                shell_command_args+=("'$i'")
            done
            if stat "${INSTALLED_ROOTFS_DIR}/${distro_name}/bin/su" >/dev/null 2>&1; then
                set -- "/bin/su" "-l" "$login_user" "-c" "${shell_command_args[*]}"
            else
                [ -x "${INSTALLED_ROOTFS_DIR}/${distro_name}/bin/bash" ] && set -- "/bin/bash" "-l" "-c" "${shell_command_args[*]}" || set -- "/bin/sh" "-l" "-c" "${shell_command_args[*]}"
            fi
        else
            if stat "${INSTALLED_ROOTFS_DIR}/${distro_name}/bin/su" >/dev/null 2>&1; then
                set -- "/bin/su" "-l" "$login_user"
            else
                [ -x "${INSTALLED_ROOTFS_DIR}/${distro_name}/bin/bash" ] && set -- "/bin/bash" "-l" || set -- "/bin/sh" "-l"
            fi
        fi

        set -- "/usr/bin/env" "-i" "HOME=/root" "LANG=C.UTF-8" "TERM=${TERM-xterm-256color}" "$@"
        set -- "--rootfs=${INSTALLED_ROOTFS_DIR}/${distro_name}" "$@"

        # Setup proot arguments
        ! $no_kill_on_exit && set -- "--kill-on-exit" "$@"
        ! $no_link2symlink && set -- "--link2symlink" "$@"
        ! $no_sysvipc && set -- "--sysvipc" "$@"
        set -- "--kernel-release=$kernel_release" "$@"
        set -- "-L" "$@"
        set -- "--cwd=/root" "$@"
        set -- "--root-id" "$@"

        # Core filesystem bindings
        set -- "--bind=/dev" "$@"
        set -- "--bind=/dev/urandom:/dev/random" "$@"
        set -- "--bind=/proc" "$@"
        set -- "--bind=/proc/self/fd:/dev/fd" "$@"
        set -- "--bind=/proc/self/fd/0:/dev/stdin" "$@"
        set -- "--bind=/proc/self/fd/1:/dev/stdout" "$@"
        set -- "--bind=/proc/self/fd/2:/dev/stderr" "$@"
        set -- "--bind=/sys" "$@"

        setup_fake_proc

        # Fake proc entries if needed
        ! cat /proc/loadavg >/dev/null 2>&1 && set -- "--bind=${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.loadavg:/proc/loadavg" "$@"
        ! cat /proc/stat >/dev/null 2>&1 && set -- "--bind=${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.stat:/proc/stat" "$@"
        ! cat /proc/uptime >/dev/null 2>&1 && set -- "--bind=${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.uptime:/proc/uptime" "$@"
        ! cat /proc/version >/dev/null 2>&1 && set -- "--bind=${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.version:/proc/version" "$@"
        ! cat /proc/vmstat >/dev/null 2>&1 && set -- "--bind=${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.vmstat:/proc/vmstat" "$@"

        # Bind tmp
        [ ! -d "${INSTALLED_ROOTFS_DIR}/${distro_name}/tmp" ] && mkdir -p "${INSTALLED_ROOTFS_DIR}/${distro_name}/tmp"
        set -- "--bind=${INSTALLED_ROOTFS_DIR}/${distro_name}/tmp:/dev/shm" "$@"

        # Additional bindings based on options
        if ! $isolated_environment; then
            set -- "--bind=/data/dalvik-cache" "$@"
            set -- "--bind=/data/data/@TERMUX_APP_PACKAGE@/cache" "$@"
            [ -d "/data/data/@TERMUX_APP_PACKAGE@/files/apps" ] && set -- "--bind=/data/data/@TERMUX_APP_PACKAGE@/files/apps" "$@"
            set -- "--bind=@TERMUX_HOME@" "$@"

            # Storage bindings
            if ls -1U /storage/self/primary/ >/dev/null 2>&1; then
                set -- "--bind=/storage/self/primary:/sdcard" "$@"
            elif ls -1U /storage/emulated/0/ >/dev/null 2>&1; then
                set -- "--bind=/storage/emulated/0:/sdcard" "$@"
            elif ls -1U /sdcard/ >/dev/null 2>&1; then
                set -- "--bind=/sdcard:/sdcard" "$@"
            fi
            
            ls -1U /storage >/dev/null 2>&1 && set -- "--bind=/storage" "$@"
        fi

        # System bindings for QEMU or non-isolated mode
        if ! $isolated_environment || $need_qemu; then
            [ -d "/apex" ] && set -- "--bind=/apex" "$@"
            [ -e "/linkerconfig/ld.config.txt" ] && set -- "--bind=/linkerconfig/ld.config.txt" "$@"
            set -- "--bind=@TERMUX_PREFIX@" "$@"
            set -- "--bind=/system" "$@"
            set -- "--bind=/vendor" "$@"
            [ -f "/plat_property_contexts" ] && set -- "--bind=/plat_property_contexts" "$@"
            [ -f "/property_contexts" ] && set -- "--bind=/property_contexts" "$@"
        fi

        # Custom bindings
        for bnd in "${custom_fs_bindings[@]}"; do
            set -- "--bind=${bnd}" "$@"
        done

        $fix_low_ports && set -- "-p" "$@"
        
        exec proot "$@"
    else
        if [ -z "${SUPPORTED_DISTRIBUTIONS["$distro_name"]+x}" ]; then
            msg "${BRED}Error: unknown distribution '${YELLOW}${distro_name}${BRED}'.${RST}"
        else
            msg "${BRED}Error: distribution '${YELLOW}${distro_name}${BRED}' not installed.${RST}"
            msg "${CYAN}Install: ${GREEN}${PROGRAM_NAME} install ${distro_name}${RST}"
        fi
        return 1
    fi
}

# Enhanced List Function
command_list() {
    unq_banner
    if [ -z "${!SUPPORTED_DISTRIBUTIONS[*]}" ]; then
        msg "${YELLOW}No distribution plugins configured.${RST}"
        msg "${YELLOW}Check directory: '$DISTRO_PLUGINS_DIR'${RST}"
    else
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RST}" >&2
        echo -e "${CYAN}║                   📦 SUPPORTED DISTRIBUTIONS                 ║${RST}" >&2
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RST}" >&2
        
        local i
        for i in $(echo "${!SUPPORTED_DISTRIBUTIONS[@]}" | tr ' ' '\n' | sort -d); do
            msg " ${CYAN}• ${YELLOW}${SUPPORTED_DISTRIBUTIONS[$i]}${RST}"
            msg "   ${CYAN}Alias: ${GREEN}${i}${RST}"
            if is_distro_installed "$i"; then
                msg "   ${CYAN}Status: ${GREEN}✓ installed${RST}"
            else
                msg "   ${CYAN}Status: ${RED}✗ not installed${RST}"
            fi
            [ -n "${SUPPORTED_DISTRIBUTIONS_COMMENTS["${i}"]+x}" ] && msg "   ${CYAN}Info: ${SUPPORTED_DISTRIBUTIONS_COMMENTS["${i}"]}${RST}"
            msg
        done
        msg "${CYAN}Install: ${GREEN}${PROGRAM_NAME} install <alias>${RST}"
    fi
}

# Simplified utility functions
command_reset() {
    local distro_name="$1"
    [ -z "$distro_name" ] && { msg "${BRED}Error: distribution not specified.${RST}"; return 1; }
    CMD_REMOVE_REQUESTED_RESET="true" command_remove "$distro_name"
    command_install "$distro_name"
}

command_clear_cache() {
    if ! ls -la "${DOWNLOAD_CACHE_DIR}"/* >/dev/null 2>&1; then
        msg "${BLUE}[${GREEN}*${BLUE}] ${CYAN}Download cache is empty.${RST}"
    else
        local size_of_cache
        size_of_cache="$(du -d 0 -h -a ${DOWNLOAD_CACHE_DIR} | awk '{$2=$2};1' | cut -d " " -f 1)"
        show_progress 5 "Clearing cache files"
        find "${DOWNLOAD_CACHE_DIR}" -type f -delete
        msg "${BLUE}[${GREEN}*${BLUE}] ${CYAN}Reclaimed ${size_of_cache} of disk space.${RST}"
    fi
}

# Setup fake proc entries
setup_fake_proc() {
    mkdir -p "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc"
    chmod 700 "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc"
    
    [ ! -f "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.loadavg" ] && 
        echo "0.54 0.41 0.30 1/931 370386" > "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.loadavg"
    
    [ ! -f "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.uptime" ] && 
        echo "284684.56 513853.46" > "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.uptime"
    
    [ ! -f "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.version" ] && 
        echo "Linux version 5.4.0-pro (termux@androidos) (gcc version 4.9.x (Faked by UnQ Proot-Distro)) #1 SMP PREEMPT" > "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.version"
    
    # Additional proc files setup (stat, vmstat) with minimal content
    [ ! -f "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.stat" ] && 
        echo "cpu 1050008 127632 898432 43828767 37203 63 99244 0 0 0" > "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.stat"
    
    [ ! -f "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.vmstat" ] && 
        echo "nr_free_pages 146031" > "${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.vmstat"
}

# Help functions
command_help() {
    unq_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RST}" >&2
    echo -e "${CYAN}║                        📋 COMMANDS                           ║${RST}" >&2
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RST}" >&2
    msg "${GREEN}install ${CYAN}- Install a Linux distribution${RST}"
    msg "${GREEN}login ${CYAN}- Start shell session${RST}"
    msg "${GREEN}remove ${CYAN}- Remove distribution ${RED}(destructive)${RST}"
    msg "${GREEN}reset ${CYAN}- Reinstall distribution ${RED}(destructive)${RST}"
    msg "${GREEN}list ${CYAN}- Show available distributions${RST}"
    msg "${GREEN}backup ${CYAN}- Create distribution backup${RST}"
    msg "${GREEN}restore ${CYAN}- Restore from backup${RST}"
    msg "${GREEN}clear-cache ${CYAN}- Clear download cache${RST}"
    msg "${GREEN}help ${CYAN}- Show this help${RST}"
    msg
    msg "${CYAN}Example: ${GREEN}${PROGRAM_NAME} install ubuntu${RST}"
    msg "${CYAN}Runtime data: ${YELLOW}${RUNTIME_DIR}${RST}"
    show_version
}

show_version() {
    msg "${ICYAN}UnQ Proot-Distro v${PROGRAM_VERSION}${RST}"
    msg "${CYAN}Enhanced by UnQ - https://github.com/UnQOfficial/ubuntu${RST}"
}

# Help functions (simplified)
command_install_help() { msg "${BYELLOW}Usage: ${BCYAN}$PROGRAM_NAME ${GREEN}install ${CYAN}[DISTRIBUTION]${RST}"; show_version; }
command_remove_help() { msg "${BYELLOW}Usage: ${BCYAN}$PROGRAM_NAME ${GREEN}remove ${CYAN}[DISTRIBUTION]${RST}"; show_version; }
command_login_help() { msg "${BYELLOW}Usage: ${BCYAN}$PROGRAM_NAME ${GREEN}login ${CYAN}[OPTIONS] [DISTRIBUTION]${RST}"; show_version; }

# Special function for distro setup
run_proot_cmd() {
    [ -z "${distro_name-}" ] && { msg "${BRED}Error: distro_name not set${RST}"; return 1; }
    [ -z "${DISTRO_ARCH-}" ] && { msg "${BRED}Error: DISTRO_ARCH not set${RST}"; return 1; }
    
    local qemu_arg=""
    if [ "$DISTRO_ARCH" != "$DEVICE_CPU_ARCH" ]; then
        local qemu_bin_path=""
        case "$DISTRO_ARCH" in
            aarch64) qemu_bin_path="@TERMUX_PREFIX@/bin/qemu-aarch64";;
            arm) [ "$DEVICE_CPU_ARCH" != "aarch64" ] && qemu_bin_path="@TERMUX_PREFIX@/bin/qemu-arm";;
            i686) [ "$DEVICE_CPU_ARCH" != "x86_64" ] && qemu_bin_path="@TERMUX_PREFIX@/bin/qemu-i386";;
            x86_64) qemu_bin_path="@TERMUX_PREFIX@/bin/qemu-x86_64";;
        esac
        
        if [ -n "$qemu_bin_path" ] && [ -x "$qemu_bin_path" ]; then
            qemu_arg="-q ${qemu_bin_path}"
            [ -d "/apex" ] && qemu_arg="${qemu_arg} --bind=/apex"
            [ -e "/linkerconfig/ld.config.txt" ] && qemu_arg="${qemu_arg} --bind=/linkerconfig/ld.config.txt"
            qemu_arg="${qemu_arg} --bind=@TERMUX_PREFIX@ --bind=/system --bind=/vendor"
        fi
    fi
    
    proot $qemu_arg -L --kernel-release=5.4.0-pro --link2symlink --kill-on-exit \
        --rootfs="${INSTALLED_ROOTFS_DIR}/${distro_name}" --root-id --cwd=/root \
        --bind=/dev --bind="/dev/urandom:/dev/random" --bind=/proc --bind=/sys \
        --bind="${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.loadavg:/proc/loadavg" \
        --bind="${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.stat:/proc/stat" \
        --bind="${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.uptime:/proc/uptime" \
        --bind="${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.version:/proc/version" \
        --bind="${INSTALLED_ROOTFS_DIR}/${distro_name}/proc/.vmstat:/proc/vmstat" \
        /usr/bin/env -i "HOME=/root" "LANG=C.UTF-8" "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        "TERM=$TERM" "TMPDIR=/tmp" "$@"
}

# Entry Point
trap 'echo -e "\\r${BLUE}[${RED}!${BLUE}] ${CYAN}Exiting...${RST}"; exit 1;' HUP INT TERM

# Check dependencies
for i in awk bzip2 curl find gzip proot sed tar xz; do
    if [ -z "$(command -v "$i")" ]; then
        msg "${BRED}Missing utility: '${i}'. Cannot continue.${RST}"
        exit 1
    fi
done

# Determine CPU architecture
case "$(uname -m)" in
    armv7l|armv8l) DEVICE_CPU_ARCH="arm";;
    *) DEVICE_CPU_ARCH=$(uname -m);;
esac
DISTRO_ARCH=$DEVICE_CPU_ARCH

# Verify architecture
if [ -x "@TERMUX_PREFIX@/bin/dpkg" ] && [ "$DEVICE_CPU_ARCH" != "$("@TERMUX_PREFIX@"/bin/dpkg --print-architecture)" ]; then
    msg "${BRED}Architecture mismatch detected. Avoid using linux32 or similar.${RST}"
    exit 1
fi

# Initialize arrays
declare -A TARBALL_URL TARBALL_SHA256 SUPPORTED_DISTRIBUTIONS SUPPORTED_DISTRIBUTIONS_COMMENTS

# Load distribution plugins
while read -r filename; do
    distro_name=$(. "$filename"; echo "${DISTRO_NAME-}")
    distro_comment=$(. "$filename"; echo "${DISTRO_COMMENT-}")
    distro_alias=${filename%%.override.sh}; distro_alias=${distro_alias%%.sh}; distro_alias=$(basename "$distro_alias")
    
    [ -z "$distro_name" ] && { msg "${BRED}Error: DISTRO_NAME not defined in '${filename}'${RST}"; exit 1; }
    
    SUPPORTED_DISTRIBUTIONS["$distro_alias"]="$distro_name"
    [ -n "$distro_comment" ] && SUPPORTED_DISTRIBUTIONS_COMMENTS["$distro_alias"]="$distro_comment"
done < <(find "$DISTRO_PLUGINS_DIR" -maxdepth 1 -type f -iname "*.sh" 2>/dev/null)

# Command routing
if [ $# -ge 1 ]; then
    case "$1" in
        -h|--help|help) shift 1; command_help ;;
        backup) shift 1; command_backup "$@" ;;
        install) shift 1; command_install "$@" ;;
        list) shift 1; command_list ;;
        login) shift 1; command_login "$@" ;;
        remove) shift 1; CMD_REMOVE_REQUESTED_RESET="false" command_remove "$@" ;;
        clear-cache) shift 1; command_clear_cache "$@" ;;
        reset) shift 1; command_reset "$@" ;;
        restore) shift 1; command_restore "$@" ;;
        *) msg "${BRED}Error: unknown command '${YELLOW}$1${BRED}'.${RST}"; command_help; exit 1 ;;
    esac
else
    command_help
fi

exit 0
