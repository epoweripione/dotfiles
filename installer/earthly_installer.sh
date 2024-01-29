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

# [Earthly - Make CI_CD Super Simple](https://earthly.dev/)
INSTALLER_APP_NAME="earthly"
INSTALLER_GITHUB_REPO="earthly/earthly"

INSTALLER_ARCHIVE_EXEC_NAME="earthly-*"

INSTALLER_INSTALL_NAME="earthly"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if App_Installer_Get_Remote_URL "https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest" "${INSTALLER_ARCHIVE_EXEC_NAME}"; then
    if App_Installer_Install; then
        sudo earthly bootstrap --with-autocomplete

        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            earthly config git "{github: {pattern: 'github.com/([^/]+)/([^/]+)', substitute: '${GITHUB_DOWNLOAD_URL}/\$1/\$2.git', auth: https}}"
        fi
    else
        colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
    fi
fi
