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
SCHEMA_ROOT_DIR="${1:-$HOME/rime}"
mkdir -p "${SCHEMA_ROOT_DIR}"

SCHEMA_LIST=(
    "rime-frost#git#https://github.com/gaboolic/rime-frost" # 白霜拼音
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
    # "clover.zip#curl#https://github.com/fkxxyz/rime-cloverpinyin/releases/download/1.1.4/clover.schema-1.1.4.zip" # 四叶草拼音
    "rime-pure#git#https://github.com/SivanLaai/rime-pure#schemes/*" # rime-pure
    "rime-shuangpin-fuzhuma#git#https://github.com/gaboolic/rime-shuangpin-fuzhuma" # 墨奇音形
)
for Target in "${SCHEMA_LIST[@]}"; do
    [[ -z "${Target}" ]] && continue

    DOWNLOAD_NAME=$(cut -d# -f1 <<<"${Target}")
    DOWNLOAD_METHOD=$(cut -d# -f2 <<<"${Target}")
    DOWNLOAD_URL=$(cut -d# -f3 <<<"${Target}")
    DOWNLOAD_SUB_DIR=$(cut -d# -f4 <<<"${Target}")

    DOWNLOAD_FILE="${SCHEMA_ROOT_DIR}/${DOWNLOAD_NAME}"
    SCHEMA_SAVE_DIR="${SCHEMA_ROOT_DIR}/${DOWNLOAD_NAME%.*}"

    [[ -n "${DOWNLOAD_SUB_DIR}" ]] && SCHEMA_DOWNLOAD_DIR="${SCHEMA_SAVE_DIR}-temp" || SCHEMA_DOWNLOAD_DIR="${SCHEMA_SAVE_DIR}"

    colorEcho "${BLUE}Downloading ${FUCHSIA}${DOWNLOAD_NAME}${BLUE} from ${ORANGE}${DOWNLOAD_URL}${BLUE}..."
    case "${DOWNLOAD_METHOD}" in
        "git")
            Git_Clone_Update_Branch "${DOWNLOAD_URL}" "${SCHEMA_DOWNLOAD_DIR}"
            ;;
        "curl")
            curl -fSL --connect-timeout 5 -o "${DOWNLOAD_FILE}" "${DOWNLOAD_URL}"
            curl_download_status=$?
            if [[ ${curl_download_status} -eq 0 ]]; then
                [[ -d "${SCHEMA_DOWNLOAD_DIR}" ]] && rm -rf "${SCHEMA_DOWNLOAD_DIR}"
                Archive_File_Extract "${DOWNLOAD_FILE}" "${SCHEMA_DOWNLOAD_DIR}"
            fi
            ;;
    esac

    # Only sub-directory
    if [[ -n "${DOWNLOAD_SUB_DIR}" ]]; then
        [[ -d "${SCHEMA_SAVE_DIR}" ]] && rm -rf "${SCHEMA_SAVE_DIR}"

        if grep -q '\/\*' <<<"${DOWNLOAD_SUB_DIR}"; then
            mkdir -p "${SCHEMA_SAVE_DIR}"

            for dir in $(fd --type d --full-path --glob "**/${DOWNLOAD_SUB_DIR}" "${SCHEMA_DOWNLOAD_DIR}"); do
                cp -rn "${dir}"* "${SCHEMA_SAVE_DIR}"
            done
        else
            cp -rn "${SCHEMA_DOWNLOAD_DIR}/${DOWNLOAD_SUB_DIR}" "${SCHEMA_SAVE_DIR}"
        fi
    fi
    
    # 同文
    if [[ -d "${SCHEMA_DOWNLOAD_DIR}/trime/rime" ]]; then
        cp -rn "${SCHEMA_DOWNLOAD_DIR}/trime/rime/"* "${SCHEMA_SAVE_DIR}"
    fi
done

SCHEMA_DIR="${SCHEMA_ROOT_DIR}/_schema"

# base on `rime-frost`
RIME_BASE="rime-frost"
if [[ ! -d "${SCHEMA_ROOT_DIR}/${RIME_BASE}" ]]; then
    colorEcho "${FUCHSIA}${RIME_BASE}${RED} not downloaded!"
    exit 1
fi

colorEcho "${BLUE}Moving ${FUCHSIA}${SCHEMA_ROOT_DIR}/${RIME_BASE}${BLUE} to ${ORANGE}${SCHEMA_DIR}${BLUE}..."
[[ -d "${SCHEMA_DIR}" ]] && rm -rf "${SCHEMA_DIR}"

cp -rn "${SCHEMA_ROOT_DIR}/${RIME_BASE}" "${SCHEMA_DIR}"

colorEcho "${BLUE}Merging ${FUCHSIA}schema${BLUE} to ${ORANGE}${SCHEMA_DIR}${BLUE}..."
# copy all subdirectroy to `_schema`
fd --min-depth 2 --max-depth 2 --exclude "_schema" --exclude "*-temp" \
    --type d . "${SCHEMA_ROOT_DIR}" \
    --exec cp -rn {} "${SCHEMA_DIR}"

# copy lua, py, txt, yaml files
fd --min-depth 2 --max-depth 2 --exclude "_schema" --exclude "*-temp" \
    --type f --extension ".lua" . "${SCHEMA_ROOT_DIR}" \
    --exec cp -n {} "${SCHEMA_DIR}"

fd --min-depth 2 --max-depth 2 --exclude "_schema" --exclude "*-temp" \
    --type f --extension ".txt" . "${SCHEMA_ROOT_DIR}" \
    --exec cp -n {} "${SCHEMA_DIR}"

fd --min-depth 2 --max-depth 2 --exclude "_schema" --exclude "*-temp" --exclude "default*" \
    --type f --extension ".yaml" . "${SCHEMA_ROOT_DIR}" \
    --exec cp -n {} "${SCHEMA_DIR}"

# symbols for `rime-ice`
if [[ -f "${SCHEMA_ROOT_DIR}/rime-ice/symbols_v.yaml" ]]; then
    cp -f "${SCHEMA_ROOT_DIR}/rime-ice/symbols_v.yaml" "${SCHEMA_DIR}/symbols_v_ice.yaml"
fi

# Schema list
yq '"    - schema: " + .schema.schema_id + " # " + .schema.name' "${SCHEMA_DIR}"/*.schema.yaml > "${SCHEMA_DIR}/_schema_list.txt"

# Repalce rime schema
REPLACE_TARGET=(
    "${WSL_APPDATA}/Rime" # Windows
    "$HOME/.config/ibus/rime" # iBus
    "$HOME/.local/share/fcitx5/rime" # Fcitx5
    "$HOME/.var/app/org.fcitx.Fcitx5/data/fcitx5/rime" # fcitx5 flatpak
    "$HOME/Library/Rime" # macOS
    # "/storage/emulated/0/Android/data/org.fcitx.fcitx5.android/files/data/rime/" # fcitx5-android
    # "/storage/sdcard0/Android/data/org.fcitx.fcitx5.android/files/data/rime/" # fcitx5-android
    # "/sdcard/Android/data/org.fcitx.fcitx5.android/files/data/rime/" # fcitx5-android
    # "/storage/emulated/0/rime" # 同文
    # "/storage/sdcard0/rime" # 同文
    # "/sdcard/rime" # 同文
)
for Target in "${REPLACE_TARGET[@]}"; do
    if [[ -d "${Target}" ]]; then
        colorEcho "${BLUE}Copying ${FUCHSIA}${SCHEMA_DIR}${BLUE} to ${ORANGE}${Target}${BLUE}..."
        # rsync -avzP "${SCHEMA_DIR}/" "${Target}"
        rsync -azq "${SCHEMA_DIR}/" "${Target}"

        if [[ -d "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/rime" ]]; then
            cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/rime/"* "${Target}"
        fi
    fi
done

colorEcho "${BLUE}输入方案合并完成！请 ${FUCHSIA}重新部署${BLUE} ${ORANGE}中州韻輸入法引擎${BLUE}。"
