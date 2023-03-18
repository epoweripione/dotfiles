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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# fx: Command-line tool and terminal JSON viewer
# https://github.com/antonmedv/fx
INSTALLER_APP_NAME="fx"
INSTALLER_GITHUB_REPO="antonmedv/fx"

INSTALLER_INSTALL_NAME="fx"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

## Install nodejs
# if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
#     [[ ! -x "$(command -v node)" && -x "$(command -v rtx)" ]] && rtx global nodejs@lts
#     [[ ! -x "$(command -v node)" && "$(command -v asdf)" ]] && asdf_App_Install nodejs lts

#     if [[ -x "$(command -v node)" && -x "$(command -v npm)" ]]; then
#         NPM_PREFIX=$(npm config get prefix 2>/dev/null)
#         if [[ ! -d "${NPM_PREFIX}" ]]; then
#             [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]] && \
#                 source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh"
#         fi
#     fi
# fi


## Install fx
# if [[ "${INSTALLER_IS_INSTALL}" == "yes" && -x "$(command -v node)" && -x "$(command -v npm)" ]]; then
#     colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
#     npm install -g fx
# fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if App_Installer_Get_Remote "https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest" 'fx_[^"]+'; then
        if App_Installer_Install; then
            :
        else
            colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit
