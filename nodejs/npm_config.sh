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

# Change npm registry to npmmirror
if [[ "${CONFIG_ACTION}" == "AUTO" && "${THE_WORLD_BLOCKED}" == "true" ]]; then
    colorEcho "${BLUE}Change npm registry to npmmirror.com..."
    npm config set registry "${MIRROR_NODEJS_REGISTRY:-"https://registry.npmmirror.com"}"

    echo "disturl=${MIRROR_NODEJS_DISTURL:-"https://npmmirror.com/dist"}" >> "$HOME/.npmrc" # node-gyp
    echo "sass_binary_site=${MIRROR_NODEJS_SASS_BINARY_SITE:-"https://npmmirror.com/mirrors/node-sass"}" >> "$HOME/.npmrc" # node-sass
    echo "electron_mirror=${MIRROR_NODEJS_ELECTRON_MIRROR:-"https://npmmirror.com/mirrors/electron/"}" >> "$HOME/.npmrc" # electron
    # echo "puppeteer_download_host=${MIRROR_NODEJS_PUPPETEER_DOWNLOAD_HOST:-"https://npmmirror.com/mirrors"}" >> "$HOME/.npmrc" # puppeteer
    echo "puppeteer_download_base_url=${MIRROR_NODEJS_PUPPETEER_DOWNLOAD_BASE_URL:-"https://cdn.npmmirror.com/binaries/chrome-for-testing"}" >> "$HOME/.npmrc" # puppeteer
    echo "chromedriver_cdnurl=${MIRROR_NODEJS_CHROMEDRIVER_CDNURL:-"https://npmmirror.com/mirrors/chromedriver"}" >> "$HOME/.npmrc" # chromedriver
    echo "operadriver_cdnurl=${MIRROR_NODEJS_OPERADRIVER_CDNURL:-"https://npmmirror.com/mirrors/operadriver"}" >> "$HOME/.npmrc" # operadriver
    echo "phantomjs_cdnurl=${MIRROR_NODEJS_PHANTOMJS_CDNURL:-"https://npmmirror.com/mirrors/phantomjs"}" >> "$HOME/.npmrc" # phantomjs
    echo "selenium_cdnurl=${MIRROR_NODEJS_SELENIUM_CDNURL:-"https://npmmirror.com/mirrors/selenium"}" >> "$HOME/.npmrc" # selenium
    echo "node_inspector_cdnurl=${MIRROR_NODEJS_NODE_INSPECTOR_CDNURL:-"https://npmmirror.com/mirrors/node-inspector"}" >> "$HOME/.npmrc" # node-inspector
fi

if [[ "${CONFIG_ACTION}" == "RESET" ]]; then
    colorEcho "${BLUE}Reset npm registry (npmjs.org)..."
    npm config set registry https://registry.npmjs.org/

    npm config delete disturl
    npm config delete sass_binary_site
    npm config delete electron_mirror
    npm config delete puppeteer_download_base_url
    npm config delete chromedriver_cdnurl
    npm config delete operadriver_cdnurl
    npm config delete phantomjs_cdnurl
    npm config delete selenium_cdnurl
    npm config delete node_inspector_cdnurl
fi


## [pnpm](https://pnpm.io/cli/config)
# The local configuration file is located in the root of the project and is named .npmrc.
# The global configuration file is located at one of the following locations:
# If the $XDG_CONFIG_HOME env variable is set, then $XDG_CONFIG_HOME/pnpm/rc
# On Windows: ~/AppData/Local/pnpm/config/rc
# On macOS: ~/Library/Preferences/pnpm/rc
# On Linux: ~/.config/pnpm/rc
if [[ -x "$(command -v pnpm)" ]]; then
    PNPM_STORE=$(pnpm config get store-dir)
    if [[ -z "${PNPM_STORE}" ]]; then
        colorEcho "${BLUE}Setting pnpm store dir..."
        mkdir -p "$HOME/.pnpm-store"
        pnpm config set store-dir "$HOME/.pnpm-store"
    fi

    # if [[ "${CONFIG_ACTION}" == "AUTO" && "${THE_WORLD_BLOCKED}" == "true" ]]; then
    #     colorEcho "${BLUE}Change pnpm registry to npmmirror.com..."
    #     pnpm config set registry https://registry.npmmirror.com

    #     pnpm config set disturl https://npmmirror.com/dist # node-gyp
    #     pnpm config set sass_binary_site https://npmmirror.com/mirrors/node-sass # node-sass
    #     pnpm config set electron_mirror https://npmmirror.com/mirrors/electron/ # electron
    #     pnpm config set puppeteer_download_base_url https://cdn.npmmirror.com/binaries/chrome-for-testing # puppeteer
    #     pnpm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver # chromedriver
    #     pnpm config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver # operadriver
    #     pnpm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs # phantomjs
    #     pnpm config set selenium_cdnurl https://npmmirror.com/mirrors/selenium # selenium
    #     pnpm config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector # node-inspector
    # fi

    # if [[ "${CONFIG_ACTION}" == "RESET" ]]; then
    #     colorEcho "${BLUE}Reset pnpm registry (npmjs.org)..."
    #     pnpm config set registry https://registry.npmjs.org/

    #     pnpm config delete disturl
    #     pnpm config delete sass_binary_site
    #     pnpm config delete electron_mirror
    #     pnpm config delete puppeteer_download_base_url
    #     pnpm config delete chromedriver_cdnurl
    #     pnpm config delete operadriver_cdnurl
    #     pnpm config delete phantomjs_cdnurl
    #     pnpm config delete selenium_cdnurl
    #     pnpm config delete node_inspector_cdnurl
    # fi
fi


## show all defaults
# npm config ls -l
npm config list
