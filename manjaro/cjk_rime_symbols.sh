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
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# Rime Emoji & Symbols
yay --noconfirm --needed -S rime-opencc-emoji-symbols-git

# merge emoji & symbol
# /usr/share/rime-data/opencc/symbol_category.txt
if  [[ -s "/usr/share/rime-data/opencc/symbol_category.txt" && -s "/usr/share/rime-data/opencc/emoji_category.txt" ]]; then
    awk '{print $1}' \
            "/usr/share/rime-data/opencc/emoji_category.txt" \
            "/usr/share/rime-data/opencc/emoji_word.txt" \
        | uniq > "${WORKDIR}/wordlist.txt"

    grep -wvf "${WORKDIR}/wordlist.txt" "/usr/share/rime-data/opencc/symbol_category.txt" \
        | grep -Ev '^\s' \
        | sudo tee -a "/usr/share/rime-data/opencc/emoji_category.txt" >/dev/null
fi

# /usr/share/rime-data/opencc/symbol_word.txt
if  [[ -s "/usr/share/rime-data/opencc/symbol_word.txt" && -s "/usr/share/rime-data/opencc/emoji_word.txt" ]]; then
    awk '{print $1}' \
            "/usr/share/rime-data/opencc/emoji_category.txt" \
            "/usr/share/rime-data/opencc/emoji_word.txt" \
        | uniq > "${WORKDIR}/wordlist.txt"
    
    DUPLICATE_ENTRY=$(awk '{print $1}' "/usr/share/rime-data/opencc/symbol_word.txt" | sort | uniq -cd | awk '{print $2}')
    while read -r DUPLICATE_WORD; do
        [[ -z "${DUPLICATE_WORD}" ]] && continue
        sudo sed -i "0,/${DUPLICATE_WORD}/b; /${DUPLICATE_WORD}/d" "/usr/share/rime-data/opencc/symbol_word.txt"
    done <<<"${DUPLICATE_ENTRY}"

    grep -wvf "${WORKDIR}/wordlist.txt" "/usr/share/rime-data/opencc/symbol_word.txt" \
        | grep -Ev '^\s' \
        | sudo tee -a "/usr/share/rime-data/opencc/emoji_word.txt" >/dev/null
fi

# /usr/share/rime-data/opencc/es.txt
if  [[ -s "/usr/share/rime-data/opencc/es.txt" && -s "/usr/share/rime-data/opencc/emoji_word.txt" ]]; then
    awk '{print $1}' \
            "/usr/share/rime-data/opencc/emoji_category.txt" \
            "/usr/share/rime-data/opencc/emoji_word.txt" \
        | uniq > "${WORKDIR}/wordlist.txt"
    
    DUPLICATE_ENTRY=$(awk '{print $1}' "/usr/share/rime-data/opencc/es.txt" | sort | uniq -cd | awk '{print $2}')
    while read -r DUPLICATE_WORD; do
        [[ -z "${DUPLICATE_WORD}" ]] && continue
        sudo sed -i "0,/${DUPLICATE_WORD}/b; /${DUPLICATE_WORD}/d" "/usr/share/rime-data/opencc/es.txt"
    done <<<"${DUPLICATE_ENTRY}"

    grep -wvf "${WORKDIR}/wordlist.txt" "/usr/share/rime-data/opencc/es.txt" \
        | grep -Ev '^\s' \
        | sudo tee -a "/usr/share/rime-data/opencc/emoji_word.txt" >/dev/null
fi

# emoji emoticons
# https://github.com/levinit/fcitx-emoji
if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/QuickPhrase.mb" ]]; then
    mkdir -p "$HOME/.local/share/fcitx5/data/"
    cat "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/QuickPhrase.mb" >> "$HOME/.local/share/fcitx5/data/QuickPhrase.mb"
fi
