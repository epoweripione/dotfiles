#!/usr/bin/env bash

# Usage:
# ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_to_xray_subscription.sh /srv/web/www/public/public.yml /srv/web/www/public/public.ray
# for file in /srv/web/www/public/*.yml; do ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_to_xray_subscription.sh "${file}"; done


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

# Format xray subscribe file
function processXRaySubscribeFile() {
    local subscribeFile=$1
    local outputFile=$2
    local readLine encodeValue encodedResult TargetType
    local encodeType=()

    sed -i -r 's/(type|tls|flow|fp|sni|path|host|pbk|sid|spx|extra|headerType|seed|serviceName|mode|authority)=&//g' "${subscribeFile}"
    sed -i -r 's/(type|tls|flow|fp|sni|path|host|pbk|sid|spx|extra|headerType|seed|serviceName|mode|authority)=#/#/g' "${subscribeFile}"

    sed -i -e 's/type=raw/type=tcp/g' "${subscribeFile}"

    sed -i -e 's/tls=true/security=tls/g' "${subscribeFile}"
    sed -i -e 's/tls=false/security=none/g' "${subscribeFile}"
    sed -i -e '/pbk=/ s/security=tls/security=reality/g' "${subscribeFile}"

    sed -i -e 's/socks5/socks/g' -e 's|//@|//|g' "${subscribeFile}"
    sed -i -e 's/\?&/?/g' -e 's/\?#/#/g' -e 's/&#/#/g' "${subscribeFile}"

    [[ -f "${outputFile}" ]] && rm "${outputFile}"

    encodeType=(
        "path"
        "host"
        "seed"
        "serviceName"
        "authority"
        "extra"
        "alpn"
        "spx"
    )

    while read -r readLine || [[ "${readLine}" ]]; do
        [[ -z "${readLine}" ]] && continue

        # descriptive-text
        encodeValue=$(awk -F '#' '{print $NF}' <<< "${readLine}")
        if [[ -n "${encodeValue}" ]]; then
            encodedResult=$(printf %s "${encodeValue}" | jq -sRr @uri)
            readLine=$(sed "s|${encodeValue}|${encodedResult}|" <<<"${readLine}")
        fi

        # encodeURIComponent
        for TargetType in "${encodeType[@]}"; do
            [[ -z "${TargetType}" ]] && continue
            
            encodeValue=$(grep -Eo "${TargetType}=([^&#]+)[&#]" <<< "${readLine}" | sed -r -e 's|^.+=||' -e 's|[&#]||')

            [[ -z "${encodeValue}" ]] && continue
            encodedResult=$(printf %s "${encodeValue}" | jq -sRr @uri)
            readLine=$(sed "s|${TargetType}=${encodeValue}|${TargetType}=${encodedResult}|" <<<"${readLine}")
        done

        echo "${readLine}" >> "${outputFile}"
    done < "${subscribeFile}"
}

CONFIG_SRC=${1:-""}
if [[ -z "${CONFIG_SRC}" ]]; then
    colorEcho "${FUCHSIA}Source file${RED} can't empty!"
    exit 1
elif [[ ! -s "${CONFIG_SRC}" ]]; then
    colorEcho "${FUCHSIA}Source file${RED} does not exist!"
    exit 1
fi

CONFIG_SRC_DIR=$(dirname -- "${CONFIG_SRC}")
CONFIG_SRC_NAME="${CONFIG_SRC##*/}"
CONFIG_SRC_EXT="${CONFIG_SRC_NAME##*.}"
CONFIG_SRC_NAME="${CONFIG_SRC_NAME%.*}"

CONFIG_TO=${2:-""}
[[ -z "${CONFIG_TO}" && "${CONFIG_SRC_EXT}" != "ini" ]] && CONFIG_TO="${CONFIG_SRC_DIR}/${CONFIG_SRC_NAME}.ini"
if [[ -z "${CONFIG_TO}" ]]; then
    colorEcho "${FUCHSIA}Target file${RED} can't empty!"
    exit 1
fi

# fix "command not found" when running via cron
FixSystemBinPath

# yq
if [[ ! -x "$(command -v yq)" ]]; then
    AppInstaller="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/yq_installer.sh"
    [[ -s "${AppInstaller}" ]] && source "${AppInstaller}"
fi

if [[ ! -x "$(command -v yq)" ]]; then
    colorEcho "${FUCHSIA}yq${RED} is not installed!"
    exit 1
fi

colorEcho "${BLUE}Converting ${ORANGE}${CONFIG_SRC} ${BLUE}to${FUCHSIA} ${CONFIG_TO}${BLUE}..."
# [VMessAEAD / VLESS 分享链接标准提案](https://github.com/XTLS/Xray-core/discussions/716)
YQ_EXP_MAIN='.type + "://"'\
' + (.uuid // "") + (.password // "")'\
' + "@"'\
' + .server'\
' + ":"'\
' + .port'

YQ_EXP_PARM='"type=" + (.network // "")'\
' + "&tls=" + (.tls // "")'\
' + "&sni=" + (.servername // "")'\
' + "&path=" + (.ws-opts.path // "") + "&path=" + (.ws-opts.Path // "")'\
' + "&host=" + (.ws-opts.headers.host // "") + "&host=" + (.ws-opts.headers.Host // "")'\
' + "&flow=" + (.flow // "")'\
' + "&fp=" + (.client-fingerprint // "")'\
' + "&pbk=" + (.reality-opts.public-key // "")'\
' + "&sid=" + (.reality-opts.short-id // "")'\
' + "&spx=" + (.reality-opts.spiderx // "")'\
' + "&extra=" + (.extra // "")'\
' + "&mode=" + (.mode // "")'\
' + "&headerType=" + (.headerType // "") '\
' + "&seed=" + (.seed // "")'\
' + "&serviceName=" + (.serviceName // "")'\
' + "&authority=" + (.authority // "")'

# YQ_EXP=".proxies[] | select(.type==\"vless\") | ${YQ_EXP_MAIN} + \"?\" + ${YQ_EXP_PARM} + \"#\" + .name"
YQ_EXP=".proxies[] | ${YQ_EXP_MAIN} + \"?\" + ${YQ_EXP_PARM} + \"#\" + .name"

yq e "${YQ_EXP}" "${CONFIG_SRC}" > "${CONFIG_TO}.tmp"
if [[ -s "${CONFIG_TO}.tmp" ]]; then
    processXRaySubscribeFile "${CONFIG_TO}.tmp" "${CONFIG_TO}"
    rm "${CONFIG_TO}.tmp"
fi

colorEcho "${BLUE}Done!"
