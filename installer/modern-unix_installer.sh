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

# [Modern Unix: A collection of modern/faster/saner alternatives to common unix commands](https://github.com/ibraheemdev/modern-unix)
AppList=(
    "bat"
    "bfs"
    "eza"
    "lsd"
    "git-delta"
    "git-lfs"
    "lazygit"
    "dust"
    "duf"
    "broot"
    "fd"
    "ripgrep"
    "ag"
    "fzf"
    "mcfly"
    "choose"
    "jq"
    "yq"
    "sd"
    # "cheat"
    # "tldr"
    # [tealdeer - A very fast implementation of tldr in Rust](https://github.com/tealdeer-rs/tealdeer)
    "tealdeer"
    "bottom"
    "glances"
    # "gtop"
    "hyperfine"
    "gping"
    "procs"
    ## [Load Testing Toolkit](https://github.com/aliesbelik/load-testing-toolkit)
    # "httpie"
    # "httpie-go"
    # "httpstat"
    "curlie"
    "xh"
    "zoxide"
    "doggo"
)

PackagesList=()
for Target in "${AppList[@]}"; do
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    if [[ -f "${AppInstaller}" ]]; then
        source "${AppInstaller}"
    else
        [[ ! -x "$(command -v "${Target}")" ]] && PackagesList+=("${Target}")
    fi
done

if [[ -n "${PackagesList[*]}" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}${PackagesList[*]}${BLUE}..."
    InstallSystemPackages "" "${PackagesList[@]}"
fi

cd "${CURRENT_DIR}" || exit