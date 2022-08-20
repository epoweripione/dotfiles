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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

function get_remote_file_size() {
    local REMOTE_FILE_URL=$1

    if [[ -n "$REMOTE_FILE_URL" ]]; then
        curl -fsSL -I "${REMOTE_FILE_URL}" \
            | grep -i "content-length" \
            | cut -d' ' -f2
    else
        echo 0
    fi
}

function get_remote_file_timestamp_modified() {
    local REMOTE_FILE_URL=$1

    if [[ -n "$REMOTE_FILE_URL" ]]; then
        curl -fsSL -I "$REMOTE_FILE_URL" \
            | grep -i "last-modified" \
            | cut -d' ' -f2- \
            | xargs -I{} date -d {} "+%s"
    else
        echo 0
    fi
}

function timestamp2date() {
    date -d @"$1"
}

function get_timestamp() {
    date +"%s"
}

# localfilesize=$(stat -c%s nerd-fonts.zip)
# localfilemodt=$(stat -c%Y nerd-fonts.zip)

# currenttime=$( timestamp )
# remotefilemodt=$( get_remote_file_timestamp_modified https://www.raycloud.tk/nerd-fonts.zip )
# [[ "$currenttime" -ne "$remotefilemodt" ]] && echo "no match"


# Download from remote server
colorEchoN "${ORANGE}Please input download DIR?[${CYAN}/tmp${ORANGE}]: "
read -r DOWNLOAD_DIR
[[ -z "$DOWNLOAD_DIR" ]] && DOWNLOAD_DIR="/tmp"
if [[ ! -d "$DOWNLOAD_DIR" ]]; then
    colorEcho "${FUCHSIA}${DOWNLOAD_DIR}${RED} does not exist or not a valid directory!"
    exit 1
fi

# colorEchoN "${ORANGE}Please input download URL?[${CYAN}https://example.com/downloads${ORANGE}]: "
# read -r DOWNLOAD_URL
# DOWNLOAD_URL=$(echo $DOWNLOAD_URL \
#                 | grep -Eo '(https|http|ftp)://[a-zA-Z0-9\+\!\.\?\|,:;/=~_-$%#&@]*')
# # trim last character with /
# while [[ "${DOWNLOAD_URL: -1}" == "/" ]]; do
#     DOWNLOAD_URL="${DOWNLOAD_URL%/}"
# done

# if [[ -z "$DOWNLOAD_URL" ]]; then
#     colorEcho "${RED}Please input valid download URL!"
#     exit 1
# fi

# DOWNLOAD_FILES=(
#     oh-my-zsh-custom.zip
#     Harmattan.zip
#     nerd-fonts.zip
#     FuraCode-Mono.zip
# )

# for TargetFile in ${DOWNLOAD_FILES[@]}; do
#     colorEcho "${BLUE}Downloading ${TargetFile}..."
#     curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_DIR}/${TargetFile}" "${DOWNLOAD_URL}/${TargetFile}"
# done


if [[ $# != 1 ]]; then
    echo "Usage: $(basename "$0") download-files-url-list"
    echo "eg: $(basename "$0") download-files-url.txt"
    exit 1
fi

DOWNLOAD_FILES_URL="$1"

if [[ ! -s "$DOWNLOAD_FILES_URL" ]]; then
    echo "${DOWNLOAD_FILES_URL} does not exist!"
    exit 1
fi

CD "${DOWNLOAD_DIR}"
while read -r TargetUrl; do
    if [[ -n "${TargetUrl}" ]]; then
        colorEcho "${BLUE}Downloading ${TargetUrl}..."
        # TargetFileName=$(echo "${TargetUrl}" | awk -F '/' '{print $NF}')
        # curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${TargetFileName}" "${TargetUrl}"
        wget -c "${TargetUrl}"
    fi
done < "$DOWNLOAD_FILES_URL"


# # oh-my-zsh custom
# # cd ~/.oh-my-zsh && \
# #     zip -qyr ~/oh-my-zsh-custom.zip ./custom && \
# #     mv ~/oh-my-zsh-custom.zip /srv/web/www/default
# if [[ -s "${DOWNLOAD_DIR}/oh-my-zsh-custom.zip" && -d "$HOME/.oh-my-zsh" ]]; then
#     rm -rf "$HOME/.oh-my-zsh/custom"
#     unzip -q "${DOWNLOAD_DIR}/oh-my-zsh-custom.zip" -d "$HOME/.oh-my-zsh"
# fi

# # Harmattan
# # if [[ -d "$HOME/Harmattan" ]]; then
# #     cd "$HOME/Harmattan" && git pull
# # else
# #     git clone https://github.com/zagortenay333/Harmattan "$HOME/Harmattan"
# # fi
# # cd ~ && \
# #     zip -qyr ~/Harmattan.zip ./Harmattan && \
# #     mv ~/Harmattan.zip /srv/web/www/default
# if [[ -s "${DOWNLOAD_DIR}/Harmattan.zip" ]]; then
#     [[ -d "$HOME/Harmattan" ]] && rm -rf "$HOME/Harmattan"
#     unzip -q "${DOWNLOAD_DIR}/Harmattan.zip" -d "$HOME"
# fi

# # nerd-fonts repository
# # git clone --depth 1 https://github.com/ryanoasis/nerd-fonts ~/nerd-fonts && \
# # 	rm -rf ~/nerd-fonts/patched-fonts ~/nerd-fonts/.git && \
# # 	: && \
# # 	# fix latest version issue patch char i,j not correct
# # 	# rm -f ~/nerd-fonts/font-patcher && \
# # 	# 	curl "${CURL_DOWNLOAD_OPTS[@]}" -o ~/nerd-fonts/font-patcher \
# # 	# 		https://github.com/ryanoasis/nerd-fonts/raw/3241ea6e44191ec89c0260f51112dec691363ebd/font-patcher
# # 	# : && \
# # 	cd ~ && zip -qyr nerd-fonts.zip ./nerd-fonts && \
# # 	mv ~/nerd-fonts.zip /srv/web/www/default
# if [[ -s "${DOWNLOAD_DIR}/nerd-fonts.zip" ]]; then
#     [[ -d "$HOME/nerd-fonts" ]] && rm -rf "$HOME/nerd-fonts"
#     unzip -q "${DOWNLOAD_DIR}/nerd-fonts.zip" -d "$HOME"
# fi
