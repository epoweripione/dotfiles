#!/usr/bin/env bash

# docker mirrors
function Set_Docker_Mirrors() {
    local REGISTRY_MIRRORS=$1

    if [[ ! -x "$(command -v jq)" ]]; then
        colorEcho "${FUCHSIA}jq${RED} is not installed!"
        return 1
    fi

    [[ -z "${REGISTRY_MIRRORS}" ]] && \
        REGISTRY_MIRRORS='"https://ustc-edu-cn.mirror.aliyuncs.com","https://docker.mirrors.sjtug.sjtu.edu.cn","https://mirror.baidubce.com","https://hub-mirror.c.163.com"'

    colorEcho "${BLUE}Setting docker registry-mirrors to:"
    colorEcho "${FUCHSIA}  ${REGISTRY_MIRRORS}"

    [[ ! -s "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    cat "/etc/docker/daemon.json" \
        | jq -r ".\"registry-mirrors\"=[${REGISTRY_MIRRORS}]" \
        | sudo tee "/etc/docker/daemon.json" >/dev/null

    colorEcho "${BLUE}Restarting docker service:"
    sudo systemctl daemon-reload && sudo systemctl restart docker
}

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
