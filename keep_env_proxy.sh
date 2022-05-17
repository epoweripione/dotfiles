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

# keep proxy env when running command with `sudo`
SUDOERS_FILE="/etc/sudoers.d/keep_env_proxy"

echo 'Defaults env_keep += "http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY"' \
    | sudo tee "${SUDOERS_FILE}" >/dev/null

[[ -s "${SUDOERS_FILE}" ]] \
    && colorEcho "${BLUE}The PROXY env success saved to ${FUCHSIA}${SUDOERS_FILE}${BLUE}!" \
    || colorEcho "${RED}The PROXY env save to ${FUCHSIA}${SUDOERS_FILE}${RED} failed!"
