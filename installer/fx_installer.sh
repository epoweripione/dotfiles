#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# fx: Command-line tool and terminal JSON viewer
# https://github.com/antonmedv/fx
APP_INSTALL_NAME="fx"
GITHUB_REPO_NAME="antonmedv/fx"

EXEC_INSTALL_NAME="fx"

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"
VERSION_FILENAME=""

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

# Install nodejs
if [[ "${IS_INSTALL}" == "yes" ]]; then
    if [[ ! -x "$(command -v node)" && "$(command -v asdf)" ]]; then
        asdf_App_Install nodejs lts
    fi

    if [[ -x "$(command -v node)" && -x "$(command -v npm)" ]]; then
        NPM_PREFIX=$(npm config get prefix 2>/dev/null)
        if [[ ! -d "${NPM_PREFIX}" ]]; then
            [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]] && \
                source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh"
        fi
    fi
fi


# Install fx
if [[ -x "$(command -v node)" && -x "$(command -v npm)" ]]; then
    if [[ "${IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

        CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
        REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
        if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
            IS_INSTALL="no"
        fi
    fi

    if [[ "${IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
        npm install -g fx
    fi
fi
