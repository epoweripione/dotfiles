#!/usr/bin/env bash

# docker mirrors
## https://github.com/docker-practice/docker-registry-cn-mirror-test/actions
#     sudo tee /etc/docker/daemon.json >/dev/null <<-'EOF'
# {
#     "registry-mirrors": [
#         "https://dockerproxy.com",
#         "https://docker.mirrors.sjtug.sjtu.edu.cn",
#         "https://hub-mirror.c.163.com"
#     ]
# }
# EOF

## fix
## curl: (35) error:1414D172:SSL routines:tls12_check_peer_sigalg:wrong signature type
## https: SSLError(SSLError(1, '[SSL: WRONG_SIGNATURE_TYPE] wrong signature type (_ssl.c:1123)'))
# sudo sed -i 's/CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=1/' /etc/ssl/openssl.cnf

## testing
# https GET "https://mirror.baidubce.com/v2/library/nginx/tags/list"
# ht GET "https://hub-mirror.c.163.com/v2/library/nginx/tags/list"
# curl -ikL -X GET "https://docker.mirrors.sjtug.sjtu.edu.cn/v2/library/nginx/tags/list"
# curl -ikL -X GET "https://docker.mirrors.sjtug.sjtu.edu.cn/v2/library/nginx/manifests/latest"

# jq -r '."registry-mirrors"=."registry-mirrors" + ["https://hub-mirror.c.163.com"]' "/etc/docker/daemon.json" | sudo tee "/etc/docker/daemon_temp.json" >/dev/null
# jq -r 'del(."registry-mirrors")' "/etc/docker/daemon.json" | sudo tee "/etc/docker/daemon_temp.json" >/dev/null
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

    [[ ! -s "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    jq -r ".\"registry-mirrors\"=[${REGISTRY_MIRRORS}]" "/etc/docker/daemon.json" \
        | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

    [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"

    colorEcho "${BLUE}Restarting docker service..."
    sudo systemctl daemon-reload && sudo systemctl restart docker
}

# clear mirrors
function dockerClearMirrors() {
    if [[ -s "/etc/docker/daemon.json" ]]; then
        jq -r 'del(."registry-mirrors")' "/etc/docker/daemon.json" | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

        [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"
        sudo systemctl daemon-reload && sudo systemctl restart docker
    fi
}

# remove unuse mirrors
function dockerRemoveUnuseMirrors() {
    local UNUSE_MIRRORS REMOVE_MIRRORS Target

    [[ ! -s "/etc/docker/daemon.json" ]] && return 0

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

# docker proxy
function dockerSetProxy() {
    if [[ -n "${HTTP_PROXY}" && -n "${HTTPS_PROXY}" && -n "${NO_PROXY}" ]]; then
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
}

# container runtime proxy
function dockerSetContainerProxy() {
    if [[ -n "${HTTP_PROXY}" && -n "${HTTPS_PROXY}" && -n "${NO_PROXY}" ]]; then
        mkdir -p "$HOME/.docker"
        tee "$HOME/.docker/config.json" >/dev/null <<-EOF
{
    "proxies":
    {
        "default":
        {
            "httpProxy": "${HTTP_PROXY}",
            "httpsProxy": "${HTTPS_PROXY}",
            "noProxy": "${NO_PROXY}"
        }
    }
}
EOF
    fi
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
    
    [[ ! -s "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    jq -r ".\"data-root\"=[${DATA_ROOT}]" "/etc/docker/daemon.json" \
        | sudo tee "/etc/docker/daemon_temp.json" >/dev/null

    [[ -f "/etc/docker/daemon_temp.json" ]] && sudo mv -f "/etc/docker/daemon_temp.json" "/etc/docker/daemon.json"
    sudo systemctl daemon-reload && sudo systemctl restart docker
}
