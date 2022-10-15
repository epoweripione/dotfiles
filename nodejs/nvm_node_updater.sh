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


if [[ -z "${NVM_NOT_UPDATE}" && -d "$HOME/.nvm" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}nvm${BLUE}..."
    if type 'nvm' 2>/dev/null | grep -q 'function'; then
        :
    else
        export NVM_DIR="$HOME/.nvm"
        source "$NVM_DIR/nvm.sh"
        # export NVM_DIR="${XDG_CONFIG_HOME:-$HOME}/.nvm"
        # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    CHECK_URL="https://api.github.com/repos/creationix/nvm/releases/latest"

    CURRENT_VERSION=$(nvm --version)
    REMOTE_VERSION=$(wget -qO- "$CHECK_URL" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_gt "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        curl -fsSL -o- "https://raw.githubusercontent.com/creationix/nvm/v$REMOTE_VERSION/install.sh" | bash
    fi

    NVM_DEFAULT_VERSION=$(nvm version default)
    NVM_LTS_VERSION=$(nvm version 'lts/*')
    NVM_NODE_VERSION=$(nvm version node)

    if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
        colorEcho "${BLUE}Updating ${FUCHSIA}node LTS${BLUE}..."
        if [[ "${NVM_DEFAULT_VERSION}" == "N/A" ]]; then
            NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node nvm install --lts
        else
            NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node nvm install --lts --reinstall-packages-from=default
        fi

        colorEcho "${BLUE}Updating ${FUCHSIA}node latest${BLUE}..."
        if [[ "${NVM_DEFAULT_VERSION}" == "N/A" ]]; then
            NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node nvm install node
        else
            NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node nvm install node --reinstall-packages-from=default
        fi
    else
        colorEcho "${BLUE}Updating ${FUCHSIA}node LTS${BLUE}..."
        if [[ "${NVM_DEFAULT_VERSION}" == "N/A" ]]; then
            nvm install --lts
        else
            nvm install --lts --reinstall-packages-from=default
        fi

        colorEcho "${BLUE}Updating ${FUCHSIA}node latest${BLUE}..."
        if [[ "${NVM_DEFAULT_VERSION}" == "N/A" ]]; then
            nvm install node
        else
            nvm install node --reinstall-packages-from=default
        fi
    fi

    # nvm use node
    # nvm alias default node

    nvm use --lts
    nvm alias default 'lts/*'

    ## Fix node & npm not found
    # [ -L "/usr/bin/node" ] && sudo rm -f /usr/bin/node
    # [ -L "/usr/bin/npm" ] && sudo rm -f /usr/bin/npm
    # sudo ln -s "$(which node)" /usr/bin/node && sudo ln -s "$(which npm)" /usr/bin/npm

    # colorEcho "${BLUE}Getting node LTS version..."
    # CURRENT_VERSION=$(nvm version lts/*)
    # REMOTE_VERSION=$(nvm version-remote lts/*)

    # if version_gt "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
    #     colorEcho "${BLUE}Updating ${FUCHSIA}node LTS${BLUE}..."
    #     nvm install --lts --latest-npm
    # fi

    # colorEcho "${BLUE}Getting node version..."
    # CURRENT_VERSION=$(nvm version)
    # REMOTE_VERSION=$(nvm version-remote)

    # if version_gt "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
    #     colorEcho "${BLUE}Updating ${FUCHSIA}node latest${BLUE}..."
    #     nvm install node --reinstall-packages-from=node --latest-npm
    #     # nvm use node
    #     nvm alias default node
    #     ## Fix node & npm not found
    #     [ -L "/usr/bin/node" ] && rm -f /usr/bin/node
    #     [ -L "/usr/bin/npm" ] && rm -f /usr/bin/npm
    #     ln -s "$(which node)" /usr/bin/node && ln -s "$(which npm)" /usr/bin/npm
    # fi

    # delete old version
    NVM_NEW_LTS_VERSION=$(nvm version 'lts/*')
    if [[ "${NVM_LTS_VERSION}" != "N/A" && "${NVM_NEW_LTS_VERSION}" != "N/A" && "${NVM_LTS_VERSION}" != "${NVM_NEW_LTS_VERSION}" ]]; then
        nvm uninstall "${NVM_LTS_VERSION}"
    fi

    NVM_NEW_NODE_VERSION=$(nvm version node)
    if [[ "${NVM_NODE_VERSION}" != "N/A" && "${NVM_NEW_NODE_VERSION}" != "N/A" && "${NVM_NODE_VERSION}" != "${NVM_NEW_NODE_VERSION}" ]]; then
        nvm uninstall "${NVM_NODE_VERSION}"
    fi
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