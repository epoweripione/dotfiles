#!/usr/bin/env zsh

GREEN="32m"

cat /dev/null > ~/.zsh_history

# exec $SHELL -l

echo -e "\033[${GREEN}Done, please restart ZSH!\033[0m"
