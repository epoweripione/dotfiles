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

App_Installer_Reset

# [fzf: A command-line fuzzy finder written in Go](https://github.com/junegunn/fzf)
if [[ ! -x "$(command -v fzf)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}fzf${BLUE}..."
    # PackagesList=(fzf) && InstallSystemPackages "" "${PackagesList[@]}"
    Git_Clone_Update_Branch "junegunn/fzf" "$HOME/.fzf"
    [[ -s "$HOME/.fzf/install" ]] && "$HOME/.fzf/install"
elif [[ -d "$HOME/.fzf" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}fzf${BLUE}..."
    Git_Clone_Update_Branch "junegunn/fzf" "$HOME/.fzf"
    [[ -s "$HOME/.fzf/install" ]] && "$HOME/.fzf/install" --bin
fi
