#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

App_Installer_Reset

# Magic Wormhole: get things from one computer to another, safely
# https://github.com/magic-wormhole/magic-wormhole
if [[ ! -x "$(command -v wormhole)" && -x "$(command -v pacman)" ]]; then
    PackagesList=(
        magic-wormhole
        python-magic-wormhole
        # python-magic-wormhole-mailbox-server
        # python-magic-wormhole-transit-relay
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi

if [[ ! -x "$(command -v wormhole)" && -x "$(command -v snap)" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}Magic Wormhole${BLUE}..."
    sudo snap install wormhole
fi

if [[ ! -x "$(command -v wormhole)" && -x "$(command -v brew)" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}Magic Wormhole${BLUE}..."
    brew install magic-wormhole
fi

if [[ ! -x "$(command -v wormhole)" && -x "$(command -v pip)" ]]; then
    if [[ -x "$(command -v pacman)" ]]; then
        PackagesList=(
            build-essential
            libffi-dev
            libssl-dev
            python-dev
            libsodium-dev
            libsodium-devel
        )
        for TargetPackage in "${PackagesList[@]}"; do
            if checkPackageNeedInstall "${TargetPackage}"; then
                colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
                sudo pacman --noconfirm -S "${TargetPackage}"
            fi
        done
    fi

    colorEcho "${BLUE}  Installing ${FUCHSIA}Magic Wormhole${BLUE}..."
    pip install --user -U magic-wormhole
    # pip install --user -U magic-wormhole-mailbox-server
    # pip install --user -U magic-wormhole-transit-relay
fi


: '
# Running Magic Wormhole Mailbox Server & Transit Relay with `docker`
tee "start_wormhole.sh" >/dev/null <<-EOF
#!/usr/bin/env bash

twistd --pidfile=mailbox.pid --logfile=mailbox.log wormhole-mailbox --usage-db=usage.sqlite
twistd --pidfile=transitrelay.pid --logfile=transitrelay.log transitrelay --port=tcp:4001

tail -F mailbox.log transitrelay.log
EOF

tee "Dockerfile" >/dev/null <<-EOF
FROM python:slim

WORKDIR /root
COPY . .

RUN pip install magic-wormhole-mailbox-server magic-wormhole-transit-relay

EXPOSE 4000
EXPOSE 4001

VOLUME [/root/]

CMD ["/bin/bash", "/root/start_wormhole.sh"]
EOF

docker build -t magicwormhole Dockerfile
docker run -p 4000:4000 -p 4001:4001 -d magicwormhole
'


: '
# Usage
wormhole send [--text TEXT] [file(s)-or-folder]
wormhole receive [code-phrase]

wormhole --relay-url="ws://example.com:4000/v1" --transit-helper="tcp:example.com:4001" send [--text TEXT] [file(s)-or-folder]
wormhole --relay-url="ws://example.com:4000/v1" --transit-helper="tcp:example.com:4001" receive [code-phrase]

## Send SSH public-key to remote host
# Remote host: Add a public-key to a ~/.ssh/authorized_keys file
wormhole ssh invite
# Send your SSH public-key In response to a `wormhole ssh invite`...
wormhole ssh accept [code-phrase]
'
