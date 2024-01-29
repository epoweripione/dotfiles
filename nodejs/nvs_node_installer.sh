#!/usr/bin/env bash

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


colorEcho "${BLUE}Installing ${FUCHSIA}nvs & nodejs${BLUE}..."
## Install nvs
# https://github.com/jasongin/nvs
if [[ ! -d "$HOME/.nvs" ]]; then
    export NVS_HOME="$HOME/.nvs"
    git clone https://github.com/jasongin/nvs --depth=1 "$NVS_HOME"
    . "$NVS_HOME/nvs.sh" install
fi

if [[ -d "$HOME/.nvs" ]]; then
    if type 'nvs' 2>/dev/null | grep -q 'function'; then
        :
    else
        export NVS_HOME="$HOME/.nvs"
        [ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"
    fi

    if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
        nvs remote node "${NVS_NODEJS_ORG_MIRROR:-"https://npmmirror.com/mirrors/node"}"
    fi
fi

## Install nodejs
if type 'nvs' 2>/dev/null | grep -q 'function'; then
    if [[ ! "$(command -v node)" ]]; then
        colorEcho "${BLUE}Installing ${FUCHSIA}node LTS${BLUE}..."
        nvs add lts

        colorEcho "${BLUE}Installing ${FUCHSIA}node latest${BLUE}..."
        nvs add latest

        # nvs use latest
        # nvs link latest

        nvs use lts
        nvs link lts
    fi
fi

if [[ -x "$(command -v npm)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]] && \
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh"

    if [[ ! -x "$(command -v npm-check)" ]]; then
        colorEcho "${BLUE}Installing ${FUCHSIA}npm-check${BLUE}..."
        npm install -g npm-check
    fi

    if [[ ! -x "$(command -v pnpm)" ]]; then
        colorEcho "${BLUE}Installing ${FUCHSIA}pnpm${BLUE}..."
        npm install -g pnpm
    fi
fi
