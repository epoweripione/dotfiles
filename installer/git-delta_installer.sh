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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# git-delta
# https://github.com/dandavison/delta
INSTALLER_APP_NAME="delta"
INSTALLER_GITHUB_REPO="dandavison/delta"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_DIR="delta-*"

INSTALLER_INSTALL_NAME="delta"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" && -x "$(command -v delta)" ]]; then
    git config --global core.pager delta

    git config --global delta.features "side-by-side line-numbers decorations"
    git config --global delta.plus-style "syntax #003800"
    git config --global delta.minus-style "syntax #3f0001"
    git config --global delta.syntax-theme Dracula

    git config --global delta.decorations.commit-decoration-style "bold yellow box ul"
    git config --global delta.decorations.file-style "bold yellow ul"
    git config --global delta.decorations.file-decoration-style none
    git config --global delta.decorations.hunk-header-decoration-style "cyan box ul"

    git config --global delta.line-numbers.line-numbers-left-style cyan
    git config --global delta.line-numbers.line-numbers-right-style cyan
    git config --global delta.line-numbers.line-numbers-minus-style 124
    git config --global delta.line-numbers.line-numbers-plus-style 28

    git config --global interactive.diffFilter "delta --color-only"
fi

cd "${CURRENT_DIR}" || exit