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

WSL_APPDATA=""
if check_os_wsl; then
    WSL_APPDATA=$(wslpath "$(wslvar APPDATA 2>/dev/null)")
fi

# Build rime schema base on `rime_ice`
# 中州韻輸入法：以 [雾凇拼音](https://github.com/iDvel/rime-ice) 为基础，合并粵語拼音、四叶草等输入法方案
DOWNLOAD_DIR="${1:-$HOME/rime}"
mkdir -p "${DOWNLOAD_DIR}"

SCHEMA_LIST=(
    "rime-ice#git#https://github.com/iDvel/rime-ice" # 雾凇拼音
    "rime-luna#git#https://github.com/rime/rime-luna-pinyin" # 朙月拼音
    "rime-terra#git#https://github.com/rime/rime-terra-pinyin" # 地球拼音
    "rime-cantonese#git#https://github.com/rime/rime-cantonese" # 粵語拼音
    "rime-bopomofo#git#https://github.com/rime/rime-bopomofo" # 注音
    "rime-cangjie#git#https://github.com/rime/rime-cangjie" # 倉頡
    "rime-middle-chinese#git#https://github.com/rime/rime-middle-chinese" # 中古漢語拼音
    "rime-stroke#git#https://github.com/rime/rime-stroke" # 五筆畫 h,s,p,n,z 代表橫、豎、撇、捺、折
    "rime-wubi#git#https://github.com/rime/rime-wubi" # 五筆字型 86 版
    # "98wubi#git#https://github.com/yanhuacuo/98wubi" # 五笔 98 版
    "rime-ipa#git#https://github.com/rime/rime-ipa" # 國際音標
    "clover.zip#curl#https://github.com/fkxxyz/rime-cloverpinyin/releases/download/1.1.4/clover.schema-1.1.4.zip" # 四叶草拼音
)
for Target in "${SCHEMA_LIST[@]}"; do
    [[ -z "${Target}" ]] && continue

    DOWNLOAD_NAME=$(cut -d# -f1 <<<"${Target}")
    DOWNLOAD_METHOD=$(cut -d# -f2 <<<"${Target}")
    DOWNLOAD_URL=$(cut -d# -f3 <<<"${Target}")

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
done

SCHEMA_DIR="${DOWNLOAD_DIR}/_schema"

# base on `rime-ice`
if [[ ! -d "${DOWNLOAD_DIR}/rime-ice" ]]; then
    colorEcho "${FUCHSIA}rime-ice${RED} not downloaded!"
    exit 1
fi

colorEcho "${BLUE}Moving ${FUCHSIA}${DOWNLOAD_DIR}/rime-ice${BLUE} to ${ORANGE}${SCHEMA_DIR}${BLUE}..."
[[ -d "${SCHEMA_DIR}" ]] && rm -rf "${SCHEMA_DIR}"

mv "${DOWNLOAD_DIR}/rime-ice" "${SCHEMA_DIR}"

colorEcho "${BLUE}Merging ${FUCHSIA}schema${BLUE} to ${ORANGE}${SCHEMA_DIR}${BLUE}..."
# copy all subdirectroy to `_schema`
fd --min-depth 2 --max-depth 2 --exclude "_schema" \
    --type d . "${DOWNLOAD_DIR}" \
    --exec cp -rn {} "${SCHEMA_DIR}"

# copy lua, py, txt, yaml files
fd --min-depth 2 --max-depth 2 --exclude "_schema" \
    --type f --extension ".lua" . "${DOWNLOAD_DIR}" \
    --exec cp -n {} "${SCHEMA_DIR}"

fd --min-depth 2 --max-depth 2 --exclude "_schema" \
    --type f --extension ".txt" . "${DOWNLOAD_DIR}" \
    --exec cp -n {} "${SCHEMA_DIR}"

fd --min-depth 2 --max-depth 2 --exclude "_schema" --exclude "default*" \
    --type f --extension ".yaml" . "${DOWNLOAD_DIR}" \
    --exec cp -n {} "${SCHEMA_DIR}"

# Repalce rime schema
REPLACE_TARGET=(
    "${WSL_APPDATA}/Rime" # Windows
    "$HOME/.config/ibus/rime" # iBus
    "$HOME/.local/share/fcitx5/rime" # Fcitx5
    "$HOME/Library/Rime" # macOS
    "/storage/emulated/0/Android/data/org.fcitx.fcitx5.android/files/data/rime/" # Android
)
for Target in "${REPLACE_TARGET[@]}"; do
    if [[ -d "${Target}" ]]; then
        colorEcho "${BLUE}Copying ${FUCHSIA}${SCHEMA_DIR}${BLUE} to ${ORANGE}${Target}${BLUE}..."
        # rm -rf "${Target}/"*
        cp -rf "${SCHEMA_DIR}/"* "${Target}"

        if [[ -d "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/rime" ]]; then
            cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/rime/"*.custom.yaml "${Target}"
        fi
    fi
done

colorEcho "${BLUE}输入方案合并完成！请 ${FUCHSIA}重新部署${BLUE} ${ORANGE}中州韻輸入法引擎${BLUE}。"
