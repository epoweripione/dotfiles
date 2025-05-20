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

# Poetry: Dependency Management for Python
# https://python-poetry.org/
INSTALLER_APP_NAME="poetry"
INSTALLER_GITHUB_REPO="python-poetry/poetry"

INSTALLER_INSTALL_NAME="poetry"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if [[ -x "$(command -v pacman)" ]]; then
        # Pre-requisite packages
        PackagesList=(
            python3-venv
        )
        InstallSystemPackages "" "${PackagesList[@]}"
    fi

    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    curl -sSL https://install.python-poetry.org | python3 -
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" && -x "$(command -v poetry)" ]]; then
    export PATH=$PATH:$HOME/.poetry/bin
    if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}" ]]; then
        mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/poetry" && \
            poetry completions zsh > "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/poetry/_poetry"
    fi
fi

# poetry config --list

## pip mirror
# tee -a "$PWD/pyproject.toml" <<-'EOF'
# [[tool.poetry.source]]
# name = "aliyun"
# url = "https://mirrors.aliyun.com/pypi/simple/"
# default = true
# EOF

## windows powershell
# (Invoke-WebRequest -Uri https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py -UseBasicParsing).Content | python -
