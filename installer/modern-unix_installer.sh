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

# Modern Unix: A collection of modern/faster/saner alternatives to common unix commands
# https://github.com/ibraheemdev/modern-unix
AppList=(
    "bat"
    "bfs"
    # "exa"
    "eza"
    "lsd"
    "git-delta"
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
    "sd"
    "cheat"
    "tldr"
    "bottom"
    "glances"
    "gtop"
    "hyperfine"
    "gping"
    "procs"
    "httpie"
    "httpie-go"
    "curlie"
    "xh"
    "zoxide"
    # "dog"
    "doggo"
)
for Target in "${AppList[@]}"; do
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    if [[ -f "${AppInstaller}" ]]; then
        source "${AppInstaller}"
    else
        PackagesList=("${Target}") && InstallSystemPackages "" "${PackagesList[@]}"
    fi
done


cd "${CURRENT_DIR}" || exit