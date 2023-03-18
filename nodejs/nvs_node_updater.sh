#!/usr/bin/env bash

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


if [[ -d "$HOME/.nvs" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}nvs${BLUE}..."
    if type 'nvs' 2>/dev/null | grep -q 'function'; then
        :
    else
        export NVS_HOME="$HOME/.nvs"
        [ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"
    fi

    INSTALLER_CHECK_URL="https://api.github.com/repos/jasongin/nvs/releases/latest"

    INSTALLER_VER_CURRENT=$(nvs --version)
    INSTALLER_VER_REMOTE=$(wget -qO- "${INSTALLER_CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        cd "$NVS_HOME" && git pull
    fi

    colorEcho "${BLUE}Updating ${FUCHSIA}node LTS${BLUE}..."
    nvs upgrade lts

    colorEcho "${BLUE}Updating ${FUCHSIA}node latest${BLUE}..."
    nvs upgrade latest
fi


if [[ -x "$(command -v npm-check)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}npm global packages${BLUE}..."
    npm-check -u -g -y
elif [[ -x "$(command -v npm)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}npm global packages${BLUE}..."
    npm update --location=global
fi


if [[ -x "$(command -v yarn)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}yarn global packages${BLUE}..."
    yarn global upgrade --latest
fi


cd "${CURRENT_DIR}" || exit