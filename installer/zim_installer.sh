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

# [Zim: Modular, customizable, and blazing fast Zsh framework](https://zimfw.sh/)
INSTALLER_APP_NAME="zim"
INSTALLER_GITHUB_REPO="zimfw/zimfw"

# uninstall oh-my-zsh first
if [[ "$(command -v uninstall_oh_my_zsh)" ]]; then
    # uninstall_oh_my_zsh
    # [[ ! -f "$HOME/.zshrc" && -f "/etc/skel/.zshrc" ]] && cp "/etc/skel/.zshrc" "$HOME/.zshrc"
    colorEcho "${FUCHSIA}Oh-my-zsh${RED} is installed, Please uninstall it first using ${PURPLE}uninstall_oh_my_zsh${RED}!"
    exit
fi

DEFALUT_SHELL=$(basename "$SHELL")
if [[ "${DEFALUT_SHELL}" != "zsh" ]]; then
    colorEcho "${RED}Not running in shell ${PURPLE}zsh${RED}!"
    exit
fi

if [[ ! "$(command -v zimfw)" ]]; then
    curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
fi

if [[ ! "$(command -v zimfw)" ]]; then
    colorEcho "${RED}Zim install failed!"
    exit
fi

sed -i -e "s/^autoload -U compinit/# &/g" -e "s/^compinit/# &/g" "$HOME/.zshrc"

if [[ ! -x "$(command -v fzf)" ]]; then
    Git_Clone_Update_Branch "junegunn/fzf" "$HOME/.fzf"
    [[ -s "$HOME/.fzf/install" ]] && "$HOME/.fzf/install"
fi

if ! grep -q "zsh_custom_conf.sh" "$HOME/.zshrc" 2>/dev/null; then
    echo -e "\n# Custom configuration\nsource ~/.dotfiles/zsh/zsh_custom_conf.sh" >> "$HOME/.zshrc"
fi

## [Themes](https://zimfw.sh/docs/themes/)
# sed -i -e "s/zmodule asciiship/zmodule bira/" "$HOME/.zimrc"

## [Modules](https://zimfw.sh/docs/modules/)
if ! grep -q "zmodule archive" "$HOME/.zimrc"; then
    {
        echo "zmodule archive"
        echo "zmodule exa"
        echo "zmodule fzf"
        echo "# zmodule k"
        echo "zmodule magic-enter"
        echo "zmodule pvenv"
        echo "zmodule ruby"
        echo "zmodule ssh"
        echo "zmodule homebrew"
        echo "zmodule pacman"
        echo "zmodule joke/zim-chezmoi"
        echo "zmodule joke/zim-github-cli"
        echo "zmodule joke/zim-gopass"
        echo "zmodule joke/zim-helm"
        echo "zmodule joke/zim-istioctl"
        echo "zmodule joke/zim-k9s"
        echo "zmodule joke/zim-kn"
        echo "zmodule joke/zim-kubectl"
        echo "zmodule joke/zim-minikube"
        echo "zmodule joke/zim-mise"
        echo "zmodule joke/zim-rtx"
        echo "zmodule joke/zim-skaffold"
        echo "# zmodule joke/zim-starship"
        echo "zmodule joke/zim-steampipe"
        echo "zmodule joke/zim-yq"
        echo "zmodule kiesman99/zim-zoxide"
    } >> "$HOME/.zimrc"
fi

colorEcho "${GREEN}Zim init done, please restart ZSH!"
