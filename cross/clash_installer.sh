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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# jq
if [[ ! -x "$(command -v jq)" ]]; then
    if checkPackageNeedInstall "jq"; then
        colorEcho "${BLUE}Installing ${FUCHSIA}jq${BLUE}..."
        sudo pacman --noconfirm -S jq
    fi
fi

if [[ ! -x "$(command -v jq)" ]]; then
    colorEcho "${FUCHSIA}jq${RED} is not installed!"
    exit 1
fi

# clash
# https://github.com/Dreamacro/clash
APP_INSTALL_NAME="clash"

REMOTE_SUFFIX=""
REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"
CHOICE="N"

if [[ -s "/srv/clash/clash" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(/srv/clash/clash -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    # CHECK_URL="https://api.github.com/repos/Dreamacro/clash/releases/latest"
    # REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'tag_name' | cut -d\" -f4 | cut -d'v' -f2)

    # Pre-release
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" -N https://github.com/Dreamacro/clash/releases \
        | grep -Eo -m1 '\/releases\/tag\/v([0-9]{1,}\.)+[0-9]{1,}' \
        | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch
    [[ -z "${OS_INFO_FLOAT}" ]] && get_arch_float

    REMOTE_FILENAME=""
    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_ARCH}" in
                arm64)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-${OS_INFO_TYPE}-armv8-v${REMOTE_VERSION}.gz
                    ;;
                arm)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-${OS_INFO_TYPE}-armv7-v${REMOTE_VERSION}.gz
                    ;;
                mips | mipsle)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-${OS_INFO_FLOAT}-v${REMOTE_VERSION}.gz
                    ;;
                *)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${REMOTE_VERSION}.gz
                    ;;
            esac
            ;;
        darwin)
            REMOTE_FILENAME=${APP_INSTALL_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${REMOTE_VERSION}.gz
            ;;
        freebsd)
            REMOTE_FILENAME=${APP_INSTALL_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${REMOTE_VERSION}.gz
            ;;
        windows)
            case "${OS_INFO_ARCH}" in
                arm)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-${OS_INFO_TYPE}-arm32v7-v${REMOTE_VERSION}.gz
                    ;;
                *)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-${OS_INFO_TYPE}-${OS_INFO_ARCH}-v${REMOTE_VERSION}.gz
                    ;;
            esac
            ;;
    esac

    [[ -z "${REMOTE_FILENAME}" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    DOWNLOAD_FILENAME="${WORKDIR}/clash-${OS_INFO_TYPE}-${OS_INFO_ARCH}.gz"
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/Dreamacro/clash/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
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
        sudo mkdir -p "/srv/clash" && \
            sudo mv "${DOWNLOAD_FILENAME}" "/srv/clash" && \
            cd "/srv/clash" && \
            sudo gzip -df "clash-${OS_INFO_TYPE}-${OS_INFO_ARCH}.gz" && \
            sudo chmod +x "clash-${OS_INFO_TYPE}-${OS_INFO_ARCH}" && \
            sudo ln -sv "/srv/clash/clash-${OS_INFO_TYPE}-${OS_INFO_ARCH}" "/srv/clash/clash" || true
    fi

    # geo database
    if [[ -s "/srv/clash/mmdb.ver" ]]; then
        CURRENT_VERSION=$(head -n1 /srv/clash/mmdb.ver)
    else
        CURRENT_VERSION="20000101"
    fi

    ## MaxMind GeoLite
    ## https://geolite.clash.dev/
    # CHECK_URL="https://geolite.clash.dev/version"
    # MMDB_URL="https://geolite.clash.dev/Country.mmdb"
    # REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}")

    ## All Country
    ## https://github.com/alecthw/mmdb_china_ip_list
    # CHECK_URL="https://api.github.com/repos/alecthw/mmdb_china_ip_list"
    # MMDB_URL="https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/Country.mmdb"

    # Only CN
    # https://github.com/Hackl0us/GeoIP2-CN
    CHECK_URL="https://api.github.com/repos/Hackl0us/GeoIP2-CN"
    MMDB_URL="https://raw.githubusercontent.com/Hackl0us/GeoIP2-CN/release/Country.mmdb"

    # REPO_PUSH_AT=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'pushed_at' | head -n1 | cut -d\" -f4)
    REPO_PUSH_AT=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.pushed_at//empty')
    REMOTE_VERSION=$(date -d "${REPO_PUSH_AT}" +"%Y%m%d")

    if version_gt "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}clash geo database ${YELLOW}${REMOTE_VERSION}${BLUE}..."

        DOWNLOAD_FILENAME="${WORKDIR}/Country.mmdb"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${MMDB_URL}" && \
            sudo mv -f "${DOWNLOAD_FILENAME}" "/srv/clash/Country.mmdb" && \
            echo "${REMOTE_VERSION}" | sudo tee "/srv/clash/mmdb.ver" >/dev/null
    fi

    [[ $(systemctl is-enabled clash 2>/dev/null) ]] || {
        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            Install_systemd_Service "clash" "/srv/clash/clash -d /srv/clash"
        else
            [[ "${IS_UPDATE}" == "no" ]] && \
                colorEchoN "${ORANGE}Install clash systemd service?[y/${CYAN}N${ORANGE}]: " && \
                read -r CHOICE
            [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]] && Install_systemd_Service "clash" "/srv/clash/clash -d /srv/clash"
        fi
    }

    if [[ "${IS_UPDATE}" == "yes" ]]; then
        [[ $(systemctl is-enabled clash 2>/dev/null) ]] && sudo systemctl restart clash && sleep 3
    fi
fi

# nohup /srv/clash/clash -d /srv/clash >/dev/null 2>&1 & disown

cd "${CURRENT_DIR}" || exit