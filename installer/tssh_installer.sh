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

# [trzsz-ssh](https://github.com/trzsz/trzsz-ssh)
INSTALLER_APP_NAME="tssh"
INSTALLER_GITHUB_REPO="trzsz/trzsz-ssh"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_DIR="tssh*"

INSTALLER_INSTALL_NAME="tssh"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if App_Installer_Install; then
    if ! grep -q "PromptThemeLayout" "$HOME/.tssh.conf" 2>/dev/null; then
        echo 'PromptThemeLayout = table' >> "$HOME/.tssh.conf"
    fi

    if [[ ! -f "$HOME/.ssh/password" ]]; then
        tee "$HOME/.ssh/password" >/dev/null <<-'EOF'
Host *
  EnableDragFile Yes
  EnableZmodem Yes
  EnableOSC52 Yes
EOF
    fi
else
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

cd "${CURRENT_DIR}" || exit