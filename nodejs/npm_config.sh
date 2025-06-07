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
    setMirrorNodejs

    colorEcho "${BLUE}Change npm registry to ${FUCHSIA}${MIRROR_NODEJS_REGISTRY:-"https://registry.npmmirror.com"}${BLUE}..."
    npm config set registry "${MIRROR_NODEJS_REGISTRY:-"https://registry.npmmirror.com"}"
fi

if [[ "${CONFIG_ACTION}" == "RESET" ]]; then
    colorEcho "${BLUE}Reset npm registry to ${FUCHSIA} https://registry.npmjs.org${BLUE}..."
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

    unset MIRROR_NODEJS_REGISTRY

    unset CHROMEDRIVER_CDNURL
    unset COREPACK_NPM_REGISTRY
    unset CYPRESS_DOWNLOAD_PATH_TEMPLATE
    unset EDGEDRIVER_CDNURL
    unset ELECTRON_BUILDER_BINARIES_MIRROR
    unset ELECTRON_MIRROR
    unset NODEJS_ORG_MIRROR
    unset NVM_NODEJS_ORG_MIRROR
    unset NWJS_URLBASE
    unset OPERADRIVER_CDNURL
    unset PHANTOMJS_CDNURL
    unset PLAYWRIGHT_DOWNLOAD_HOST
    unset PRISMA_ENGINES_MIRROR
    unset PUPPETEER_CHROME_DOWNLOAD_BASE_URL
    unset PUPPETEER_CHROME_HEADLESS_SHELL_DOWNLOAD_BASE_URL
    unset PUPPETEER_DOWNLOAD_BASE_URL
    unset PUPPETEER_DOWNLOAD_HOST
    unset RE2_DOWNLOAD_MIRROR
    unset RE2_DOWNLOAD_SKIP_PATH
    unset SASS_BINARY_SITE
    unset SAUCECTL_INSTALL_BINARY_MIRROR
    unset SENTRYCLI_CDNURL
    unset SWC_BINARY_SITE
    # binary_host
    unset better_sqlite3_binary_host
    unset gl_binary_host
    unset keytar_binary_host
    unset robotjs_binary_host
    unset sharp_binary_host
    unset sharp_libvips_binary_host
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
fi


## show all defaults
# npm config ls -l
npm config list
