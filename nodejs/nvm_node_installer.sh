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

# Node Version Manager: https://github.com/nvm-sh/nvm
APP_INSTALL_NAME="nvm"
GITHUB_REPO_NAME="nvm-sh/nvm"

colorEcho "${BLUE}Installing ${FUCHSIA}nvm & nodejs${BLUE}..."
if [[ ! -d "$HOME/.nvm" ]]; then
    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(wget -qO- $CHECK_URL | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if [[ -n "$REMOTE_VERSION" ]]; then
        curl -fsSL -o- "https://raw.githubusercontent.com/${GITHUB_REPO_NAME}/v$REMOTE_VERSION/install.sh" | bash
    fi
fi

if [[ -d "$HOME/.nvm" ]]; then
    if type 'nvm' 2>/dev/null | grep -q 'function'; then
        :
    else
        export NVM_DIR="$HOME/.nvm"
        [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    fi
fi

# Install nodejs
if [[ "$(command -v nvm)" ]]; then
    if [[ ! "$(command -v node)" ]]; then
        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            colorEcho "${BLUE}Installing ${FUCHSIA}node LTS${BLUE}..."
            NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node nvm install --lts

            colorEcho "${BLUE}Installing ${FUCHSIA}node latest${BLUE}..."
            NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node nvm install node
        else
            colorEcho "${BLUE}Installing ${FUCHSIA}node LTS${BLUE}..."
            nvm install --lts

            colorEcho "${BLUE}Installing ${FUCHSIA}node latest${BLUE}..."
            nvm install node
        fi

        # nvm use node
        # nvm alias default node

        nvm use --lts
        nvm alias default 'lts/*'

        ## Fix node & npm not found
        # [ -L "/usr/bin/node" ] && sudo rm -f /usr/bin/node
        # [ -L "/usr/bin/npm" ] && sudo rm -f /usr/bin/npm
        # sudo ln -s "$(which node)" /usr/bin/node && sudo ln -s "$(which npm)" /usr/bin/npm
    fi
fi

if [[ -x "$(command -v npm)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]] && \
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh"

    if [[ ! -x "$(command -v npm-check)" ]]; then
        colorEcho "${BLUE}Installing ${FUCHSIA}npm-check${BLUE}..."
        npm install -g npm-check
    fi
fi
