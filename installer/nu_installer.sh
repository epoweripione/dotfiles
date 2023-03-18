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

# Nushell: A new type of shell
# https://www.nushell.sh/
# https://github.com/nushell/nushell
INSTALLER_APP_NAME="nushell"
INSTALLER_GITHUB_REPO="nushell/nushell"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_DIR="nu-*"
INSTALLER_ARCHIVE_EXEC_NAME="nu"

INSTALLER_INSTALL_PATH="/usr/local/bin/nushell"
INSTALLER_INSTALL_NAME="nu"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    INSTALLER_EXEC_FULLNAME=$(readlink -f "$(which ${INSTALLER_INSTALL_NAME})")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

## Install via scoop in Windows
# scoop install nu

## Install via winget in Windows
# winget install --id=Nushell.Nushell --exact --rainbow
# [System.Environment]::SetEnvironmentVariable("PATH", $systemenv + ";$env:ProgramFiles\nu\bin", 'Machine')

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    INSTALLER_INSTALL_METHOD="custom"

    if checkPackageExists "${INSTALLER_APP_NAME}"; then
        INSTALLER_INSTALL_METHOD="pacman"
    else
        if [[ -n "${INSTALLER_EXEC_FULLNAME}" ]] && [[ "${INSTALLER_EXEC_FULLNAME}" != *"${INSTALLER_INSTALL_PATH}"* ]]; then
            [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]] && INSTALLER_INSTALL_METHOD="build"
        fi
    fi
fi

# pacman
if [[ "${INSTALLER_INSTALL_METHOD}" == "pacman" ]]; then
    if checkPackageNeedInstall "${INSTALLER_APP_NAME}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        [[ -x "$(command -v pacman)" ]] && sudo pacman --noconfirm -S "${INSTALLER_APP_NAME}"
    fi
fi

# app installer
if [[ "${INSTALLER_INSTALL_METHOD}" == "custom" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

    case "${OS_INFO_TYPE}" in
        darwin)
            case "${OS_INFO_VDIS}" in
                64)
                    INSTALLER_FILE_NAME="nu-${INSTALLER_VER_REMOTE}-x86_64-apple-${OS_INFO_TYPE}.${INSTALLER_ARCHIVE_EXT}"
                    ;;
                arm64)
                    INSTALLER_FILE_NAME="nu-${INSTALLER_VER_REMOTE}-aarch64-apple-${OS_INFO_TYPE}.${INSTALLER_ARCHIVE_EXT}"
                    ;;
            esac
            ;;
        linux)
            case "${OS_INFO_VDIS}" in
                64)
                    INSTALLER_FILE_NAME="nu-${INSTALLER_VER_REMOTE}-x86_64-unknown-${OS_INFO_TYPE}-musl.${INSTALLER_ARCHIVE_EXT}"
                    ;;
                arm)
                    INSTALLER_FILE_NAME="nu-${INSTALLER_VER_REMOTE}-armv7-unknown-${OS_INFO_TYPE}-gnueabihf.${INSTALLER_ARCHIVE_EXT}"
                    ;;
                arm64)
                    INSTALLER_FILE_NAME="nu-${INSTALLER_VER_REMOTE}-aarch64-unknown-${OS_INFO_TYPE}-gnu.${INSTALLER_ARCHIVE_EXT}"
                    ;;
            esac
            ;;
        windows)
            INSTALLER_ARCHIVE_EXT="zip"
            INSTALLER_FILE_NAME="nu-${INSTALLER_VER_REMOTE}-x86_64-pc-${OS_INFO_TYPE}-msvc.${INSTALLER_ARCHIVE_EXT}"
            ;;
    esac

    [[ -z "${INSTALLER_FILE_NAME}" ]] && INSTALLER_INSTALL_METHOD="build"
fi

if [[ "${INSTALLER_INSTALL_METHOD}" == "custom" ]]; then
    if [[ -x "$(command -v pacman)" ]]; then
        PackagesList=(
            cmake
            pkg-config
            libssl-dev
            libxcb
            libxcb-composite0-dev
            libx11-dev
            libX11-devel
            openssl-devel 
        )
        for TargetPackage in "${PackagesList[@]}"; do
            if checkPackageNeedInstall "${TargetPackage}"; then
                colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
                sudo pacman --noconfirm -S "${TargetPackage}"
            fi
        done
    fi

    # Download file
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_APP_NAME}.tar.gz"

    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        INSTALLER_DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        # Extract file
        case "${INSTALLER_ARCHIVE_EXT}" in
            "zip")
                unzip -qo "${INSTALLER_DOWNLOAD_FILE}" -d "${WORKDIR}"
                ;;
            "tar.bz2")
                tar -xjf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}"
                ;;
            "tar.gz")
                tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}"
                ;;
            "tar.xz")
                tar -xJf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}"
                ;;
            "gz")
                cd "${WORKDIR}" && gzip -df "${INSTALLER_DOWNLOAD_FILE}"
                ;;
            "bz")
                cd "${WORKDIR}" && bzip2 -df "${INSTALLER_DOWNLOAD_FILE}"
                ;;
            "7z")
                7z e "${INSTALLER_DOWNLOAD_FILE}" -o"${WORKDIR}"
                ;;
        esac

        # Install
        [[ -n "${INSTALLER_ARCHIVE_EXEC_DIR}" ]] && INSTALLER_ARCHIVE_EXEC_DIR=$(find "${WORKDIR}" -type d -name "${INSTALLER_ARCHIVE_EXEC_DIR}")
        [[ -z "${INSTALLER_ARCHIVE_EXEC_DIR}" || ! -d "${INSTALLER_ARCHIVE_EXEC_DIR}" ]] && INSTALLER_ARCHIVE_EXEC_DIR=${WORKDIR}

        if [[ -s "${INSTALLER_ARCHIVE_EXEC_DIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]]; then
            rm "${INSTALLER_DOWNLOAD_FILE}"
            sudo mkdir -p "${INSTALLER_INSTALL_PATH}" && \
                sudo cp -f "${INSTALLER_ARCHIVE_EXEC_DIR}"/nu* "${INSTALLER_INSTALL_PATH}" && \
                sudo chmod +x "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
                sudo ln -sv "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" "/usr/local/bin/nu" || true
        fi
    fi
fi

# homebrew or build from source
if [[ "${INSTALLER_INSTALL_METHOD}" == "build" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    # Install via Homebrew
    [[ -x "$(command -v brew)" ]] && brew install "${INSTALLER_APP_NAME}"

    # From source on crates.io
    [[ ! -x "$(command -v brew)" && -x "$(command -v cargo)" ]] && cargo install nu --features=extra
fi

## Start the shell
# nu

cd "${CURRENT_DIR}" || exit