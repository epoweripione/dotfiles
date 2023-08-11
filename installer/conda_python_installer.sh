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

# Miniconda
colorEcho "${BLUE}Installing ${FUCHSIA}Miniconda3${BLUE}..."

# mirror channels
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    [[ -z "${MIRROR_PYTHON_CONDA}" ]] && MIRROR_PYTHON_CONDA="https://mirrors.bfsu.edu.cn"
fi

if [[ ! -d "$HOME/miniconda3" ]]; then
    if [[ -n "${MIRROR_PYTHON_CONDA}" ]]; then
        INSTALLER_DOWNLOAD_URL="${MIRROR_PYTHON_CONDA}/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    else
        INSTALLER_DOWNLOAD_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    fi
    wget -O "${WORKDIR}/Miniconda3.sh" -c "${INSTALLER_DOWNLOAD_URL}" && \
        bash "${WORKDIR}/Miniconda3.sh" -b -p "$HOME/miniconda3"
fi

if [[ -d "$HOME/miniconda3" ]]; then
    export PATH=$PATH:$HOME/miniconda3/condabin
    source "$HOME/miniconda3/bin/activate"

    ## Use mirror channels
    if [[ -n "${MIRROR_PYTHON_CONDA}" && ! -s "$HOME/.condarc" ]]; then
        # conda config --add channels ${MIRROR_PYTHON_CONDA}/anaconda/pkgs/main/
        # conda config --add channels ${MIRROR_PYTHON_CONDA}/anaconda/cloud/pytorch/
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
    # conda config --remove-key channels
    # rm "$HOME/.condarc"

    ## clean channels cache
    # conda clean -i

    conda update -y --all

    ## Use conda
    ## https://conda.io/docs/user-guide/getting-started.html
    ## https://conda.io/docs/_downloads/conda-cheatsheet.pdf
    # conda info
    # conda update -y conda
    # conda install <PackageName>
    # conda update <PackageName>
    # conda update -y --all

    # conda clean --tarballs
    # conda clean --all

    # conda config --set show_channel_urls yes
    conda config --set auto_activate_base false

    DEFALUT_SHELL=$(basename "$SHELL")
    conda init "${DEFALUT_SHELL}"

    # conda create -n py38 python=3.8
    # conda activate py38
    # conda deactivate

    # conda create -n py27 python=2.7
    # conda activate py27
    # conda deactivate

    ## pip updates
    # pip list --outdated

    ## https://pypi.org/project/pip-review/
    pip install pip-review
    # pip-review --auto
    # pip-review --local --interactive

    ## Fix:
    ## Cannot uninstall ‘xxx’.
    ## It is a distutils installed project and thus we cannot accurately determine 
    ## which files belong to it which would lead to only a partial uninstall.
    # pip install -U --ignore-installed xxx
fi


# [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/python_pip_config.sh" ]] && \
#     source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/python_pip_config.sh"
