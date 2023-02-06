#!/usr/bin/env bash

# fix "command not found" when running via cron
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
        ;;
    'up')
        [[ ! -x "$(command -v naiveproxy)" ]] && echo "naiveproxy not installed!" && exit 1

        pgrep -f "naive" >/dev/null 2>&1 && pkill -f "naive"
        pgrep -f "naiveproxy" >/dev/null 2>&1 && pkill -f "naiveproxy"

        for TargetUrl in "${NAIVEPROXY_URL[@]}"; do
            [[ -z "${TargetUrl}" ]] && continue

            nohup naiveproxy --listen="socks://127.0.0.1:${NAIVEPROXY_PORT}" --proxy="${TargetUrl}" >/dev/null 2>&1 &

            NAIVEPROXY_PORT=$((NAIVEPROXY_PORT + 1))
        done
        ;;
esac
