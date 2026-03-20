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

# [OpenClaw — Personal AI Assistant](https://github.com/openclaw/openclaw)
INSTALLER_APP_NAME="openclaw"
INSTALLER_GITHUB_REPO="openclaw/openclaw"
INSTALLER_BINARY_NAME="openclaw"

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
        npm_Install_Global "${INSTALLER_APP_NAME}"

        # [Clawhub - Skill Directory for OpenClaw](https://clawhub.ai/)
        npm_Install_Global "clawhub"
    fi
fi

## Quick start
# openclaw --version
# openclaw doctor

## Install the Gateway daemon (launchd/systemd user service)
# openclaw onboard --install-daemon
# openclaw status --deep
# openclaw gateway --port 18789 --verbose

## Send a message
# openclaw message send --to +1234567890 --message "Hello from OpenClaw"

## Talk to the assistant
## optionally deliver back to any connected channel:
## WhatsApp/Telegram/Slack/Discord/Google Chat/Signal/iMessage/BlueBubbles/IRC/Microsoft Teams/Matrix/Feishu/LINE/Mattermost/Nextcloud Talk/Nostr/Synology Chat/Tlon/Twitch/Zalo/Zalo Personal/WebChat
# openclaw agent --message "Ship checklist" --thinking high

## Update Gateway systemd service after update openclaw
# openclaw doctor
