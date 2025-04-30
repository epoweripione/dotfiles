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

# inlets: Cloud Native Tunnel for APIs
# https://github.com/inlets/inlets
INSTALLER_APP_NAME="inlets"
INSTALLER_GITHUB_REPO="inlets/inlets"

INSTALLER_INSTALL_NAME="inlets"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi


## Usage:
## 1. On the exit-server (or server)
## Start the tunnel server on a machine with a publicly-accessible IPv4 IP address such as a VPS.
## Example with a token for client authentication:
# export INLETS_TOKEN=$(head -c 16 /dev/urandom | shasum | cut -d" " -f1)
# inlets server --port=8090 --token="${INLETS_TOKEN}"

## 2. Head over to your machine where you are running a sample service, or something you want to expose.
## For example:
## Python's built-in HTTP server:
# mkdir -p /tmp/inlets-test/ && cd /tmp/inlets-test/ && touch hello-world && python -m SimpleHTTPServer 3000

## 3. Start the tunnel client
# export INLETS_REMOTE="127.0.0.1:8090"    # for testing inlets on your laptop, replace with the public IPv4
# export INLETS_TOKEN="CLIENT-TOKEN-HERE"  # the client token is found on your VPS or on start-up of "inlets server"
# export INLETS_UPSTREAM="http://127.0.0.1:3000"
# inlets client --remote="${INLETS_REMOTE}" --token="${INLETS_TOKEN}" --upstream="${INLETS_UPSTREAM}"


## Run behind nginx
## https://github.com/inlets/inlets/blob/master/contrib/nginx.md
# # If you already have an existing nginx webserver running, 
## you can proxy your inlets server through nginx. Simply create a new site configuration file.
## This example assumes inlets is running port 8000, the default port, 
## but you can use any port number you'd like via --port= when starting the server:
# server {
#     listen 80;

#     # Replace *.inlets.example.com with your own wildcard domain.
#     server_name *.inlets.example.com;

#     #Inlets proxy
#     location / {
#         proxy_pass http://127.0.0.1:8000;
#         proxy_http_version 1.1;
#         proxy_read_timeout 120s;
#         proxy_connect_timeout 120s;
#         proxy_set_header Host $host;
#         proxy_set_header Upgrade $http_upgrade;
#         proxy_set_header Connection "upgrade";
#     }
# }
## You can even secure your connection with SSL via your own certificate, or use Letsencrypt.

## Start the tunnel client with wss
# export INLETS_REMOTE="wss://inlets.inlets.example.com"
# export INLETS_TOKEN="CLIENT-TOKEN-HERE"
# export INLETS_UPSTREAM="web1.inlets.example.com=http://127.0.0.1:3000,web2.inlets.example.com=http://127.0.0.1:3001"
# inlets client --remote="${INLETS_REMOTE}" --token="${INLETS_TOKEN}" --upstream="${INLETS_UPSTREAM}"


cd "${CURRENT_DIR}" || exit