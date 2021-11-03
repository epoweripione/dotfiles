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

# bottom: Yet another cross-platform graphical process/system monitor
# https://github.com/ClementTsang/bottom
APP_INSTALL_NAME="bottom"
GITHUB_REPO_NAME="ClementTsang/bottom"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_DIR=""
ARCHIVE_EXEC_NAME=""

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="btm"

DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"

DOWNLOAD_URL=""
REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

INSTALL_FROM_SOURCE="no"
EXEC_FULL_NAME=""

CURRENT_VERSION="0.0.0"
VERSION_FILENAME=""

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

# Install Latest Version
if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    if [[ -n "${EXEC_FULL_NAME}" ]] && [[ ! "${EXEC_FULL_NAME}" =~ "${EXEC_INSTALL_PATH}" ]]; then
        [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]] && INSTALL_FROM_SOURCE="yes"
    fi
fi

if [[ "${INSTALL_FROM_SOURCE}" == "yes" ]]; then
    # From source on crates.io
    [[ -x "$(command -v cargo)" ]] && cargo install "${APP_INSTALL_NAME}"

    # Install via Homebrew
    [[ ! -x "$(command -v cargo)" && -x "$(command -v brew)" ]] && \
        brew tap clementtsang/bottom && \
        brew install clementtsang/bottom/bottom
elif [[ "${INSTALL_FROM_SOURCE}" == "no" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_ARCH}" in
                arm)
                    REMOTE_FILENAME="${APP_INSTALL_NAME}_armv7-unknown-${OS_INFO_TYPE}-gnueabihf.${ARCHIVE_EXT}"
                    ;;
                arm64)
                    REMOTE_FILENAME="${APP_INSTALL_NAME}_aarch64-unknown-${OS_INFO_TYPE}-gnu.${ARCHIVE_EXT}"
                    ;;
                amd64)
                    REMOTE_FILENAME="${APP_INSTALL_NAME}_x86_64-unknown-${OS_INFO_TYPE}-musl.${ARCHIVE_EXT}"
                    ;;
                386)
                    REMOTE_FILENAME="${APP_INSTALL_NAME}_i686-unknown-${OS_INFO_TYPE}-musl.${ARCHIVE_EXT}"
                    ;;
            esac
            ;;
        darwin)
            REMOTE_FILENAME="${APP_INSTALL_NAME}_x86_64-apple-${OS_INFO_TYPE}.${ARCHIVE_EXT}"
            ;;
        windows)
            ARCHIVE_EXT="zip"
            REMOTE_FILENAME="${APP_INSTALL_NAME}_x86_64-pc-${OS_INFO_TYPE}-msvc.${ARCHIVE_EXT}"
            ;;
    esac

    [[ -z "${REMOTE_FILENAME}" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" && -n "${REMOTE_FILENAME}" ]]; then
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

        if echo "${ARCHIVE_EXEC_NAME}" | grep -q '\*'; then
            ARCHIVE_EXEC_NAME=$(find "${ARCHIVE_EXEC_DIR}" -type f -name "${ARCHIVE_EXEC_NAME}") && \
                ARCHIVE_EXEC_NAME=$(basename "${ARCHIVE_EXEC_NAME}")
        fi
        [[ -z "${ARCHIVE_EXEC_NAME}" || ! -s "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" ]] && ARCHIVE_EXEC_NAME=${EXEC_INSTALL_NAME}

        if [[ -s "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" ]]; then
            sudo cp -f "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                sudo cp -f "${WORKDIR}/completion/_btm" "/usr/local/share/zsh/site-functions" && \
                sudo chmod 644 "/usr/local/share/zsh/site-functions/_btm" && \
                sudo chown "$(id -u)":"$(id -g)" "/usr/local/share/zsh/site-functions/_btm" && \
                [[ -n "${VERSION_FILENAME}" ]] && echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit