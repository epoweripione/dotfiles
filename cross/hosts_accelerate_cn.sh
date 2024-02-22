#!/usr/bin/env bash

# Usage: ./hosts_accelerate_cn.sh /etc/hosts dig|curl|reset test

# if [[ $UID -ne 0 ]]; then
#     echo "Please run this script as root user!"
#     exit 0
# fi

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

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type


# Local WAN IP GEO
[[ -z "${NETWORK_WAN_NET_IP_GEO}" ]] && get_network_wan_geo

if [[ "${NETWORK_WAN_NET_IP_GEO}" =~ 'China' || "${NETWORK_WAN_NET_IP_GEO}" =~ 'CN' ]]; then
    :
else
    colorEcho "${BLUE}You are not in china! Congratulations!"
    colorEchoN "${ORANGE}Continue?[y/${CYAN}N${ORANGE}]: "
    read -r -t 5 EXIT_CONTINUE
    [[ -z "$EXIT_CONTINUE" || "$EXIT_CONTINUE" == "n" || "$EXIT_CONTINUE" == "N" ]] && exit 0
fi

if [[ -z "${NETWORK_WAN_NET_IP}" ]]; then
    colorEcho "${RED}Can't get local WAN IP address!"
    exit 1
fi


PARAMS_NUM=$#

# hosts file
if [[ $PARAMS_NUM -gt 0 ]]; then
    HostsFile="$1"
else
    if [[ "${OS_INFO_TYPE}" == "windows" ]]; then
        HostsFile=/c/Windows/System32/drivers/etc/hosts
    else
        HostsFile=/etc/hosts
    fi
fi

if [[ ! -s "$HostsFile" ]]; then
    # colorEcho "${FUCHSIA}${HostsFile}${RED} does not exist!"
    # exit 1
    Hosts_URL="https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/hosts"
    curl -fSL --connect-timeout 5 --max-time 20 -o "$HostsFile" "$Hosts_URL"
fi

# use dig or curl
CHECK_METHOD=${2:-"curl"}

# don't modify hosts file
TEST_OR_DOWNLOAD_URL=${3:-""}


# if param $3 is a link then download from url and exit
if echo "$TEST_OR_DOWNLOAD_URL" | grep -Eq "^http|^https"; then
    if download_hosts "$TEST_OR_DOWNLOAD_URL" "$HostsFile"; then
        exit 0
    fi
fi


# dig
if [[ "$CHECK_METHOD" == "dig" && ! -x "$(command -v dig)" ]]; then
    PackagesList=(
        bind-tools
        bind-utils
        dnsutils
    )
    InstallSystemPackages "" "${PackagesList[@]}"
fi

if [[ "$CHECK_METHOD" == "dig" && ! -x "$(command -v dig)" ]]; then
    colorEcho "${FUCHSIA}dig${RED} is not installed!"
    exit 1
fi

if [[ "$CHECK_METHOD" == "dig" && -x "$(command -v dig)" ]]; then
    colorEchoN "${ORANGE}DNS Server adderss for dig?[${CYAN}8.8.8.8${ORANGE}]: "
    read -r DIG_DNS_SERVER
    [[ -z "$DIG_DNS_SERVER" ]] && DIG_DNS_SERVER=8.8.8.8
fi

