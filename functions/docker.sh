#!/usr/bin/env bash

# docker mirrors

## fix
## curl: (35) error:1414D172:SSL routines:tls12_check_peer_sigalg:wrong signature type
## https: SSLError(SSLError(1, '[SSL: WRONG_SIGNATURE_TYPE] wrong signature type (_ssl.c:1123)'))
# sudo sed -i 's/CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=1/' /etc/ssl/openssl.cnf

## testing
# https GET "https://mirror.baidubce.com/v2/library/nginx/tags/list"
# ht GET "https://hub-mirror.c.163.com/v2/library/nginx/tags/list"
# curl -ikL --noproxy "*" --connect-timeout 5 -X GET "https://docker.mirrors.sjtug.sjtu.edu.cn/v2/library/nginx/tags/list"
# curl -ikL --noproxy "*" --connect-timeout 5 -X GET "https://docker.mirrors.sjtug.sjtu.edu.cn/v2/library/nginx/manifests/latest"

# jq -r '."registry-mirrors"=."registry-mirrors" + ["https://dockerpull.com"]' "/etc/docker/daemon.json" | sudo tee "/etc/docker/daemon_temp.json" >/dev/null
# jq -r 'del(."registry-mirrors")' "/etc/docker/daemon.json" | sudo tee "/etc/docker/daemon_temp.json" >/dev/null
# dockerSetMirrors '"https://dockerproxy.cn","https://docker.chenby.cn","https://dockerpull.com","https://docker.1panel.live"'
function dockerSetMirrors() {
    local REGISTRY_MIRRORS=$1

    if [[ ! -x "$(command -v docker)" ]]; then
        colorEcho "${FUCHSIA}docker${RED} is not installed!"
        return 1
    fi

    if [[ ! -x "$(command -v jq)" ]]; then
        colorEcho "${FUCHSIA}jq${RED} is not installed!"
        return 1
    fi

    if check_os_wsl; then
        # colorEcho "Running in ${FUCHSIA}WSL${RED}, you must setting registry in Docker Desktop!"
        return 0
    fi

    if [[ -z "${REGISTRY_MIRRORS}" ]]; then
        [[ -z "${MIRROR_DOCKER_REGISTRY}" ]] && return 0
        REGISTRY_MIRRORS=${MIRROR_DOCKER_REGISTRY}
    fi

    colorEcho "${BLUE}Setting docker registry-mirrors to:"
    colorEcho "${FUCHSIA}  ${REGISTRY_MIRRORS}"

    [[ ! -f "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    jq -r ".\"registry-mirrors\"=[${REGISTRY_MIRRORS}]" "/etc/docker/daemon.json" \
        | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

    [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"

    colorEcho "${BLUE}Restarting docker service..."
    sudo systemctl daemon-reload && sudo systemctl restart docker
}

# clear mirrors
function dockerClearMirrors() {
    if [[ -f "/etc/docker/daemon.json" ]]; then
        jq -r 'del(."registry-mirrors")' "/etc/docker/daemon.json" | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

        [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"
        sudo systemctl daemon-reload && sudo systemctl restart docker
    fi
}

# remove unuse mirrors
function dockerRemoveUnuseMirrors() {
    local UNUSE_MIRRORS REMOVE_MIRRORS Target

    [[ ! -f "/etc/docker/daemon.json" ]] && return 0

    if [[ -z "${UNUSE_MIRRORS[*]}" ]]; then
        UNUSE_MIRRORS=(
            '"https://docker.mirrors.ustc.edu.cn"'
            '"https://ustc-edu-cn.mirror.aliyuncs.com"'
            '"https://mirror.baidubce.com"'
            '"https://mirror.ccs.tencentyun.com"'
            '"https://dockerproxy.com"'
        )
    fi

    REMOVE_MIRRORS=""
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
}

# [Configure Docker to use a proxy server](https://docs.docker.com/network/proxy/)
# docker build --build-arg HTTP_PROXY="http://localhost.localdomain:7890" .
# docker run --env HTTP_PROXY="http://localhost.localdomain:7890" redis
# docker proxy
function dockerSetProxy() {
    [[ -f "/etc/systemd/system/docker.service.d/99-proxy.conf" ]] && return 0

    if [[ -n "${HTTP_PROXY}" && -n "${HTTPS_PROXY}" && -n "${NO_PROXY}" ]]; then
        sudo mkdir -p "/etc/systemd/system/docker.service.d"
        sudo tee "/etc/systemd/system/docker.service.d/99-proxy.conf" >/dev/null <<-EOF
[Service]
Environment="HTTP_PROXY=${HTTP_PROXY}"
Environment="HTTPS_PROXY=${HTTPS_PROXY}"
Environment="NO_PROXY=${NO_PROXY}"
EOF
        sudo systemctl daemon-reload && sudo systemctl restart docker
        # sudo systemctl show --property=Environment docker
    fi
}

function dockerClearProxy() {
    [[ ! -f "/etc/systemd/system/docker.service.d/99-proxy.conf" ]] && return 0

    sudo rm "/etc/systemd/system/docker.service.d/99-proxy.conf"

    sudo systemctl daemon-reload && sudo systemctl restart docker
    # sudo systemctl show --property=Environment docker
}

## container runtime proxy
## Linux
# curl -fSL --proxy "http://localhost.localdomain:7890" --connect-timeout 3 --max-time 5 -I "www.google.com"
# export http_proxy="http://localhost.localdomain:7890" && export https_proxy=${http_proxy} && export HTTP_PROXY=${http_proxy} && export HTTPS_PROXY=${http_proxy}
## Docker for Windows
# curl -fsL -I --connect-timeout 3 --max-time 5 --proxy "http://host.docker.internal:7890" "www.google.com"
# export http_proxy="http://host.docker.internal:7890" && export https_proxy=${http_proxy} && export HTTP_PROXY=${http_proxy} && export HTTPS_PROXY=${http_proxy}
function dockerSetContainerProxy() {
    [[ -f "$HOME/.docker/config.json" ]] && return 0

    if [[ -n "${HTTP_PROXY}" && -n "${HTTPS_PROXY}" && -n "${NO_PROXY}" ]]; then
        mkdir -p "$HOME/.docker"
        tee "$HOME/.docker/config.json" >/dev/null <<-EOF
{
    "proxies":
    {
        "default":
        {
            "httpProxy": "${HTTP_PROXY/127.0.0.1/localhost.localdomain}",
            "httpsProxy": "${HTTPS_PROXY/127.0.0.1/localhost.localdomain}",
            "noProxy": "${NO_PROXY}"
        }
    }
}
EOF
    fi
}

function dockerClearContainerProxy() {
    [[ ! -f "$HOME/.docker/config.json" ]] && return 0

    jq -r 'del(."proxies")' "$HOME/.docker/config.json" | tee "$HOME/.docker/config_temp.json" >/dev/null
    [[ -f "$HOME/.docker/config_temp.json" ]] && mv -f "$HOME/.docker/config_temp.json" "$HOME/.docker/config.json"
}

## docker build proxy
# docker build . \
#     --build-arg "HTTP_PROXY=${HTTP_PROXY}" \
#     --build-arg "HTTPS_PROXY=${HTTPS_PROXY}" \
#     --build-arg "NO_PROXY=${NO_PROXY}" \
#     -t your/image:tag

# docker pull: Pull multiple images together
# https://github.com/moby/moby/issues/16106
function dockerPullImages() {
    # usage: 
    # dockerPullImages "node:lts-alpine golang:alpine"

    # https://www.linuxjournal.com/content/parallel-shells-xargs-utilize-all-your-cpu-cores-unix-and-windows
    # nproc: the number of installed processors
    # --ignore=N if possible, exclude N processing units
    echo "$@" | xargs -P "$(nproc --ignore=1)" -n1 docker pull

    # for dockerImage in "$@"; do docker pull $dockerImage; done
}

# [Prune unused Docker objects](https://docs.docker.com/config/pruning/)
function dockerRemoveDangling() {
    local list imageTag

    colorEcho "${BLUE}Removing all dangling containers & images..."
    docker system df
    docker system prune

    ## container build cache
    ## list=$(docker ps -a | grep -v 'CONTAINER' | awk '{print $1}')
    # list=$(docker ps -aq --filter "status=exited" --filter "status=created")
    # if [[ -n "${list}" ]]; then
    #     docker ps -aq --filter "status=exited" --filter "status=created" | xargs -n1 docker rm
    # fi

    # docker builder prune --force
    # docker container prune --force
    # docker image prune --force

    ## local images
    ## The RepoDigest field in the image inspect will have a sha256 reference if you pulled the image from a registry
    ## list=$(docker images --format "{{.Repository}}" | grep '_')
    # list=$(docker images --filter "dangling=false" --format "{{.Repository}}:{{.Tag}}" \
    #     | grep -v ':<none>' \
    #     | xargs -n1 docker image inspect \
    #         --format '{{if .RepoTags}}{{index .RepoTags 0}}{{end}} {{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' \
    #     | grep -v '@' | sed 's/\s//g')
    # if [[ -n "${list}" ]]; then
    #     while read -r imageTag; do
    #         docker rmi "${imageTag}"
    #     done <<<"${list}"
    # fi
}

function dockerForceRemoveDangling() {
    local list imageTag

    colorEcho "${BLUE}Removing all dangling containers & images..."
    docker system df
    docker system prune --force
}

# Relocating the Docker root directory
# docker info -f '{{ .DockerRootDir}}' # /var/lib/docker
function dockerRelocateRoot() {
    local DATA_ROOT=$1

    if [[ ! -x "$(command -v jq)" ]]; then
        colorEcho "${FUCHSIA}jq${RED} is not installed!"
        return 1
    fi

    [[ -z "${DATA_ROOT}" ]] && DATA_ROOT="/data/docker"
    sudo mkdir -p "${DATA_ROOT}"
    
    [[ ! -f "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    jq -r ".\"data-root\"=[${DATA_ROOT}]" "/etc/docker/daemon.json" \
        | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

    [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"
    sudo systemctl daemon-reload && sudo systemctl restart docker
}

# [How to Secure a Docker Host Using Firewalld](https://dev.to/soerenmetje/how-to-secure-a-docker-host-using-firewalld-2joo)
function dockerSetFirewalld() {
    local if_default if_docker

    if ! sudo firewall-cmd --state >/dev/null 2>&1; then
        # sudo pacman -S firewalld
        colorEcho "${FUCHSIA}firewalld${RED} is not running!"
        return 1
    fi

    [[ ! -f "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    # jq -r ".\"iptables\"=false" "/etc/docker/daemon.json" | jq -r ".\"ipv6\"=false" | sudo tee "/etc/docker/daemon_temp.json" >/dev/null
    jq -r ".\"iptables\"=false" "/etc/docker/daemon.json" | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

    [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"

    # Masquerading allows for docker ingress and egress (this is the juicy bit)
    sudo firewall-cmd --zone=public --add-masquerade --permanent
    # sudo firewall-cmd --zone=docker --add-masquerade --permanent
    # sudo firewall-cmd --zone=trusted --add-masquerade --permanent

    # Show interfaces to find out docker interface name
    # Show interfaces to find out network interface name with your public IP
    # ip link show && ip addr
    if_default=$(ip route 2>/dev/null | grep default | sed -e "s/^.*dev.//" | awk '{print $1}' | head -n1)
    if_docker=$(ip route 2>/dev/null | grep docker | sed -e "s/^.*dev.//" | awk '{print $1}' | head -n1)

    # Assumes docker interface is docker0
    sudo firewall-cmd --permanent --zone=trusted --add-interface="${if_docker:-docker0}"

    # Assumes network interface with your public IP is eth0
    sudo firewall-cmd --permanent --zone=public --add-interface="${if_default:-eth0}"

    # Open Firewall Ports 80, 443
    sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
    sudo firewall-cmd --permanent --zone=public --add-port=443/tcp

    # Reload docker service
    sudo systemctl daemon-reload && sudo systemctl restart docker

    # Reload firewall to apply permanent rules
    sudo firewall-cmd --reload

    # List Firewall Ports
    # sudo firewall-cmd --permanent --zone=public --list-ports
    echo ""
    sudo firewall-cmd --get-active-zones

    echo ""
    sudo firewall-cmd --get-active-policies

    echo ""
    sudo firewall-cmd --list-all

    ## docker bridge network
    # docker network create "frontend" -d bridge -o com.docker.network.bridge.name="br-frontend" --label="permanent=true"
    # docker network create "backend" -d bridge -o com.docker.network.bridge.name="br-backend" --label="permanent=true"
    # sudo firewall-cmd --permanent --zone=docker --add-interface="br-frontend"
    # sudo firewall-cmd --permanent --zone=docker --add-interface="br-backend"
    # sudo firewall-cmd --reload

    # ip -br a
    # docker network ls
    # docker network inspect frontend
    # sudo firewall-cmd --info-zone docker
    # sudo firewall-cmd --zone=docker --list-all
    # sudo firewall-cmd --info-zone trusted
    # sudo firewall-cmd --zone=trusted --list-all
    # sudo firewall-cmd --list-all-zones
}
