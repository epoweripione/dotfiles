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

# [mieru](https://github.com/enfein/mieru)
INSTALLER_APP_NAME="mieru"
INSTALLER_GITHUB_REPO="enfein/mieru"

INSTALLER_INSTALL_NAME="mieru"

INSTALLER_ARCHIVE_EXT="tar.gz"

if [[ -x "$(command -v mieru)" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(mieru version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

: '
tee "$HOME/.config/mieru_client.json" >/dev/null <<-'EOF'
{
    "profiles": [
        {
            "profileName": "default",
            "user": {
                "name": "<username@example.com>",
                "password": "<your-password>"
            },
            "servers": [
                {
                    "ipAddress": "<1.1.1.1>",
                    "domainName": "",
                    "portBindings": [
                        {
                            "port": -1,
                            "protocol": "TCP"
                        }
                    ]
                }
            ],
            "mtu": 1400
        }
    ],
    "activeProfile": "default",
    "rpcPort": -1,
    "socks5Port": -1,
    "loggingLevel": "INFO",
    "socks5ListenLAN": false,
    "httpProxyPort": -1,
    "httpProxyListenLAN": false
}
EOF

mieru apply config "$HOME/.config/mieru_client.json"
mieru describe config

mieru start
mieru status
mieru stop
'