[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

colorEcho "${BLUE}Reading hosts list..."
# first char with `-`: Same IP as prior host
HostListFile="${CURRENT_DIR}/hosts_accelerate_cn.list"
if [[ -s "$HostListFile" ]]; then
    # HostListFileContent=$(cat $HostListFile | tr "\n" " ")
    # HostsList=($(echo ${HostListFileContent}))
    HostsList=()
    # || In case the file has an incomplete (missing newline) last line
    while read -r READLINE || [[ "$READLINE" ]]; do
        HostsList+=("$READLINE")
    done < "${HostListFile}"
else
    HostsList=(
        github.com
        www.github.com
        api.github.com
        gist.github.com
        codeload.github.com
        assets-cdn.github.com
        github.global.ssl.fastly.net
        github-cloud.s3.amazonaws.com
        github-production-release-asset-2e65be.s3.amazonaws.com
        github.githubassets.com
        raw.githubusercontent.com
        -gist.githubusercontent.com
        -cloud.githubusercontent.com
        -camo.githubusercontent.com
        -avatars0.githubusercontent.com
        -avatars1.githubusercontent.com
        -avatars2.githubusercontent.com
        -avatars3.githubusercontent.com
        -avatars4.githubusercontent.com
        -avatars5.githubusercontent.com
        -avatars6.githubusercontent.com
        -avatars7.githubusercontent.com
        -avatars8.githubusercontent.com
    )
fi

# Delete exist host entry
if [[ -z "$TEST_OR_DOWNLOAD_URL" ]]; then
    colorEcho "${BLUE}Deleting exist entry in hosts..."
    # if grep -q "^# Github Start" "${HostsFile}" 2>/dev/null; then
    #     LineBegin=$(cat -n "${HostsFile}" | grep '# Github Start' | awk '{print $1}')
    #     LineEnd=$(cat -n "${HostsFile}" | grep '# Github End' | awk '{print $1}')
    #     if [[ -n "$LineBegin" && -n "$LineEnd" ]]; then
    #         DeleteBegin=$((LineBegin + 1))
    #         DeleteEnd=$((LineEnd - 1))
    #         sudo sed -i "${DeleteBegin},${DeleteEnd}d" "${HostsFile}"
    #         LineEnd=$(cat -n "${HostsFile}" | grep '# Github End' | awk '{print $1}')
    #     fi
    # else
    #     # echo -e "\n# Github Start" | sudo tee -a "${HostsFile}"
    #     IP_HOSTS="\n# Github Start"
    #     sudo sed -i "/github/d" "${HostsFile}"
    # fi

    # sudo sed -i "/[Gg]ithub/d" "${HostsFile}"
    # for (( i = 0; i < ${#HostsList[@]}; i++ )); do
    #     TargetHost=${HostsList[$i]}
    for TargetHost in "${HostsList[@]}"; do
        # remove both leading and trailing spaces
        TargetHost=$(echo "${TargetHost}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        TargetHost=$(echo "${TargetHost}" | sed 's/^-//')
        [[ -z "$TargetHost" ]] && continue

        if echo "${TargetHost}" | grep -q "^#"; then
            sudo sed -i "/^${TargetHost}$/d" "${HostsFile}"
        else
            sudo sed -i "/[[:space:]]${TargetHost}$/d" "${HostsFile}"
        fi
    done
fi

[[ "$CHECK_METHOD" == "reset" ]] && exit 0

# https://amazonaws.com.ipaddress.com/github-cloud.s3.amazonaws.com
# https://github.com.ipaddress.com/
# https://github.com.ipaddress.com/assets-cdn.github.com
# https://fastly.net.ipaddress.com/github.global.ssl.fastly.net
colorEcho "${BLUE}Setting host entries..."
IP_HOSTS=""
for TargetHost in "${HostsList[@]}"; do
    # remove both leading and trailing spaces
    TargetHost=$(echo "${TargetHost}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # empty line as newline
    if [[ -z "$TargetHost" ]]; then
        IP_HOSTS="${IP_HOSTS}\n"
        continue
    fi
    # comment
    if echo "${TargetHost}" | grep -q "^#"; then
        IP_HOSTS="${IP_HOSTS}\n${TargetHost}"
        continue
    fi
    # first char with `-`: Same IP as prior host entry
    SameIPPrior=""
    if echo "${TargetHost}" | grep -q "^-"; then
        SameIPPrior="yes"
        # TargetHost=$(echo ${TargetHost##-}) # remove -
        TargetHost=$(echo "${TargetHost}" | sed 's/^-//')
    fi

    colorEchoN "${BLUE}Checking ${TargetHost}"
    TargetDomain=$(echo "${TargetHost}" | awk -F. '{print $(NF-1),$NF}' OFS=".")
    if [[ "$TargetDomain" == "$TargetHost" ]]; then
        TargetURL=https://${TargetDomain}.ipaddress.com/
    else
        TargetURL=https://${TargetDomain}.ipaddress.com/${TargetHost}
    fi

    if [[ -z "$SameIPPrior" ]]; then
        if [[ "$CHECK_METHOD" == "dig" ]]; then
            TargetIP=$(dig +short "${TargetHost}" @"${DIG_DNS_SERVER}" \
                        | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}' \
                        | grep -v "${NETWORK_WAN_NET_IP}" | head -n1)
        else
            TargetIP=$(curl -fsSL --connect-timeout 5 --max-time 15 "${TargetURL}" \
                        | grep -Eo '<main>.*</main>' \
                        | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}' \
                        | grep -v "${NETWORK_WAN_NET_IP}" | head -n1)
        fi
    fi

    if [[ -n "$TargetIP" ]]; then
        if [[ -x "$(command -v geoiplookup)" ]]; then
            TargetIPGeo=$(geoiplookup "${TargetIP}" | head -n1 | cut -d':' -f2-)
            # TargetIPGeo=""
            # # IPGeo=$(curl -fsSL --connect-timeout 5 --max-time 15 "https://ipinfo.io/${TargetIP}/country")
            # IPGeo=$(curl -fsSL --connect-timeout 5 --max-time 15 \
            #                 "https://ipinfo.io/${TargetIP}/geo" \
            #                 | sed -e 's/[{}", ]//g' -e 's/\r//g')
            # if [[ -n "$IPGeo" ]]; then
            #     IPGeoCountry=$(echo "${IPGeo}" | grep '^country:' | cut -d':' -f2-)
            #     IPGeoRegion=$(echo "${IPGeo}" | grep '^region:' | cut -d':' -f2-)
            #     IPGeoCity=$(echo "${IPGeo}" | grep '^city:' | cut -d':' -f2-)
            #     TargetIPGeo="${IPGeoCity}, ${IPGeoRegion}, ${IPGeoCountry}"
            # fi
        fi
        colorEcho "${YELLOW} ${TargetIP}(${TargetIPGeo/[[:space:]]/})"

        if [[ -z "$IP_HOSTS" ]]; then
            IP_HOSTS="${TargetIP} ${TargetHost}"
        else
            IP_HOSTS="${IP_HOSTS}\n${TargetIP} ${TargetHost}"
        fi
    fi
done

[[ -n "$IP_HOSTS" ]] && echo -e "${IP_HOSTS}"

if [[ -n "$IP_HOSTS" && -z "$TEST_OR_DOWNLOAD_URL" ]]; then
    echo -e "${IP_HOSTS}" | sudo tee -a "${HostsFile}" >/dev/null
fi

# if [[ -n "$IP_HOSTS" && -z "$TEST_OR_DOWNLOAD_URL" ]]; then
#     if ! grep "^# Github End" "${HostsFile}"; then
#         IP_HOSTS="${IP_HOSTS}\n# Github End"
#     fi

#     if [[ -n "$LineBegin" ]]; then
#         sudo sed -i "${LineBegin}a ${IP_HOSTS}" "${HostsFile}"
#     elif [[ -n "$LineEnd" ]]; then
#         sudo sed -i "${LineEnd}i ${IP_HOSTS}" "${HostsFile}"
#     else
#         # echo -e "${IP_HOSTS}" | sudo tee -a "${HostsFile}"
#         echo -e "${IP_HOSTS}" | sudo tee -a "${HostsFile}" >/dev/null
#     fi
# fi


# Flush DNS cache
if [[ "${OS_INFO_TYPE}" == "windows" ]]; then
    ipconfig -flushdns || true
else
    flush_dns_cache
fi


colorEcho "${BLUE}Done."