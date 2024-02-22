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

APPS_DATA_ROOT=${1:-"/data"}

[[ ! -d "${APPS_DATA_ROOT}" ]] && colorEcho "${FUCHSIA}${APPS_DATA_ROOT}${RED} doesn't exist!" && exit 1

# jq
[[ ! -x "$(command -v jq)" ]] && PackagesList=(jq) && InstallSystemPackages "" "${PackagesList[@]}"

# Docker
# Relocating the Docker root directory
# docker info -f '{{ .DockerRootDir}}' # /var/lib/docker
if [[ -x "$(command -v docker)" ]]; then
    DATA_ROOT="${APPS_DATA_ROOT}/docker" && sudo mkdir -p "${DATA_ROOT}"
    [[ ! -s "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    jq -r ".\"data-root\"=[${DATA_ROOT}]" "/etc/docker/daemon.json" \
        | sudo tee "/etc/docker/daemon.json" >/dev/null

    sudo systemctl daemon-reload && sudo systemctl restart docker
fi

# KVM & QEMU
# Change default location of libvirt VM images
# Defalut ISO image at: /var/lib/libvirt/images
if [[ -x "$(command -v virsh)" ]]; then
    DATA_ROOT="${APPS_DATA_ROOT}/libvirt/images" && sudo mkdir -p "${DATA_ROOT}"

    # run `virt-manager` once to create `default` pool
    sudo virt-manager

    sudo virsh pool-dumpxml default | tee "${WORKDIR}/libvirt_pool.xml" >/dev/null

    sed -i "s|/var/lib/libvirt/images|${DATA_ROOT}|" "${WORKDIR}/libvirt_pool.xml"

    sudo virsh pool-destroy default && sudo virsh pool-create "${WORKDIR}/libvirt_pool.xml"
fi


cd "${CURRENT_DIR}" || exit
