#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

# Package managers with pacman-style command syntax
# https://github.com/icy/pacapt
# https://github.com/rami3l/pacaptr
[[ -z "${OS_PACKAGE_MANAGER}" ]] && get_os_package_manager

if [[ -n "${OS_PACKAGE_MANAGER}" && "${OS_PACKAGE_MANAGER}" != "pacman" ]]; then
    # Use built-in package manager to install packages required for install pacapt or pacaptr
    # [List of software package management systems](https://en.wikipedia.org/wiki/List_of_software_package_management_systems)
    PackagesList=()
    [[ ! "$(command -v axel)" ]] && PackagesList+=("axel")
    [[ ! "$(command -v curl)" ]] && PackagesList+=("curl")
    [[ ! "$(command -v wget)" ]] && PackagesList+=("wget")
    [[ ! "$(command -v git)" ]] && PackagesList+=("git")
    [[ ! "$(command -v tar)" ]] && PackagesList+=("tar")
    [[ ! "$(command -v zip)" ]] && PackagesList+=("zip")
    [[ ! "$(command -v unzip)" ]] && PackagesList+=("unzip")

    if [[ -n "${PackagesList[*]}" ]]; then
        colorEcho "${BLUE}Installing ${FUCHSIA}${PackagesList[*]}${BLUE}..."
        case "${OS_PACKAGE_MANAGER}" in
            apt | apt-get | dpkg)
                sudo apt update && sudo apt install -y "${PackagesList[@]}"
                ;;
            dnf)
                sudo dnf -y install "${PackagesList[@]}"
                ;;
            yum)
                sudo yum -y install "${PackagesList[@]}"
                ;;
            pacman)
                sudo pacman --noconfirm -S "${PackagesList[@]}"
                ;;
            apk)
                sudo apk add --no-cache "${PackagesList[@]}"
                ;;
            zypper)
                sudo zypper refresh && sudo zypper install -y "${PackagesList[@]}"
                ;;
            emerge | portage)
                sudo emerge --ask=n "${PackagesList[@]}"
                ;;
            pkg | pkgng)
                sudo pkg install -y "${PackagesList[@]}"
                ;;
            macports)
                sudo port install "${PackagesList[@]}"
                ;;
            *)
                colorEcho "${RED}Unsupported package manager! Please install ${FUCHSIA}${PackagesList[*]}${RED} manually!"
                exit 1
                ;;
        esac
    fi

    PACMAN_STYLE_COMMAND="pacapt"

    PACAPTR_SUPPORT_PM=(apk dpkg dnf homebrew macports portage xbps zypper)
    [[ " ${PACAPTR_SUPPORT_PM[*]} " == *" ${OS_PACKAGE_MANAGER} "* ]] && PACMAN_STYLE_COMMAND="pacaptr"

    [[ "$(uname -o 2>/dev/null)" == "Android" ]] && PACMAN_STYLE_COMMAND="pacapt"
    # [[ -x "/data/data/com.termux/files/usr/bin/apt-get" ]] && PACMAN_STYLE_COMMAND="pacapt"

    [[ -s "${MY_SHELL_SCRIPTS}/installer/${PACMAN_STYLE_COMMAND}_installer.sh" ]] && \
        source "${MY_SHELL_SCRIPTS}/installer/${PACMAN_STYLE_COMMAND}_installer.sh"
fi
