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

# if [[ -x "$(command -v npm)" ]]; then
#     [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]] && \
#         source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh"
# fi

# npm install -g nrm
# nrm use taobao

# Install global packages with binaries
colorEcho "${BLUE}Installing ${FUCHSIA}cnpm${BLUE}..."
npm install -g cnpm

colorEcho "${BLUE}Installing ${FUCHSIA}cnpm${BLUE}..."
npm install -g pnpm

colorEcho "${BLUE}Installing ${FUCHSIA}npm-check-updates${BLUE}..."
npm install -g npm-check-updates

colorEcho "${BLUE}Installing ${FUCHSIA}npm-check es-checker eslint jslint jshint standard${BLUE}..."
npm install -g npm-check es-checker eslint jslint jshint standard

colorEcho "${BLUE}Installing ${FUCHSIA}babel webpack traceur${BLUE}..."
npm install -g @babel/core @babel/cli webpack webpack-cli traceur

colorEcho "${BLUE}Installing ${FUCHSIA}typescript${BLUE}..."
npm install -g typescript

colorEcho "${BLUE}Installing ${FUCHSIA}angular/cli${BLUE}..."
npm install -g @angular/cli

colorEcho "${BLUE}Installing ${FUCHSIA}vue/cli${BLUE}..."
npm install -g @vue/cli

colorEcho "${BLUE}Installing ${FUCHSIA}quasar/cli${BLUE}..."
npm install -g @quasar/cli

colorEcho "${BLUE}Installing ${FUCHSIA}storybook/cli${BLUE}..."
npm install -g react react-dom
npm install -g @storybook/cli

colorEcho "${BLUE}Installing ${FUCHSIA}parcel-bundler${BLUE}..."
npm install -g parcel-bundler

colorEcho "${BLUE}Installing ${FUCHSIA}cordova ionic${BLUE}..."
npm install -g cordova ionic

colorEcho "${BLUE}Installing ${FUCHSIA}electron${BLUE}..."
npm install -g electron

# https://ice.work/iceworks
colorEcho "${BLUE}Installing ${FUCHSIA}iceworks${BLUE}..."
npm install -g iceworks

colorEcho "${BLUE}Installing ${FUCHSIA}express-generator${BLUE}..."
npm install -g express-generator

colorEcho "${BLUE}Installing ${FUCHSIA}tldr${BLUE}..."
npm install -g tldr

# https://github.com/cnwhy/lib-qqwry/
colorEcho "${BLUE}Installing ${FUCHSIA}lib-qqwry${BLUE}..."
npm install -g lib-qqwry

# colorEcho "${BLUE}Installing ${FUCHSIA}arch-wiki-man${BLUE}..."
# # arch-wiki-man
# ## https://github.com/greg-js/arch-wiki-man
# npm install -g arch-wiki-man

# Install global packages without binaries
colorEcho "${BLUE}Installing ${FUCHSIA}puppeteer${BLUE}..."
npm install -g puppeteer

# colorEcho "${BLUE}Installing ${FUCHSIA}jquery popper.js bootstrap${BLUE}..."
# npm install -g jquery popper.js bootstrap

# colorEcho "${BLUE}Installing ${FUCHSIA}mdbootstrap${BLUE}..."
# npm install -g mdbootstrap

# colorEcho "${BLUE}Installing ${FUCHSIA}echarts echarts-gl${BLUE}..."
# npm install -g echarts echarts-gl

# https://github.com/afc163/fanyi
colorEcho "${BLUE}Installing ${FUCHSIA}fanyi${BLUE}..."
npm install -g fanyi

# https://github.com/splash-cli/splash-cli
colorEcho "${BLUE}Installing ${FUCHSIA}splash-cli${BLUE}..."
npm install -g splash-cli

# https://github.com/sindresorhus/speed-test
colorEcho "${BLUE}Installing ${FUCHSIA}speedtest-net${BLUE}..."
npm install -g speedtest-net

# https://github.com/riyadhalnur/weather-cli
colorEcho "${BLUE}Installing ${FUCHSIA}weather-cli${BLUE}..."
npm install -g weather-cli

# Clean npm cache
# npm cache clean --force
# npm cache verify

# List Installed packages
colorEcho "${BLUE}List Installed packages..."
npm list --depth=0 -g

colorEcho "${GREEN}Install npm package finished!"
