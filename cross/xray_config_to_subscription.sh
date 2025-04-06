#!/usr/bin/env bash

# Usage:
# ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/xray_config_to_subscription.sh /srv/web/www/public/public.json /srv/web/www/public/public.ray
# for file in /srv/web/www/public/*.yml; do ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/xray_config_to_subscription.sh "${file}"; done


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

colorEcho "${BLUE}Converting ${ORANGE}${CONFIG_SRC} ${BLUE}to${FUCHSIA} ${CONFIG_TO}${BLUE}..."
# [VMessAEAD / VLESS 分享链接标准提案](https://github.com/XTLS/Xray-core/discussions/716)
JQ_EXP_MAIN='.protocol + "://"'\
' + (if(.settings.vnext) then .settings.vnext[0].users[0].id//"" else "" end)'\
' + (if(.settings.servers) then .settings.servers[0].password//"" else "" end)'\
' + "@"'\
' + (if(.settings.vnext) then .settings.vnext[0].address//"" else "" end)'\
' + (if(.settings.servers) then .settings.servers[0].address//"" else "" end)'\
' + ":"'\
' + (if(.settings.vnext) then (.settings.vnext[0].port//443 | tostring) else "" end)'\
' + (if(.settings.servers) then (.settings.servers[0].port//443 | tostring) else "" end)'

JQ_EXP_PARM='"type=" + (if(.streamSettings) then .streamSettings.network//"" else "" end)'\
' + "&security=" + (if(.streamSettings) then .streamSettings.security//"" else "" end)'\
' + "&sni=" + (if(.streamSettings.realitySettings) then .streamSettings.realitySettings.serverName//"" else "" end)'\
' + (if(.streamSettings.tlsSettings) then .streamSettings.tlsSettings.serverName//"" else "" end)'\
' + "&path=" + (if(.streamSettings.wsSettings) then .streamSettings.wsSettings.path//"" else "" end)'\
' + (if(.streamSettings.xhttpSettings) then .streamSettings.xhttpSettings.path//"" else "" end)'\
' + (if(.streamSettings.httpupgradeSettings) then .streamSettings.httpupgradeSettings.path//"" else "" end)'\
' + "&host=" + (if(.settings.vnext) then .settings.vnext[0].address//"" else "" end)'\
' + (if(.settings.servers) then .settings.servers[0].address//"" else "" end)'\
' + "&flow=" + (if(.settings.vnext) then .settings.vnext[0].users[0]?.flow//"" else "" end)'\
' + "&fp=" + (if(.streamSettings.realitySettings) then .streamSettings.realitySettings.fingerprint//"" else "" end)'\
' + "&pbk=" + (if(.streamSettings.realitySettings) then .streamSettings.realitySettings.publicKey//"" else "" end)'\
' + "&sid=" + (if(.streamSettings.realitySettings) then .streamSettings.realitySettings.shortId//"" else "" end)'\
' + "&spx=" + (if(.streamSettings.realitySettings) then .streamSettings.realitySettings.spiderX//"" else "" end)'\
' + "&extra=" + (if(.streamSettings.xhttpSettings) then .streamSettings.xhttpSettings.extra//"" else "" end)'\
' + "&mode=" + (if(.streamSettings.xhttpSettings) then .streamSettings.xhttpSettings.mode//"" else "" end)'\
' + "&headerType=" + (if(.streamSettings.kcpSettings) then .streamSettings.kcpSettings.headerType//"" else "" end)'\
' + "&seed=" + (if(.streamSettings.kcpSettings) then .streamSettings.kcpSettings.seed//"" else "" end)'\
' + "&serviceName=" + (if(.streamSettings.grpcSettings) then .streamSettings.grpcSettings.serviceName//"" else "" end)'\
' + "&authority=" + (if(.streamSettings.grpcSettings) then .streamSettings.grpcSettings.authority//"" else "" end)'

JQ_EXP=".outbounds[] | select(.protocol != \"freedom\" and .protocol != \"blackhole\") | ${JQ_EXP_MAIN} + \"?\" + ${JQ_EXP_PARM} + \"#\" + .tag"

jq -r "${JQ_EXP}" "${CONFIG_SRC}" > "${CONFIG_TO}.tmp"
sed -i 's/#out-/#/g' "${CONFIG_TO}.tmp"
if [[ -s "${CONFIG_TO}.tmp" ]]; then
    processXRaySubscribeFile "${CONFIG_TO}.tmp" "${CONFIG_TO}"
    rm "${CONFIG_TO}.tmp"
fi

colorEcho "${BLUE}Done!"
