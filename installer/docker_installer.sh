#!/usr/bin/env bash

# if [[ $UID -ne 0 ]]; then
#     echo "Please run this script as root user!"
#     exit 0
# fi

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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch
[[ -z "${OS_INFO_RELEASE}" ]] && get_os_release
[[ -z "${OS_INFO_DESKTOP}" ]] && get_os_desktop

# jq
if [[ ! -x "$(command -v jq)" ]]; then
    if checkPackageNeedInstall "jq"; then
        colorEcho "${BLUE}Installing ${FUCHSIA}jq${BLUE}..."
        sudo pacman --noconfirm -S jq
    fi
fi

# [Manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/)
if [[ $UID -ne 0 ]]; then
    if ! id -nG "$USER" | grep -qw "docker"; then
        sudo groupadd docker 2>/dev/null
        sudo usermod -aG docker "$USER" 2>/dev/null

        [[ -d "$HOME/.docker" ]] && sudo chown -R "$USER":"$USER" "$HOME/.docker" && sudo chmod -R g+rwx "$HOME/.docker"
    fi
fi

## Docker
# https://github.com/docker/docker-install
if [[ ! -x "$(command -v docker)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}Docker${BLUE}..."
    if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
        curl "${CURL_DOWNLOAD_OPTS[@]}" https://get.docker.com -o "${WORKDIR}/get-docker.sh" && \
            sudo bash "${WORKDIR}/get-docker.sh" --mirror Aliyun
    else
        curl "${CURL_DOWNLOAD_OPTS[@]}" https://get.docker.com -o "${WORKDIR}/get-docker.sh" && \
            sudo bash "${WORKDIR}/get-docker.sh"
    fi
fi

if [[ ! -x "$(command -v docker)" ]]; then
    # Oracle Linux、RHEL
    if [[ "${OS_INFO_RELEASE}" == "ol" || "${OS_INFO_RELEASE}" == "rhel" ]]; then
        # sudo yum -y install docker-engine
        # sudo yum -y remove docker docker-common docker-selinux docker-engine docker-cli
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum -y install docker-ce && \
            sudo systemctl enable docker && \
            sudo systemctl start docker

        # fix: Error response from daemon: OCI runtime create failed: 
        # ...write /proc/self/attr/keycreate: permission denied
        OS_VERSION_ID=$(grep -E '^VERSION_ID=([a-zA-Z]*)' /etc/os-release \
                        | cut -d'=' -f2 | sed 's/\"//g' | cut -d'.' -f1)
        if [[ "$OS_VERSION_ID" == "7" ]]; then
            sudo yum -y install \
                http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-1.el7_6.noarch.rpm
        fi
    fi

    # SUSE Linux Enterprise Server
    if [[ "${OS_INFO_RELEASE}" == "sles" ]]; then
        sudo zypper in docker && \
            sudo systemctl enable docker && \
            sudo systemctl start docker
    fi
fi

if [[ ! -x "$(command -v docker)" ]]; then
    colorEcho "${FUCHSIA}Docker${RED} is not installed! Please manual install ${FUCHSIA}docker-ce${RED} or ${FUCHSIA}docker-engine${RED}!"
    exit 1
fi

## [CLI Plugins](https://github.com/docker/cli/issues/1534)
CLI_BUILDX_BUILTIN="yes"
CLI_COMPOSE_BUILTIN="yes"
CLI_PLUGINS_DIR=""
DirList=(
    "/usr/local/lib/docker/cli-plugins"
    "/usr/local/libexec/docker/cli-plugins"
    "/usr/lib/docker/cli-plugins"
    "/usr/libexec/docker/cli-plugins"
)
for TargetDir in "${DirList[@]}"; do
    [[ -d "${TargetDir}" ]] && CLI_PLUGINS_DIR="${TargetDir}" && break
done

if [[ -z "${CLI_PLUGINS_DIR}" ]]; then
    CLI_BUILDX_BUILTIN="no"
    CLI_COMPOSE_BUILTIN="no"
    CLI_PLUGINS_DIR="$HOME/.docker/cli-plugins"
    mkdir -p "${CLI_PLUGINS_DIR}"
else
    [[ ! -f "${CLI_PLUGINS_DIR}/docker-buildx" ]] && CLI_BUILDX_BUILTIN="no"
    [[ ! -f "${CLI_PLUGINS_DIR}/docker-compose" ]] && CLI_COMPOSE_BUILTIN="no"
fi

# [buildx](https://docs.docker.com/build/install-buildx/)
INSTALLER_IS_INSTALL="no"
INSTALLER_VER_CURRENT=""

# Install & update buildx if not built-in
if [[ "${CLI_BUILDX_BUILTIN}" == "no" ]]; then
    if [[ -f "${CLI_PLUGINS_DIR}/docker-buildx" ]]; then
        INSTALLER_VER_CURRENT=$(docker buildx version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    fi
fi

if [[ -n "${INSTALLER_VER_CURRENT}" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}buildx${BLUE}..."
    INSTALLER_CHECK_URL="https://api.github.com/repos/docker/buildx/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
else
    INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}buildx ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    if [[ "${OS_INFO_ARCH}" == "arm" ]]; then
        INSTALLER_FILE_NAME="buildx-v${INSTALLER_VER_REMOTE}.${OS_INFO_TYPE}-${OS_INFO_ARCH}-v7"
    else
        INSTALLER_FILE_NAME="buildx-v${INSTALLER_VER_REMOTE}.${OS_INFO_TYPE}-${OS_INFO_ARCH}"
    fi

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/docker-buildx"
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/docker/buildx/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
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
        [[ "${CLI_PLUGINS_DIR}" != "$HOME/.docker/cli-plugins" && -f "$HOME/.docker/cli-plugins/docker-buildx" ]] && \
            rm -f "$HOME/.docker/cli-plugins/docker-buildx"

        sudo cp -f "${INSTALLER_DOWNLOAD_FILE}" "${CLI_PLUGINS_DIR}/docker-buildx" && \
            sudo chmod a+x "${CLI_PLUGINS_DIR}/docker-buildx"
    fi
fi


# [compose](https://docs.docker.com/compose/install/)
INSTALLER_IS_INSTALL="no"
INSTALLER_VER_CURRENT=""

# Install & update compose if not built-in
if [[ "${CLI_COMPOSE_BUILTIN}" == "no" ]]; then
    if [[ -f "${CLI_PLUGINS_DIR}/docker-compose" ]]; then
        INSTALLER_VER_CURRENT=$(docker compose version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    elif [[ -x "$(command -v docker-compose)" ]]; then
        INSTALLER_VER_CURRENT=$(docker-compose -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    fi
fi

if [[ -n "${INSTALLER_VER_CURRENT}" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}docker-compose${BLUE}..."
    INSTALLER_CHECK_URL="https://api.github.com/repos/docker/compose/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
else
    INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}docker-compose ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    # if [[ "${OS_INFO_ARCH}" == "arm" ]]; then
    #     INSTALLER_FILE_NAME="docker-compose-${OS_INFO_TYPE}-armv7"
    # else
    #     INSTALLER_FILE_NAME="docker-compose-${OS_INFO_TYPE}-${OS_INFO_ARCH}"
    # fi
    INSTALLER_FILE_NAME="docker-compose-${OS_INFO_TYPE}-$(uname -m)"

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/docker-compose"
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/docker/compose/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
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
        [[ "${CLI_PLUGINS_DIR}" != "$HOME/.docker/cli-plugins" && -f "$HOME/.docker/cli-plugins/docker-compose" ]] && \
            rm -f "$HOME/.docker/cli-plugins/docker-compose"

        sudo cp -f "${INSTALLER_DOWNLOAD_FILE}" "${CLI_PLUGINS_DIR}/docker-compose" && \
            sudo chmod a+x "${CLI_PLUGINS_DIR}/docker-compose"
    fi

    ## Compose V2
    ## https://docs.docker.com/compose/cli-command/#installing-compose-v2
    # curl "${CURL_DOWNLOAD_OPTS[@]}" -o docker-compose-v2.sh "https://raw.githubusercontent.com/docker/compose-cli/main/scripts/install/install_linux.sh" && \
    #     bash docker-compose-v2.sh
fi

# Allow your user to access the Docker CLI without needing root.
# sudo usermod -aG docker $USER


# [ctop](https://github.com/bcicen/ctop)
INSTALLER_IS_INSTALL="yes"
INSTALLER_VER_CURRENT="0.0.0"

if [[ -x "$(command -v ctop)" ]]; then
    INSTALLER_VER_CURRENT=$(ctop -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
fi

colorEcho "${BLUE}Checking latest version for ${FUCHSIA}ctop${BLUE}..."
INSTALLER_CHECK_URL="https://api.github.com/repos/bcicen/ctop/releases/latest"
App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
    INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}ctop ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    INSTALLER_FILE_NAME="ctop-${INSTALLER_VER_REMOTE}-${OS_INFO_TYPE}-${OS_INFO_ARCH}"

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/ctop"
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/bcicen/ctop/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
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
        sudo mv -f "${INSTALLER_DOWNLOAD_FILE}" "/usr/local/bin/ctop" && \
            sudo chmod +x "/usr/local/bin/ctop"
    fi
fi


## lazydocker
## https://github.com/jesseduffield/lazydocker
# docker run --rm -it -v \
#     /var/run/docker.sock:/var/run/docker.sock \
#     -v ~/.config/lazydocker:/.config/jesseduffield/lazydocker \
#     lazyteam/lazydocker


# docker mirrors
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && "${THE_WORLD_BLOCKED}" == "true" ]]; then
    # colorEchoN "${ORANGE}Setting docker registry-mirrors?[y/${CYAN}N${ORANGE}]: "
    # read -r -t 5 SET_REGISTRY_MIRROR
    # echo ""
    dockerSetMirrors
fi

# remove unuse mirrors
dockerRemoveUnuseMirrors

cd "${CURRENT_DIR}" || exit