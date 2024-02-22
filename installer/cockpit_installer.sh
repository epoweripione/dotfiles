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

# Cockpit
# https://cockpit-project.org/
# https://github.com/cockpit-project/cockpit
# GETTING STARTED WITH COCKPIT
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/getting_started_with_cockpit/index

# Setting up the primary Cockpit server
colorEcho "${BLUE}Installing ${FUCHSIA}Cockpit${BLUE}..."
if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        cockpit
        cockpit-docker
        # cockpit-doc
        # cockpit-machines
    )
    InstallSystemPackages "" "${PackagesList[@]}"
fi

if check_release_package_manager release centos; then
    sudo systemctl enable --now cockpit.socket

    sudo firewall-cmd --permanent --zone=public --add-service=cockpit
    sudo firewall-cmd --reload
fi

# If you already have Cockpit on your server, 
# point your web browser to: https://ip-address-of-machine:9090

# /etc/cockpit/cockpit.conf

# Proxying Cockpit over NGINX
# https://github.com/cockpit-project/cockpit/wiki/Proxying-Cockpit-over-NGINX
# tee /etc/cockpit/cockpit.conf <<-'EOF'
# [WebService]
# AllowUnencrypted=true
# UrlRoot=/server/
# EOF
sudo tee /etc/cockpit/cockpit.conf <<-'EOF'
[WebService]
AllowUnencrypted=true
EOF

# Adding secondary systems
# Once you log in to the primary server,
# you will be able to connect to secondary servers.
# These secondary systems need to have:
# The cockpit packages installed.
# An SSH server running and available on port 22 that supports password or key-based authentication.

# https://github.com/cockpit-project/cockpit/issues/8110
# secondary needs cockpit-system.
# The only package that it doesn't need is cockpit-ws.
# systemctl disable cockpit.socket
# systemctl disable cockpit