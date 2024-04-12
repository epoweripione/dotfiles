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


## Giving a user sudo privileges
## You will need to logout and back in for changes to take effect
# sudo usermod -aG sudo <username>

# Disable Password Authentication
sudo sed -i 's/[#]*[ ]*PasswordAuthentication.*/PasswordAuthentication no/g' "/etc/ssh/sshd_config"
sudo sed -i 's/[#]*[ ]*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' "/etc/ssh/sshd_config"

# Disable Forwarding
sudo sed -i 's/[#]*[ ]*AllowAgentForwarding.*/AllowAgentForwarding no/g' "/etc/ssh/sshd_config"
sudo sed -i 's/[#]*[ ]*AllowTcpForwarding.*/AllowTcpForwarding no/g' "/etc/ssh/sshd_config"
sudo sed -i 's/[#]*[ ]*X11Forwarding.*/X11Forwarding no/g' "/etc/ssh/sshd_config"

# /etc/ssh/ssh_config.d/
SUB_CONFIG_FILE=""
if systemctl is-enabled ssh >/dev/null 2>&1; then
    [[ -d "/etc/ssh/ssh_config.d" ]] && SUB_CONFIG_FILE="/etc/ssh/ssh_config.d/00-only-ssh-login.conf"
fi

if systemctl is-enabled sshd >/dev/null 2>&1; then
    [[ -d "/etc/ssh/sshd_config.d" ]] && SUB_CONFIG_FILE="/etc/ssh/sshd_config.d/00-only-ssh-login.conf"
fi

if [[ -n "${SUB_CONFIG_FILE}" ]]; then
    sudo tee "${SUB_CONFIG_FILE}" >/dev/null <<-'EOF'
# Disable Password Authentication
PasswordAuthentication no
ChallengeResponseAuthentication no
# UsePAM no

# Disable Forwarding
ForwardX11 no
ForwardAgent no
# AllowAgentForwarding no
# AllowTcpForwarding no
# X11Forwarding no

## Disable root login
# PermitRootLogin no
# PermitRootLogin prohibit-password
EOF
fi

# Restart ssh service
systemctl is-enabled ssh >/dev/null 2>&1 && sudo systemctl restart ssh
systemctl is-enabled sshd >/dev/null 2>&1 && sudo systemctl restart sshd

# output the effective configuration
sudo sshd -T | grep -Ei 'Forward|Authentication'


## Generate ssh key
## https://linux.die.net/man/1/ssh-keygen
## ssh-keygen [-q] [-b bits] -t type [-N new_passphrase] [-C comment] [-f output_keyfile]
# ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "<username@remote-server.org>"
# ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)-$(date -I)"

## Fix: Load key ... bad permissions
# chmod 600 ~/.ssh/id_ed25519


## Install public key in remote machine's authorized_keys
# ssh-copy-id -i ~/.ssh/id_ed25519.pub username@remote-server.org
## or
# rsync -avz --progress ~/.ssh/id_ed25519.pub username@remote-server.org:
# ssh username@remote-server.org
# mkdir ~/.ssh && \
#     cat ~/id_ed25519.pub >> ~/.ssh/authorized_keys && \
#     rm -f ~/id_ed25519.pub && \
#     chmod 700 ~/.ssh/ && \
#     chmod 600 ~/.ssh/authorized_keys


## [How to Check Failed SSH Login Attempts in Linux](https://operavps.com/docs/check-failed-ssh-login-in-linux/)
# grep -E "Failed|Failure" /var/log/auth.log
# grep -E "Failed|Failure" /var/log/secure
# sudo journalctl -u ssh --since "yesterday"
# sudo journalctl -u sshd --since "yesterday"

cd "${CURRENT_DIR}" || exit