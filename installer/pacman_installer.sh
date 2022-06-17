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
    PACMAN_STYLE_COMMAND="pacapt"

    PACATPR_SUPPORT_PM=(apk dpkg dnf homebrew macports portage zypper)
    [[ " ${PACATPR_SUPPORT_PM[*]} " == *" ${OS_PACKAGE_MANAGER} "* ]] && PACMAN_STYLE_COMMAND="pacaptr"

    [[ "$(uname -o 2>/dev/null)" == "Android" ]] && PACMAN_STYLE_COMMAND="pacapt"
    # [[ -x "/data/data/com.termux/files/usr/bin/apt-get" ]] && PACMAN_STYLE_COMMAND="pacapt"

    [[ -s "${MY_SHELL_SCRIPTS}/installer/${PACMAN_STYLE_COMMAND}_installer.sh" ]] && \
        source "${MY_SHELL_SCRIPTS}/installer/${PACMAN_STYLE_COMMAND}_installer.sh"
fi
