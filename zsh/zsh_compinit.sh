#!/usr/bin/env zsh

# if [[ "$ZSH_VERSION" ]]; then
#     rm -f ~/.zcompdump*
#     autoload -U compinit && compinit
#     if [[ -e ~/.zcompdump ]]; then
#         [[ -n "$HOST" ]] && cp ~/.zcompdump ~/.zcompdump-$HOST-$ZSH_VERSION
#         [[ -n "$HOSTNAME" ]] && cp ~/.zcompdump ~/.zcompdump-$HOSTNAME-$ZSH_VERSION
#     fi
# fi


# Initialize the completion system
autoload -Uz compinit

# Cache completion if nothing changed - faster startup time
typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
if [ $(date +'%j') != $updated_at ]; then
    compinit -i
else
    compinit -C -i
fi

# Enhanced form of menu completion called `menu selection'
zmodload -i zsh/complist
