#!/usr/bin/env bash

# Usage:
# ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_client_config.sh /etc/clash/config.yaml /srv/web/www/public/clash_config.yml
# ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_client_config.sh /etc/clash/config_mini.yaml /srv/web/www/public/clash_mini.yml My_Clash_Rules.ini My_Clash_Sub_Exclude.txt
# (crontab -l 2>/dev/null || true; echo "0 8,12,15,20 * * * $HOME/.dotfiles/cross/clash_client_config.sh /etc/clash/config.yaml /srv/web/www/public/clash_config.yml >/dev/null") | crontab -

# while getopts ":t:c:i:u:o:g:l" OPTNAME; do
#     case $OPTNAME in
#         t) TARGET_CONFIG_FILE="$OPTARG";;
#         c) COPY_TO_FILE="$OPTARG";;
#         i) RULES_INI="$OPTARG";;
#         u) SUB_URL_TXT="$OPTARG";;
#         o) OPTIMIZE_OPTION="$OPTARG";;
#         g) CLASH_CONFIG="$OPTARG";;
#         l) SUB_LIST_FILE="$OPTARG";;
#         :)
#         echo "No argument value for option $OPTARG!"
#         exit 1
#         ;;
#         ?)
#         echo "Unknown option $OPTARG!"
#         exit 1
#         ;;
#         *)
#         echo "Unknown error while processing options!"
#         exit 1
#         ;;
#     esac
#     # echo "-$OPTNAME=$OPTARG index=$OPTIND"
# done

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

# fix "command not found" when running via cron
DirList=(
    "/usr/local/sbin"
    "/usr/local/bin"
    "/usr/sbin"
    "/usr/bin"
    "/sbin"
    "/bin"
)
for TargetDir in "${DirList[@]}"; do
    [[ -d "${TargetDir}" && ":$PATH:" != *":${TargetDir}:"* ]] && PATH="${TargetDir}:$PATH"
done

# jq
if [[ ! -x "$(command -v jq)" ]]; then
    if checkPackageNeedInstall "jq"; then
        colorEcho "${BLUE}Installing ${FUCHSIA}jq${BLUE}..."
        sudo pacman --noconfirm -S jq
    fi
fi

if [[ ! -x "$(command -v jq)" ]]; then
    colorEcho "${FUCHSIA}jq${RED} is not installed!"
    exit 1
fi


TARGET_CONFIG_FILE=${1:-""}
if [[ -z "$TARGET_CONFIG_FILE" ]]; then
    mkdir -p "/srv/clash"
    TARGET_CONFIG_FILE="/srv/clash/config.yaml"
fi
TARGET_WITH_CUSTOM_PROXY="${TARGET_CONFIG_FILE//./_custom.}"

COPY_TO_FILE=${2:-""}

RULES_INI=${3:-"My_Clash_Rules.ini"}

SUB_URL_TXT=${4:-"My_Clash_Sub_URL.txt"}

OPTIMIZE_OPTION=${5:-"no"}

CLASH_CONFIG=${6:-"/etc/clash/clash_client_config.yml"}
[[ ! -s "$CLASH_CONFIG" ]] && CLASH_CONFIG="$HOME/clash_client_config.yml"
[[ ! -s "$CLASH_CONFIG" ]] && CLASH_CONFIG="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_client_config.yml"
if [[ ! -s "$CLASH_CONFIG" ]]; then
    colorEcho "${FUCHSIA}    ${CLASH_CONFIG}${RED} does not exist!"
    exit 1
fi

SUB_LIST_FILE=${7:-"/etc/clash/clash_client_subscription.list"}
[[ ! -s "$SUB_LIST_FILE" ]] && SUB_LIST_FILE="$HOME/clash_client_subscription.list"
[[ ! -s "$SUB_LIST_FILE" ]] && SUB_LIST_FILE="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_client_subscription.list"

