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

# [Bifrost AI Gateway - The fastest way to build AI applications that never go down](https://github.com/maximhq/bifrost)
INSTALLER_APP_NAME="bifrost"
INSTALLER_GITHUB_REPO="maximhq/bifrost"
INSTALLER_BINARY_NAME="bifrost"

INSTALLER_NPM_PACKAGE="@maximhq/bifrost"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# install nodejs & npm using fnm
fnm_Install_Nodejs

if [[ -x "$(command -v npx)" ]]; then
    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

        INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
        App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
        if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
            INSTALLER_IS_INSTALL="no"
        fi
    fi

    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        # Install and run locally
        npx -y "${INSTALLER_NPM_PACKAGE}"
    fi
fi


## Step 1: Start Bifrost Gateway
## Install and run locally
# npx -y @maximhq/bifrost

## Or use Docker
# docker run -p 8080:8080 -v $(pwd)/data:/app/data maximhq/bifrost

## Step 2: Configure via Web UI
# Open the built-in web interface: `http://localhost:8080`

## Step 3: Make your first API call
# curl -X POST http://localhost:8080/v1/chat/completions \
#     -H "Content-Type: application/json" \
#     -d '{
#         "model": "openai/gpt-4o-mini",
#         "messages": [{"role": "user", "content": "Hello, Bifrost!"}]
#     }'
