#!/usr/bin/env bash

# fix "command not found" when running via cron
function FixSystemBinPath() {
    local DirList=()
    local TargetDir

    DirList=(
        "/usr/local/sbin"
        "/usr/local/bin"
        "/usr/sbin"
        "/usr/bin"
        "/sbin"
        "/bin"
    )

    for TargetDir in "${DirList[@]}"; do
        [[ -d "${TargetDir}" && ":$PATH:" != *":${TargetDir}:"* ]] && PATH="${TargetDir}:$PATH"
    done
}

# fix "command not found" when running via cron
FixSystemBinPath

## Run proxy client from local variables
# NAIVEPROXY_PORT=7895
# NAIVEPROXY_URL=()

# Load variables from local proxy env file
[[ -s "$HOME/.proxy.env.local" ]] || exit 1

source "$HOME/.proxy.env.local"

case "$1" in
    'down')
        pgrep -f "naive" >/dev/null 2>&1 && pkill -f "naive"
        pgrep -f "naiveproxy" >/dev/null 2>&1 && pkill -f "naiveproxy"
        pgrep -f "mieru" >/dev/null 2>&1 && pkill -f "mieru"
        ;;
    'up')
        # [[ ! -x "$(command -v naiveproxy)" ]] && echo "naiveproxy not installed!" && exit 1

        if [[ -x "$(command -v naiveproxy)" ]]; then
            pgrep -f "naive" >/dev/null 2>&1 && pkill -f "naive"
            pgrep -f "naiveproxy" >/dev/null 2>&1 && pkill -f "naiveproxy"

            for TargetUrl in "${NAIVEPROXY_URL[@]}"; do
                [[ -z "${TargetUrl}" ]] && continue

                nohup naiveproxy --listen="socks://127.0.0.1:${NAIVEPROXY_PORT}" --proxy="${TargetUrl}" >/dev/null 2>&1 &

                NAIVEPROXY_PORT=$((NAIVEPROXY_PORT + 1))
            done
        fi

        if [[ -x "$(command -v mieru)" && -s "${MIERU_CONFIG}" ]]; then
            pgrep -f "mieru" >/dev/null 2>&1 && pkill -f "mieru"

            if mieru describe config | grep -q '{}'; then
                mieru apply config "${MIERU_CONFIG}"
            fi

            mieru stop
            nohup mieru start >/dev/null 2>&1 &
        fi
        ;;
esac
