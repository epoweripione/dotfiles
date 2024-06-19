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

# [eza - A modern, maintained replacement for ls](https://github.com/eza-community/eza)
INSTALLER_APP_NAME="eza"
INSTALLER_GITHUB_REPO="eza-community/eza"

INSTALLER_ARCHIVE_EXT="zip"
INSTALLER_INSTALL_NAME="eza"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

[[ ! -x "$(command -v cargo)" && ! -x "$(command -v brew)" ]] && INSTALLER_IS_INSTALL="no"

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    installBuildBinary "${INSTALLER_APP_NAME}" "${INSTALLER_INSTALL_NAME}" "cargo"

    curl "${CURL_DOWNLOAD_OPTS[@]}" "https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza" \
        | sudo tee "${INSTALLER_ZSH_FUNCTION_PATH}/_eza" >/dev/null
fi

# INSTALLER_ADDON_FILES=(
#     "_eza#https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza#${INSTALLER_ZSH_FUNCTION_PATH}/_eza"
# )
# if App_Installer_Install; then
#     [[ -f "/usr/local/share/zsh/site-functions/exa.zsh" ]] && sudo rm -f "/usr/local/share/zsh/site-functions/exa.zsh"
# else
#     colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
# fi

cd "${CURRENT_DIR}" || exit