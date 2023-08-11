#!/usr/bin/env bash

# Load custom environment variables
[[ -s "$HOME/.dotfiles.env.local" ]] && source "$HOME/.dotfiles.env.local"

if [[ -z "${MY_SHELL_SCRIPTS}" ]]; then
    [[ -d "$HOME/.dotfiles" ]] && export MY_SHELL_SCRIPTS="$HOME/.dotfiles"
fi

FunctionList=(
    "public"
    "system"
    "osinfo"
    "network"
    "proxy"
    "git"
    "docker"
    "installer"
    "versions"
    "web"
    "misc"
    "mirrors"
)
for Target in "${FunctionList[@]}"; do
    TargetFile="${MY_SHELL_SCRIPTS}/functions/${Target}.sh"
    [[ -s "${TargetFile}" ]] && source "${TargetFile}"
done

# Environment variables
[[ -s "${MY_SHELL_SCRIPTS}/functions/env.sh" ]] && source "${MY_SHELL_SCRIPTS}/functions/env.sh"

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env
# if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
#     # Check & set global proxy
#     check_set_global_proxy "${GLOBAL_PROXY_SOCKS_PORT:-7891}" "${GLOBAL_PROXY_MIXED_PORT:-7890}"
# fi

# mirrors
[[ -z "${USE_MIRROR_WHEN_BLOCKED}" ]] && USE_MIRROR_WHEN_BLOCKED="true"
if [[ "${THE_WORLD_BLOCKED}" == "true" && "${USE_MIRROR_WHEN_BLOCKED}" == "true" ]]; then
    setMirrorDocker
    setMirrorHomebrew
    # setMirrorGo # set by installer/goup_go_installer.sh, installer/gvm_go_installer.sh
    setMirrorFlutter
    setMirrorRust
    setMirrorNodejs
    # setMirrorNpm # set by nodejs/nvm_node_installer.sh, nodejs/nvs_node_installer.sh
    setMirrorPip
    setMirrorConda
    setMirrorRbenv
    # setMirrorGem # set by installer/rbenv_ruby_installer.sh
fi
