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

# zoxide: A smarter cd command
# https://github.com/ajeetdsouza/zoxide
if [[ -x "$(command -v zoxide)" && "$(command -v asdf)" ]]; then
    if asdf current "zoxide" >/dev/null 2>&1; then
        asdf uninstall "zoxide" && asdf plugin remove "zoxide"
    fi
fi

INSTALLER_APP_NAME="zoxide"
INSTALLER_GITHUB_REPO="ajeetdsouza/zoxide"

INSTALLER_INSTALL_PATH="/usr/local/bin"
INSTALLER_INSTALL_NAME="zoxide"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_DIR="zoxide-*"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    INSTALLER_EXEC_FULLNAME=$(readlink -f "$(which ${INSTALLER_INSTALL_NAME})")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
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
