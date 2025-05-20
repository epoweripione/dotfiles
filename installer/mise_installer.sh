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

# [The front-end to your dev env (formerly called "rtx")](https://mise.jdx.dev/)
INSTALLER_GITHUB_REPO="jdx/mise"
INSTALLER_BINARY_NAME="mise"

INSTALLER_ARCHIVE_EXT="tar.gz"

installPrebuiltBinary "${INSTALLER_BINARY_NAME}#${INSTALLER_GITHUB_REPO}#${INSTALLER_ARCHIVE_EXT}#${INSTALLER_BINARY_NAME}*"

if [[ "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    sed -i -e '/^# rtx$/d' -e '/rtx activate bash/d' "$HOME/.bashrc"
    sed -i -e '/^# rtx$/d' -e '/rtx activate zsh/d' "$HOME/.zshrc"
    [[ -f "/usr/local/share/zsh/site-functions/_rtx" ]] && sudo rm -f "/usr/local/share/zsh/site-functions/_rtx"

    if ! grep -q 'mise activate bash' "$HOME/.bashrc" >/dev/null 2>&1; then
        (echo -e '\n# mise'; echo 'eval "$(mise activate bash)"') >> "$HOME/.bashrc"
    fi

    if ! grep -q 'mise activate zsh' "$HOME/.zshrc" >/dev/null 2>&1; then
        (echo -e '\n# mise'; echo 'eval "$(mise activate zsh)"') >> "$HOME/.zshrc"
    fi

    # Hook mise into ZSH
    [[ -n "$ZSH" && -z "${MISE_SHELL}" ]] && eval "$(mise activate zsh)"

    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        mise complete --shell zsh | sudo tee "/usr/local/share/zsh/site-functions/_mise" >/dev/null

        [[ -s "$HOME/.tool-versions" ]] && cd "$HOME" && mise install --yes
    fi
fi

# mise plugins ls-remote
# mise ls
# mise ls-remote <PLUGIN>
# mise latest <RUNTIME>
# mise use --global <RUNTIME>

cd "${CURRENT_DIR}" || exit