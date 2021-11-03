#!/usr/bin/env bash

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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# https://brew.sh/index_zh-cn
colorEcho "${BLUE}Installing ${FUCHSIA}homebrew${BLUE}..."

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type

case "${OS_INFO_TYPE}" in
    darwin | linux)
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        ;;
    *)
        colorEcho "${RED}Operating system does not support!"
        exit 0
        ;;
esac

# https://docs.brew.sh/Homebrew-on-Linux
if [[ "${OS_INFO_TYPE}" == "linux" && -s "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> "$HOME/.zprofile"
    # eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

## offical
# cd "$(brew --repo)"
# git remote set-url origin https://github.com/Homebrew/brew.git

# cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
# git remote set-url origin https://github.com/Homebrew/homebrew-core

# cd "$(brew --repo)/Library/Taps/homebrew/homebrew-cask"
# git remote set-url origin https://github.com/Homebrew/homebrew-cask

## mirrors
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    cd "$(brew --repo)" && \
        git remote set-url origin https://mirrors.ustc.edu.cn/brew.git

    cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core" && \
        git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git

    cd "$(brew --repo)/Library/Taps/homebrew/homebrew-cask" && \
        git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git
fi

## Bottles (Binary Packages)
## https://docs.brew.sh/Bottles
# if ! grep -q "HOMEBREW_BOTTLE_DOMAIN" "$HOME/.zshrc" 2>/dev/null; then
#     echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles' >> ~/.zshrc
#     # source ~/.zshrc
# fi


cd "${CURRENT_DIR}" || exit