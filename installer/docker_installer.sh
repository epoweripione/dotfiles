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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch
[[ -z "${OS_INFO_RELEASE}" ]] && get_os_release

OS_INFO_WSL=$(uname -r)

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
    if [[ "$OS_INFO_RELEASE" == "ol" || "$OS_INFO_RELEASE" == "rhel" ]]; then
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
    if [[ "$OS_INFO_RELEASE" == "sles" ]]; then
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
IS_INSTALL="no"
CURRENT_VERSION=""

# Install & update buildx if not built-in
if [[ "${CLI_BUILDX_BUILTIN}" == "no" ]]; then
    if [[ -f "${CLI_PLUGINS_DIR}/docker-buildx" ]]; then
        CURRENT_VERSION=$(docker buildx version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    fi
fi

if [[ -n "${CURRENT_VERSION}" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}buildx${BLUE}..."
    CHECK_URL="https://api.github.com/repos/docker/buildx/releases/latest"
    App_Installer_Get_Remote_Version "${CHECK_URL}"
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
else
    IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}buildx ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    if [[ "${OS_INFO_ARCH}" == "arm" ]]; then
        REMOTE_FILENAME="buildx-v${REMOTE_VERSION}.${OS_INFO_TYPE}-${OS_INFO_ARCH}-v7"
    else
        REMOTE_FILENAME="buildx-v${REMOTE_VERSION}.${OS_INFO_TYPE}-${OS_INFO_ARCH}"
    fi

    DOWNLOAD_FILENAME="${WORKDIR}/docker-buildx"
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/docker/buildx/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        [[ "${CLI_PLUGINS_DIR}" != "$HOME/.docker/cli-plugins" && -f "$HOME/.docker/cli-plugins/docker-buildx" ]] && \
            rm -f "$HOME/.docker/cli-plugins/docker-buildx"

        sudo cp -f "${DOWNLOAD_FILENAME}" "${CLI_PLUGINS_DIR}/docker-buildx" && \
            sudo chmod a+x "${CLI_PLUGINS_DIR}/docker-buildx"
    fi
fi


# [compose](https://docs.docker.com/compose/install/)
IS_INSTALL="no"
CURRENT_VERSION=""

# Install & update compose if not built-in
if [[ "${CLI_COMPOSE_BUILTIN}" == "no" ]]; then
    if [[ -f "${CLI_PLUGINS_DIR}/docker-compose" ]]; then
        CURRENT_VERSION=$(docker compose version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    elif [[ -x "$(command -v docker-compose)" ]]; then
        CURRENT_VERSION=$(docker-compose -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    fi
fi

if [[ -n "${CURRENT_VERSION}" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}docker-compose${BLUE}..."
    CHECK_URL="https://api.github.com/repos/docker/compose/releases/latest"
    App_Installer_Get_Remote_Version "${CHECK_URL}"
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
else
    IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}docker-compose ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    # if [[ "${OS_INFO_ARCH}" == "arm" ]]; then
    #     REMOTE_FILENAME="docker-compose-${OS_INFO_TYPE}-armv7"
    # else
    #     REMOTE_FILENAME="docker-compose-${OS_INFO_TYPE}-${OS_INFO_ARCH}"
    # fi
    REMOTE_FILENAME="docker-compose-${OS_INFO_TYPE}-$(uname -m)"

    DOWNLOAD_FILENAME="${WORKDIR}/docker-compose"
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/docker/compose/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        [[ "${CLI_PLUGINS_DIR}" != "$HOME/.docker/cli-plugins" && -f "$HOME/.docker/cli-plugins/docker-compose" ]] && \
            rm -f "$HOME/.docker/cli-plugins/docker-compose"

        sudo cp -f "${DOWNLOAD_FILENAME}" "${CLI_PLUGINS_DIR}/docker-compose" && \
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
IS_INSTALL="yes"
CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ctop)" ]]; then
    CURRENT_VERSION=$(ctop -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
fi

colorEcho "${BLUE}Checking latest version for ${FUCHSIA}ctop${BLUE}..."
CHECK_URL="https://api.github.com/repos/bcicen/ctop/releases/latest"
App_Installer_Get_Remote_Version "${CHECK_URL}"
if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
    IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}ctop ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    REMOTE_FILENAME="ctop-${REMOTE_VERSION}-${OS_INFO_TYPE}-${OS_INFO_ARCH}"

    DOWNLOAD_FILENAME="${WORKDIR}/ctop"
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/bcicen/ctop/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo mv -f "${DOWNLOAD_FILENAME}" "/usr/local/bin/ctop" && \
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
SET_REGISTRY_MIRROR="N"
if [[ "${IS_INSTALL}" == "yes" && "${THE_WORLD_BLOCKED}" == "true" && ! -s "/etc/docker/daemon.json" ]]; then
    # colorEchoN "${ORANGE}Setting docker registry-mirrors?[y/${CYAN}N${ORANGE}]: "
    # read -r -t 5 SET_REGISTRY_MIRROR
    # echo ""
    SET_REGISTRY_MIRROR="Y"

    [[ "${OS_INFO_WSL}" =~ "Microsoft" || "${OS_INFO_WSL}" =~ "microsoft" ]] && SET_REGISTRY_MIRROR="N"
fi

if [[ "${SET_REGISTRY_MIRROR}" == "y" || "${SET_REGISTRY_MIRROR}" == "Y" ]]; then
    ## https://github.com/docker-practice/docker-registry-cn-mirror-test/actions

    ## fix:
    ## curl: (35) error:1414D172:SSL routines:tls12_check_peer_sigalg:wrong signature type
    ## https: SSLError(SSLError(1, '[SSL: WRONG_SIGNATURE_TYPE] wrong signature type (_ssl.c:1123)'))
    # sudo sed -i 's/CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=1/' /etc/ssl/openssl.cnf

    # https GET "https://mirror.baidubce.com/v2/library/nginx/tags/list"
    # ht GET "https://hub-mirror.c.163.com/v2/library/nginx/tags/list"
    # curl -ikL -X GET "https://docker.mirrors.sjtug.sjtu.edu.cn/v2/library/nginx/tags/list"
    # curl -ikL -X GET "https://docker.mirrors.sjtug.sjtu.edu.cn/v2/library/nginx/manifests/latest"

#     sudo tee /etc/docker/daemon.json >/dev/null <<-'EOF'
# {
#     "registry-mirrors": [
#         "https://dockerproxy.com",
#         "https://docker.mirrors.sjtug.sjtu.edu.cn",
#         "https://hub-mirror.c.163.com"
#     ]
# }
# EOF

    REGISTRY_MIRRORS='"https://docker.mirrors.sjtug.sjtu.edu.cn","https://hub-mirror.c.163.com"'

    [[ ! -s "/etc/docker/daemon.json" ]] && sudo mkdir -p "/etc/docker" && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    # jq -r '."registry-mirrors"=."registry-mirrors" + ["https://hub-mirror.c.163.com"]' "/etc/docker/daemon.json" \
    #     | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

    # jq -r 'del(."registry-mirrors")' "/etc/docker/daemon.json" \
    #     | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

    jq -r ".\"registry-mirrors\"=[${REGISTRY_MIRRORS}]" "/etc/docker/daemon.json" \
        | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

    [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"
    sudo systemctl daemon-reload && sudo systemctl restart docker
fi

# remove unuse mirrors
UNUSE_MIRRORS=(
    '"https://docker.mirrors.ustc.edu.cn"'
    '"https://ustc-edu-cn.mirror.aliyuncs.com"'
    '"https://mirror.baidubce.com"'
    '"https://mirror.ccs.tencentyun.com"'
    '"https://dockerproxy.com"'
)

REMOVE_MIRRORS=""
if [[ -s "/etc/docker/daemon.json" ]]; then
    for Target in "${UNUSE_MIRRORS[@]}"; do
        if grep -q "${Target}" "/etc/docker/daemon.json" 2>/dev/null; then
            [[ -z "${REMOVE_MIRRORS}" ]] && REMOVE_MIRRORS="${Target}" || REMOVE_MIRRORS="${REMOVE_MIRRORS},${Target}"
        fi
    done

    if [[ -n "${REMOVE_MIRRORS}" ]]; then
        jq -r ".\"registry-mirrors\"=.\"registry-mirrors\" - [${REMOVE_MIRRORS}]" "/etc/docker/daemon.json" \
            | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

        [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"
        sudo systemctl daemon-reload && sudo systemctl restart docker
    fi
fi

# docker proxy
SET_DOCKER_PROXY="N"
if [[ "${OS_INFO_WSL}" =~ "Microsoft" || "${OS_INFO_WSL}" =~ "microsoft" ]]; then
    :
else
    if [[ "${IS_INSTALL}" == "yes" && -n "${HTTP_PROXY}" && ! -s "/etc/docker/daemon.json" ]]; then
        colorEchoN "${ORANGE}Setting docker proxy?[y/${CYAN}N${ORANGE}]: "
        read -r -t 5 SET_DOCKER_PROXY
        echo ""
    fi
fi

if [[ "${SET_DOCKER_PROXY}" == "y" || "${SET_DOCKER_PROXY}" == "Y" ]]; then
    sudo mkdir -p "/etc/systemd/system/docker.service.d"
    sudo tee "/etc/systemd/system/docker.service.d/99-proxy.conf" >/dev/null <<-EOF
[Service]
Environment="HTTP_PROXY=${HTTP_PROXY}"
Environment="HTTPS_PROXY=${HTTPS_PROXY}"
Environment="NO_PROXY=${NO_PROXY}"
EOF
    sudo systemctl daemon-reload && sudo systemctl restart docker
    sudo systemctl show --property=Environment docker
fi

## Relocating the Docker root directory
## docker info -f '{{ .DockerRootDir}}' # /var/lib/docker
# DATA_ROOT="/data/docker" && sudo mkdir -p "${DATA_ROOT}"
# if [[ -x "$(command -v jq)" ]]; then
#     [[ ! -s "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

#     jq -r ".\"data-root\"=[${DATA_ROOT}]" "/etc/docker/daemon.json" \
#         | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

#     [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"
#     sudo systemctl daemon-reload && sudo systemctl restart docker
# fi

## container runtime proxy
# tee "$HOME/.docker/config.json" >/dev/null <<-EOF
# {
#     "proxies":
#     {
#         "default":
#         {
#             "httpProxy": "${HTTP_PROXY}",
#             "httpsProxy": "${HTTPS_PROXY}",
#             "noProxy": "${NO_PROXY}"
#         }
#     }
# }
# EOF

## docker build proxy
# docker build . \
#     --build-arg "HTTP_PROXY=${HTTP_PROXY}" \
#     --build-arg "HTTPS_PROXY=${HTTPS_PROXY}" \
#     --build-arg "NO_PROXY=${NO_PROXY}" \
#     -t your/image:tag


cd "${CURRENT_DIR}" || exit