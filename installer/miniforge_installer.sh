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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# [Miniforge](https://github.com/conda-forge/miniforge)
colorEcho "${BLUE}Installing ${FUCHSIA}Miniforge${BLUE}..."

MINIFORGE_FILENAME="Miniforge3-$(uname)-$(uname -m).sh"

if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    [[ -z "${MIRROR_PYTHON_CONDA}" ]] && MIRROR_PYTHON_CONDA="https://mirror.sjtu.edu.cn"
    [[ -z "${MIRROR_PYTHON_MINIFORGE}" ]] && MIRROR_PYTHON_MINIFORGE="${MIRROR_PYTHON_CONDA}/github-release/conda-forge/miniforge/LatestRelease/"
fi

if [[ ! -d "$HOME/miniforge3" ]]; then
    if [[ -n "${MIRROR_PYTHON_MINIFORGE}" ]]; then
        INSTALLER_DOWNLOAD_URL="${MIRROR_PYTHON_MINIFORGE}/${MINIFORGE_FILENAME}"
    else
        INSTALLER_DOWNLOAD_URL="https://github.com/conda-forge/miniforge/releases/latest/download/${MINIFORGE_FILENAME}"
    fi
    wget -O "${WORKDIR}/Miniforge3.sh" -c "${INSTALLER_DOWNLOAD_URL}" && \
        bash "${WORKDIR}/Miniforge3.sh" -b -p "$HOME/miniforge3"
fi

if [[ -d "$HOME/miniforge3" ]]; then
    export PATH=$PATH:$HOME/miniforge3/condabin
    source "$HOME/miniforge3/bin/activate"

    ## Use mirror channels
    if [[ -n "${MIRROR_PYTHON_CONDA}" && ! -s "$HOME/.condarc" ]]; then
        # mamba config --add channels ${MIRROR_PYTHON_CONDA}/anaconda/pkgs/main/
        # mamba config --add channels ${MIRROR_PYTHON_CONDA}/anaconda/cloud/pytorch/
        tee -a "$HOME/.condarc" >/dev/null <<-EOF
channels:
  - defaults
show_channel_urls: true
default_channels:
  - ${MIRROR_PYTHON_CONDA}/anaconda/pkgs/main
  - ${MIRROR_PYTHON_CONDA}/anaconda/pkgs/r
  - ${MIRROR_PYTHON_CONDA}/anaconda/pkgs/msys2
custom_channels:
  conda-forge: ${MIRROR_PYTHON_CONDA}/anaconda/cloud
  msys2: ${MIRROR_PYTHON_CONDA}/anaconda/cloud
  bioconda: ${MIRROR_PYTHON_CONDA}/anaconda/cloud
  menpo: ${MIRROR_PYTHON_CONDA}/anaconda/cloud
  pytorch: ${MIRROR_PYTHON_CONDA}/anaconda/cloud
  simpleitk: ${MIRROR_PYTHON_CONDA}/anaconda/cloud
EOF
    fi

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

# [Micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)
"${SHELL}" <(curl -L micro.mamba.pm/install.sh)
