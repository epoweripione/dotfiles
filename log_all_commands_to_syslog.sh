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

# https://gist.github.com/dayreiner/cbe525defc5159c2ae36
# Enable log anything going to local6
if [[ ! -s "/etc/rsyslog.d/commands.conf" ]]; then
    colorEcho "${BLUE}Enable log anything going to local6 into ${FUCHSIA}/var/log/commands.log${BLUE}..."
    echo 'local6.*    /var/log/commands.log' | sudo tee -a "/etc/rsyslog.d/commands.conf" >/dev/null

    colorEcho "${BLUE}Restarting ${FUCHSIA}syslog${BLUE}..."
    sudo systemctl restart syslog
    sudo systemctl restart rsyslog
fi

# Global Bash Profile Setup
if ! grep -q "^export PROMPT_COMMAND=" "/etc/bashrc" 2>/dev/null; then
    colorEcho "${BLUE}Enable bash commands log into ${FUCHSIA}/etc/bashrc${BLUE}..."
    sudo tee -a "/etc/bashrc" >/dev/null <<-'EOF'

# Log commands to syslog for future reference
export PROMPT_COMMAND='RETRN_VAL=$?;logger -p local6.debug "$(whoami) $(who | awk "{print \$NF}" | sed -e "s/[()]//g") [$$]: $(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//" ) [$RETRN_VAL]"'
EOF
fi

# Global ZSH Profile Setup
[[ -d "/etc/zsh" ]] && ZSHRC_FILE="/etc/zsh/zshrc" || ZSHRC_FILE="/etc/zshrc"
if ! grep -q "^precmd()" "${ZSHRC_FILE}" 2>/dev/null; then
    colorEcho "${BLUE}Enable zsh commands log into ${FUCHSIA}${ZSHRC_FILE}${BLUE}..."
    sudo tee -a "${ZSHRC_FILE}" >/dev/null <<-'EOF'

# Log commands to syslog for future reference
precmd() { eval 'RETRN_VAL=$?;logger -p local6.debug "$(whoami) $(who | awk "{print \$NF}" | sed -e "s/[()]//g") [$$]: $(history | tail -n1 | sed "s/^[ ]*[0-9]\+[ ]*//" ) [$RETRN_VAL]"' }
EOF
fi

colorEcho "${BLUE}  Done, all commands using ${YELLOW}bash${BLUE} or ${YELLOW}zsh${BLUE} will log into ${FUCHSIA}/var/log/commands.log${BLUE}!"
