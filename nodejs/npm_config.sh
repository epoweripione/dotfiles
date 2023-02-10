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


if [[ ! -x "$(command -v npm)" ]]; then
    colorEcho "${FUCHSIA}npm${RED} is not installed!"
    exit 0
fi

# npm config
colorEcho "${BLUE}Setting npm config..."
# npm config set user 0
# npm config set unsafe-perm true

## npm global
# NPM_PREFIX=$(npm config get prefix 2>/dev/null)
# if ! echo "${NPM_PREFIX}" | grep -q "\.asdf/installs/nodejs"; then
#     mkdir -p "$HOME/.npm-global"
#     npm config set prefix "$HOME/.npm-global"
#     export PATH="$PATH:$HOME/.npm-global/bin"
# fi

CONFIG_ACTION=${1:-"AUTO"}

# Change npm registry to taobao
if [[ "${CONFIG_ACTION}" == "AUTO" && "${THE_WORLD_BLOCKED}" == "true" ]]; then
    colorEcho "${BLUE}Change npm registry to npmmirror.com..."
    npm config set registry https://registry.npmmirror.com

    # npm config set disturl https://npmmirror.com/dist # node-gyp
    # npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass # node-sass
    # npm config set electron_mirror https://npmmirror.com/mirrors/electron/ # electron
    # npm config set puppeteer_download_host https://npmmirror.com/mirrors # puppeteer
    # npm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver # chromedriver
    # npm config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver # operadriver
    # npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs # phantomjs
    # npm config set selenium_cdnurl https://npmmirror.com/mirrors/selenium # selenium
    # npm config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector # node-inspector
fi

if [[ "${CONFIG_ACTION}" == "RESET" ]]; then
    colorEcho "${BLUE}Reset npm registry (npmjs.org)..."
    npm config set registry https://registry.npmjs.org/

    # npm config delete disturl
    # npm config delete sass_binary_site
    # npm config delete electron_mirror
    # npm config delete puppeteer_download_host
    # npm config delete chromedriver_cdnurl
    # npm config delete operadriver_cdnurl
    # npm config delete phantomjs_cdnurl
    # npm config delete selenium_cdnurl
    # npm config delete node_inspector_cdnurl
fi


# pnpm
if [[ -x "$(command -v pnpm)" ]]; then
    PNPM_STORE=$(pnpm config get store-dir)
    if [[ -z "${PNPM_STORE}" ]]; then
        colorEcho "${BLUE}Setting pnpm store dir..."
        mkdir -p "$HOME/.pnpm-store"
        pnpm config set store-dir "$HOME/.pnpm-store"
    fi
fi


## show all defaults
# npm config ls -l
npm config list
