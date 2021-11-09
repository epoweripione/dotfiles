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
npm config set user 0
npm config set unsafe-perm true

# npm global
NPM_PREFIX=$(npm config get prefix 2>/dev/null)
if ! echo "${NPM_PREFIX}" | grep -q "\.asdf/installs/nodejs"; then
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"
    export PATH="$PATH:$HOME/.npm-global/bin"
fi

# Change npm registry to taobao
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    colorEcho "${BLUE}Change npm registry to taobao..."
    npm set registry https://registry.npmmirror.com

    npm set disturl https://npmmirror.com/dist # node-gyp
    npm set sass_binary_site https://npmmirror.com/mirrors/node-sass # node-sass
    npm set electron_mirror https://npmmirror.com/mirrors/electron/ # electron
    npm set puppeteer_download_host https://npmmirror.com/mirrors # puppeteer
    npm set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver # chromedriver
    npm set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver # operadriver
    npm set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs # phantomjs
    npm set selenium_cdnurl https://npmmirror.com/mirrors/selenium # selenium
    npm set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector # node-inspector
fi

## show all defaults
# npm config ls -l
npm config list

colorEcho "${GREEN}Done!"
