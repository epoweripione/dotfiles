#!/usr/bin/env bash

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

if [[ -z "$ZSH" ]]; then
    colorEcho "${RED}Please install ${FUCHSIA}ZSH & Oh-my-zsh${RED} first!"
    exit 0
else
    [[ -z "$ZSH_CUSTOM" ]] && ZSH_CUSTOM="$ZSH/custom"
fi

changeTheme() {
    local theme="$1"
    local theme_name="$1"
    local custom_theme="zsh_custom_theme_${theme}"

    if [[ ! -s "$ZSH/themes/${theme}.zsh-theme" && ! -s "$ZSH_CUSTOM/themes/${theme}.zsh-theme" ]]; then
        colorEcho "${RED}Theme ${FUCHSIA}${theme}${RED} does not exist!"
        exit
    fi

    # custom theme
    [[ "$theme" == "powerlevel9k" ]] && theme_name="powerlevel9k/powerlevel9k"

    # https://github.com/romkatv/powerlevel10k
    [[ "$theme" == "powerlevel10k" ]] && theme_name="powerlevel10k/powerlevel10k"
    [[ "$theme" != "powerlevel10k" ]] && sed -i "/\.p10k\.zsh/d" "$HOME/.zshrc"

    # https://github.com/sindresorhus/pure
    if [[ "$theme" == "pure" ]]; then
        theme_name=""
        sed $'$a \\\n' "$HOME/.zshrc"
        sed -i '$a source ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_custom_pure_prompt.sh' "$HOME/.zshrc"
    else
        sed -i "/zsh_custom_pure_prompt\.sh/d" "$HOME/.zshrc"
    fi

    # change theme
    sed -i "s|^ZSH_THEME=.*|ZSH_THEME=\"${theme_name}\"|" "$HOME/.zshrc"

    # custom theme configuration
    sed -i "/zsh_custom_theme_.*/d" "$HOME/.zshrc"
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/${custom_theme}.sh" ]]; then
        sed -i "/^ZSH_THEME=.*/a\source ~/.dotfiles/zsh/${custom_theme}.sh" "$HOME/.zshrc"
    fi

    # .zshenv
    [[ -s "$HOME/.zshenv" ]] && rm -f "$HOME/.zshenv"

    # if [[ "$theme" == "powerlevel9k" && $(tput colors) -ne 256 ]]; then
    #     cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_custom_env_xterm.sh" "$HOME/.zshenv"
    # fi

    # if [[ "$theme" == "powerlevel10k" && $(tput colors) -ne 256 ]]; then
    #     cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_custom_env_xterm.sh" "$HOME/.zshenv"
    # else
    #     cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_custom_env.sh" "$HOME/.zshenv"
    # fi

    if [[ "$theme" == "powerlevel10k" || "$theme" == "powerlevel9k" ]]; then
        echo -e "\n# Time format for powerlevel10k\nPOWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'" >> "$HOME/.zshrc"
        echo -e '\n# When using Powerlevel10k with instant prompt, prompt_cr must be unset' >> "$HOME/.zshrc"
        echo '(( ! ${+functions[p10k]} )) || p10k finalize' >> "$HOME/.zshrc"
    fi

    colorEcho "${GREEN}ZSH theme has change to ${theme}, please exit and restart ZSH Shell!"
}


if [[ -z "$ZSH" ]]; then
    colorEcho "${RED}Please install ${FUCHSIA}ZSH & Oh-my-zsh${RED} first!"
    exit 0
else
    [[ -z "$ZSH_CUSTOM" ]] && ZSH_CUSTOM=$ZSH/custom
fi


PARAMS_NUM=$#

