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

[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    [[ -z "${MIRROR_LYX_BASE}" ]] && MIRROR_LYX_BASE="https://mirrors.tuna.tsinghua.edu.cn/lyx/"
fi

# [LyX](https://www.lyx.org/Home)
colorEcho "${BLUE}Installing ${FUCHSIA}LyX${BLUE}..."
if [[ -n "${MIRROR_LYX_BASE}" ]]; then
    cd "${WORKDIR}" && yay -G lyx
    if [[ -s "${WORKDIR}/lyx/PKGBUILD" ]]; then
        # sed "s|https://ftp.lip6.fr/pub/lyx/|${MIRROR_LYX_BASE}|g" "${WORKDIR}/lyx/PKGBUILD" > "${WORKDIR}/lyx/PKGBUILD.new"
        # diff -u "${WORKDIR}/lyx/PKGBUILD" "${WORKDIR}/lyx/PKGBUILD.new" > "${WORKDIR}/lyx/PKGBUILD.patch"
        # patch -u "${WORKDIR}/lyx/PKGBUILD" -i "${WORKDIR}/lyx/PKGBUILD.patch"
        sed -i "s|https://ftp.lip6.fr/pub/lyx/|${MIRROR_LYX_BASE}|g" "${WORKDIR}/lyx/PKGBUILD"
        # updpkgsums
        # yay -S lyx --answerdiff=None --noremovemake --pgpfetch --answerclean=None --noconfirm --asdeps
        makepkg -si
    fi
else
    yay --noconfirm --needed -S lyx
fi

cd "${CURRENT_DIR}" || exit