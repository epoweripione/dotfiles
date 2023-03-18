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

# proxypool
# https://github.com/Sansui233/proxypool
INSTALLER_APP_NAME="proxypool"
INSTALLER_GITHUB_REPO="Sansui233/proxypool"

INSTALLER_ARCHIVE_EXT="gz"
INSTALLER_ARCHIVE_EXEC_NAME="proxypool"

INSTALLER_INSTALL_PATH="/usr/local/bin"
INSTALLER_INSTALL_NAME="proxypool"

[[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"

INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_INSTALL_NAME}"
[[ -n "${INSTALLER_ARCHIVE_EXT}" ]] && INSTALLER_DOWNLOAD_FILE="${INSTALLER_DOWNLOAD_FILE}.${INSTALLER_ARCHIVE_EXT}"

INSTALLER_VER_FILE="${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}.version"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    [[ -s "${INSTALLER_VER_FILE}" ]] && INSTALLER_VER_CURRENT=$(head -n1 "${INSTALLER_VER_FILE}")
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

    INSTALLER_FILE_NAME="${INSTALLER_INSTALL_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${INSTALLER_VER_REMOTE}.${INSTALLER_ARCHIVE_EXT}"
    case "${OS_INFO_ARCH}" in
        arm64)
            INSTALLER_FILE_NAME="${INSTALLER_INSTALL_NAME}-${OS_INFO_TYPE}-armv8-v${INSTALLER_VER_REMOTE}.${INSTALLER_ARCHIVE_EXT}"
            ;;
        arm)
            INSTALLER_FILE_NAME="${INSTALLER_INSTALL_NAME}-${OS_INFO_TYPE}-armv7-v${INSTALLER_VER_REMOTE}.${INSTALLER_ARCHIVE_EXT}"
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
        [[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"

        if [[ -s "${WORKDIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]]; then
            sudo cp -f "${WORKDIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
                sudo chmod +x "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
                [[ -n "${INSTALLER_VER_FILE}" ]] && echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_VER_FILE}" >/dev/null || true
        fi
    fi
fi


# config
if [[ ! -s "/etc/proxypool/config.yaml" ]]; then
    mkdir -p "/etc/proxypool" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/source.yaml" \
            "https://raw.githubusercontent.com/Sansui233/proxypool/master/config/source.yaml" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/config.yaml" \
            "https://raw.githubusercontent.com/Sansui233/proxypool/master/config/config.yaml" && \
        sudo cp -f "${WORKDIR}/source.yaml" "/etc/proxypool/source.yaml" && \
        sudo cp -f "${WORKDIR}/config.yaml" "/etc/proxypool/config.yaml" && \
        sudo sed -i "s|./config/source.yaml|/etc/proxypool/source.yaml|" "/etc/proxypool/config.yaml"
fi

# sudo sed -i "s|domain:.*|domain: pool.example.com|" "/etc/proxypool/config.yaml"
# Install_systemd_Service "proxypool" "/usr/local/bin/proxypool -c /etc/proxypool/config.yaml"

## nginx
# proxy_pass http://127.0.0.1:12580/;


cd "${CURRENT_DIR}" || exit