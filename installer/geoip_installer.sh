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

App_Installer_Reset

# GeoIP binary and database
# http://kbeezie.com/geoiplookup-command-line/
if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        geoip-bin
        geoip-database
        GeoIP
        GeoIP-data
        geoip
        geoip-data
    )
    InstallSystemPackages "" "${PackagesList[@]}"
fi

## How to use
# geoiplookup 8.8.8.8
