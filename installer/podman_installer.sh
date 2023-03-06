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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type

# [Podman](https://github.com/containers/podman)
# [Podman Installation Instructions](https://podman.io/getting-started/installation)
APP_INSTALL_NAME="podman"

if [[ ! -x "$(command -v podman)" ]]; then
    if [[ "${OS_INFO_TYPE}" == "darwin" ]]; then
        if [[ -x "$(command -v brew)" ]]; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."
            brew install "${APP_INSTALL_NAME}"
        fi
    elif [[ -x "$(command -v pacman)" ]]; then
        if check_os_arch; then
            PackagesList=(
                "podman"
                "cni-plugins"
                "buildah"
                "skopeo"
                "podman-docker"
                "podman-compose"
                # "podman-desktop"
            )
        else
            PackagesList=(
                "podman"
                "buildah"
                "skopeo"
            )
        fi

        for TargetPackage in "${PackagesList[@]}"; do
            if checkPackageNeedInstall "${TargetPackage}"; then
                colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
                sudo pacman --noconfirm -S "${TargetPackage}"
            fi
        done
    fi
fi

# registries
SET_REGISTRY_MIRROR="N"
if [[ "${THE_WORLD_BLOCKED}" == "true" && -s "/etc/containers/registries.conf" && ! -s "/etc/containers/registries.conf.backup" ]]; then
    SET_REGISTRY_MIRROR="Y"
    sudo cp "/etc/containers/registries.conf" "/etc/containers/registries.conf.backup"
    echo '' | sudo tee "/etc/containers/registries.conf" >/dev/null
fi

if [[ "${SET_REGISTRY_MIRROR}" == "y" || "${SET_REGISTRY_MIRROR}" == "Y" ]]; then
    sudo tee -a "/etc/containers/registries.conf" >/dev/null <<-'EOF'
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "docker.mirrors.sjtug.sjtu.edu.cn"

[[registry.mirror]]
location = "hub-mirror.c.163.com"

[[registry.mirror]]
location = "ghcr.io"
EOF
fi

# [Run containers on Linux without sudo in Podman](https://opensource.com/article/22/1/run-containers-without-sudo-podman)
if [[ $UID -ne 0 ]]; then
    # cat /etc/subuid /etc/subgid
    # sudo usermod --add-subuids 10000-75535 --add-subgids 10000-75535 "$USER"
    sudo usermod --add-subuids 200000-265535 --add-subgids 200000-265535 "$USER"

    MAX_USER_NAMESPACES=$(sysctl --all --pattern user_namespaces | cut -d= -f2 | sed 's/ //g')
    if [[ ${MAX_USER_NAMESPACES} -lt 10000 ]]; then
        echo 'user.max_user_namespaces=28633' | sudo tee "/etc/sysctl.d/91-max_user_namespaces.conf" >/dev/null
        sudo sysctl -p "/etc/sysctl.d/91-max_user_namespaces.conf"
    fi
fi

# sudo reboot

## create and start your first Podman machine
# podman machine init
# podman machine start

## verify the installation information
# podman info
