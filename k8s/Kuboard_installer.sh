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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

K8S_WORKDIR="$HOME/k8s" && mkdir -p "${K8S_WORKDIR}"

# Kuboard for Kubernetes
# https://kuboard.cn/
curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${K8S_WORKDIR}/kuboard.yaml" \
    "https://addons.kuboard.cn/kuboard/kuboard-v3.yaml"

kubectl apply -f "${K8S_WORKDIR}/kuboard.yaml"

kubectl wait -n kuboard --for=condition=ready pod --all --timeout=120s

# http://your-node-ip-address:30080
# admin:Kuboard123

cd "${CURRENT_DIR}" || exit
