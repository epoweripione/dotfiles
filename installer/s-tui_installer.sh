#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

# s-tui: The Stress Terminal UI: s-tui
# https://github.com/amanusk/s-tui
APP_INSTALL_NAME="s-tui"
EXEC_INSTALL_NAME="s-tui"
PIP_PACKAGE_NAME="s-tui"

if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        stress
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi

[[ ! -x "$(command -v ${EXEC_INSTALL_NAME})" ]] && IS_INSTALL="yes" || IS_INSTALL="no"
[[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"

[[ "${IS_INSTALL}" == "yes" ]] && pip_Package_Install "${PIP_PACKAGE_NAME}"
