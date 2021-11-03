#!/usr/bin/env bash

GREEN="32m"

pacman --noconfirm -Scc

[ -d ~/.cache ] && rm -rf ~/.cache
[ -e ~/.wget-hsts ] && rm -f ~/.wget-hsts
[ -e ~/.ssh/known_hosts ] && rm -f ~/.ssh/known_hosts
[ -e ~/.local/share/lftp/rl_history ] && rm -f ~/.local/share/lftp/rl_history

cat /dev/null > ~/.bash_history
cat /dev/null > ~/.zsh_history
# exec $SHELL -l

echo -e "\033[${GREEN}Done, please restart MSYS2!\033[0m"
