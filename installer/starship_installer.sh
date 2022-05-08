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

# ☄🌌️ The minimal, blazing-fast, and infinitely customizable prompt for any shell!
# https://github.com/starship/starship
APP_INSTALL_NAME="starship"

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v starship)" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(starship -V | cut -d" " -f2)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/starship/starship/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    # curl -fsSL https://starship.rs/install.sh | bash

    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/starship_install.sh" "https://starship.rs/install.sh" && \
        chmod +x "${WORKDIR}/starship_install.sh" && \
        "${WORKDIR}/starship_install.sh" --force

    ## config
    # mkdir -p ~/.config && touch ~/.config/starship.toml
    if [[ ! -s "$HOME/.config/starship.toml" ]]; then
        mkdir -p "$HOME/.config"
        cp -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/themes/starship.toml" "$HOME/.config"
    fi

    # bash
    if ! grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
        echo '' >> "$HOME/.bashrc"
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    fi

    # zsh
    if ! grep -q "starship init zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo '' >> "$HOME/.zshrc"
        echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
    fi
fi

## powershell
# @'
# ## https://starship.rs/
# if (Get-Command "starship" -ErrorAction SilentlyContinue) {
#     Invoke-Expression (&starship init powershell)
# }
# '@ | Tee-Object $PROFILE -Append | Out-Null
