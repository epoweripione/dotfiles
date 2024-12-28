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

mkdir -p "${CURRENT_DIR}/dist/"

Git_Clone_Update_Branch "av01d/fontpicker-jquery-plugin" "${CURRENT_DIR}/dist/fontpicker-jquery-plugin"

if [[ -s "${CURRENT_DIR}/fontpicker-jquery-plugin.patch" ]]; then
    cd "${CURRENT_DIR}/dist/fontpicker-jquery-plugin" && \
        git apply "${CURRENT_DIR}/fontpicker-jquery-plugin.patch" && \
        cp "${CURRENT_DIR}/dist/fontpicker-jquery-plugin/dist/jquery.fontpicker.css" "${CURRENT_DIR}/dist/" && \
        cp "${CURRENT_DIR}/dist/fontpicker-jquery-plugin/dist/jquery.fontpicker.js" "${CURRENT_DIR}/dist/"
fi

cd "${CURRENT_DIR}" || exit