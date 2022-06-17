#!/usr/bin/env bash

[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

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

# https://brew.sh/index_zh-cn
colorEcho "${BLUE}Installing ${FUCHSIA}homebrew${BLUE}..."

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type

if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
fi

# Brew installation fails due to Ruby versioning?
# https://unix.stackexchange.com/questions/694020/brew-installation-fails-due-to-ruby-versioning
BREW_RUBY_VERSION="2.6.8"
BREW_RUBY_MAIN_VERSION=$(echo "${BREW_RUBY_VERSION}" | cut -d'.' -f1-2)
RUBY_DOWNLOAD_URL="https://cache.ruby-china.com/pub/ruby/${BREW_RUBY_MAIN_VERSION}/ruby-${BREW_RUBY_VERSION}.tar.bz2"

SYSTEM_RUBY_VERSION="0.0.0"
[[ -x "$(command -v ruby)" ]] && SYSTEM_RUBY_VERSION=$(ruby -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)

if [[ "${BREW_RUBY_VERSION}" != "${SYSTEM_RUBY_VERSION}" ]]; then
    OS_RELEASE_ID="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release 2>/dev/null | cut -d '=' -f2)"
    OS_RELEASE_ID_LIKE="$(grep -E '^ID_LIKE=([a-zA-Z]*)' /etc/os-release 2>/dev/null | cut -d '=' -f2)"
    if [[ "${OS_RELEASE_ID}" == "arch" || "${OS_RELEASE_ID}" == "arch" || "${OS_RELEASE_ID_LIKE}" == "arch" ]]; then
        # https://github.com/rbenv/rbenv
        if [[ -x "$(command -v yay)" ]]; then
            yay --noconfirm --needed -S rbenv
            # https://github.com/Homebrew/discussions/discussions/3183
            sudo pacman --noconfirm --needed -S libxcrypt-compat
        fi

        if [[ -x "$(command -v rbenv)" ]]; then
            mkdir "$(rbenv root)/plugins"
            mkdir "$(rbenv root)/cache"

            if ! grep -q 'rbenv init -' "$HOME/.zshrc" >/dev/null 2>&1; then
                echo -e '\n# rbenv' >> "$HOME/.zshrc"
                echo 'eval "$(rbenv init -)"' >> "$HOME/.zshrc"
            fi

            if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
                Git_Clone_Update_Branch "andorchen/rbenv-china-mirror" "$(rbenv root)/plugins/rbenv-china-mirror"
                export RUBY_BUILD_MIRROR_URL="https://cache.ruby-china.com"
            fi

            Git_Clone_Update_Branch "rbenv/ruby-build" "$(rbenv root)/plugins/ruby-build"

            wget "${RUBY_DOWNLOAD_URL}" -P "$(rbenv root)/cache"
            rbenv install "${BREW_RUBY_VERSION}" && rbenv rehash
            if rbenv versions | grep "${BREW_RUBY_VERSION}" >/dev/null 2>&1; then
                rbenv global "${BREW_RUBY_VERSION}"
            fi

            ## fallback to system installed version
            # rbenv global system
        fi

        if [[ -x "$(command -v gem)" ]]; then
            noproxy_cmd gem sources --add "https://gems.ruby-china.com/" --remove "https://rubygems.org/"
            gem sources -l
        fi
    fi
fi

case "${OS_INFO_TYPE}" in
    darwin | linux)
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        ;;
    *)
        colorEcho "${RED}Operating system does not support!"
        exit 0
        ;;
esac

# https://docs.brew.sh/Homebrew-on-Linux
if [[ "${OS_INFO_TYPE}" == "linux" && -s "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    # if ! grep -q 'brew shellenv' "$HOME/.zprofile" >/dev/null 2>&1; then
    #     echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> "$HOME/.zprofile"
    # fi

    if ! grep -q 'brew shellenv' "$HOME/.zshrc" >/dev/null 2>&1; then
        echo -e '\n# homebrew' >> "$HOME/.zshrc"
        echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> "$HOME/.zshrc"
    fi

    # eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

## offical
# cd "$(brew --repo)"
# git remote set-url origin https://github.com/Homebrew/brew.git

# cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
# git remote set-url origin https://github.com/Homebrew/homebrew-core

# cd "$(brew --repo)/Library/Taps/homebrew/homebrew-cask"
# git remote set-url origin https://github.com/Homebrew/homebrew-cask

# unset HOMEBREW_CORE_GIT_REMOTE
# brew tap --custom-remote --force-auto-update homebrew/core "https://github.com/Homebrew/homebrew-core"
# brew tap --custom-remote --force-auto-update homebrew/cask "https://github.com/Homebrew/homebrew-cask"
# brew tap --custom-remote --force-auto-update homebrew/cask-versions "https://github.com/Homebrew/homebrew-cask-versions"

## mirrors
if [[ "${THE_WORLD_BLOCKED}" == "true" && -x "$(command -v brew)" ]]; then
    # cd "$(brew --repo)" && \
    #     git remote set-url origin "https://mirrors.ustc.edu.cn/brew.git"

    # cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core" && \
    #     git remote set-url origin "https://mirrors.ustc.edu.cn/homebrew-core.git"

    # cd "$(brew --repo)/Library/Taps/homebrew/homebrew-cask" && \
    #     git remote set-url origin "https://mirrors.ustc.edu.cn/homebrew-cask.git"

    brew tap --custom-remote --force-auto-update homebrew/core "https://mirrors.ustc.edu.cn/homebrew-core.git"
    brew tap --custom-remote --force-auto-update homebrew/cask "https://mirrors.ustc.edu.cn/homebrew-cask.git"
    brew tap --custom-remote --force-auto-update homebrew/cask-versions "https://mirrors.ustc.edu.cn/homebrew-cask-versions.git"
fi

## Bottles (Binary Packages)
## https://docs.brew.sh/Bottles
# if ! grep -q "HOMEBREW_BOTTLE_DOMAIN" "$HOME/.zshrc" 2>/dev/null; then
#     echo 'export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"' >> ~/.zshrc
#     # source ~/.zshrc
# fi


## How to force homebrew to install a local file?
## https://stackoverflow.com/questions/59017569/how-to-force-homebrew-to-install-a-local-file
# brew install -b <formula>
## If a package fails to download, look for the cached location name and the url to download
## Note 3 things from the response:
## Cache folder location: <Cacheed_folder>($HOME/.cache/Homebrew/downloads/<Cacheed_filename>)
## Cached filename: <Cacheed_filename>
## Download url: <Download_url>
## Manual download the package:
# wget "<Download_url>" -O "<Cacheed_folder>/<Cacheed_filename>"
## Run brew install again
# brew install -b <formula>
# brew --cache <formula>

cd "${CURRENT_DIR}" || exit