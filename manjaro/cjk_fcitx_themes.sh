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

if [[ ! -x "$(command -v fd)" ]]; then
    AppInstaller="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/fd_installer.sh"
    [[ -s "${AppInstaller}" ]] && source "${AppInstaller}"
fi

if [[ ! -x "$(command -v fd)" ]]; then
    colorEcho "${FUCHSIA}fd${RED} is not installed!"
    exit 1
fi

# Fcitx5 custom themes
DOWNLOAD_DIR="${1:-$HOME/fcitx5/themes}"
mkdir -p "${DOWNLOAD_DIR}"

THEME_DIR="$HOME/.local/share/fcitx5/themes"
mkdir -p "${THEME_DIR}"

THEME_LIST=(
    "candlelight#git#https://github.com/thep0y/fcitx5-themes-candlelight#*"
    "material-nord#git#https://github.com/evansan/fcitx-skin-material-nord#*"
    "catppuccin#git#https://github.com/catppuccin/fcitx5#catppuccin*"
)
for Target in "${THEME_LIST[@]}"; do
    [[ -z "${Target}" ]] && continue

    DOWNLOAD_NAME=$(cut -d# -f1 <<<"${Target}")
    DOWNLOAD_METHOD=$(cut -d# -f2 <<<"${Target}")
    DOWNLOAD_URL=$(cut -d# -f3 <<<"${Target}")
    THEME_MATCH=$(cut -d# -f4 <<<"${Target}")

    colorEcho "${BLUE}Downloading ${FUCHSIA}${DOWNLOAD_NAME}${BLUE} from ${ORANGE}${DOWNLOAD_URL}${BLUE}..."
    case "${DOWNLOAD_METHOD}" in
        "git")
            Git_Clone_Update_Branch "${DOWNLOAD_URL}" "${DOWNLOAD_DIR}/${DOWNLOAD_NAME}"
            ;;
        "curl")
            curl -fSL --connect-timeout 5 -o "${DOWNLOAD_DIR}/${DOWNLOAD_NAME}" "${DOWNLOAD_URL}"
            curl_download_status=$?
            if [[ ${curl_download_status} -eq 0 ]]; then
                Archive_File_Extract "${DOWNLOAD_DIR}/${DOWNLOAD_NAME}" "${DOWNLOAD_DIR}/${DOWNLOAD_NAME%.*}"
            fi
            ;;
    esac

    colorEcho "${BLUE}Installing theme ${FUCHSIA}${DOWNLOAD_NAME}${BLUE} to ${ORANGE}${THEME_DIR}${BLUE}..."
    fd --type d --glob "${THEME_MATCH}" "${DOWNLOAD_DIR}/${DOWNLOAD_NAME}" --exec cp -rn {} "${THEME_DIR}"
done

colorEcho "${BLUE}Fcitx5 主题安装完成！请在 ${FUCHSIA}系统设置→输入法→配置附加组件...→经典用户界面${BLUE} 中选择 ${ORANGE}主题${BLUE}。"
