#!/usr/bin/env zsh

# Pure prompt
# https://github.com/sindresorhus/pure

fpath+=("$ZSH_CUSTOM/themes/pure")

autoload -U promptinit; promptinit
prompt pure