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

# subconverter
# https://github.com/tindy2013/subconverter
INSTALLER_APP_NAME="subconverter"

if [[ -s "/srv/subconverter/subconverter" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(head -n1 /srv/subconverter/.version)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/tindy2013/subconverter/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_VDIS}" in
                arm64)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}_aarch64.tar.gz
                    ;;
                arm)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}_armhf.tar.gz
                    ;;
                *)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}_${OS_INFO_TYPE}${OS_INFO_VDIS}.tar.gz
                    ;;
            esac
            ;;
        darwin)
            INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}_darwin64.tar.gz
            ;;
        windows)
            case "${OS_INFO_VDIS}" in
                32)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}_win32.zip
                    ;;
                64)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}_win64.zip
                    ;;
            esac
            ;;
    esac

    [[ -z "${INSTALLER_FILE_NAME}" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/subconverter.tar.gz"
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/tindy2013/subconverter/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
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
        sudo tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "/srv" && \
            echo "${INSTALLER_VER_REMOTE}" | sudo tee "/srv/subconverter/.version" >/dev/null
    fi

    if [[ "${INSTALLER_IS_UPDATE}" == "no" ]]; then
        [[ ! -s "/srv/subconverter/pref.yml" ]] && sudo cp "/srv/subconverter/pref.example.yml" "/srv/subconverter/pref.yml"

        colorEchoN "${ORANGE}Enter api access password: "
        read -r -s API_PASSWORD
        if [[ -n "${API_PASSWORD}" ]]; then
            sudo sed -i "s|api_access_token:.*|api_access_token: ${API_PASSWORD}|" "/srv/subconverter/pref.yml"
            # sed -i "s|api_access_token:.*|api_access_token: ${API_PASSWORD}|" "/srv/subconverter/pref-new.yml"
            # sed -i "s|api_access_token=.*|api_access_token=${API_PASSWORD}|" "/srv/subconverter/pref.ini"
        fi
    fi

    systemctl is-enabled subconverter >/dev/null 2>&1 || {
        # [[ "${INSTALLER_IS_UPDATE}" == "no" ]] && \
        #         colorEchoN "${ORANGE}Install clash subconverter service?[y/${CYAN}N${ORANGE}]: " && \
        #         read -r INSTALLER_CHOICE
        # [[ "${INSTALLER_CHOICE}" == 'y' || "${INSTALLER_CHOICE}" == 'Y' ]] && Install_systemd_Service "subconverter" "/srv/subconverter/subconverter"
        Install_systemd_Service "subconverter" "/srv/subconverter/subconverter"
    }

    if [[ "${INSTALLER_IS_UPDATE}" == "yes" ]]; then
        systemctl is-enabled subconverter >/dev/null 2>&1 && sudo systemctl restart subconverter
    fi
fi

# nohup /srv/subconverter/subconverter >/dev/null 2>&1 & disown
# http://127.0.0.1:25500/sub?target=clash&url=https%3A%2F%2Fjiang.netlify.com%2F&config=https%3A%2F%2Fraw.githubusercontent.com%2FACL4SSR%2FACL4SSR%2Fmaster%2FClash%2Fpref.ini

cd "${CURRENT_DIR}" || exit