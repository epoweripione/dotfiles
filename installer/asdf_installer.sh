#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

# asdf: Extendable version manager with support for Ruby, Node.js, Elixir, Erlang & more
# https://asdf-vm.com/
# https://github.com/asdf-vm/asdf
IS_INSTALL="yes"
IS_UPDATE="no"

if [[ -d "$HOME/.asdf" ]]; then
    IS_UPDATE="yes"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking update for ${FUCHSIA}asdf${BLUE}..."
    Git_Clone_Update_Branch "asdf-vm/asdf" "$HOME/.asdf"
fi

[[ ! "$(command -v asdf)" ]] && source "$HOME/.asdf/asdf.sh"

# https://asdf-vm.com/manage/configuration.html
if ! grep -q "legacy_version_file" "$HOME/.asdfrc" 2>/dev/null; then
    echo 'legacy_version_file = yes' >> "$HOME/.asdfrc"
fi

# if ! grep -q "always_keep_download" "$HOME/.asdfrc" 2>/dev/null; then
#     echo 'always_keep_download = yes' >> "$HOME/.asdfrc"
# fi


# [[ "${IS_UPDATE}" == "yes" ]] && asdf plugin update --all


## asdf plugins repository
## https://asdf-vm.com/#/plugins-all
# asdf plugin add <name>
# asdf plugin add <name> <git-url>
# asdf plugin list
# asdf plugin list all
# asdf plugin list --urls
# asdf plugin update --all
# asdf plugin remove <name>

## Manage version
## https://asdf-vm.com/#/core-manage-versions
# asdf install <name> <version>
# asdf install <name> latest
# asdf install <name> latest:<version>
# asdf list <name>
# asdf list all <name>
# asdf latest <name>
# asdf latest <name> <version>
# asdf global <name> <version> [<version>...]
# asdf shell <name> <version> [<version>...]
# asdf local <name> <version> [<version>...]
# asdf current
# asdf current <name>
# asdf uninstall <name> <version>


## golang
## https://github.com/kennyp/asdf-golang
# asdf plugin add golang
# asdf install golang latest
# asdf global golang latest

## nodejs
## https://github.com/asdf-vm/asdf-nodejs
# asdf plugin add nodejs
## clear_proxy
# bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'
# bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-previous-release-team-keyring'
## [[ "${THE_WORLD_BLOCKED}" == "true" ]] && check_set_global_proxy 7891 7890
# asdf install nodejs latest:14
# asdf global nodejs $(asdf list all nodejs 14 | tail -1)

## php
## https://github.com/asdf-community/asdf-php
# asdf plugin add php
# PHP_VERSION=$(asdf list all php 7.4 | grep -E -i -v '[alpha|beta|rc]' | tail -1)
# PHP_WITHOUT_PEAR=yes asdf install php ${PHP_VERSION}
## Global Composer Dependencies
## After installing a global composer package you will need to run asdf reshim.
# composer global require friendsofphp/php-cs-fixer
# asdf reshim
# php-cs-fixer --version


## Remove
# rm -rf ${ASDF_DATA_DIR:-$HOME/.asdf} ~/.tool-versions