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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

[[ ! "$(command -v asdf)" ]] && colorEcho "${FUCHSIA}asdf${RED} is not installed!" && exit 0

# Neovim: Vim-fork focused on extensibility and usability
# https://neovim.io/
asdf plugin add neovim
asdf install neovim stable
asdf global neovim stable

# alias update-nvim-stable='asdf uninstall neovim stable && asdf install neovim stable'


if [[ -x "$(command -v nvim)" ]]; then
    ## vim-plug: Minimalist Vim Plugin Manager
    # sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    #     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

    # Install NeoVim config and Plugin config
    NEOVIM_CUSTOM="$HOME/.config/nvim"
    NEOVIM_BACKUP="$HOME/.local/share/nvim/backup"
    mkdir -p "${NEOVIM_CUSTOM}"
    mkdir -p "${NEOVIM_BACKUP}"

    # wget "https://raw.githubusercontent.com/mkinoshi/dotfiles/master/nvim/init.vim" -O init.vim && \
    #     wget "https://raw.githubusercontent.com/mkinoshi/dotfiles/master/nvim/plugins.vim" -O plugins.vim && \
    #     mv init.vim "${NEOVIM_CUSTOM}" && \
    #     mv plugins.vim "${NEOVIM_CUSTOM}" && \
    #     sed -i '/^Plug.*coc\.nvim/ s/^/" /' "${NEOVIM_CUSTOM}/plugins.vim" && \
    #     sed -i '/^Plug.*new-denite/ s/^/" /' "${NEOVIM_CUSTOM}/plugins.vim" && \
    #     sed -i '/^"\s*Plug.*denite.nvim/ s/"\s*//' "${NEOVIM_CUSTOM}/plugins.vim" && \
    #     nvim +PlugInstall +qall # This script assumes that you are using vim-plug for plugin management 

    # Enable python3 support for NeoVim
    pip_Package_Install "neovim"

    ## NvChad
    ## An attempt to make neovim cli as functional as an IDE while being very beautiful , blazing fast.
    ## https://github.com/NvChad/NvChad
    ## https://github.com/NvChad/NvChad/wiki/Mappings
    # if ! grep -q 'NvChad' "${NEOVIM_CUSTOM}/README.md" 2>/dev/null; then
    #     colorEcho "${BLUE}  Installing ${FUCHSIA}NvChad${BLUE}..."
    #     [[ -d "${NEOVIM_CUSTOM}.backup" ]] && rm -rf "${NEOVIM_CUSTOM}.backup"
    #     [[ -d "${NEOVIM_CUSTOM}" ]] && mv "${NEOVIM_CUSTOM}" "${NEOVIM_CUSTOM}.backup"
    #     Git_Clone_Update_Branch "NvChad/NvChad" "${NEOVIM_CUSTOM}"
    #     nvim +'hi NormalFloat guibg=#1e222a' +PackerSync
    # fi

    ## AstroVim is an aesthetic and feature-rich neovim config that is extensible and easy to use with a great set of plugins
    ## https://github.com/kabinspace/AstroVim
    # if ! grep -q 'AstroVim' "${NEOVIM_CUSTOM}/README.md" 2>/dev/null; then
    #     colorEcho "${BLUE}  Installing ${FUCHSIA}AstroVim${BLUE}..."
    #     [[ -d "${NEOVIM_CUSTOM}.backup" ]] && rm -rf "${NEOVIM_CUSTOM}.backup"
    #     [[ -d "${NEOVIM_CUSTOM}" ]] && mv "${NEOVIM_CUSTOM}" "${NEOVIM_CUSTOM}.backup"
    #     Git_Clone_Update_Branch "kabinspace/AstroVim" "${NEOVIM_CUSTOM}"
    #     nvim +PackerSync
    # fi

    # SpaceVim: A community-driven vim distribution
    # https://spacevim.org/
    colorEcho "${BLUE}  Installing ${FUCHSIA}SpaceVim${BLUE}..."
    [[ -d "${NEOVIM_CUSTOM}.backup" ]] && rm -rf "${NEOVIM_CUSTOM}.backup"
    [[ -d "${NEOVIM_CUSTOM}" ]] && mv "${NEOVIM_CUSTOM}" "${NEOVIM_CUSTOM}.backup"
    curl -sLf https://spacevim.org/install.sh | bash
fi


cd "${CURRENT_DIR}" || exit