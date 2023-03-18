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

App_Installer_Reset

# nnn - Supercharge your productivity!
# https://github.com/jarun/nnn
INSTALLER_APP_NAME="nnn"
INSTALLER_GITHUB_REPO="jarun/nnn"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_NAME="nnn-*"

INSTALLER_INSTALL_NAME="nnn"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

# install all plugins
# https://github.com/jarun/nnn/tree/master/plugins
# ${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && "${INSTALLER_IS_UPDATE}" == "no" && -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins" ]] && \
        find "${XDG_CONFIG_HOME:-$HOME/.config}/nnn" -type f -name "plugins-*.tar.gz" -delete

    [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins" ]] && \
        rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins"

    curl -fsL "https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs" | sh
fi

cd "${CURRENT_DIR}" || exit