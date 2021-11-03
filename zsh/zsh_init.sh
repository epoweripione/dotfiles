#!/usr/bin/env bash

if [[ -z "$ZSH" ]]; then
    colorEcho "${RED}Please install ${FUCHSIA}ZSH & Oh-my-zsh${RED} first!"
    exit 0
else
    [[ -z "$ZSH_CUSTOM" ]] && ZSH_CUSTOM="$ZSH/custom"
fi

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

# Determine which desktop environment is installed from the shell
# desktop=$(ps -e | grep -E -i "gnome|kde|mate|cinnamon|lxde|xfce|jwm")
if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
    desktop=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(gnome\|kde\|mate\|cinnamon\|lxde\|xfce\|jwm\).*/\1/')
else
    desktop=$XDG_CURRENT_DESKTOP
fi


# custom configuration
colorEcho "${BLUE}Source custom configuration ${FUCHSIA}~/.dotfiles/zsh/zsh_custom_conf.sh${BLUE} in ${ORANGE}.zshrc${BLUE}..."
if ! grep -q "zsh_custom_conf.sh" "$HOME/.zshrc" 2>/dev/null; then
    # echo -e "\n# Custom configuration\nsource ~/.dotfiles/zsh/zsh_custom_conf.sh" >> "$HOME/.zshrc"
    sed -i "/^# User configuration.*/a\\\n# Custom configuration\nsource ~/.dotfiles/zsh/zsh_custom_conf.sh" "$HOME/.zshrc"
fi
# tee -a "$HOME/.zshrc" >/dev/null <<-'EOF'

# # Custom configuration
# source ~/.dotfiles/zsh/zsh_custom_conf.sh

# EOF


# change the command execution time stamp shown in the history command output
sed -i 's/[#]*[ ]*HIST_STAMPS.*/HIST_STAMPS="yyyy-mm-dd"/' "$HOME/.zshrc"

# disable auto update
sed -i "s/[#]*[ ]*DISABLE_AUTO_UPDATE.*/DISABLE_AUTO_UPDATE=\"true\"/" "$HOME/.zshrc"


# custom theme
colorEcho "${BLUE}custom theme..."
# cp "$HOME/.dotfiles/zsh/zsh_custom_env.sh" "$HOME/.zshenv"
if ! grep -q '# Custom ENV' "$HOME/.zshenv" 2>/dev/null; then
    tee -a "$HOME/.zshenv" >/dev/null <<-'EOF'
# Custom ENV
[[ -z "$TERM" && $(tput colors 2>/dev/null) -eq 256 ]] && export TERM="xterm-256color"

# load-nvmrc: use specified node version for the current directory with .nvmrc
export NVM_LOAD_NVMRC_IN_CURRENT_DIRECTORY=false

# https://superuser.com/questions/645599/why-is-a-percent-sign-appearing-before-each-prompt-on-zsh-in-windows/645612
export PROMPT_EOL_MARK=""
EOF
fi

theme="ys"
custom_theme="zsh_custom_theme_${theme}"

sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"${theme}\"/" "$HOME/.zshrc"

sed -i "/zsh_custom_theme_.*/d" "$HOME/.zshrc"
if [[ -s "${MY_SHELL_SCRIPTS}/zsh/${custom_theme}.sh" ]]; then
    sed -i "/^ZSH_THEME=.*/a\source ~/.dotfiles/zsh/${custom_theme}.sh" "$HOME/.zshrc"
fi

# if [[ -n "$desktop" ]]; then
#   cp ~/.dotfiles/zsh/zsh_custom_env_xterm.sh "$HOME/.zshenv"
#   sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"powerlevel9k\"/" "$HOME/.zshrc"
#   sed -i "/zsh_custom_theme_.*/d" "$HOME/.zshrc"
#   sed -i "/^ZSH_THEME=.*/a\source ~/.dotfiles/zsh/zsh_custom_theme_powerlevel9k.sh" "$HOME/.zshrc"
#   # echo -e "\nsource ~/.dotfiles/zsh/zsh_custom_theme_powerlevel9k.sh" >> "$HOME/.zshrc"
# else
#   cp ~/.dotfiles/zsh/zsh_custom_env.sh "$HOME/.zshenv"
#   sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"agnosterzak-my\"/" "$HOME/.zshrc"
#   sed -i "/zsh_custom_theme_.*/d" "$HOME/.zshrc"
#   sed -i "/^ZSH_THEME=.*/a\source ~/.dotfiles/zsh/zsh_custom_theme_agnosterzak-my.sh" "$HOME/.zshrc"
# fi


colorEcho "${GREEN}ZSH init done, please restart ZSH!"
