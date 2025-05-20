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

# ☄🌌️ The minimal, blazing-fast, and infinitely customizable prompt for any shell!
# https://github.com/starship/starship
INSTALLER_APP_NAME="starship"

if [[ -x "$(command -v starship)" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(starship -V | cut -d" " -f2)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/starship/starship/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
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
