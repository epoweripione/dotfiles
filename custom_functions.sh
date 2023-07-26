#!/usr/bin/env bash

if [[ -z "${MY_SHELL_SCRIPTS}" ]]; then
    [[ -d "$$HOME/.dotfiles" ]] && export MY_SHELL_SCRIPTS="$$HOME/.dotfiles"
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
)
for Target in "${FunctionList[@]}"; do
    TargetFile="${MY_SHELL_SCRIPTS}/functions/${Target}.sh"
    [[ -s "${TargetFile}" ]] && source "${TargetFile}"
done
