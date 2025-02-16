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

App_Installer_Reset

# [Miniforge](https://github.com/conda-forge/miniforge)
colorEcho "${BLUE}Installing ${FUCHSIA}Miniforge${BLUE}..."

MINIFORGE_FILENAME="Miniforge3-$(uname)-$(uname -m).sh"

if [[ ! -d "$HOME/miniforge3" ]]; then
    INSTALLER_DOWNLOAD_URL="https://github.com/conda-forge/miniforge/releases/latest/download/${MINIFORGE_FILENAME}"
    wget -O "${WORKDIR}/Miniforge3.sh" -c "${INSTALLER_DOWNLOAD_URL}" && \
        bash "${WORKDIR}/Miniforge3.sh" -b -p "$HOME/miniforge3"
fi

if [[ -d "$HOME/miniforge3" ]]; then
    export PATH=$PATH:$HOME/miniforge3/condabin
    source "$HOME/miniforge3/bin/activate"

    # conda mirror
    setMirrorConda

    ## Use default channels
    # mamba config --remove-key channels
    # rm "$HOME/.condarc"

    ## clean channels cache
    # mamba clean -i

    mamba update -y --all

    # mamba info
    # mamba update -y conda
    # mamba install <PackageName>
    # mamba update <PackageName>
    # mamba update -y --all

    # mamba clean --tarballs
    # mamba clean --all

    # mamba config --set show_channel_urls yes
    mamba config --set auto_activate_base false

    DEFALUT_SHELL=$(basename "$SHELL")
    mamba init "${DEFALUT_SHELL}"

    # mamba create -n py312 python=3.12
    # mamba activate py12
    # mamba deactivate
fi
