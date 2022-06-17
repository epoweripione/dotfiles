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

INSTALL_TOOL=${1:-"all"}

# Bash-Snippets
# https://github.com/alexanderepstein/Bash-Snippets
colorEcho "${BLUE}Installing ${FUCHSIA}Bash-Snippets${BLUE}..."
Git_Clone_Update_Branch "alexanderepstein/Bash-Snippets" "$HOME/Bash-Snippets"

[[ -n "${INSTALL_TOOL}" ]] && \
    cd "$HOME/Bash-Snippets" && \
    ./install.sh "${INSTALL_TOOL}"

cd "${CURRENT_DIR}" || exit