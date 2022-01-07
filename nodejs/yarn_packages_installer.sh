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


if [[ ! -x "$(command -v yarn)" ]]; then
    colorEcho "${FUCHSIA}yarn${RED} is not installed!"
    exit 0
fi

# yarn config
yarn config set emoji true

# if [[ -x "$(command -v npm)" ]]; then
#     # Change npm registry to taobao
#     colorEcho "${BLUE}Change npm registry to ${FUCHSIA}taobao${BLUE}..."
#     npm config set registry https://registry.npmmirror.com

#     npm config set disturl https://npmmirror.com/dist # node-gyp
#     npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass # node-sass
#     npm config set electron_mirror https://npmmirror.com/mirrors/electron/ # electron
#     npm config set puppeteer_download_host https://npmmirror.com/mirrors # puppeteer
#     npm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver # chromedriver
#     npm config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver # operadriver
#     npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs # phantomjs
#     npm config set selenium_cdnurl https://npmmirror.com/mirrors/selenium # selenium
#     npm config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector # node-inspector
# fi

# Change yarn registry to taobao
# colorEcho "${BLUE}Change yarn registry to ${FUCHSIA}taobao${BLUE}..."
# yarn config set registry https://registry.npmmirror.com

# yarn config set disturl https://npmmirror.com/dist # node-gyp
# yarn config set sass_binary_site https://npmmirror.com/mirrors/node-sass # node-sass
# yarn config set electron_mirror https://npmmirror.com/mirrors/electron/ # electron
# yarn config set puppeteer_download_host https://npmmirror.com/mirrors # puppeteer
# yarn config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver # chromedriver
# yarn config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver # operadriver
# yarn config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs # phantomjs
# yarn config set selenium_cdnurl https://npmmirror.com/mirrors/selenium # selenium
# yarn config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector # node-inspector

# Custom global packages install location
# `yarn global bin` will output the location where Yarn will install symlinks to your installed executables
# mkdir -p ~/.yarn && yarn config set prefix ~/.yarn

# `yarn global dir` will print the output of the global installation folder that houses the global node_modules.
# By default that will be: ~/.config/yarn/global

# Install global packages with binaries
colorEcho "${BLUE}Installing ${FUCHSIA}npm-check-updates${BLUE}..."
yarn global add npm-check-updates

colorEcho "${BLUE}Installing ${FUCHSIA}es-checker eslint tslint jslint jshint standard${BLUE}..."
yarn global add es-checker eslint tslint jslint jshint standard

colorEcho "${BLUE}Installing ${FUCHSIA}babel-cli webpack traceur${BLUE}..."
yarn global add @babel/core @babel/cli webpack webpack-cli traceur

colorEcho "${BLUE}Installing ${FUCHSIA}typescript${BLUE}..."
yarn global add typescript

colorEcho "${BLUE}Installing ${FUCHSIA}angular/cli${BLUE}..."
yarn global add @angular/cli

colorEcho "${BLUE}Installing ${FUCHSIA}vue/cli${BLUE}..."
yarn global add @vue/cli

colorEcho "${BLUE}Installing ${FUCHSIA}quasar/cli${BLUE}..."
yarn global add @quasar/cli

colorEcho "${BLUE}Installing ${FUCHSIA}storybook/cli${BLUE}..."
yarn global add react react-dom
yarn global add @storybook/cli

colorEcho "${BLUE}Installing ${FUCHSIA}parcel-bundler${BLUE}..."
yarn global add parcel-bundler

colorEcho "${BLUE}Installing ${FUCHSIA}cordova ionic${BLUE}..."
yarn global add cordova ionic

colorEcho "${BLUE}Installing ${FUCHSIA}electron${BLUE}..."
yarn global add electron

# https://ice.work/iceworks
colorEcho "${BLUE}Installing ${FUCHSIA}iceworks${BLUE}..."
yarn global add iceworks

colorEcho "${BLUE}Installing ${FUCHSIA}express-generator${BLUE}..."
yarn global add express-generator

colorEcho "${BLUE}Installing ${FUCHSIA}tldr${BLUE}..."
yarn global add tldr

# https://github.com/cnwhy/lib-qqwry/
colorEcho "${BLUE}Installing ${FUCHSIA}lib-qqwry${BLUE}..."
yarn global add lib-qqwry

# colorEcho "${BLUE}Installing ${FUCHSIA}arch-wiki-man${BLUE}..."
# # arch-wiki-man
# ## https://github.com/greg-js/arch-wiki-man
# yarn global add arch-wiki-man

# Install global packages without binaries
colorEcho "${BLUE}Installing ${FUCHSIA}puppeteer${BLUE}..."
yarn global add puppeteer

# colorEcho "${BLUE}Installing ${FUCHSIA}jquery popper.js bootstrap${BLUE}..."
# yarn global add jquery popper.js bootstrap

# colorEcho "${BLUE}Installing ${FUCHSIA}mdbootstrap${BLUE}..."
# yarn global add mdbootstrap

# colorEcho "${BLUE}Installing ${FUCHSIA}echarts echarts-gl${BLUE}..."
# yarn global add echarts echarts-gl

# Clean yarn cache
# yarn cache clean --force
# yarn cache verify

# List Installed packages
colorEcho "${BLUE}List Installed packages..."
yarn global list

colorEcho "${GREEN}Install yarn package finished!"
