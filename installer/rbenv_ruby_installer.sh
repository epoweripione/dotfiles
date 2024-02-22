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

App_Installer_Reset

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# [Manage your app's Ruby environment](https://github.com/rbenv/rbenv)
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    [[ -z "${RUBY_BUILD_MIRROR_URL}" ]] && RUBY_BUILD_MIRROR_URL="https://cache.ruby-china.com"
    [[ -z "${RUBY_GEM_SOURCE_MIRROR}" ]] && RUBY_GEM_SOURCE_MIRROR="https://gems.ruby-china.com/"
fi

if [[ -d "$HOME/.rbenv" ]]; then
    INSTALLER_IS_UPDATE="yes"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# new install
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && "${INSTALLER_IS_UPDATE}" == "no" ]]; then
    # https://github.com/rbenv/ruby-build/wiki#suggested-build-environment
    # Ruby 3.2 and above requires the Rust compiler if you want to have YJIT enabled
    if [[ -x "$(command -v pacman)" ]]; then
        PackagesList=(
            # Ubuntu/Debian/Mint
            autoconf
            patch
            build-essential
            libssl-dev
            libyaml-dev
            libreadline6-dev
            zlib1g-dev
            libgmp-dev
            libncurses5-dev
            libffi-dev
            libgdbm5
            libgdbm6
            libgdbm-dev
            libdb-dev
            uuid-dev
            # RHEL/CentOS
            gcc-6
            bzip2
            openssl-devel
            readline-devel
            zlib-devel
            gdbm-devel
            ncurses-devel
            # arch
            base-devel
            libffi
            libyaml
            openssl
            zlib
            libxcrypt-compat
        )
        InstallSystemPackages "${BLUE}Checking Pre-requisite packages for ${FUCHSIA}rbenv${BLUE}..." "${PackagesList[@]}"
    fi

    colorEcho "${BLUE}Installing ${FUCHSIA}rbenv${BLUE}..."
    Git_Clone_Update_Branch "rbenv/rbenv" "$HOME/.rbenv"
fi

if [[ "${INSTALLER_IS_UPDATE}" == "yes" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}rbenv${BLUE}..."
    Git_Clone_Update_Branch "rbenv/rbenv" "$HOME/.rbenv"
fi

if [[ -d "$HOME/.rbenv" && ! -x "$(command -v rbenv)" ]]; then
    [[ ":$PATH:" != *":$HOME/.rbenv/bin:"* ]] && export PATH=$PATH:$HOME/.rbenv/bin
fi

if [[ -x "$(command -v rbenv)" ]]; then
    mkdir -p "$(rbenv root)/plugins"
    mkdir -p "$(rbenv root)/cache"

    ## config
    # bash
    if ! grep -q "rbenv init" "$HOME/.bashrc" 2>/dev/null; then
        echo -e '\n# rbenv' >> "$HOME/.bashrc"
        echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> "$HOME/.bashrc"
    fi

    # zsh
    if ! grep -q "rbenv init" "$HOME/.zshrc" 2>/dev/null; then
        echo -e '\n# rbenv' >> "$HOME/.zshrc"
        echo 'eval "$(~/.rbenv/bin/rbenv init - zsh)"' >> "$HOME/.zshrc"
    fi

    colorEcho "${BLUE}Updating ${FUCHSIA}ruby-build${BLUE}..."
    Git_Clone_Update_Branch "rbenv/ruby-build" "$(rbenv root)/plugins/ruby-build"
fi

if [[ -d "$HOME/.rbenv" && ! -x "$(command -v rbenv)" ]]; then
    [[ ":$PATH:" != *":$HOME/.rbenv/bin:"* ]] && export PATH=$PATH:$HOME/.rbenv/bin
fi

# install latest ruby if no installed version
if [[ -x "$(command -v rbenv)" && ! -x "$(command -v ruby)" ]]; then
    RUBY_VER_LATEST=$(rbenv install -l 2>&1 | grep -Eo '^([0-9]{1,}\.)+[0-9]{1,}' | sort -rV | head -n1)
    [[ -z "${RUBY_VER_LATEST}" ]] && rbenvInstallRuby "${RUBY_VER_LATEST}" && rbenv global "${RUBY_VER_LATEST}"
fi

if [[ -x "$(command -v ruby)" && "${THE_WORLD_BLOCKED}" == "true" ]]; then
    setMirrorRbenv
    setMirrorGem
fi