if [[ -s "$SUB_LIST_FILE" ]]; then
    # Subscribe urls
    URL_EXCLUDE=$(grep -E '^# exclude=' "${SUB_LIST_FILE}" | cut -d" " -f2)
    URL_CONFIG=$(grep -E '^# config=' "${SUB_LIST_FILE}" | cut -d" " -f2)
    URL_LIST_CONTENT=$(grep -E '^# url=' "${SUB_LIST_FILE}" | cut -d" " -f2 | cut -d"=" -f2)

    URL_UNION=""
    URL_LIST=()
    while read -r READLINE || [[ "${READLINE}" ]]; do
        URL_LIST+=("${READLINE}")
        [[ -n "${URL_UNION}" ]] && URL_UNION="${URL_UNION}%7C${READLINE}" || URL_UNION="${READLINE}"
    done <<<"${URL_LIST_CONTENT}"

    URL_LIST+=("${URL_UNION}")

    # Subconverter web service urls
    SUB_LIST=()
    # || In case the file has an incomplete (missing newline) last line
    while read -r READLINE || [[ "${READLINE}" ]]; do
        [[ "${READLINE}" =~ ^#.* ]] && continue
        SUB_LIST+=("${READLINE}")
    done < "${SUB_LIST_FILE}"

    # Download clash configuration file
    SUB_DOWNLOAD_FILE="${WORKDIR}/clash_sub.yaml"
    for TargetURL in "${SUB_LIST[@]}"; do
        [[ -z "${TargetURL}" ]] && continue

        for URL_URL in "${URL_LIST[@]}"; do
            [[ -z "${URL_URL}" ]] && continue

            # https://www.example.com/sub?target=clash&url=<url>&config=<config>&exclude=<exclude>
            DownloadURL="${TargetURL}&url=${URL_URL}&${URL_CONFIG}"
            [[ -n "${URL_EXCLUDE}" ]] && DownloadURL="${DownloadURL}&${URL_EXCLUDE}"

            colorEcho "${BLUE}Downloading clash configuration from ${FUCHSIA}${DownloadURL}${BLUE}..."
            curl -fSL --noproxy "*" --connect-timeout 10 --max-time 60 \
                -o "${SUB_DOWNLOAD_FILE}" "${DownloadURL}"

            curl_download_status=$?
            if [[ ${curl_download_status} -eq 0 ]]; then
                sed -i -e "s/^allow-lan:.*/allow-lan: false/" \
                    -e "s/^external-controller:.*/# &/" \
                    -e "s/^port:.*/# &/" \
                    -e "s/^redir-port:.*/# &/" \
                    -e "s/^mixed-port:.*/# &/" \
                    -e "s/^socks-port:.*/# &/" "${SUB_DOWNLOAD_FILE}"
                sed -i "1i\mixed-port: 7890\nredir-port: 7892" "${SUB_DOWNLOAD_FILE}"

                DNS_ENABLE=$(yq e ".dns.enable // \"\"" "${SUB_DOWNLOAD_FILE}")
                [[ -z "${DNS_ENABLE}" ]] && sed -i "/^redir-port/r ${DNS_CONIFG_FILE}" "${SUB_DOWNLOAD_FILE}"

                sudo cp -f "${SUB_DOWNLOAD_FILE}" "${TARGET_CONFIG_FILE}"

                # if pgrep -f "clash" >/dev/null 2>&1; then
                if [[ $(systemctl is-enabled clash 2>/dev/null) ]]; then
                    colorEcho "${BLUE}Checking clash connectivity..."
                    sudo systemctl restart clash && sleep 3

                    if check_socks5_proxy_up "127.0.0.1:7890"; then
                        colorEcho "${GREEN}The configuration looks ok, done!"
                        exit 0
                    else
                        colorEcho "${RED}Connection failed!"
                    fi
                else
                    exit 0
                fi
            fi
        done
    done
fi


if ! pgrep -f "subconverter" >/dev/null 2>&1; then
    # if [[ -s "/srv/subconverter/subconverter" ]]; then
    #     nohup /srv/subconverter/subconverter >/dev/null 2>&1 & disown
    # fi
    [[ $(systemctl is-enabled subconverter 2>/dev/null) ]] && sudo systemctl restart subconverter
fi

if ! pgrep -f "subconverter" >/dev/null 2>&1; then
    colorEcho "${RED}Please install and run ${FUCHSIA}subconverter${RED} first!"
    exit 1
fi


colorEcho "${BLUE}Getting ${FUCHSIA}clash rules${BLUE}..."

# Update ACL4SSR
# https://github.com/ACL4SSR/ACL4SSR
if [[ -s "/srv/subconverter/subconverter" ]]; then
    if [[ -d "/etc/clash" ]]; then
        find "/etc/clash" -type f -name "*_Profile*" -print0 | xargs -0 -I{} cp -f {} "/srv/subconverter/profiles"
        find "/srv/subconverter/config" -type l -name "*_Rules*" -print0 | xargs -0 -I{} rm -f {}
        find "/etc/clash" -type f -name "*_Rules*" -print0 | xargs -0 -I{} cp -f {} "/srv/subconverter/config"
    fi

    if Git_Clone_Update_Branch "ACL4SSR/ACL4SSR" "/srv/subconverter/ACL4SSR" "github.com" "master"; then
        cp -f /srv/subconverter/ACL4SSR/Clash/*.list /srv/subconverter/rules/ACL4SSR/Clash
        cp -f /srv/subconverter/ACL4SSR/Clash/Ruleset/*.list /srv/subconverter/rules/ACL4SSR/Clash/Ruleset
        cp -f /srv/subconverter/ACL4SSR/Clash/*.yml /srv/subconverter/config
        cp -f /srv/subconverter/ACL4SSR/Clash/config/*.ini /srv/subconverter/config
    fi
fi

CFW_BYPASS_LINE=$(grep -E -n "^# \[CFW_BYPASS\]" "$CLASH_CONFIG" | cut -d: -f1)
[[ -z "${CFW_BYPASS_LINE}" ]] && CFW_BYPASS_LINE=0

PROXY_CUSTOM_LINE=$(grep -E -n "^# \[PROXY_CUSTOM\]" "$CLASH_CONFIG" | cut -d: -f1)
[[ -z "${PROXY_CUSTOM_LINE}" ]] && PROXY_CUSTOM_LINE=0

PROXY_LINE=$(grep -E -n "^# \[PROXY\]" "$CLASH_CONFIG" | cut -d: -f1)

PROXY_MERGE_LINE=$(grep -E -n "^# \[PROXY_MERGE\]" "$CLASH_CONFIG" | cut -d: -f1)
[[ -z "${PROXY_MERGE_LINE}" ]] && PROXY_MERGE_LINE=0

PROXY_GROUP_LINE=$(grep -E -n "^# \[PROXY_GROUP\]" "$CLASH_CONFIG" | cut -d: -f1)

RULES_LINE=$(grep -E -n "^# \[RULES\]" "$CLASH_CONFIG" | cut -d: -f1)

# [RULES]
colorEcho "${BLUE}  Getting ${FUCHSIA}subscription rules${BLUE}..."
RULES=""

if [[ -s "/etc/clash/${SUB_URL_TXT}" ]]; then
    RULES_URL=$(head -n1 "/etc/clash/${SUB_URL_TXT}")
else
    if [[ ${RULES_LINE} -gt 0 ]]; then
        RULES_URL=$(sed -n "${RULES_LINE}p" "$CLASH_CONFIG" | cut -d"]" -f2-)
    fi
fi

if [[ -n "$RULES_URL" ]]; then
    curl -fsL --connect-timeout 10 --max-time 30 \
        -o "${WORKDIR}/rules.yml" "${RULES_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} != 0 ]]; then
        colorEcho "${RED}    Can't get rules from ${FUCHSIA}${RULES_URL}${RED}!"
        exit 1
    fi
fi

if [[ -s "${WORKDIR}/rules.yml" ]]; then
    RULES_START_LINE=$(grep -E -n "^rules:" "${WORKDIR}/rules.yml" | cut -d: -f1)
    if [[ ${RULES_START_LINE} -gt 0 ]]; then
        RULES_START_LINE=$((RULES_START_LINE + 1))
        RULES=$(sed -n "${RULES_START_LINE},$ p" "${WORKDIR}/rules.yml")
    fi
fi

# [PROXY_GROUP]
colorEcho "${BLUE}  Getting ${FUCHSIA}proxy-groups${BLUE}..."
PROXY_GROUP=""
if [[ ${RULES_START_LINE} -gt 0 ]]; then
    if [[ -s "${WORKDIR}/rules.yml" ]]; then
        GROUP_START_LINE=$(grep -E -n "^proxy-groups:" "${WORKDIR}/rules.yml" | cut -d: -f1)
        if [[ ${GROUP_START_LINE} -gt 0 ]]; then
            GROUP_START_LINE=$((GROUP_START_LINE + 1))
            GROUP_END_LINE=$((RULES_START_LINE - 2))
            PROXY_GROUP=$(sed -n "${GROUP_START_LINE},${GROUP_END_LINE} p" "${WORKDIR}/rules.yml")
        fi
    fi
fi

# [PROXY]
colorEcho "${BLUE}  Getting ${FUCHSIA}proxies${BLUE}..."
PROXY=""
if [[ ${GROUP_START_LINE} -gt 0 ]]; then
    if [[ -s "${WORKDIR}/rules.yml" ]]; then
        PROXY_START_LINE=$(grep -E -n "^proxies:" "${WORKDIR}/rules.yml" | cut -d: -f1)
        if [[ ${GROUP_START_LINE} -gt 0 ]]; then
            PROXY_START_LINE=$((PROXY_START_LINE + 1))
            PROXY_END_LINE=$((GROUP_START_LINE - 2))
            PROXY=$(sed -n "${PROXY_START_LINE},${PROXY_END_LINE} p" "${WORKDIR}/rules.yml")
        fi
    fi
fi

# [PROXY_CUSTOM]
PROXY_CUSTOM=""
PROXY_CUSTOM_FILE="/etc/clash/clash_proxy_custom.yml"
if [[ -s "$PROXY_CUSTOM_FILE" ]]; then
    colorEcho "${BLUE}  Getting ${FUCHSIA}custom proxies${BLUE}..."
    PROXY_CUSTOM=$(< "$PROXY_CUSTOM_FILE")
fi

# [PROXY_MERGE]
PROXY_MERGE=""
if [[ ${PROXY_MERGE_LINE} -gt 0 ]]; then
    MERGE_URL=$(sed -n "${PROXY_MERGE_LINE}p" "$CLASH_CONFIG" | cut -d"]" -f2-)
    if [[ -n "$MERGE_URL" ]]; then
        colorEcho "${BLUE}  Getting ${FUCHSIA}merge proxies${BLUE}..."
        curl -fsL --connect-timeout 10 --max-time 30 \
            -o "${WORKDIR}/merge.yml" "${MERGE_URL}"

        curl_download_status=$?
        if [[ ${curl_download_status} != 0 ]]; then
            colorEcho "${RED}    Can't get merge proxies from ${FUCHSIA}${MERGE_URL}${RED}!"
            exit 1
        fi
    fi

    if [[ -s "${WORKDIR}/merge.yml" ]]; then
        PROXY_MERGE=$(grep "{name:" "${WORKDIR}/merge.yml")
    fi
fi

# [CFW_BYPASS]
colorEcho "${BLUE}  Getting ${FUCHSIA}cfw bypass rules${BLUE}..."
CFW_BYPASS=""
if [[ ${CFW_BYPASS_LINE} -gt 0 ]]; then
    CFW_BYPASS_FILE="/srv/subconverter/config/GeneralClashConfig.yml"
    if [[ ! -s "${CFW_BYPASS_FILE}" ]]; then
        CFW_BYPASS_FILE=""
        CFW_BYPASS_URL=$(sed -n "${CFW_BYPASS_LINE}p" "$CLASH_CONFIG" | cut -d"]" -f2-)
        if [[ -n "$CFW_BYPASS_URL" ]]; then
            curl -fsL --connect-timeout 10 --max-time 30 \
                -o "${CFW_BYPASS_FILE}" "${CFW_BYPASS_URL}"

            curl_download_status=$?
            if [[ ${curl_download_status} != 0  ]]; then
                colorEcho "${RED}    Can't get cfw bypass rules from ${FUCHSIA}${CFW_BYPASS_URL}${RED}!"
                exit 1
            fi
        fi
    fi

    if [[ -s "${CFW_BYPASS_FILE}" ]]; then
        BYPASS_START_LINE=$(grep -E -n "^cfw\-bypass:" "${CFW_BYPASS_FILE}" | cut -d: -f1)
        if [[ ${BYPASS_START_LINE} -gt 0 ]]; then
            BYPASS_START_LINE=$((BYPASS_START_LINE + 1))
            CFW_BYPASS=$(sed -n "${BYPASS_START_LINE},$ p" "${CFW_BYPASS_FILE}")
        fi
    fi
fi

# custom rules
RULE_CUSTOM_FILE="/etc/clash/clash_rule_custom.yml"
if [[ -s "$RULE_CUSTOM_FILE" ]]; then
    colorEcho "${BLUE}  Getting ${FUCHSIA}custom rules${BLUE}..."
    RULE_CUSTOM=$(< "$RULE_CUSTOM_FILE")
fi

# all rules
[[ -n "${RULE_CUSTOM}" ]] && RULES=$(echo -e "${RULE_CUSTOM}\n${RULES}")

# remove 2nd+ occurernce rules
colorEcho "${BLUE}  Processing ${FUCHSIA}duplicate rules${BLUE}..."
DUPLICATE_RULES=$(echo "${RULES}" | grep -Eo ",[a-zA-Z0-9./?=_%:-]*," \
                    | sort -n | uniq -c | awk '{if($1>1) print $2}' | sort -rn)
while read -r line; do
    [[ -z "${line}" ]] && continue
    DUPLICATE_ENTRY=$(echo "${line}" \
        | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"]/\\&/g' \
        | sed 's/]/\\&/g')

    # https://stackoverflow.com/questions/30688682/how-to-remove-from-second-occurrence-until-the-end-of-the-file
    RULES=$(echo "${RULES}" | sed "0,/${DUPLICATE_ENTRY}/b; /${DUPLICATE_ENTRY}/d")

    ## https://stackoverflow.com/questions/16202900/using-sed-between-specific-lines-only
    # ENTRY_FIRST_LINE=$(echo "${RULES}" | grep -En "${DUPLICATE_ENTRY}" | cut -d: -f1 | head -n1)
    # [[ -z "${ENTRY_FIRST_LINE}" ]] && continue
    # ENTRY_START_LINE=$((ENTRY_FIRST_LINE + 1))
    # RULES=$(echo "${RULES}" | sed "${ENTRY_START_LINE},$ {/${DUPLICATE_ENTRY}/d;}")
done <<<"${DUPLICATE_RULES}"

# proxy list
# Extract word from string using grep/sed/awk
# https://askubuntu.com/questions/697120/extract-word-from-string-using-grep-sed-awk
PROXY_NAME=()
PROXY_TYPE=()
while read -r line; do
    [[ -z "${line}" ]] && continue
    line_name=$(echo "$line" \
        | sed -rn "s/.*[\s\{\,]+name:([^,{}]+).*/\1/ip" \
        | sed -e "s/^\s//" -e "s/\s$//" \
        | sed -e "s/^\"//" -e "s/\"$//")
    PROXY_NAME+=("$line_name")

    line_type=$(echo "$line" \
        | sed -rn "s/.*type:([^,{}]+).*/\1/ip" \
        | sed -e "s/^\s//" -e "s/\s$//" \
        | sed -e "s/^\"//" -e "s/\"$//")
    PROXY_TYPE+=("$line_type")
done <<<"$PROXY"

# Optimize proxies
if [[ "$OPTIMIZE_OPTION" == "yes" && -n "$PROXY" && -n "$PROXY_GROUP" ]]; then
    colorEcho "${BLUE}  Optimizing ${FUCHSIA}proxies${BLUE}..."

    # GROUP_CNT=$(echo "$PROXY_GROUP" | grep -E "^[ ]*\-\sname:" | wc -l)
    PROXY_GROUP_MAIN=$(echo "$PROXY_GROUP" | awk "/^[ ]*-[ ]*name:/{i++}i<=2")
    PROXY_GROUP_REMAIN=$(echo "$PROXY_GROUP" | awk "/^[ ]*-[ ]*name:/{i++}i>2")

    # add custom proxies to 1st,2nd group,before 1st proxy list
    if [[ -n "$PROXY_CUSTOM" ]]; then
        CUSTOM_NAME=()
        while read -r line; do
            [[ -z "${line}" ]] && continue
            line_name=$(echo "$line" \
                | sed -rn "s/.*[\s\{\,]+name:([^,{}]+).*/\1/ip" \
                | sed -e "s/^\s//" -e "s/\s$//" \
                | sed -e "s/^\"//" -e "s/\"$//")
            CUSTOM_NAME+=("$line_name")
        done <<<"$PROXY_CUSTOM"

        FIRST_PROXY_NAME=$(echo "${PROXY_NAME[0]}" \
            | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"]/\\&/g' \
            | sed 's/]/\\&/g')
        for TargetName in "${CUSTOM_NAME[@]}"; do
            [[ -z "$TargetName" ]] && continue
            PROXY_GROUP_MAIN=$(echo "$PROXY_GROUP_MAIN" \
                | sed "/^\s*\-\s*${FIRST_PROXY_NAME}$/i\      - ${TargetName}" \
                | sed "/^\s*\-\s*\"${FIRST_PROXY_NAME}\"$/i\      - ${TargetName}")
        done
    fi

    # add merge proxies to 1st,2nd group,after last proxy list
    if [[ -n "$PROXY_MERGE" ]]; then
        MERGE_NAME=()
        while read -r line; do
            [[ -z "${line}" ]] && continue
            line_name=$(echo "$line" \
                | sed -rn "s/.*[\s\{\,]+name:([^,{}]+).*/\1/ip" \
                | sed -e "s/^\s//" -e "s/\s$//" \
                | sed -e "s/^\"//" -e "s/\"$//")
            MERGE_NAME+=("$line_name")
        done <<<"$PROXY_MERGE"

        LAST_PROXY_NAME=$(echo "${PROXY_NAME[-1]}" \
            | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"]/\\&/g' \
            | sed 's/]/\\&/g')
        for TargetName in "${MERGE_NAME[@]}"; do
            [[ -z "$TargetName" ]] && continue
            PROXY_GROUP_MAIN=$(echo "$PROXY_GROUP_MAIN" \
                | sed "/^\s*\-\s*${LAST_PROXY_NAME}$/a\      - ${TargetName}" \
                | sed "/^\s*\-\s*\"${LAST_PROXY_NAME}\"$/a\      - ${TargetName}")
        done
    fi

    for TargetName in "${PROXY_NAME[@]}"; do
        [[ -z "$TargetName" ]] && continue

        TargetName=$(echo "${TargetName}" \
            | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"]/\\&/g' \
            | sed 's/]/\\&/g')

        # delete proxy list after 3th group
        PROXY_GROUP_REMAIN=$(echo "$PROXY_GROUP_REMAIN" \
            | sed -e "/^\s*\-\s*${TargetName}$/d" -e "/^\s*\-\s*\"${TargetName}\"$/d")
    done

    PROXY_GROUP_REMAIN=$(echo "$PROXY_GROUP_REMAIN" | sed "/^\s*\-\s*\"\"$/d")
    PROXY_GROUP=$(echo -e "${PROXY_GROUP_MAIN}\n${PROXY_GROUP_REMAIN}")
    # add blank line before each group
    PROXY_GROUP=$(echo "$PROXY_GROUP" | sed 's/^\s*\-\s*name:/\n&/' | sed '1d')
fi

# Delete Shadowsocks proxies
colorEcho "${BLUE}  Deleting ${FUCHSIA}Shadowsocks proxies${BLUE}..."
PROXY_INDEX=-1
for TargetName in "${PROXY_NAME[@]}"; do
    PROXY_INDEX=$((PROXY_INDEX + 1))

    [[ -z "$TargetName" ]] && continue

    TargetName=$(echo "${TargetName}" \
        | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"]/\\&/g' \
        | sed 's/]/\\&/g')

    if [[ "${PROXY_TYPE[$PROXY_INDEX]}" == "ss" || "${PROXY_TYPE[$PROXY_INDEX]}" == "ssr" ]]; then
        PROXY=$(echo "$PROXY" | sed "/name:\s*${TargetName},/d")
        PROXY_GROUP=$(echo "$PROXY_GROUP" | sed "/^\s*\-\s*${TargetName}$/d")
    fi
done

# Delete empty group
colorEcho "${BLUE}  Deleting ${FUCHSIA}empty group${BLUE}..."
if [[ -n "$PROXY_GROUP" ]]; then
    GROUP_LIST=$(echo "$PROXY_GROUP" | grep -E "^[ ]*\-\sname:" | sed "s/^[ ]*\-\sname:\s//g")
    GROUP_NAME=()
    while read -r line; do
        GROUP_NAME+=("$line")
    done <<<"$GROUP_LIST"

    # GROUP_CNT=$(echo "$PROXY_GROUP" | grep -E "^[ ]*\-\sname:" | wc -l)
    PROXY_GROUP_REMAIN=""
    GROUP_DELETE=()
    for ((g=0; g < ${#GROUP_NAME[@]}; g++)); do
        awk_cnt=$((g + 1))
        GROUP_CHECK=$(echo "$PROXY_GROUP" | awk "/^[ ]*-[ ]*name:/{i++}i==${awk_cnt}")

        if echo "${GROUP_NAME[$g]}" | grep -q '直连'; then
            PROXIES_CNT=3
        else
            PROXIES_CNT=$(echo "$GROUP_CHECK" | grep -E "^[ ]*\-" | grep -v 'DIRECT' | wc -l)
        fi

        if [[ ${PROXIES_CNT} -gt 1 ]]; then
            if [[ -n "${PROXY_GROUP_REMAIN}" ]]; then
                PROXY_GROUP_REMAIN=$(echo -e "${PROXY_GROUP_REMAIN}\n${GROUP_CHECK}")
            else
                PROXY_GROUP_REMAIN="${GROUP_CHECK}"
            fi
        else
            GROUP_DELETE+=("${GROUP_NAME[$g]}")
        fi
    done

    for TargetName in "${GROUP_DELETE[@]}"; do
        TargetName=$(echo "${TargetName}" \
            | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"]/\\&/g' \
            | sed 's/]/\\&/g')
        PROXY_GROUP_REMAIN=$(echo "$PROXY_GROUP_REMAIN" | sed "/^\s*\-\s*${TargetName}$/d")
    done

    PROXY_GROUP="${PROXY_GROUP_REMAIN}"
fi

# Add contents to target config file
colorEcho "${BLUE}  Setting ${FUCHSIA}all config to ${FUCHSIA}${TARGET_CONFIG_FILE}${BLUE}..."
[[ -f "$TARGET_CONFIG_FILE" ]] && rm -f "$TARGET_CONFIG_FILE"

START_LINE=1
if [[ ${CFW_BYPASS_LINE} -gt 0 ]]; then
    ADD_CONTENT=$(sed -n "${START_LINE},${CFW_BYPASS_LINE} p" "$CLASH_CONFIG")
    echo "$ADD_CONTENT" >> "$TARGET_CONFIG_FILE"
fi

if [[ -n "$CFW_BYPASS" ]]; then
    colorEcho "${BLUE}    Setting ${FUCHSIA}cfw bypass${BLUE}..."
    echo "${CFW_BYPASS}" | tee -a "$TARGET_CONFIG_FILE" >/dev/null
fi

START_LINE=$((CFW_BYPASS_LINE + 1))
if [[ ${PROXY_CUSTOM_LINE} -gt 0 ]]; then
    ADD_CONTENT=$(sed -n "${START_LINE},${PROXY_CUSTOM_LINE} p" "$CLASH_CONFIG")
    echo "$ADD_CONTENT" >> "$TARGET_CONFIG_FILE"
fi

if [[ -n "$PROXY_CUSTOM" ]]; then
    colorEcho "${BLUE}    Setting ${FUCHSIA}custom proxies${BLUE}..."
    echo "${PROXY_CUSTOM}" | tee -a "$TARGET_CONFIG_FILE" >/dev/null
fi

if [[ ${PROXY_CUSTOM_LINE} -gt 0 ]]; then
    START_LINE=$((PROXY_CUSTOM_LINE + 1))
else
    START_LINE=$((CFW_BYPASS_LINE + 1))
fi
ADD_CONTENT=$(sed -n "${START_LINE},${PROXY_LINE} p" "$CLASH_CONFIG")
echo "$ADD_CONTENT" >> "$TARGET_CONFIG_FILE"

if [[ -n "$PROXY" ]]; then
    colorEcho "${BLUE}    Setting ${FUCHSIA}proxies${BLUE}..."
    echo "${PROXY}" | tee -a "$TARGET_CONFIG_FILE" >/dev/null
fi

START_LINE=$((PROXY_LINE + 1))
if [[ ${PROXY_MERGE_LINE} -gt 0 ]]; then
    ADD_CONTENT=$(sed -n "${START_LINE},${PROXY_MERGE_LINE} p" "$CLASH_CONFIG")
    echo "$ADD_CONTENT" >> "$TARGET_CONFIG_FILE"
fi

if [[ -n "$PROXY_MERGE" ]]; then
    colorEcho "${BLUE}    Setting ${FUCHSIA}merge proxies${BLUE}..."
    echo "${PROXY_MERGE}" | tee -a "$TARGET_CONFIG_FILE" >/dev/null
fi

if [[ ${PROXY_MERGE_LINE} -gt 0 ]]; then
    START_LINE=$((PROXY_MERGE_LINE + 1))
else
    START_LINE=$((PROXY_LINE + 1))
fi
ADD_CONTENT=$(sed -n "${START_LINE},${PROXY_GROUP_LINE} p" "$CLASH_CONFIG")
echo "$ADD_CONTENT" >> "$TARGET_CONFIG_FILE"

if [[ -n "$PROXY_GROUP" ]]; then
    colorEcho "${BLUE}    Setting ${FUCHSIA}proxy groups${BLUE}..."
    echo "${PROXY_GROUP}" | tee -a "$TARGET_CONFIG_FILE" >/dev/null
fi

START_LINE=$((PROXY_GROUP_LINE + 1))
ADD_CONTENT=$(sed -n "${START_LINE},${RULES_LINE} p" "$CLASH_CONFIG")
echo "$ADD_CONTENT" >> "$TARGET_CONFIG_FILE"

# if [[ -n "$RULE_CUSTOM" ]]; then
#     colorEcho "${BLUE}    Setting ${FUCHSIA}custom rules${BLUE}..."
#     echo "${RULE_CUSTOM}" | tee -a "$TARGET_CONFIG_FILE" >/dev/null
# fi

if [[ -n "$RULES" ]]; then
    colorEcho "${BLUE}    Setting ${FUCHSIA}rules${BLUE}..."
    echo "${RULES}" | tee -a "$TARGET_CONFIG_FILE" >/dev/null
fi

sed -i "/^# \[.*/d" "$TARGET_CONFIG_FILE"

# Config file with custom proxy
if [[ -n "$TARGET_WITH_CUSTOM_PROXY" ]]; then
    cp -f "$TARGET_CONFIG_FILE" "$TARGET_WITH_CUSTOM_PROXY"
fi

# Remove custom proxy from $TARGET_CONFIG_FILE
if [[ -n "$PROXY_CUSTOM" ]]; then
    CUSTOM_START_LINE=$(grep -E -n "^proxies:" "${TARGET_CONFIG_FILE}" | cut -d: -f1)
    CUSTOM_START_LINE=$((CUSTOM_START_LINE + 1))
    PROXY_CUSTOM_COUNT=$(echo "$PROXY_CUSTOM" | wc -l)
    CUSTOM_END_LINE=$((CUSTOM_START_LINE + PROXY_CUSTOM_COUNT))
    sed -i "${CUSTOM_START_LINE},${CUSTOM_END_LINE} d" "$TARGET_CONFIG_FILE"

    for TargetName in "${CUSTOM_NAME[@]}"; do
        sed -i "/      - ${TargetName}/d" "$TARGET_CONFIG_FILE"
    done
fi

# Copy to file
if [[ -n "$COPY_TO_FILE" ]]; then
    colorEcho "${BLUE}  Copy config to ${FUCHSIA}${COPY_TO_FILE}${BLUE}..."
    if [[ -d "/srv/clash" && "$TARGET_CONFIG_FILE" != "/srv/clash/config.yaml" ]]; then
        cp -f "$TARGET_CONFIG_FILE" "/srv/clash/config.yaml"
    fi

    cp -f "$TARGET_CONFIG_FILE" "$COPY_TO_FILE"

    if [[ ! -s "${COPY_TO_FILE}.md5" ]]; then
        colorEcho "${BLUE}  Gen md5 for ${FUCHSIA}${COPY_TO_FILE}${BLUE}..."
        (openssl md5 -hex "${COPY_TO_FILE}" | cut -d" " -f2) > "${COPY_TO_FILE}.md5"
    fi

    COPY_TO_CUSTOM="${COPY_TO_FILE//./_custom.}"
    colorEcho "${BLUE}  Copy config with custom proxy to ${FUCHSIA}${COPY_TO_CUSTOM}${BLUE}..."
    cp -f "$TARGET_WITH_CUSTOM_PROXY" "$COPY_TO_CUSTOM"

    if [[ ! -s "${COPY_TO_CUSTOM}.md5" ]]; then
        colorEcho "${BLUE}  Gen md5 for ${FUCHSIA}${COPY_TO_CUSTOM}${BLUE}..."
        (openssl md5 -hex "${COPY_TO_CUSTOM}" | cut -d" " -f2) > "${COPY_TO_CUSTOM}.md5"
    fi
fi

cd "${CURRENT_DIR}" || exit

colorEcho "${BLUE}  Done!"
