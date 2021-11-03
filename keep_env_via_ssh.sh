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

# keep SSH env when using `sudo -i`
# https://mwl.io/archives/1000
# sudo visudo -f /etc/sudoers.d/keep_env_via_ssh
echo 'Defaults env_keep += "SSH_CLIENT SSH_CONNECTION SSH_TTY SSH_AUTH_SOCK"' \
    | sudo tee "/etc/sudoers.d/keep_env_via_ssh" >/dev/null

[[ -s "/etc/sudoers.d/keep_env_via_ssh" ]] \
    && colorEcho "${BLUE}The SSH env success saved to ${FUCHSIA}/etc/sudoers.d/keep_env_via_ssh${BLUE}!" \
    || colorEcho "${RED}The SSH env save to ${FUCHSIA}/etc/sudoers.d/keep_env_via_ssh${RED} failed!"
