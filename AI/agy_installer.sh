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

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

# [Antigravity CLI - The terminal-first surface to interact with Antigravity agents](https://antigravity.google/product/antigravity-cli)
INSTALLER_APP_NAME="Antigravity CLI"
INSTALLER_BINARY_NAME="agy"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    DOWNLOAD_BASE_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app"
    if check_os_musl; then
        INSTALLER_CHECK_URL="${DOWNLOAD_BASE_URL}/manifests/${OS_INFO_TYPE}_${OS_INFO_ARCH}_musl.json"
    else
        INSTALLER_CHECK_URL="${DOWNLOAD_BASE_URL}/manifests/${OS_INFO_TYPE}_${OS_INFO_ARCH}.json"
    fi

    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}" "^jq=.version"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    curl -fsSL https://antigravity.google/cli/install.sh | bash
fi
