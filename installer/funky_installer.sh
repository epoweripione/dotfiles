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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# Funky takes shell functions to the next level by making them easier to define, more flexible, and more interactive.
# https://github.com/bbugyi200/funky
APP_INSTALL_NAME="funky"
EXEC_INSTALL_NAME="funky"
PIP_PACKAGE_NAME="pyfunky"

[[ ! -x "$(command -v ${EXEC_INSTALL_NAME})" ]] && IS_INSTALL="yes" || IS_INSTALL="no"
[[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"

[[ "${IS_INSTALL}" == "yes" ]] && pip_Package_Install "${PIP_PACKAGE_NAME}"


# Integrate funky into shell environment
if [[ ! -s "$HOME/.local/share/funky/funky.sh" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}funky shell Integrate script${BLUE}..."

    DOWNLOAD_FILENAME="${WORKDIR}/funky.sh"
    DOWNLOAD_URL="https://raw.githubusercontent.com/bbugyi200/funky/master/scripts/shell/funky.sh"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -eq 0 ]]; then
        mkdir -p "$HOME/.local/share/funky" && \
            cp -f "${DOWNLOAD_FILENAME}" "$HOME/.local/share/funky/funky.sh"
    fi
fi

# [[ -s "$HOME/.local/share/funky/funky.sh" ]] && source "$HOME/.local/share/funky/funky.sh"
