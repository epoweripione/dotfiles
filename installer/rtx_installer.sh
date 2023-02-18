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

# [Runtime Executor (asdf rust clone)](https://github.com/jdxcode/rtx)
APP_INSTALL_NAME="rtx"
GITHUB_REPO_NAME="jdxcode/rtx"

EXEC_INSTALL_NAME="rtx"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_DIR="rtx*"
ARCHIVE_EXEC_NAME="rtx*"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${APP_INSTALL_NAME}${RED} failed!"
fi

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    if ! grep -q 'rtx activate zsh' "$HOME/.zshrc" >/dev/null 2>&1; then
        (echo -e '\n# rtx'; echo 'eval "$(rtx activate zsh)"') >> "$HOME/.zshrc"
    fi

    ## completions
    # if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}" ]]; then
    #     mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/rtx" && \
    #         rtx complete --shell zsh > "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/rtx/_rtx"
    # fi
    if [[ ! -s "/usr/local/share/zsh/site-functions/_rtx" ]]; then
        rtx complete --shell zsh | sudo tee "/usr/local/share/zsh/site-functions/_rtx" >/dev/null
    fi
fi

# rtx plugins ls-remote
# rtx ls
# rtx ls-remote <PLUGIN>
# rtx latest <RUNTIME>
# rtx global <RUNTIME>

cd "${CURRENT_DIR}" || exit