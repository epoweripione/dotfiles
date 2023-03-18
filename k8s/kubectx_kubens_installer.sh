#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

App_Installer_Reset
# kubectx + kubens: Power tools for kubectl
# https://github.com/ahmetb/kubectx
INSTALLER_APP_NAME="kubectx"
INSTALLER_GITHUB_REPO="ahmetb/kubectx"

INSTALLER_ARCHIVE_EXT="tar.gz"

INSTALLER_INSTALL_PATH="/usr/local/bin"
INSTALLER_INSTALL_NAME="kubectx"

[[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"

INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_INSTALL_NAME}"
[[ -n "${INSTALLER_ARCHIVE_EXT}" ]] && INSTALLER_DOWNLOAD_FILE="${INSTALLER_DOWNLOAD_FILE}.${INSTALLER_ARCHIVE_EXT}"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
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

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch
    [[ -z "${OS_INFO_FLOAT}" ]] && get_arch_float

    case "${OS_INFO_ARCH}" in
        amd64)
            INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}_v${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_x86_64.${INSTALLER_ARCHIVE_EXT}"
            ;;
        arm )
            [[ "${OS_INFO_FLOAT}" == "hardfloat" ]] && \
                INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}_v${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_armhf.${INSTALLER_ARCHIVE_EXT}" || \
                INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}_v${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_armv7.${INSTALLER_ARCHIVE_EXT}"
            ;;
        arm64 | ppc64le)
            INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}_v${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_${OS_INFO_ARCH}.${INSTALLER_ARCHIVE_EXT}"
            ;;
    esac

    [[ -z "${INSTALLER_FILE_NAME}" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    # Download file
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
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

        if echo "${INSTALLER_ARCHIVE_EXEC_NAME}" | grep -q '\*'; then
            if [[ -n "${INSTALLER_ARCHIVE_EXT}" ]]; then
                INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}" -not -name "*.${INSTALLER_ARCHIVE_EXT}") && \
                    INSTALLER_ARCHIVE_EXEC_NAME=$(basename "${INSTALLER_ARCHIVE_EXEC_NAME}")
            else
                INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}") && \
                    INSTALLER_ARCHIVE_EXEC_NAME=$(basename "${INSTALLER_ARCHIVE_EXEC_NAME}")
            fi
        fi
        [[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" || ! -s "${INSTALLER_ARCHIVE_EXEC_DIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME=${INSTALLER_INSTALL_NAME}

        if [[ -s "${INSTALLER_ARCHIVE_EXEC_DIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]]; then
            sudo cp -f "${INSTALLER_ARCHIVE_EXEC_DIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
                sudo chmod +x "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
                [[ -n "${INSTALLER_VER_FILE}" ]] && echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_VER_FILE}" >/dev/null || true
        fi
    fi
fi


App_Installer_Reset
# kubens
INSTALLER_APP_NAME="kubens"
INSTALLER_GITHUB_REPO="ahmetb/kubectx"

INSTALLER_ARCHIVE_EXT="tar.gz"

INSTALLER_INSTALL_PATH="/usr/local/bin"
INSTALLER_INSTALL_NAME="kubens"

[[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"

INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_INSTALL_NAME}"
[[ -n "${INSTALLER_ARCHIVE_EXT}" ]] && INSTALLER_DOWNLOAD_FILE="${INSTALLER_DOWNLOAD_FILE}.${INSTALLER_ARCHIVE_EXT}"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
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

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch
    [[ -z "${OS_INFO_FLOAT}" ]] && get_arch_float

    case "${OS_INFO_ARCH}" in
        amd64)
            INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}_v${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_x86_64.${INSTALLER_ARCHIVE_EXT}"
            ;;
        arm )
            [[ "${OS_INFO_FLOAT}" == "hardfloat" ]] && \
                INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}_v${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_armhf.${INSTALLER_ARCHIVE_EXT}" || \
                INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}_v${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_armv7.${INSTALLER_ARCHIVE_EXT}"
            ;;
        arm64 | ppc64le)
            INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}_v${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_${OS_INFO_ARCH}.${INSTALLER_ARCHIVE_EXT}"
            ;;
    esac

    [[ -z "${INSTALLER_FILE_NAME}" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    # Download file
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
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

        if echo "${INSTALLER_ARCHIVE_EXEC_NAME}" | grep -q '\*'; then
            if [[ -n "${INSTALLER_ARCHIVE_EXT}" ]]; then
                INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}" -not -name "*.${INSTALLER_ARCHIVE_EXT}") && \
                    INSTALLER_ARCHIVE_EXEC_NAME=$(basename "${INSTALLER_ARCHIVE_EXEC_NAME}")
            else
                INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}") && \
                    INSTALLER_ARCHIVE_EXEC_NAME=$(basename "${INSTALLER_ARCHIVE_EXEC_NAME}")
            fi
        fi
        [[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" || ! -s "${INSTALLER_ARCHIVE_EXEC_DIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME=${INSTALLER_INSTALL_NAME}

        if [[ -s "${INSTALLER_ARCHIVE_EXEC_DIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]]; then
            sudo cp -f "${INSTALLER_ARCHIVE_EXEC_DIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
                sudo chmod +x "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
                [[ -n "${INSTALLER_VER_FILE}" ]] && echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_VER_FILE}" >/dev/null || true
        fi
    fi
fi


cd "${CURRENT_DIR}" || exit