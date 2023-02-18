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

# ag: A code-searching tool similar to ack, but faster
# https://github.com/ggreer/the_silver_searcher
if [[ ! -x "$(command -v ag)" ]]; then
    PackagesList=(
        silversearcher-ag
        the_silver_searcher
        silver-searcher
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi

# Pre-requisite packages
# PackagesList=(
#     automake
#     gcc
#     pkg-config
#     pkgconfig
#     libpcre3-dev
#     liblzma-dev
#     pcre
#     pcre-devel
#     xz
#     xz-devel
#     zlib1g-dev
#     zlib-devel
# )
# for TargetPackage in "${PackagesList[@]}"; do
#     if checkPackageNeedInstall "${TargetPackage}"; then
#         colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
#         sudo pacman --noconfirm -S "${TargetPackage}"
#     fi
# done

# [[ ! -x "$(command -v ag)" && -x "$(command -v rtx)" ]] && rtx global ag@latest
# [[ ! -x "$(command -v ag)" && "$(command -v asdf)" ]] && asdf_App_Install ag
