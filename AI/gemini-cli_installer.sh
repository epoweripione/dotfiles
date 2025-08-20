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

# [Gemini CLI - open-source AI agent that brings the power of Gemini directly into your terminal](hhttps://github.com/google-gemini/gemini-cli)
INSTALLER_APP_NAME="gemini-cli"
INSTALLER_GITHUB_REPO="google-gemini/gemini-cli"
INSTALLER_BINARY_NAME="gemini"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# Nodejs
if [[ ! -x "$(command -v npm)" ]]; then
    # nvs
    [[ -d "$HOME/.nvs" ]] && export NVS_HOME="$HOME/.nvs" && source "$NVS_HOME/nvs.sh"
    # nvm
    [[ -d "$HOME/.nvm" ]] && export NVM_DIR="$HOME/.nvm" && source "$NVM_DIR/nvm.sh"
fi

# if [[ ! -x "$(command -v npm)" ]]; then
#     colorEcho "${RED}Please install ${FUCHSIA}nodejs & npm${RED} first!"
#     cd "${CURRENT_DIR}" && exit 1
# fi

if [[ -x "$(command -v node)" && -x "$(command -v npm)" ]]; then
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
        npm install -g @google/gemini-cli
    fi
fi


## Authentication Options
## Option 1: OAuth login (Using your Google Account)

## Option 2: Gemini API Key
## Get your key from https://aistudio.google.com/apikey
# export GEMINI_API_KEY="YOUR_API_KEY"
# gemini

## Option 3: Vertex AI
## Get your key from Google Cloud Console
# export GOOGLE_API_KEY="YOUR_API_KEY"
# export GOOGLE_GENAI_USE_VERTEXAI=true
# gemini
