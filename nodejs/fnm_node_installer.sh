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

# [fnm - Fast and simple Node.js version manager, built in Rust](https://github.com/Schniz/fnm)
INSTALLER_APP_NAME="fnm"
INSTALLER_GITHUB_REPO="Schniz/fnm"

INSTALLER_BINARY_NAME="fnm"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    App_Installer_Get_Remote_Version
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

# Load fnm
if [[ ! -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    FNM_PATH="$HOME/.local/share/fnm"
    if [ -d "${FNM_PATH}" ]; then
        export PATH="${FNM_PATH}:$PATH"
        [[ "${THE_WORLD_BLOCKED}" == "true" ]] && export FNM_NODE_DIST_MIRROR="https://npmmirror.com/mirrors/node"
        eval "$(fnm env --use-on-cd)"
    fi
fi

# migrate from nvm to fnm
if type 'nvm' 2>/dev/null | grep -q 'function'; then
    installed_node_version=()
    nvm_ls_output=$(nvm ls --no-colors | grep -E '^[[:space:]\-]+' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
    while read -r line; do
        nvm_version=$(cut -d'.' -f1 <<<"${line}")
        installed_node_version+=("${nvm_version}")
        fnm install "${nvm_version}"
    done <<<"${nvm_ls_output}"

    # reinstall global packages from nvm to fnm
    nvm_default_version=$(nvm version default)
    if [[ "${nvm_default_version}" != "N/A" ]]; then
        # nvm_global_packages=$(npm list --global --depth=0 --json | jq -r '.dependencies | keys[]' 2>/dev/null | grep -Ev '^(npm|corepack)$')
        nvm_global_packages=$(npm list --global --depth=0 --json | jq -r '.dependencies | keys[]' 2>/dev/null | grep -Ev '^npm$')
        for version in "${installed_node_version[@]}"; do
            colorEcho "${BLUE}Installing global packages for ${FUCHSIA}Nodejs ${YELLOW}$version${BLUE}..."
            fnm use "${version}"
            for package in ${nvm_global_packages}; do
                npm install --global "${package}"
            done
        done
    fi

    # remove nvm
    sed -i '/NVM_DIR/s/^#*\s*/# /g' "$HOME/.bashrc" "$HOME/.zshrc" 2>/dev/null
    rm -rf "$HOME/.nvm"
fi

# Install lts and latest nodejs
if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" && ! "$(command -v node)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}Nodejs ${YELLOW}LTS${BLUE}..."
    fnm install --lts --corepack-enabled

    colorEcho "${BLUE}Installing ${FUCHSIA}Nodejs ${YELLOW}latest${BLUE}..."
    fnm install --latest --corepack-enabled

    fnm default lts-latest
    fnm use lts-latest
fi

if [[ -x "$(command -v npm)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]] && \
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh"

    npm_Global_Upgrade
fi

cd "${CURRENT_DIR}" || exit