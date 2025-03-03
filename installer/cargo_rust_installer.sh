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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# rustup & cargo mirror
[[ "${THE_WORLD_BLOCKED}" == "true" ]] && setMirrorRust

## Rust and Cargo
## https://www.rust-lang.org/learn/get-started
## On Linux and macOS systems
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

## On Windows
## https://win.rustup.rs/
# scoop install rustup

[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

if [[ -x "$(command -v cargo)" ]]; then
    AppInstaller="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/cargo-binstall_installer.sh"
    [[ -f "${AppInstaller}" ]] && source "${AppInstaller}"
fi
