#!/usr/bin/env bash

## Usage:
## 1. Install `curl git`
## 2. Clone repo: source <(curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue)
##    or
##    curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue | bash "$HOME/.dotfiles"
## 3. Install zsh and oh-my-zsh: ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_installer.sh
## 4. Change default shell to zsh: chsh -s $(which zsh)
## 5. Init: ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_upgrade_all_packages.sh && ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_init.sh
## 6. Update: source <(curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue) && ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_upgrade_all_packages.sh
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Colors
NOCOLOR='\033[0m'
RED='\033[0;31m'        # Error message
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'      # Success message
LIGHTGREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'     # Warning message
BLUE='\033[0;34m'       # Info message
LIGHTBLUE='\033[1;34m'
PURPLE='\033[0;35m'
FUCHSIA='\033[0;35m'
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHTCYAN='\033[1;36m'
DARKGRAY='\033[1;30m'
LIGHTGRAY='\033[0;37m'
WHITE='\033[1;37m'

function colorEcho() {
    if [[ $# -gt 1 ]]; then
        local COLOR=$1
        echo -e "${COLOR}${@:2}${NOCOLOR}"
    else
        echo -e "${@:1}${NOCOLOR}"
    fi
}

if [[ ! "$(command -v git)" ]]; then
    colorEcho "${FUCHSIA}git${RED} is not installed, Please install it first!"
    exit
fi

MY_SHELL_SCRIPTS="${1:-$HOME/.dotfiles}"

colorEcho "${BLUE}Cloning ${ORANGE}dotfiles & scripts ${BLUE}to ${FUCHSIA}${MY_SHELL_SCRIPTS}${BLUE}..."
# [[ -d "$HOME/terminal-custom" ]] && rm -rf "$HOME/terminal-custom"
if [[ -d "${MY_SHELL_SCRIPTS}" ]]; then
    cd "${MY_SHELL_SCRIPTS}" && \
        BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null) && \
            git pull --rebase --stat origin "${BRANCH:-main}"
else
    REPOREMOTE="https://github.com/epoweripione/dotfiles.git"
    BRANCH=$(git ls-remote --symref "${REPOREMOTE}" HEAD \
                | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
    git clone -c core.autocrlf=false -c core.filemode=false \
        -c fsck.zeroPaddedFilemode=ignore \
        -c fetch.fsck.zeroPaddedFilemode=ignore \
        -c receive.fsck.zeroPaddedFilemode=ignore \
        --depth=1 --branch "${BRANCH:-main}" "${REPOREMOTE}" "${MY_SHELL_SCRIPTS}"
fi

# starship config
if [[ -x "$(command -v starship)" ]]; then
    [[ ! -d "$HOME/.config" ]] && mkdir -p "$HOME/.config"
    cp -f "${MY_SHELL_SCRIPTS}/zsh/themes/starship.toml" "$HOME/.config/starship.toml"
fi

# starship config
if [[ -x "$(command -v oh-my-posh)" ]]; then
    cp -f "${MY_SHELL_SCRIPTS}/powershell/themes/"*.omp.json "$HOME/.poshthemes"
fi

# make *.sh executable
find "${MY_SHELL_SCRIPTS}" -type f -iname "*.sh" -exec chmod +x {} \;

## git global config
# if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/git/git_global_config.sh" ]]; then
#     source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/git/git_global_config.sh"
# fi

# fix location in .zshrc
if [[ -s "$HOME/.zshrc" ]]; then
    sed -i "s|^source ~/zsh_custom_conf.sh|source ~/.dotfiles/zsh/zsh_custom_conf.sh|" "$HOME/.zshrc"
    sed -i "s|^source ~/terminal-custom/zsh/zsh_custom_conf.sh|source ~/.dotfiles/zsh/zsh_custom_conf.sh|" "$HOME/.zshrc"
    sed -i "s|~/terminal-custom|~/.dotfiles|g" "$HOME/.zshrc"
fi

# fix location in cron jobs
if [[ -x "$(command -v crontab)" ]]; then
    if crontab -l | grep -q '/terminal-custom/' 2>/dev/null; then
        crontab -l | sed "s|/terminal-custom/|/.dotfiles/|g" | crontab -
    fi
fi

if [[ -d "$ZSH/custom" ]]; then
    colorEcho "${BLUE}Copying ZSH custom plugins & themes to ${FUCHSIA}$ZSH/custom${BLUE}..."
    # zsh custom plugins
    [ -d "$HOME/.dotfiles/zsh/plugins" ] && cp -f "$HOME/.dotfiles/zsh/plugins/"* "$ZSH/custom/plugins"

    # zsh custom themes
    [ -d "$HOME/.dotfiles/zsh/themes" ] && cp -f "$HOME/.dotfiles/zsh/themes/"*.zsh-theme "$ZSH/custom/themes"
fi

colorEcho "${ORANGE}Dotfiles & Scripts ${GREEN}successfully downloaded to ${FUCHSIA}${MY_SHELL_SCRIPTS}${GREEN}!"

cd "${CURRENT_DIR}" || exit