#!/usr/bin/env bash

if [[ $UID -ne 0 ]]; then
    echo "Please run this script as root user!"
    exit 0
fi

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


# Webmin
# http://www.webmin.com/index.html
colorEcho "${BLUE}Installing ${FUCHSIA}Webmin${BLUE}..."
if check_release_package_manager packageManager yum; then
    tee /etc/yum.repos.d/webmin.repo <<-'EOF'
[Webmin]
name=Webmin Distribution Neutral
#baseurl=https://download.webmin.com/download/yum
mirrorlist=https://download.webmin.com/download/yum/mirrorlist
enabled=1
EOF
    wget http://www.webmin.com/jcameron-key.asc
    rpm --import jcameron-key.asc
    yum install -y -q webmin
    firewall-cmd --permanent --zone=public --add-port=10000/tcp
    firewall-cmd --reload
elif check_release_package_manager packageManager apt; then
    curl -fsSL http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
    echo "deb https://download.webmin.com/download/repository sarge contrib" | tee /etc/apt/sources.list.d/webmin.list
    apt update && apt -y install apt-transport-https webmin
fi

# Once Webmin is installed and runing, 
# you can access Webmin via the IP or web address you supplied or were given by the system.
# Specify port 10000.
# Example:
# https://192.168.1.100:10000/