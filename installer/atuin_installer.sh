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

# [Sync, search and backup shell history with Atuin](https://github.com/atuinsh/atuin)
INSTALLER_APP_NAME="atuin"
INSTALLER_GITHUB_REPO="atuinsh/atuin"

INSTALLER_INSTALL_NAME="atuin"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if [[ "${INSTALLER_IS_UPDATE}" == "yes" ]]; then
        colorEcho "${BLUE}  Updating ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE} to ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        atuin update
    else
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    fi

    # bash
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -q "atuin init" "$HOME/.bashrc"; then
            # use fzf to search history, disable ctrl-r in atuin
            if ! grep -q "disable-ctrl-r" "$HOME/.bashrc"; then
                sed -i 's/atuin init bash/atuin init bash --disable-ctrl-r/g' "$HOME/.bashrc"
            fi
        else
            echo 'source $HOME/.atuin/bin/env' >> "$HOME/.bashrc"
            echo 'eval "$(atuin init bash --disable-ctrl-r)"' >> "$HOME/.bashrc"
        fi
    fi

    # zsh
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q "atuin init" "$HOME/.zshrc"; then
            # use fzf to search history, disable ctrl-r in atuin
            if ! grep -q "disable-ctrl-r" "$HOME/.zshrc"; then
                sed -i 's/atuin init zsh/atuin init zsh --disable-ctrl-r/g' "$HOME/.zshrc"
            fi
        else
            echo 'source $HOME/.atuin/bin/env' >> "$HOME/.zshrc"
            echo 'eval "$(atuin init zsh --disable-ctrl-r)"' >> "$HOME/.zshrc"
        fi
    fi

    ## [Configure atuin](https://docs.atuin.sh/cli/reference/config/)
    # atuin config print
    if [[ -f "$HOME/.config/atuin/config.toml" ]]; then
        # Disable immediately executing a command when pressing Enter in atuin's interactive search mode
        # sed -i 's/^[# ]*enter_accept[ ]*=.*/enter_accept = false/' "$HOME/.config/atuin/config.toml"
        atuin config set enter_accept false
        # Inline window
        atuin config set style "compact"
        atuin config set inline_height 20
    fi
fi

# atuin register -u <USERNAME> -e <EMAIL>
# atuin import auto
# atuin sync
