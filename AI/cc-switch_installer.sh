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

# [CC Switch: The All-in-One Manager for Claude Code, Claude Desktop, Codex, Gemini CLI, OpenCode, OpenClaw & Hermes Agent](https://github.com/farion1231/cc-switch)
INSTALLER_APP_NAME="CC Switch"
INSTALLER_GITHUB_REPO="farion1231/cc-switch"

INSTALLER_INSTALL_NAME="cc-switch"
INSTALLER_INSTALL_PACKAGE="cc-switch-bin"

INSTALLER_INSTALL_PATH="$HOME/Applications"

INSTALLER_DOWNLOAD_FILE="cc-switch.AppImage"
INSTALLER_VER_FILE="${INSTALLER_DOWNLOAD_FILE}.version"

if [[ -f "${INSTALLER_INSTALL_PATH}/${INSTALLER_DOWNLOAD_FILE}" ]]; then
    INSTALLER_IS_UPDATE="yes"
    [[ -s "${INSTALLER_INSTALL_PATH}/${INSTALLER_VER_FILE}" ]] && INSTALLER_VER_CURRENT=$(head -n1 "${INSTALLER_INSTALL_PATH}/${INSTALLER_VER_FILE}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# INSTALLER_VER_REMOTE="1.2.9"
if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}" && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    if checkPackageExists "${INSTALLER_APP_NAME}"; then
        PackagesList=("${INSTALLER_INSTALL_PACKAGE}") && InstallSystemPackages "" "${PackagesList[@]}"
    elif [[ -x "$(command -v brew)" ]]; then
        if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
            brew upgrade "${INSTALLER_INSTALL_NAME}"
        else
            brew install "${INSTALLER_INSTALL_NAME}"
        fi
    else
        INSTALLER_INSTALL_METHOD="custom"
    fi
fi

if [[ "${INSTALLER_INSTALL_METHOD}" == "custom" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_VDIS}" in
                64)
                    INSTALLER_FILE_NAME="CC-Switch-v${INSTALLER_VER_REMOTE}-Linux-x86_64.AppImage"
                    ;;
                arm64)
                    INSTALLER_FILE_NAME="CC-Switch-v${INSTALLER_VER_REMOTE}-Linux-arm64.AppImage"
                    ;;
            esac
            ;;
        darwin)
            INSTALLER_FILE_NAME="CC-Switch-v${INSTALLER_VER_REMOTE}-macOS.dmg"
            ;;
    esac

    [[ -n "${INSTALLER_FILE_NAME}" ]] && INSTALLER_DOWNLOAD_URL="https://github.com/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"

    if [[ -n "${INSTALLER_DOWNLOAD_URL}" ]]; then
        if App_Installer_Download "${INSTALLER_DOWNLOAD_URL}" "${WORKDIR}/${INSTALLER_DOWNLOAD_FILE}"; then
            mkdir -p "${INSTALLER_INSTALL_PATH}"
            cp -f "${WORKDIR}/${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_INSTALL_PATH}/${INSTALLER_DOWNLOAD_FILE}"
            echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_INSTALL_PATH}/${INSTALLER_VER_FILE}" >/dev/null || true
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit
