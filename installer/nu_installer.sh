#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

# Nushell: A new type of shell
# https://www.nushell.sh/
# https://github.com/nushell/nushell
APP_INSTALL_NAME="nushell"
GITHUB_REPO_NAME="nushell/nushell"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_DIR="nushell-*"
ARCHIVE_EXEC_NAME="nu"

EXEC_INSTALL_PATH="/usr/local/bin/nushell"
EXEC_INSTALL_NAME="nu"

REMOTE_SUFFIX=""
REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

INSTALL_FROM_SOURCE="no"
EXEC_FULL_NAME=""

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    EXEC_FULL_NAME=$(which ${EXEC_INSTALL_NAME})
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'tag_name' | cut -d\" -f4 | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

## Install via scoop in Windows
# scoop install nu

## Install via winget in Windows
# winget install --id=Nushell.Nushell --exact --rainbow
# [System.Environment]::SetEnvironmentVariable("PATH", $systemenv + ";$env:ProgramFiles\nu\bin")

# Install Latest Version
if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    if [[ -n "${EXEC_FULL_NAME}" ]] && [[ "${EXEC_FULL_NAME}" != *"${EXEC_INSTALL_PATH}"* ]]; then
        [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]] && INSTALL_FROM_SOURCE="yes"
    fi
fi

if [[ "${INSTALL_FROM_SOURCE}" == "yes" ]]; then
    # From source on crates.io
    [[ -x "$(command -v cargo)" ]] && cargo install nu --features=extra

    # Install via Homebrew
    [[ ! -x "$(command -v cargo)" && -x "$(command -v brew)" ]] && brew install nushell
elif [[ "${INSTALL_FROM_SOURCE}" == "no" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type

    case "${OS_INFO_TYPE}" in
        darwin)
            ARCHIVE_EXT="zip"
            REMOTE_FILENAME="nu_${REMOTE_VERSION//./_}_macOS.${ARCHIVE_EXT}"
            ;;
        windows)
            ARCHIVE_EXT="zip"
            REMOTE_FILENAME="nu_${REMOTE_VERSION//./_}_${OS_INFO_TYPE}.${ARCHIVE_EXT}"
            ;;
        linux)
            REMOTE_FILENAME="nu_${REMOTE_VERSION//./_}_${OS_INFO_TYPE}.${ARCHIVE_EXT}"
            ;;
    esac

    [[ -z "${REMOTE_FILENAME}" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" && "${INSTALL_FROM_SOURCE}" == "no" ]]; then
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
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/${REMOTE_VERSION}/${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        # Extract file
        case "${ARCHIVE_EXT}" in
            "zip")
                unzip -qo "${DOWNLOAD_FILENAME}" -d "${WORKDIR}"
                ;;
            "tar.bz2")
                tar -xjf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
                ;;
            "tar.gz")
                tar -xzf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
                ;;
            "tar.xz")
                tar -xJf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
                ;;
            "gz")
                cd "${WORKDIR}" && gzip -df "${DOWNLOAD_FILENAME}"
                ;;
            "bz")
                cd "${WORKDIR}" && bzip2 -df "${DOWNLOAD_FILENAME}"
                ;;
            "7z")
                7z e "${DOWNLOAD_FILENAME}" -o"${WORKDIR}"
                ;;
        esac

        # Install
        [[ -n "${ARCHIVE_EXEC_DIR}" ]] && ARCHIVE_EXEC_DIR=$(find "${WORKDIR}" -type d -name "${ARCHIVE_EXEC_DIR}")
        [[ -z "${ARCHIVE_EXEC_DIR}" || ! -d "${ARCHIVE_EXEC_DIR}" ]] && ARCHIVE_EXEC_DIR=${WORKDIR}

        if [[ -s "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" ]]; then
            sudo mkdir -p "${EXEC_INSTALL_PATH}" && \
                sudo cp -f "${ARCHIVE_EXEC_DIR}"/* "${EXEC_INSTALL_PATH}" && \
                sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                sudo ln -sv "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" "/usr/local/bin/nu" || true
        fi
    fi
fi

## Start the shell
# nu

cd "${CURRENT_DIR}" || exit