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

# [oh-my-posh: A prompt theme engine for any shell](https://github.com/JanDeDobbeleer/oh-my-posh)
INSTALLER_GITHUB_REPO="JanDeDobbeleer/oh-my-posh"
INSTALLER_BINARY_NAME="oh-my-posh"
INSTALLER_MATCH_PATTERN="posh*"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_BINARY_NAME} --version 2>/dev/null | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_BINARY_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    INSTALLER_ADDON_FILES=(
        "${INSTALLER_BINARY_NAME}-themes.zip#https://github.com/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/themes.zip#"
    )

    if installPrebuiltBinary "${INSTALLER_BINARY_NAME}" "${INSTALLER_GITHUB_REPO}" "${INSTALLER_MATCH_PATTERN}"; then
        if [[ -f "${WORKDIR}/${INSTALLER_BINARY_NAME}-themes.zip" ]]; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_BINARY_NAME} ${YELLOW}themes${BLUE}..."
            mkdir -p "$HOME/.poshthemes"

            unzip -qo "${WORKDIR}/${INSTALLER_BINARY_NAME}-themes.zip" -d "$HOME/.poshthemes" && chmod u+rw "$HOME"/.poshthemes/*.json

            cp -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/powershell/themes/"*.omp.json "$HOME/.poshthemes" 2>/dev/null
        fi
    fi

    ## config
    # bash
    if ! grep -q "oh-my-posh init" "$HOME/.bashrc" 2>/dev/null; then
        sed -i '/oh-my-posh --init/d' "$HOME/.bashrc"

        {
            echo ''
            echo 'if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then'
            echo '  # eval "$(oh-my-posh init bash --config ~/.poshthemes/powerlevel10k_my.omp.json)"'
            echo '  eval "$(oh-my-posh init bash --config ~/.poshthemes/atomic_my.omp.json)"'
            echo 'fi'
        } >> "$HOME/.bashrc"
    fi

    # zsh
    if ! grep -q "oh-my-posh init" "$HOME/.zshrc" 2>/dev/null; then
        sed -i '/oh-my-posh --init/d' "$HOME/.zshrc"

        {
            echo ''
            echo 'if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then'
            echo '  # eval "$(oh-my-posh init zsh --config ~/.poshthemes/powerlevel10k_my.omp.json)"'
            echo '  eval "$(oh-my-posh init bash --config ~/.poshthemes/atomic_my.omp.json)"'
            echo 'fi'
        } >> "$HOME/.zshrc"
    fi
fi

## Preview the themes
# for file in ~/.poshthemes/*.omp.json; do echo "$file\n"; oh-my-posh --config $file --shell universal; echo "\n"; done;

## nushell
# config set prompt "(oh-my-posh --config ~/.poshthemes/powerlevel10k_rainbow.omp.json | str collect)"

## powershell
# oh-my-posh --init --shell pwsh --config /.poshthemes/powerlevel10k_rainbow.omp.json | Invoke-Expression
