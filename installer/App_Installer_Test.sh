#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

GITHUB_REPOS=(
    "jez/as-tree"
    "sharkdp/bat"
    "aristocratos/btop"
    "ClementTsang/bottom"
    "rs/curlie"
    "muesli/duf"
    "bootandy/dust"
    "tstack/lnav"
    "Peltoche/lsd"
    "denisidoro/navi"
    "jarun/nnn"
    "nushell/nushell"
    "ericchiang/pup"
    "rclone/rclone"
    "alash3al/re-txt"
    "restic/restic"
    "isacikgoz/tldr"
    "xo/usql"
    "mikefarah/yq"
)

for TargetRepo in "${GITHUB_REPOS[@]}"; do
    colorEchoN "${BLUE}${TargetRepo}: "

    INSTALLER_CHECK_URL="https://api.github.com/repos/${TargetRepo}/releases/latest"
    if App_Installer_Get_Remote "${INSTALLER_CHECK_URL}"; then
        colorEcho "${FUCHSIA}${INSTALLER_VER_REMOTE}"

        if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}"; then
            INSTALLER_FILE_NAME=$(echo "${INSTALLER_DOWNLOAD_URL}" | awk -F"/" '{print $NF}')
            colorEcho "  ${ORANGE}${INSTALLER_FILE_NAME}${BLUE} has been downloaded & extracted!"
        fi
    else
        echo ""
    fi

    sleep 1
done
