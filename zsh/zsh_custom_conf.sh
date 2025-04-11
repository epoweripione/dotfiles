#!/usr/bin/env zsh

# Custom ZSH configuration
export MY_SHELL_SCRIPTS="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}"

OS_TYPE=$(uname)

# custom PS2
# export PS2="> "

# fix duplicate environment variables "SHELL=/usr/bin/zsh"
if (( $(env | grep -E '^SHELL=' | wc -l) > 1 )); then
    unset SHELL
    SHELL=$(which zsh)
    export SHELL
fi

# compinit
# source "${MY_SHELL_SCRIPTS}/zsh/zsh_compinit.sh"

### Fix slowness of pastes with zsh-syntax-highlighting.zsh
### https://github.com/zsh-users/zsh-autosuggestions/issues/238#issuecomment-389324292
pasteinit() {
    OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
    zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
    zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish
### Fix slowness of pastes

# disable hosts auto completion
zstyle ':completion:*' hosts off

# custom bindkey
bindkey \^U backward-kill-line

# bind the Control-P/N keys for zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

# not confirm a rm *
setopt localoptions rmstarsilent

## disable globbing for all commands
## [Using wildcards in commands with zsh](https://superuser.com/questions/584249/using-wildcards-in-commands-with-zsh)
## [no matches found / no such file or directory](https://unix.stackexchange.com/questions/434066/why-im-i-getting-the-no-matches-found-error-when-there-is-a-match)
## sudo sh -c 'ls ./backup*'
# unsetopt nomatch
# setopt no_nomatch

## Colors
# autoload -U colors && colors
# export CLICOLOR=1
# export LSCOLORS='gxfxcxdxbxegedabagacad'
# export LS_COLORS="di=36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"


# complete hard drives in MSYS2
if [[ "$OS_TYPE" =~ "MSYS_NT" || "$OS_TYPE" =~ "MINGW" || "$OS_TYPE" =~ "CYGWIN_NT" ]]; then
    drives=$(mount | sed -rn 's#^[A-Z]: on /([a-z]).*#\1#p' | tr '\n' ' ')
    zstyle ':completion:*' fake-files /: "/:$drives"
    unset drives
fi


# Load custom functions
if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/custom_functions.sh"

    # Check & set global proxy
    setGlobalProxies
fi

# zsh-command-time
# If command execution time above min. time, plugins will not output time.
ZSH_COMMAND_TIME_MIN_SECONDS=3

# Message to display (set to "" for disable).
# → Execution time: ←
if [[ "$DISABLE_ZSH_COMMAND_TIME_MSG" == true ]]; then
    ZSH_COMMAND_TIME_MSG=""
else
    ZSH_COMMAND_TIME_MSG=" \u2192 Execution time: %s \u2190"

    # Message color.
    if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        ZSH_COMMAND_TIME_COLOR="magenta"
    else
        if [[ $UID -eq 0 ]]; then
            ZSH_COMMAND_TIME_COLOR="red"
        else
            ZSH_COMMAND_TIME_COLOR="yellow"
        fi
    fi
fi

# funky
[[ -s "$HOME/.local/share/funky/funky.sh" ]] && source "$HOME/.local/share/funky/funky.sh"

# fzf
if [[ -x "$(command -v fzf)" && -s "${MY_SHELL_SCRIPTS}/fzf_config.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/fzf_config.sh"
fi

# nvm
if [[ "$(command -v nvm)" ]]; then
    if [[ "${NVM_LOAD_NVMRC_IN_CURRENT_DIRECTORY}" == true ]]; then
        # use specified node version for the current directory with .nvmrc
        # echo "lts/*" > .nvmrc # to default to the latest LTS version
        # echo "node" > .nvmrc # to default to the latest version
        autoload -U add-zsh-hook
        load-nvmrc() {
            local node_version nvmrc_path nvmrc_node_version

            node_version="$(nvm version)"
            nvmrc_path="$(nvm_find_nvmrc)"
            if [[ -n "$nvmrc_path" ]]; then
                    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
                    if [[ "$nvmrc_node_version" == "N/A" ]]; then
                            nvm install
                    elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
                            nvm use
                    fi
            elif [[ "$node_version" != "$(nvm version default)" ]]; then
                    # echo "Reverting to nvm default version"
                    nvm use default
            fi
        }
        add-zsh-hook chpwd load-nvmrc
        load-nvmrc
    fi
fi

# broot
if [[ ! "$(command -v br)" && -x "$(command -v broot)" ]]; then
    [[ -s "$HOME/.config/broot/launcher/bash/br" ]] && source "$HOME/.config/broot/launcher/bash/br"
fi

# nnn
if [[ -x "$(command -v nnn)" && -z "${NNN_PLUG}" ]]; then
    NNN_PLUG_INLINE='g:!go run $nnn*'
    NNN_PLUG_DEFAULT="1:bookmarks;a:autojump;b:oldbigfile;d:diffs;e:suedit;f:finder;i:ipinfo;k:pskill;m:nmount"
    NNN_PLUG_DEFAULT="${NNN_PLUG_DEFAULT};o:fzz;p:preview-tui;u:getplugs;v:imgview;w:pdfread;x:togglex"
    NNN_PLUG="${NNN_PLUG_DEFAULT};${NNN_PLUG_INLINE}"

    export NNN_PLUG
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_FIFO="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/nnn.fifo"
    [[ -x "$(command -v pistol)" ]] && export USE_PISTOL=1

    unset NNN_PLUG_INLINE
    unset NNN_PLUG_DEFAULT
fi

# alias
[[ -s "${MY_SHELL_SCRIPTS}/functions/aliases.sh" ]] && source "${MY_SHELL_SCRIPTS}/functions/aliases.sh"

# Proxies
set_git_sshCommand # git sshCommand with ProxyCommand

# Autostart Tmux/screen Session On Remote System When Logging In Via SSH
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    if [[ "$(command -v zellij)" ]]; then
        newZellijSession
    elif [[ "$(command -v tmux)" ]]; then
        newTmuxSession
    elif [[ -x "$(command -v screen)" ]]; then
        newScreenSession
    fi
fi
