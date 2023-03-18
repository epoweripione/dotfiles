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

# tldr++: fast and interactive tldr client written with go
# https://github.com/isacikgoz/tldr
INSTALLER_APP_NAME="tldr++"
INSTALLER_GITHUB_REPO="isacikgoz/tldr"

INSTALLER_ARCHIVE_EXT="tar.gz"

INSTALLER_INSTALL_NAME="tldr"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1 | cut -d. -f1-2)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if App_Installer_Install; then
    # Pulls the github.com/tldr-pages/tldr repository
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    case "${OS_INFO_TYPE}" in
        darwin)
            TLDR_PAGES="$HOME/Library/Application Support/tldr"
            ;;
        windows)
            # TLDR_PAGES="$HOME/AppData/Roaming/tldr"
            TLDR_PAGES=""
            ;;
        *)
            TLDR_PAGES="$HOME/.local/share/tldr"
            ;;
    esac
    [[ -n "${TLDR_PAGES}" ]] && Git_Clone_Update_Branch "tldr-pages/tldr" "${TLDR_PAGES}"
else
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi


cd "${CURRENT_DIR}" || exit