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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# jq
[[ ! -x "$(command -v jq)" ]] && PackagesList=(jq) && InstallSystemPackages "" "${PackagesList[@]}"

if [[ ! -x "$(command -v jq)" ]]; then
    colorEcho "${FUCHSIA}jq${RED} is not installed!"
    exit 1
fi

# clash
# https://github.com/Dreamacro/clash
INSTALLER_APP_NAME="clash"

if [[ -s "/srv/clash/clash" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(/srv/clash/clash -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    # INSTALLER_CHECK_URL="https://api.github.com/repos/Dreamacro/clash/releases/latest"
    # App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"

    # Pre-release
    INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" -N https://github.com/Dreamacro/clash/releases \
        | grep -Eo -m1 '/releases/tag/v([0-9]{1,}\.)+[0-9]{1,}' \
        | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch
    [[ -z "${OS_INFO_FLOAT}" ]] && get_arch_float

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_ARCH}" in
                arm64)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}-${OS_INFO_TYPE}-armv8-v${INSTALLER_VER_REMOTE}.gz
                    ;;
                arm)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}-${OS_INFO_TYPE}-armv7-v${INSTALLER_VER_REMOTE}.gz
                    ;;
                mips | mipsle)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-${OS_INFO_FLOAT}-v${INSTALLER_VER_REMOTE}.gz
                    ;;
                *)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${INSTALLER_VER_REMOTE}.gz
                    ;;
            esac
            ;;
        darwin)
            INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${INSTALLER_VER_REMOTE}.gz
            ;;
        freebsd)
            INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${INSTALLER_VER_REMOTE}.gz
            ;;
        windows)
            case "${OS_INFO_ARCH}" in
                arm)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}-${OS_INFO_TYPE}-arm32v7-v${INSTALLER_VER_REMOTE}.gz
                    ;;
                *)
                    INSTALLER_FILE_NAME=${INSTALLER_APP_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${INSTALLER_VER_REMOTE}.gz
                    ;;
            esac
            ;;
    esac

    [[ -z "${INSTALLER_FILE_NAME}" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/clash-${OS_INFO_TYPE}-${OS_INFO_ARCH}.gz"
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/Dreamacro/clash/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
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
        sudo mkdir -p "/srv/clash" && \
            sudo mv "${INSTALLER_DOWNLOAD_FILE}" "/srv/clash" && \
            cd "/srv/clash" && \
            sudo gzip -df "clash-${OS_INFO_TYPE}-${OS_INFO_ARCH}.gz" && \
            sudo chmod +x "clash-${OS_INFO_TYPE}-${OS_INFO_ARCH}" && \
            sudo ln -sv "/srv/clash/clash-${OS_INFO_TYPE}-${OS_INFO_ARCH}" "/srv/clash/clash" || true
    fi

    # geo database
    if [[ -s "/srv/clash/mmdb.ver" ]]; then
        INSTALLER_VER_CURRENT=$(head -n1 /srv/clash/mmdb.ver)
    else
        INSTALLER_VER_CURRENT="20000101"
    fi

    ## MaxMind GeoLite
    ## https://geolite.clash.dev/
    # INSTALLER_CHECK_URL="https://geolite.clash.dev/version"
    # MMDB_URL="https://geolite.clash.dev/Country.mmdb"
    # INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}")

    ## All Country
    ## https://github.com/alecthw/mmdb_china_ip_list
    # INSTALLER_CHECK_URL="https://api.github.com/repos/alecthw/mmdb_china_ip_list"
    # MMDB_URL="https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/Country.mmdb"

    # Only CN
    # https://github.com/Hackl0us/GeoIP2-CN
    INSTALLER_CHECK_URL="https://api.github.com/repos/Hackl0us/GeoIP2-CN"
    MMDB_URL="https://raw.githubusercontent.com/Hackl0us/GeoIP2-CN/release/Country.mmdb"

    # REPO_PUSH_AT=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | grep 'pushed_at' | head -n1 | cut -d\" -f4)
    REPO_PUSH_AT=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | jq -r '.pushed_at//empty')
    INSTALLER_VER_REMOTE=$(date -d "${REPO_PUSH_AT}" +"%Y%m%d")

    if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}clash geo database ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

        INSTALLER_DOWNLOAD_FILE="${WORKDIR}/Country.mmdb"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${MMDB_URL}" && \
            sudo mv -f "${INSTALLER_DOWNLOAD_FILE}" "/srv/clash/Country.mmdb" && \
            echo "${INSTALLER_VER_REMOTE}" | sudo tee "/srv/clash/mmdb.ver" >/dev/null
    fi

    systemctl is-enabled clash >/dev/null 2>&1 || {
        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            Install_systemd_Service "clash" "/srv/clash/clash -d /srv/clash" "root"
        else
            [[ "${INSTALLER_IS_UPDATE}" == "no" ]] && \
                colorEchoN "${ORANGE}Install clash systemd service?[y/${CYAN}N${ORANGE}]: " && \
                read -r INSTALLER_CHOICE
            [[ "${INSTALLER_CHOICE}" == 'y' || "${INSTALLER_CHOICE}" == 'Y' ]] && Install_systemd_Service "clash" "/srv/clash/clash -d /srv/clash" "root"
        fi
    }

    if [[ "${INSTALLER_IS_UPDATE}" == "yes" ]]; then
        systemctl is-enabled clash >/dev/null 2>&1 && sudo systemctl restart clash && sleep 3
    fi

    # if [[ -d "/srv/clash" && ! -s "/srv/clash/cache.db" ]]; then
    #     sudo touch "/srv/clash/cache.db" && sudo chmod o=rw "/srv/clash/cache.db"
    # fi
fi

# nohup /srv/clash/clash -d /srv/clash >/dev/null 2>&1 & disown

cd "${CURRENT_DIR}" || exit