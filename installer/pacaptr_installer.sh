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

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

# pacaptr - Pacman-like syntax wrapper for many package managers
# https://github.com/rami3l/pacaptr
INSTALLER_APP_NAME="pacaptr"
INSTALLER_GITHUB_REPO="rami3l/pacaptr"

INSTALLER_INSTALL_NAME="pacaptr"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    ECHO_TYPE="Updating"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
    ECHO_TYPE="Installing"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi

    case "${OS_INFO_TYPE}" in
        darwin)
            INSTALLER_FILE_NAME="${INSTALLER_INSTALL_NAME}-${OS_INFO_TYPE}-universal2.tar.gz"
            ;;
        linux)
            case "${OS_INFO_ARCH}" in
                amd64 | arm64)
                    INSTALLER_FILE_NAME="${INSTALLER_INSTALL_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}.tar.gz"
                    ;;
            esac
            ;;
    esac

    [[ -z "${INSTALLER_FILE_NAME}" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if [[ "${INSTALLER_IS_UPDATE}" == "yes" ]]; then
        [[ -s "/root/.config/pacaptr/pacaptr.toml" ]] && \
            sudo sed -i "s/needed.*/needed = true/" "/root/.config/pacaptr/pacaptr.toml"
    else
        # pacaptr config   
        sudo mkdir -p "/root/.config/pacaptr/"
        echo -e "dry_run = false\nneeded = true\nno_confirm = false\nforce_cask = false\nno_cache = false" \
            | sudo tee "/root/.config/pacaptr/pacaptr.toml" >/dev/null
    fi

    [[ "$(readlink -f /usr/bin/pacman)" == "/usr/bin/pacapt" ]] && \
        sudo rm -f "/usr/bin/pacman" && sudo rm -f "/usr/bin/pacapt"

    colorEcho "${BLUE}  ${ECHO_TYPE} ${FUCHSIA}pacaptr ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/rami3l/pacaptr/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_FILE_NAME}"
    if App_Installer_Download "${INSTALLER_DOWNLOAD_URL}" "${INSTALLER_DOWNLOAD_FILE}"; then
        sudo tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}" && \
            sudo mv "${WORKDIR}/pacaptr" "${INSTALLER_INSTALL_PATH}"
            sudo chmod +x "${INSTALLER_INSTALL_PATH}/pacaptr" && \
            sudo ln -sv "${INSTALLER_INSTALL_PATH}/pacaptr" "/usr/bin/pacman" || true

        # Save downloaded file to cache
        App_Installer_Save_to_Cache "${INSTALLER_APP_NAME}" "${INSTALLER_VER_REMOTE}" "${INSTALLER_DOWNLOAD_FILE}"
    fi
fi