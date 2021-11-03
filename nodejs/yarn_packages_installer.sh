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
#     npm set registry https://registry.npm.taobao.org

#     npm set disturl https://npm.taobao.org/dist # node-gyp
#     npm set sass_binary_site https://npm.taobao.org/mirrors/node-sass # node-sass
#     npm set electron_mirror https://npm.taobao.org/mirrors/electron/ # electron
#     npm set puppeteer_download_host https://npm.taobao.org/mirrors # puppeteer
#     npm set chromedriver_cdnurl https://npm.taobao.org/mirrors/chromedriver # chromedriver
#     npm set operadriver_cdnurl https://npm.taobao.org/mirrors/operadriver # operadriver
#     npm set phantomjs_cdnurl https://npm.taobao.org/mirrors/phantomjs # phantomjs
#     npm set selenium_cdnurl https://npm.taobao.org/mirrors/selenium # selenium
#     npm set node_inspector_cdnurl https://npm.taobao.org/mirrors/node-inspector # node-inspector
# fi

# Change yarn registry to taobao
# colorEcho "${BLUE}Change yarn registry to ${FUCHSIA}taobao${BLUE}..."
# yarn config set registry https://registry.npm.taobao.org

# yarn config set disturl https://npm.taobao.org/dist # node-gyp
# yarn config set sass_binary_site https://npm.taobao.org/mirrors/node-sass # node-sass
# yarn config set electron_mirror https://npm.taobao.org/mirrors/electron/ # electron
# yarn config set puppeteer_download_host https://npm.taobao.org/mirrors # puppeteer
# yarn config set chromedriver_cdnurl https://npm.taobao.org/mirrors/chromedriver # chromedriver
# yarn config set operadriver_cdnurl https://npm.taobao.org/mirrors/operadriver # operadriver
# yarn config set phantomjs_cdnurl https://npm.taobao.org/mirrors/phantomjs # phantomjs
# yarn config set selenium_cdnurl https://npm.taobao.org/mirrors/selenium # selenium
# yarn config set node_inspector_cdnurl https://npm.taobao.org/mirrors/node-inspector # node-inspector

# Custom global packages install location
# `yarn global bin` will output the location where Yarn will install symlinks to your installed executables
# mkdir -p ~/.yarn && yarn config set prefix ~/.yarn

# `yarn global dir` will print the output of the global installation folder that houses the global node_modules.
# By default that will be: ~/.config/yarn/global

# Install global packages with binaries
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
