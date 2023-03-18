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

# zoxide: A smarter cd command
# https://github.com/ajeetdsouza/zoxide
if [[ -x "$(command -v zoxide)" && "$(command -v asdf)" ]]; then
    if asdf current "zoxide" >/dev/null 2>&1; then
        asdf uninstall "zoxide" && asdf plugin remove "zoxide"
    fi
fi

APP_INSTALL_NAME="zoxide"
GITHUB_REPO_NAME="ajeetdsouza/zoxide"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="zoxide"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_DIR="zoxide-*"
ARCHIVE_EXEC_NAME=""

MAN1_FILE="*.1"
ZSH_COMPLETION_FILE=""

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"
REMOTE_VERSION=""
VERSION_FILENAME=""

REMOTE_DOWNLOAD_URL=""

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    EXEC_FULL_NAME=$(readlink -f "$(which ${EXEC_INSTALL_NAME})")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${APP_INSTALL_NAME}${RED} failed!"
fi

# if [[ -x "$(command -v zoxide)" ]]; then
#     if ! grep -q "_ZO_ECHO" "$HOME/.zshenv" 2>/dev/null; then
#         {
#             echo ""
#             echo "# zoxide: print the matched directory before navigating to it"
#             echo "export _ZO_ECHO=1"
#         } >> "$HOME/.zshenv"
#     fi
# fi

cd "${CURRENT_DIR}" || exit