# get params
while [[ $# -gt 0 ]]; do
    theme="$1"
    changeTheme "${theme}"
    # sed -i "s/[#]*[ ]*ZSH_THEME=.*/ZSH_THEME=\"${theme}\"/" "$HOME/.zshrc"
    shift # past argument or value
done

# if pass a valid param then exit
[[ $PARAMS_NUM -gt 0 ]] && exit

echo -e ""
echo -e "1.ys"
echo -e "2.ys-my"
echo -e "3.agnosterzak"
echo -e "4.agnosterzak-my"
echo -e "5.agkozak"
echo -e "6.alien"
echo -e "7.powerlevel10k"
echo -e "8.spaceship"
echo -e "9.pure"

while :; do
    echo
    colorEchoN "${ORANGE}Please choose a theme(enter to exit): "
	read -r CHOICE
    [[ -z "$CHOICE" ]] && exit 0
	# if [[ ! $CHOICE =~ ^[0-9a-zA-Z]$ ]]; then
	if [[ ! $CHOICE =~ ^[0-9]$ ]]; then
		colorEcho "${RED}Input error, please choose theme from above!"
	else
		break
	fi
done

case "$CHOICE" in
    1)
        changeTheme "ys"
        ;;
    2)
        changeTheme "ys-my"
        ;;
    3)
        Git_Clone_Update_Branch "zakaziko99/agnosterzak-ohmyzsh-theme" "${ZSH_CUSTOM}/themes/agnosterzak-ohmyzsh-theme"

        [[ -L "$ZSH_CUSTOM/themes/agnosterzak.zsh-theme" ]] && \
            rm -f "$ZSH_CUSTOM/themes/agnosterzak.zsh-theme"
        [[ -s "$ZSH_CUSTOM/themes/agnosterzak-ohmyzsh-theme/agnosterzak.zsh-theme" ]] && \
            ln -s "$ZSH_CUSTOM/themes/agnosterzak-ohmyzsh-theme/agnosterzak.zsh-theme" \
                "$ZSH_CUSTOM/themes/agnosterzak.zsh-theme"

        changeTheme "agnosterzak"
        ;;
    4)
        changeTheme "agnosterzak-my"
        ;;
    5)
        Git_Clone_Update_Branch "agkozak/agkozak-zsh-prompt" "${ZSH_CUSTOM}/themes/agkozak-zsh-prompt"

        [[ -L "$ZSH_CUSTOM/themes/agkozak.zsh-theme" ]] && \
            rm -f "$ZSH_CUSTOM/themes/agkozak.zsh-theme"
        [[ -s "$ZSH_CUSTOM/themes/agkozak-zsh-prompt/agkozak-zsh-prompt.plugin.zsh" ]] && \
            ln -s "$ZSH_CUSTOM/themes/agkozak-zsh-prompt/agkozak-zsh-prompt.plugin.zsh" \
                "$ZSH_CUSTOM/themes/agkozak.zsh-theme"

        changeTheme "agkozak"
        ;;
    6)
        Git_Clone_Update_Branch "eendroroy/alien" "${ZSH_CUSTOM}/themes/alien"

        [[ -L "$ZSH_CUSTOM/themes/alien.zsh-theme" ]] && \
            rm -f "$ZSH_CUSTOM/themes/alien.zsh-theme"
        [[ -s "$ZSH_CUSTOM/themes/alien/alien.plugin.zsh" ]] && \
            ln -s "$ZSH_CUSTOM/themes/alien/alien.plugin.zsh" \
                "$ZSH_CUSTOM/themes/alien.zsh-theme"

        changeTheme "alien"
        ;;
    7)
        Git_Clone_Update_Branch "romkatv/powerlevel10k" "${ZSH_CUSTOM}/themes/powerlevel10k"

        [[ -L "$ZSH_CUSTOM/themes/powerlevel10k.zsh-theme" ]] && \
            rm -f "$ZSH_CUSTOM/themes/powerlevel10k.zsh-theme"
        [[ -s "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme" ]] && \
            ln -s "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme" \
                "$ZSH_CUSTOM/themes/powerlevel10k.zsh-theme"

        changeTheme "powerlevel10k"
        ;;
    8)
        Git_Clone_Update_Branch "denysdovhan/spaceship-prompt" "${ZSH_CUSTOM}/themes/spaceship-prompt"

        [[ -L "$ZSH_CUSTOM/themes/spaceship.zsh-theme" ]] && \
            rm -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
        [[ -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" ]] && \
            ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" \
                "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

        changeTheme "spaceship"
        ;;
    9)
        Git_Clone_Update_Branch "sindresorhus/pure" "${ZSH_CUSTOM}/themes/pure"

        changeTheme "pure"
        ;;
    *)
        colorEcho "${YELLOW}Wrong choice!"  # unknown option
        ;;
esac
