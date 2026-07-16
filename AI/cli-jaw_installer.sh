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

# [CLI-JAW: Your personal AI agent](https://github.com/lidge-jun/cli-jaw)
INSTALLER_APP_NAME="cli-jaw"
INSTALLER_GITHUB_REPO="lidge-jun/cli-jaw"
INSTALLER_BINARY_NAME="jaw"

INSTALLER_NPM_PACKAGE="cli-jaw"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# install nodejs & npm using fnm
fnm_Install_Nodejs

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
        # export CLI_JAW_INSTALL_CLI_TOOLS=1
        npm_Install_Global "${INSTALLER_NPM_PACKAGE}"
    fi
fi

## Authenticate
## Free options (no credit card needed)
# copilot login        # GitHub Copilot (free tier available)
# opencode             # OpenCode — free models available
# kiro                 # AWS Kiro (free tier with AWS account)

## Paid (monthly subscription you already pay for)
# claude auth login    # Anthropic Claude Pro or higher
# codex login          # OpenAI ChatGPT Pro or higher
# cursor-agent login   # Cursor
# grok login --oauth   # xAI Grok / Grok Heavy

## Check everything at once
# jaw doctor

## The Dashboard
# jaw dashboard
# http://localhost:24576

## Skills
# jaw skill install <name>    # activate a reference skill
# jaw skill list              # see what's available
