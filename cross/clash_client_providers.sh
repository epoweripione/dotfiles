#!/usr/bin/env bash

# Usage:
# ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_client_providers.sh /srv/web/www/public
# (crontab -l 2>/dev/null || true; echo "0 8,12,15,20 * * * $HOME/.dotfiles/cross/clash_client_providers.sh /srv/web/www/public >/dev/null") | crontab -

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

# filter, minify, compact subscribe yaml file
# only keep `proxies`
function processSubscribeFile() {
    local subscribeFile=$1
    local readYamlLine yamlLineCount yamlLineToDelete yamlLineToRemove curlyLeft curlyRight

    [[ ! -f "${subscribeFile}" ]] && return

    ## Global filter
    # if [[ -n "${GLOBAL_FILTER}" ]]; then
    #     sed -ri "/(${GLOBAL_FILTER})/d" "${subscribeFile}"
    # fi

    # if [[ -n "${GLOBAL_PERL_FILTER}" ]]; then
    #     perl -i -ne "/${GLOBAL_PERL_FILTER}/ or print" "${subscribeFile}"
    # fi

    # delete the commented line
    sed -i '/^\s*#/d' "${subscribeFile}"

    # Remove certain characters
    if [[ -n "${TARGET_WORD_REPLACE}" ]]; then
        TARGET_WORD_REPLACE="${TARGET_WORD_REPLACE//|/\\|}"
        sed -i "s/\(${TARGET_WORD_REPLACE}\)//g" "${subscribeFile}"
    fi

    # Replace \r\n with \n
    sed -i 's/\r$//g' "${subscribeFile}"

    # Minify yaml file
    if ! grep -Eq '\-\s+{' "${subscribeFile}"; then
        colorEcho "${BLUE}      Minifying ${FUCHSIA}${subscribeFile}${BLUE}..."
        PROXY_START_LINE=$(grep -Ean "^proxies:" "${subscribeFile}" | cut -d: -f1)
        GROUP_START_LINE=$(grep -Ean "^proxy-groups:" "${subscribeFile}" | cut -d: -f1)
        [[ -z "${GROUP_START_LINE}" || ${GROUP_START_LINE} -le ${PROXY_START_LINE} ]] && GROUP_START_LINE=$(grep -Ean "^rules:" "${subscribeFile}" | cut -d: -f1)
        [[ -z "${GROUP_START_LINE}" || ${GROUP_START_LINE} -le ${PROXY_START_LINE} ]] && GROUP_START_LINE=$(wc -l "${subscribeFile}" | awk '{print $1}') && GROUP_START_LINE=$((GROUP_START_LINE + 1))
        if [[ ${PROXY_START_LINE} -gt 0 && ${GROUP_START_LINE} -gt 0 && ${GROUP_START_LINE} -gt ${PROXY_START_LINE} ]]; then
            PROXY_START_LINE=$((PROXY_START_LINE + 0))
            PROXY_END_LINE=$((GROUP_START_LINE - 1))
            sed -n "${PROXY_START_LINE},${PROXY_END_LINE} p" "${subscribeFile}" > "${subscribeFile}.yml"
        fi

        if [[ -f "${subscribeFile}.yml" ]]; then
            # Minify to new file
            yq '.. style="flow"' "${subscribeFile}.yml" \
                | sed -e 's|^{||' -e 's|]}||' \
                | sed 's|\s\[|\n  - |' \
                | sed 's|}, {|}\n  - {|g' \
                > "${subscribeFile}.new"

            # Convert unicode codepoints '\uXXXX' in file
            echo -e "$(cat "${subscribeFile}.new")" > "${subscribeFile}.yml"
            [[ -f "${subscribeFile}.new" ]] && rm "${subscribeFile}.new"
        fi

        if [[ -f "${subscribeFile}.yml" ]]; then
            echo 'proxy-groups:' >> "${subscribeFile}.yml"
            rm "${subscribeFile}" && mv "${subscribeFile}.yml" "${subscribeFile}"
        fi
    fi

    # Compact proxies
    sed -i '/^\s*#/d' "${subscribeFile}"
    sed -i 's/^\s*-/-/g' "${subscribeFile}"
    sed -i -e 's/":/: /g' -e 's/:"/: /g' -e 's/",/, /g' -e 's/,"/, /g' -e 's/"//g' "${subscribeFile}"
    sed -i -e "s/':/: /g" -e "s/:'/: /g" -e "s/',/, /g" -e "s/,'/, /g" -e "s/'//g" "${subscribeFile}"
    # sed -i -e 's/\[/【/g' -e 's/\]/】/g' -e 's/|/｜/g' -e 's/\?/？/g' -e 's/\&/δ/g' "${subscribeFile}"
    sed -i -e "s/name:\s*\-\s*/name: /g" "${subscribeFile}"
    sed -i -e 's/\(\&[a-zA-Z0-9]\+;\)\+.*\(\&[a-zA-Z0-9]\+;\)\+\s*//g' "${subscribeFile}"
    sed -i -e 's/\&[a-zA-Z0-9]\+;//g' -e 's/\[/【/g' -e 's/\]/】/g' -e 's/[\|\&\(\)]//g' "${subscribeFile}"

    # yaml: character `@` cannot start any token
    sed -i -e 's/:\s\+@/: /g' "${subscribeFile}"

    # Delete lines with empty name
    sed -i '/name:\s*,/d' "${subscribeFile}"
    sed -i 's/,,/,/g' "${subscribeFile}"

    # Remove char `,` occurernce more than once in proxy name
    sed -ri "/(name:\s([^:]+,){2,}[^:]+:)/ { s/,//g; s/\s+([^[:space:]:{]+:)/, \1/g; }" "${subscribeFile}"

    # Remove line that curly brackets `{}` unmatched
    yamlLineCount=0
    yamlLineToDelete=()
    while read -r readYamlLine || [[ "${readYamlLine}" ]]; do
        yamlLineCount=$((yamlLineCount + 1))
        [[ -z "${readYamlLine}" ]] && continue

        curlyLeft=$(grep -o '{' <<<"${readYamlLine}" | wc -w)
        curlyRight=$(grep -o '}' <<<"${readYamlLine}" | wc -w)
        [[ ${curlyLeft} -eq ${curlyRight} ]] && continue

        yamlLineToDelete+=("${yamlLineCount}")
    done < "${subscribeFile}"

    IFS=$'\n' yamlLineToRemove=$(sort -nr <<<"${yamlLineToDelete[*]}")
    while read -r readYamlLine || [[ "${readYamlLine}" ]]; do
        [[ -z "${readYamlLine}" ]] && continue
        sed -i "${readYamlLine} d" "${subscribeFile}"
    done <<< "${yamlLineToRemove}"

    # Global filter
    if [[ -n "${GLOBAL_FILTER}" ]]; then
        # private,subscription
        if [[ "${TARGET_OPTION}" != "private" && "${TARGET_OPTION}" != *"subscription"* ]]; then
            sed -ri "/(${GLOBAL_FILTER})/d" "${subscribeFile}"
        fi
    fi

    if [[ -n "${GLOBAL_PERL_FILTER}" ]]; then
        perl -i -ne "/${GLOBAL_PERL_FILTER}/ or print" "${subscribeFile}"
    fi

    # delete lines contain control characters
    NOT_VALID_LINE=$(grep -n -P "[\x80-\xFF]" "${subscribeFile}" | cut -d: -f1 | sort -nr)
    while read -r line; do
        [[ ${line} -gt 0 ]] && sed -i "${line}d" "${subscribeFile}"
    done <<< "${NOT_VALID_LINE}"

    # only keep `proxies`
    PROXY_START_LINE=$(grep -Ean "^proxies:" "${subscribeFile}" | cut -d: -f1)
    GROUP_START_LINE=$(grep -Ean "^proxy-groups:" "${subscribeFile}" | cut -d: -f1)
    [[ -z "${GROUP_START_LINE}" || ${GROUP_START_LINE} -le ${PROXY_START_LINE} ]] && GROUP_START_LINE=$(grep -Ean "^rules:" "${subscribeFile}" | cut -d: -f1)
    [[ -z "${GROUP_START_LINE}" || ${GROUP_START_LINE} -le ${PROXY_START_LINE} ]] && GROUP_START_LINE=$(wc -l "${subscribeFile}" | awk '{print $1}') && GROUP_START_LINE=$((GROUP_START_LINE + 1))
    if [[ ${PROXY_START_LINE} -gt 0 && ${GROUP_START_LINE} -gt 0 && ${GROUP_START_LINE} -gt ${PROXY_START_LINE} ]]; then
        PROXY_START_LINE=$((PROXY_START_LINE + 0))
        PROXY_END_LINE=$((GROUP_START_LINE - 1))
        sed -n "${PROXY_START_LINE},${PROXY_END_LINE} p" "${subscribeFile}" > "${subscribeFile}.yml"
    fi
    if [[ -f "${subscribeFile}.yml" ]]; then
        rm "${subscribeFile}" && mv "${subscribeFile}.yml" "${subscribeFile}"
    fi
}

[[ -z "${READ_ARRAY_OPTS[*]}" ]] && Get_Read_Array_Options
[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

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


COPY_TO_DIR=${1:-""}
TARGET_CONFIG_FILE=${2:-"/etc/clash/clash_provider.yml"}

SUB_URL_LIST=${3:-"/etc/clash/My_Clash_Sub_Providers.txt"}
if [[ ! -s "${SUB_URL_LIST}" ]]; then
    colorEcho "${FUCHSIA}    ${SUB_URL_LIST}${RED} does not exist!"
    exit 1
fi
TMP_URL_LIST="${WORKDIR}/url.txt"
cp "${SUB_URL_LIST}" "${TMP_URL_LIST}"

OUTPUT_OPTIONS=${4:-""} # private,subscription@only

CLASH_CONFIG=${5:-"/etc/clash/clash_client_providers.yml"}
if [[ ! -s "${CLASH_CONFIG}" ]]; then
    colorEcho "${FUCHSIA}    ${CLASH_CONFIG}${RED} does not exist!"
    exit 1
fi

# clash subscribe files store directory
[[ -z "${SUBSCRIBE_DOWNLOAD_DIR}" || ! -d "${SUBSCRIBE_DOWNLOAD_DIR}" ]] && SUBSCRIBE_DOWNLOAD_DIR="${WORKDIR}"

if ! pgrep -f "subconverter" >/dev/null 2>&1; then
    # if [[ -s "/srv/subconverter/subconverter" ]]; then
    #     nohup /srv/subconverter/subconverter >/dev/null 2>&1 & disown
    # fi
    systemctl is-enabled subconverter >/dev/null 2>&1 && sudo systemctl restart subconverter
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
        find "/etc/clash" -type f -name "*_Profile*" -print0 | xargs -0 -I{} sudo cp -f {} "/srv/subconverter/profiles"
        find "/srv/subconverter/config" -type l -name "*_Rules*" -print0 | xargs -0 -I{} sudo rm -f {}
        find "/etc/clash" -type f -name "*_Rules*" -print0 | xargs -0 -I{} sudo cp -f {} "/srv/subconverter/config"
    fi

    if Git_Clone_Update_Branch "ACL4SSR/ACL4SSR" "$HOME/subconverter/ACL4SSR" "github.com" "master"; then
        sudo mkdir -p "/srv/subconverter/ACL4SSR"
        sudo mkdir -p "/srv/subconverter/templates"
        sudo cp -rf "$HOME/subconverter/ACL4SSR"/* "/srv/subconverter/ACL4SSR"
        sudo cp -f /srv/subconverter/ACL4SSR/Clash/*.list /srv/subconverter/rules/ACL4SSR/Clash
        sudo cp -f /srv/subconverter/ACL4SSR/Clash/Ruleset/*.list /srv/subconverter/rules/ACL4SSR/Clash/Ruleset
        sudo cp -f /srv/subconverter/ACL4SSR/Clash/*.yml /srv/subconverter/config
        sudo cp -f /srv/subconverter/ACL4SSR/Clash/config/*.ini /srv/subconverter/config
    fi
fi


TARGET_CONFIG_DIR=$(dirname "${TARGET_CONFIG_FILE}")
TARGET_CONFIG_NAME=$(basename "${TARGET_CONFIG_FILE}")

RULES_FILE_NAME=""
PROXIES_PRIVATE=""
PROXIES_PUBLIC=""

PROXY_LIST_ALL=()
PROXY_SERVER_ALL=()

PROXY_EMPTY_GROUP=()

FILELIST=()
FILEOPTION=()

GLOBAL_FILTER=$(grep '^# global' "${SUB_URL_LIST}" | cut -d' ' -f3-)
GLOBAL_TYPE_FILTER=$(grep '^# type' "${SUB_URL_LIST}" | cut -d' ' -f3-)
GLOBAL_WORD_REPLACE=$(grep '^# word' "${SUB_URL_LIST}" | cut -d' ' -f3-)
GLOBAL_PERL_FILTER=$(grep '^# perl' "${SUB_URL_LIST}" | cut -d' ' -f3-)
CONVERTER_SERVICE=$(grep '^# converter' "${SUB_URL_LIST}" | cut -d' ' -f3-)
USER_AGENT=$(grep '^# useragent' "${SUB_URL_LIST}" | cut -d' ' -f3-)
while read -r READLINE || [[ "${READLINE}" ]]; do
    [[ -z "${READLINE}" ]] && continue

    TARGET_FILE=$(cut -d' ' -f1 <<<"${READLINE}")
    [[ "${TARGET_FILE}" == "#"* ]] && continue

    TARGET_URL=$(cut -d' ' -f2 <<<"${READLINE}")
    # url with date format
    URL_DATE_FORMAT=$(grep -Eo '\[date+.*\]' <<<"${TARGET_URL}" 2>/dev/null | sed -e 's/date+//g' -e 's/\[//g' -e 's/\]//g')
    if [[ -n "${URL_DATE_FORMAT}" ]]; then
        CURRENT_DATE=$(date +"%Y-%m-%d")
        for i in $(seq 0 10); do
            URL_DATE=$(date -d "${CURRENT_DATE} - ${i} day" +"${URL_DATE_FORMAT}" 2>/dev/null)
            [[ -z "${URL_DATE}" ]] && break
            TARGET_DATE_URL=$(sed -r "s|\[date+.*\]|${URL_DATE}|" <<<"${TARGET_URL}")
            if check_url_exists "${TARGET_DATE_URL}"; then
                TARGET_URL="${TARGET_DATE_URL}"
                break
            fi
        done
    fi

    TARGET_OPTION=$(cut -d' ' -f3 <<<"${READLINE}")
    TARGET_FILTER=$(cut -d' ' -f4 <<<"${READLINE}")

    TARGET_TYPE_FILTER=$(cut -d' ' -f5 <<<"${READLINE}")
    [[ -z "${TARGET_TYPE_FILTER}" ]] && TARGET_TYPE_FILTER="${GLOBAL_TYPE_FILTER}"

    TARGET_WORD_REPLACE=$(cut -d' ' -f6 <<<"${READLINE}")
    [[ -z "${TARGET_WORD_REPLACE}" ]] && TARGET_WORD_REPLACE="${GLOBAL_WORD_REPLACE}"

    # private,subscription
    [[ "${TARGET_OPTION}" =~ "private" && "${OUTPUT_OPTIONS}" != *"private"* ]] && continue
    [[ "${TARGET_OPTION}" =~ "subscription" && "${OUTPUT_OPTIONS}" != *"subscription"* ]] && continue

    # Output only the specified target files
    if [[ "${OUTPUT_OPTIONS}" == *"@only"* ]]; then
        OUTPUT_ONLY_FILES="${OUTPUT_OPTIONS//@only/}"

        OUTPUT_ONLY=()
        if ! IFS="," read -r "${READ_ARRAY_OPTS[@]}" OUTPUT_ONLY <<<"${OUTPUT_ONLY_FILES}" 2>/dev/null; then
            while read -r opts; do
                OUTPUT_ONLY+=("${opts}")
            done < <(tr ',' '\n'<<<"${OUTPUT_ONLY_FILES}")
        fi

        # `rules` must include
        OUTPUT_ONLY+=("rules")

        SKIP_PROCESS=true
        for opts_only in "${OUTPUT_ONLY[@]}"; do
            [[ "${TARGET_FILE}" == "${opts_only}" ]] && SKIP_PROCESS=false
        done

        [[ "${SKIP_PROCESS}" == "true" ]] && continue
    fi

    DOWNLOAD_FILE="${SUBSCRIBE_DOWNLOAD_DIR}/${TARGET_FILE}.yml"

    SCRAP_OPTION="${TARGET_OPTION}"
    SUBSCRIBE_DOWNLOAD_FILE_EXISTS=false
    if [[ -s "${DOWNLOAD_FILE}" ]]; then
        # subscribe file already downloaded
        SCRAP_OPTION=""
        SUBSCRIBE_DOWNLOAD_FILE_EXISTS=true
    else
        colorEcho "${BLUE}  Getting ${FUCHSIA}${TARGET_FILE}${BLUE} from ${YELLOW}${TARGET_URL}${BLUE}..."
        if grep -q "^http" <<<"${TARGET_URL}"; then
            DOWNLOAD_FROM_URL="yes"
            [[ "${TARGET_OPTION}" =~ "scrap" && "${TARGET_OPTION}" != *"→"* ]] && DOWNLOAD_FROM_URL="no"

            if [[ "${DOWNLOAD_FROM_URL}" == "yes" ]]; then
                if [[ "${TARGET_OPTION}" =~ "converter" && ! "${TARGET_OPTION}" =~ "scrap" ]]; then
                    CONVERTER_URL="${TARGET_URL}"
                    colorEcho "${BLUE}    Converting ${FUCHSIA}${TARGET_FILE}${BLUE} from ${YELLOW}${CONVERTER_URL}${BLUE}..."
                    CONVERTER_URL=$(printf %s "${CONVERTER_URL}" | jq -sRr @uri) # encode URL
                    CONVERTER_URL=$(sed "s|\[URL\]|${CONVERTER_URL}|" <<<"${CONVERTER_SERVICE}")
                    curl -fsL --connect-timeout 10 --max-time 30 -o "${DOWNLOAD_FILE}" "${CONVERTER_URL}"
                else
                    if [[ "${TARGET_OPTION}" =~ "useragent" ]]; then
                        curl -fsL -A "${USER_AGENT}" --connect-timeout 10 --max-time 30 -o "${DOWNLOAD_FILE}" "${TARGET_URL}"
                    else
                        curl -fsL --connect-timeout 10 --max-time 30 -o "${DOWNLOAD_FILE}" "${TARGET_URL}"
                    fi
                fi

                curl_download_status=$?
                if [[ ${curl_download_status} != 0 ]]; then
                    colorEcho "${RED}    Error when downloading from ${FUCHSIA}${TARGET_URL}${RED}!"
                    [[ "${TARGET_OPTION}" == "rules" ]] && exit 1 || continue
                fi
            fi
        else
            if [[ -s "/etc/clash/${TARGET_URL}" ]]; then
                cp "/etc/clash/${TARGET_URL}" "${DOWNLOAD_FILE}"
            elif [[ -s "${TARGET_URL}" ]]; then
                cp "${TARGET_URL}" "${DOWNLOAD_FILE}"
            else
                continue
            fi
        fi
    fi

    if [[ "${SCRAP_OPTION}" =~ "scrap" ]]; then
        SCRAP_PATTERN=()
        SCRAP_SUCCESS="no"
        SCRAP_INDEX=0
        CONVERTER_URL=""

        IFS=" " read -r "${READ_ARRAY_OPTS[@]}" SCRAP_PATTERN <<< "${TARGET_OPTION//→/ }"
        for TargetPattern in "${SCRAP_PATTERN[@]}"; do
            SCRAP_INDEX=$((SCRAP_INDEX + 1))
            [[ ${SCRAP_INDEX} -eq 1 ]] && continue

            sed -i -e 's/\s*\&amp;/\&/g' -e 's/\&amp;/\&/g' -e 's/\&\&/\&/g' "${DOWNLOAD_FILE}"

            MATCH_URL=$(grep -o -P "${TargetPattern}" "${DOWNLOAD_FILE}" | uniq)
            if ! grep -E -q '(http:|https:|ftp:)' <<<"${MATCH_URL}"; then
                URL_PROTOCOL=$(awk -F/ '{print $1}' <<<"${TARGET_URL}")
                URL_DOMAIN=$(awk -F/ '{print $3}' <<<"${TARGET_URL}")
                if grep -q "^/" <<<"${MATCH_URL}"; then
                    MATCH_URL=$(sed -e "s|^/|${URL_PROTOCOL}//${URL_DOMAIN}/|g" <<<"${MATCH_URL}")
                else
                    MATCH_URL=$(sed -e "s|^|${TARGET_URL%\/}/|g" <<<"${MATCH_URL}")
                fi
            fi

            # sort & get first match URL
            if [[ ${SCRAP_INDEX} -eq ${#SCRAP_PATTERN[@]} ]]; then
                [[ "${TARGET_OPTION}" =~ "SortFirst" ]] && MATCH_URL=$(sort <<<"${MATCH_URL}" | head -n1)
                [[ "${TARGET_OPTION}" =~ "SortReverseFirst" ]] && MATCH_URL=$(sort -r <<<"${MATCH_URL}" | head -n1)
            fi

            SCRAP_ACTION="scrap"
            while read -r TARGET_URL; do
                [[ -z "${TARGET_URL}" ]] && continue

                TARGET_URL=$(grep -o -P "(((ht|f)tps?):\/\/)+[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?" <<<"${TARGET_URL}")
                [[ -z "${TARGET_URL}" ]] && continue

                SCRAP_DOWNLOAD_FILE="${DOWNLOAD_FILE}"
                if [[ ${SCRAP_INDEX} -eq ${#SCRAP_PATTERN[@]} ]]; then
                    [[ "${TARGET_OPTION}" =~ "converter" && "${TARGET_OPTION}" =~ "protect" ]] && SCRAP_ACTION="stop"

                    # Maybe multiple subscirbe files
                    if [[ "${SCRAP_SUCCESS}" == "yes" && -f "${SCRAP_DOWNLOAD_FILE}" ]]; then
                        for i in $(seq 1 50); do
                            SCRAP_DOWNLOAD_FILE="${SUBSCRIBE_DOWNLOAD_DIR}/${TARGET_FILE}.${i}.yml"
                            [[ ! -f "${SCRAP_DOWNLOAD_FILE}" ]] && break
                        done
                    fi
                fi

                if [[ "${SCRAP_ACTION}" != "stop" ]]; then
                    colorEcho "${BLUE}    Scraping ${FUCHSIA}${TARGET_FILE}${BLUE} from ${YELLOW}${TARGET_URL}${BLUE} to ${ORANGE}${SCRAP_DOWNLOAD_FILE}${BLUE}..."
                    curl -fsL --connect-timeout 10 --max-time 30 -o "${SCRAP_DOWNLOAD_FILE}" "${TARGET_URL}"

                    curl_download_status=$?
                    [[ ${curl_download_status} -gt 0 ]] && continue
                fi

                if [[ ${SCRAP_INDEX} -eq ${#SCRAP_PATTERN[@]} ]]; then
                    if [[ "${TARGET_OPTION}" =~ "converter" ]]; then
                        colorEcho "${BLUE}    Converting ${FUCHSIA}${TARGET_FILE}${BLUE} from ${YELLOW}${TARGET_URL}${BLUE}..."
                        TARGET_URL=$(printf %s "${TARGET_URL}" | jq -sRr @uri) # encode URL
                        TARGET_URL=$(sed "s|\[URL\]|${TARGET_URL}|" <<<"${CONVERTER_SERVICE}")
                        curl -fsL --connect-timeout 10 --max-time 30 -o "${SCRAP_DOWNLOAD_FILE}" "${TARGET_URL}"

                        curl_download_status=$?
                        [[ ${curl_download_status} -gt 0 ]] && continue

                        SCRAP_SUCCESS="yes"
                    elif [[ "${TARGET_OPTION}" =~ "protect" ]]; then
                        PROTECT_URL="${TARGET_URL}" && break
                    else
                        SCRAP_SUCCESS="yes"
                    fi
                else
                    MATCH_NEXT=$(grep -o -P "${SCRAP_PATTERN[$SCRAP_INDEX]}" "${DOWNLOAD_FILE}")
                    [[ -n "${MATCH_NEXT}" ]] && break
                fi
            done <<<"${MATCH_URL}"
        done

        if [[ -z "${CONVERTER_URL}" && "${SCRAP_SUCCESS}" == "no" ]]; then
            [[ "${TARGET_OPTION}" =~ "converter" ]] && CONVERTER_URL="${TARGET_URL}"
        fi

        if [[ -n "${CONVERTER_URL}" ]]; then
            colorEcho "${BLUE}    Converting ${FUCHSIA}${TARGET_FILE}${BLUE} from ${YELLOW}${CONVERTER_URL}${BLUE}..."
            CONVERTER_URL=$(printf %s "${CONVERTER_URL}" | jq -sRr @uri) # encode URL
            CONVERTER_URL=$(sed "s|\[URL\]|${CONVERTER_URL}|" <<<"${CONVERTER_SERVICE}")
            curl -fsL --connect-timeout 10 --max-time 30 -o "${DOWNLOAD_FILE}" "${CONVERTER_URL}"

            curl_download_status=$?
            [[ ${curl_download_status} -gt 0 ]] && continue
        fi

        if [[ -n "${PROTECT_URL}" ]]; then
            PROTECT_MATCH=$(grep "^# ${TARGET_FILE}-match" "${TMP_URL_LIST}" | cut -d' ' -f3-)

            PROTECT_CMD=$(grep "^# ${TARGET_FILE}-protect" "${TMP_URL_LIST}" | cut -d' ' -f3-)
            PROTECT_CMD=$(sed -e "s|ProtectURL|${PROTECT_URL}|" -e "s|text.txt|${WORKDIR}/${TARGET_FILE}.txt|" -e "s|protect.txt|${DOWNLOAD_FILE}|" <<<"${PROTECT_CMD}")

            # [How can we run a command stored in a variable?](https://unix.stackexchange.com/questions/444946/how-can-we-run-a-command-stored-in-a-variable)
            runProtectCMD=()
            [[ -z "${READ_ARRAY_OPTS[*]}" ]] && Get_Read_Array_Options
            if ! IFS=" " read -r "${READ_ARRAY_OPTS[@]}" runProtectCMD <<<"${PROTECT_CMD}" 2>/dev/null; then
                while read -r cmdPart; do
                    runProtectCMD+=("${cmdPart}")
                done < <(tr ' ' '\n' <<<"${PROTECT_CMD}")
            fi

            colorEcho "${BLUE}    Running ${FUCHSIA}${runProtectCMD[*]}${BLUE}..."
            cd "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}" || exit
            if "${runProtectCMD[@]}"; then
                TARGET_URL=$(grep -o -P "${PROTECT_MATCH}" "${DOWNLOAD_FILE}" | head -n1)
                TARGET_URL=$(grep -o -P "(((ht|f)tps?):\/\/)+[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?" <<<"${TARGET_URL}")
                [[ -z "${TARGET_URL}" ]] && continue

                colorEcho "${BLUE}    Scraping ${FUCHSIA}${TARGET_FILE}${BLUE} from ${YELLOW}${TARGET_URL}${BLUE}..."
                curl -fsL --connect-timeout 10 --max-time 30 -o "${DOWNLOAD_FILE}" "${TARGET_URL}"

                curl_download_status=$?
                [[ ${curl_download_status} -gt 0 ]] && continue
            fi
            cd "${CURRENT_DIR}" || exit
        fi
    fi

    [[ ! -s "${DOWNLOAD_FILE}" ]] && continue

    if [[ "${TARGET_OPTION}" == "rules" ]]; then
        # Get rules
        RULES_FILE_NAME="${DOWNLOAD_FILE}"
        RULES_START_LINE=$(grep -Ean "^rules:" "${DOWNLOAD_FILE}" | cut -d: -f1)
        if [[ ${RULES_START_LINE} -gt 0 ]]; then
            sed -i "1,${RULES_START_LINE} d" "${RULES_FILE_NAME}"
            sed -i '/^$/d' "${RULES_FILE_NAME}"
        fi
    else
        colorEcho "${BLUE}  Processing ${FUCHSIA}${TARGET_FILE}${BLUE}..."
        FILELIST+=("${TARGET_FILE}")
        FILEOPTION+=("${TARGET_OPTION}")

        # Process new downloaded subscribe files
        if [[ "${SUBSCRIBE_DOWNLOAD_FILE_EXISTS}" == "false" ]]; then
            # filter, minify, compact subscribe yaml file
            processSubscribeFile "${DOWNLOAD_FILE}"

            # Merge multiple downloaded files
            MERGE_DOWNLOAD_FILES=$(find "${SUBSCRIBE_DOWNLOAD_DIR}" -type f -name "${TARGET_FILE}.*.yml")
            while read -r finded_file; do
                [[ ! -f "${finded_file}" ]] && continue

                processSubscribeFile "${finded_file}"

                colorEcho "${BLUE}      Merging ${FUCHSIA}${finded_file}${BLUE} to ${YELLOW}${DOWNLOAD_FILE}${BLUE}..."
                PROXY_START_LINE=$(grep -Ean "^proxies:" "${finded_file}" | cut -d: -f1)
                PROXY_END_LINE=$(sed -n '$=' "${finded_file}")
                if [[ ${PROXY_START_LINE} -gt 0 && ${PROXY_END_LINE} -gt 0 && ${PROXY_END_LINE} -gt ${PROXY_START_LINE} ]]; then
                    PROXY_START_LINE=$((PROXY_START_LINE + 1))
                    sed -n "${PROXY_START_LINE},${PROXY_END_LINE} p" "${finded_file}" >> "${DOWNLOAD_FILE}"
                fi

                rm -f "${finded_file}"
            done <<<"${MERGE_DOWNLOAD_FILES}"

            # Add `proxy-groups:`
            echo 'proxy-groups:' >> "${DOWNLOAD_FILE}"
        fi

        # Merge proxies
        TARGET_PROXIES=""
        if [[ "${TARGET_OPTION}" == *"full"* ]]; then
            PROXY_START_LINE=$(grep -Ean "^proxies:" "${DOWNLOAD_FILE}" | cut -d: -f1)
            GROUP_START_LINE=$(grep -Ean "^proxy-groups:" "${DOWNLOAD_FILE}" | cut -d: -f1)
            [[ -z "${GROUP_START_LINE}" || ${GROUP_START_LINE} -le ${PROXY_START_LINE} ]] && GROUP_START_LINE=$(grep -Ean "^rules:" "${DOWNLOAD_FILE}" | cut -d: -f1)
            [[ -z "${GROUP_START_LINE}" || ${GROUP_START_LINE} -le ${PROXY_START_LINE} ]] && GROUP_START_LINE=$(wc -l "${DOWNLOAD_FILE}" | awk '{print $1}') && GROUP_START_LINE=$((GROUP_START_LINE + 1))
            if [[ ${PROXY_START_LINE} -gt 0 && ${GROUP_START_LINE} -gt 0 && ${GROUP_START_LINE} -gt ${PROXY_START_LINE} ]]; then
                PROXY_START_LINE=$((PROXY_START_LINE + 1))
                PROXY_END_LINE=$((GROUP_START_LINE - 1))
                TARGET_PROXIES=$(sed -n "${PROXY_START_LINE},${PROXY_END_LINE} p" "${DOWNLOAD_FILE}")
            fi
        elif [[ "${TARGET_OPTION}" == *"proxypool"* ]]; then
            TARGET_PROXIES=$(sed -e '1d' -e '$d' "${DOWNLOAD_FILE}")
        else
            TARGET_PROXIES=$(sed '1d' "${DOWNLOAD_FILE}")
        fi

        # Remove specified type proxies
        if [[ -n "${TARGET_TYPE_FILTER}" ]]; then
            TARGET_PROXIES=$(grep -Eva "type:\s*(${TARGET_TYPE_FILTER})," <<<"${TARGET_PROXIES}")
        fi

        # Remove proxies not start with '- {'
        TARGET_PROXIES=$(grep -a '^\s*-\s*{' <<<"${TARGET_PROXIES}")

        # Remove proxies not end with '}'
        TARGET_PROXIES=$(grep -a '}$' <<<"${TARGET_PROXIES}")

        PROXY_NAME=()
        PROXY_NEW_NAME=()
        PROXY_DELETE=()
        while read -r line; do
            [[ -z "${line}" ]] && continue

            TargetName=$(echo "${line}" \
                | sed -rn "s/.*[,{ ]+name:([^,{}]+).*/\1/ip" \
                | sed -e "s/^\s//" -e "s/\s$//" \
                | sed -e "s/^\"//" -e "s/\"$//")

            TargetServer=$(echo "${line}" \
                | sed -rn "s/.*[,{ ]+server:([^,{}]+).*/\1/ip" \
                | sed -e "s/^\s//" -e "s/\s$//" \
                | sed -e "s/^\"//" -e "s/\"$//")

            [[ -z "${TargetName}" || -z "${TargetServer}" ]] && continue

            TargetUUID=$(echo "${line}" \
                | sed -rn "s/.*[,{ ]+uuid:([^,{}]+).*/\1/ip" \
                | sed -e "s/^\s//" -e "s/\s$//" \
                | sed -e "s/^\"//" -e "s/\"$//")

            TargetHost=$(echo "${line}" \
                | sed -rn "s/.*Host:([^{}]+).*/\1/ip" \
                | sed -e "s/^\s//" -e "s/\s$//" \
                | sed -e "s/^\"//" -e "s/\"$//")

            # Rename node name start only with numbers & spaces & special characters
            if LC_ALL=C grep -Eaq "^[[:digit:][:space:][:punct:]]+" <<<"${TargetName}"; then
                TargetNewName="ZZ💤${TargetName}"
            else
                TargetNewName="${TargetName}"
            fi

            PROXY_IS_DELETE="N"
            if [[ " ${PROXY_LIST_ALL[*]} " == *" ${TargetNewName} "* ]]; then
                PROXY_IS_DELETE="Y"
            else
                if [[ "${TARGET_OPTION}" == *"proxypool"* && " ${PROXY_SERVER_ALL[*]} " == *" ${TargetServer} "* ]]; then
                    PROXY_IS_DELETE="Y"
                elif [[ -n "${TARGET_FILTER}" ]]; then
                    if grep -Eaq "${TARGET_FILTER}" <<<"${TargetName}"; then
                        PROXY_IS_DELETE="Y"
                    fi
                fi

                if [[ -n "${TargetUUID}" ]]; then
                    [[ ${TargetUUID//-/} =~ ^[[:xdigit:]]{32}$ ]] || PROXY_IS_DELETE="Y"
                fi

                if [[ -n "${TargetHost}" ]]; then
                    if grep -Eaq ',' <<<"${TargetHost}"; then
                        PROXY_IS_DELETE="Y"
                    fi
                fi
            fi

            if [[ "${PROXY_IS_DELETE}" == "Y" ]]; then
                PROXY_DELETE+=("${TargetName}")
            else
                PROXY_NAME+=("${TargetName}")
                PROXY_NEW_NAME+=("${TargetNewName}")
                PROXY_LIST_ALL+=("${TargetNewName}")
                PROXY_SERVER_ALL+=("${TargetServer}")
            fi
        done <<<"${TARGET_PROXIES}"

        for TargetName in "${PROXY_DELETE[@]}"; do
            TargetName_Escape_GREP=$(echo "${TargetName}" \
                | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"\(\)]/\\&/g' \
                | sed 's/]/\\&/g')
            TARGET_PROXIES=$(grep -Eav "name:\s*${TargetName_Escape_GREP}," <<<"${TARGET_PROXIES}")
        done

        # Delete lines with empty name
        TARGET_PROXIES=$(sed '/name:\s*,/d' <<<"${TARGET_PROXIES}" | sed 's/,,/,/g')

        # Add proxies node to `.list` file
        TARGET_LIST_FILE="${WORKDIR}/${TARGET_FILE}.list"
        [[ -f "${TARGET_LIST_FILE}" ]] && rm -f "${TARGET_LIST_FILE}"

        PROXY_INDEX=-1
        for TargetName in "${PROXY_NAME[@]}"; do
            PROXY_INDEX=$((PROXY_INDEX + 1))

            TargetNewName="${PROXY_NEW_NAME[$PROXY_INDEX]}"

            TargetNewName_Escape=$(echo "${TargetNewName}" \
                | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"]/\\&/g' \
                | sed 's/]/\\&/g')

            if [[ "${TargetName}" != "${TargetNewName}" ]]; then
                TargetName_Escape=$(echo "${TargetName}" \
                    | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"]/\\&/g' \
                    | sed 's/]/\\&/g')
                TARGET_PROXIES=$(sed "s/name:\s*${TargetName_Escape},/name: ${TargetNewName_Escape},/" <<<"${TARGET_PROXIES}")
            fi

            TargetNewName_Escape_GREP=$(echo "${TargetNewName}" \
                | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"\(\)]/\\&/g' \
                | sed 's/]/\\&/g')

            if grep -Eaq "name:\s*${TargetNewName_Escape_GREP}," <<<"${TARGET_PROXIES}"; then
                echo "      - ${TargetNewName}" | tee -a "${TARGET_LIST_FILE}" >/dev/null
            fi
        done

        case "${TARGET_OPTION}" in
            "*private*")
                [[ -n "${PROXIES_PRIVATE}" ]] && \
                    PROXIES_PRIVATE=$(echo -e "${PROXIES_PRIVATE}\n${TARGET_PROXIES}") || \
                    PROXIES_PRIVATE="${TARGET_PROXIES}"
                ;;
            *)
                [[ -n "${PROXIES_PUBLIC}" ]] && \
                    PROXIES_PUBLIC=$(echo -e "${PROXIES_PUBLIC}\n${TARGET_PROXIES}") || \
                    PROXIES_PUBLIC="${TARGET_PROXIES}"
                ;;
        esac
    fi
done < "${SUB_URL_LIST}"


colorEcho "${BLUE}  Processing ${FUCHSIA}proxies${BLUE}..."
# Sort public proxies
PROXIES_PUBLIC=$(echo "${PROXIES_PUBLIC}" | sort | uniq)

# Proxies
if [[ -n "${PROXIES_PRIVATE}" ]]; then
    PROXIES_ALL=$(echo -e "${PROXIES_PRIVATE}\n${PROXIES_PUBLIC}" | sed 's/^-/  -/g')
else
    PROXIES_ALL=$(echo -e "${PROXIES_PUBLIC}" | sed 's/^-/  -/g')
fi

# Delete lines with empty name
PROXIES_ALL=$(sed '/name:\s*,/d' <<<"${PROXIES_ALL}" | sed 's/,,/,/g')

## Add placeholder for proxy-groups
# PROXIES_ALL=$(echo -e "${PROXIES_ALL}\n  - {name: FORBIDDEN-PLACEHOLDER, server: forbidden-placeholder.com, port: 0000, type: trojan, password: Trojan}")

# sort proxy list
# sort_array PROXY_LIST_ALL
PROXY_LIST_SORT=""
PROXIES_USE_ALL=""
for TargetName in "${PROXY_LIST_ALL[@]}"; do
    [[ -z "${TargetName}" ]] && continue

    TargetName_Escape_GREP=$(echo "${TargetName}" \
        | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"\(\)]/\\&/g' \
        | sed 's/]/\\&/g')

    TargetProxies=$(grep -Ea "name:\s*${TargetName_Escape_GREP}," <<<"${PROXIES_ALL}")
    if [[ -n "${TargetProxies}" ]]; then
        [[ -n "${PROXY_LIST_SORT}" ]] && \
            PROXY_LIST_SORT=$(echo -e "${PROXY_LIST_SORT}\n${TargetName}") || \
            PROXY_LIST_SORT="${TargetName}"

        [[ -n "${PROXIES_USE_ALL}" ]] && \
            PROXIES_USE_ALL=$(echo -e "${PROXIES_USE_ALL}\n${TargetProxies}") || \
            PROXIES_USE_ALL="${TargetProxies}"
    fi
done

PROXY_LIST_SORT=$(sort <<<"${PROXY_LIST_SORT}")

PROXY_LIST_ALL=()
while read -r list; do
    [[ -z "${list}" ]] && continue
    PROXY_LIST_ALL+=("${list}")
done <<<"${PROXY_LIST_SORT}"

# get proxy type
PROXY_USE_ALL=""
PROXY_TYPE_ALL=()
for TargetName in "${PROXY_LIST_ALL[@]}"; do
    [[ -n "${PROXY_USE_ALL}" ]] && \
        PROXY_USE_ALL=$(echo -e "${PROXY_USE_ALL}\n      - ${TargetName}") || \
        PROXY_USE_ALL="      - ${TargetName}"

    TargetName_Escape_GREP=$(echo "${TargetName}" \
        | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"\(\)]/\\&/g' \
        | sed 's/]/\\&/g')

    TargetLine=$(grep -Ea "name: ${TargetName_Escape_GREP}," <<<"${PROXIES_USE_ALL}")

    TargetType=$(echo "${TargetLine}" \
        | sed -rn "s/.*[,{ ]+type:([^,{}]+).*/\1/ip" \
        | sed -e "s/^\s//" -e "s/\s$//" \
        | sed -e "s/^\"//" -e "s/\"$//")

    [[ "${TargetType}" == "ss" || "${TargetType}" == "ssr" ]] && TargetType="shadowsocks"
    PROXY_TYPE_ALL+=("${TargetType}")
done

# custom rules
RULE_CUSTOM_FILE="/etc/clash/clash_rule_custom.yml"
# if [[ -s "${RULE_CUSTOM_FILE}" ]]; then
#     colorEcho "${BLUE}  Getting ${FUCHSIA}custom rules${BLUE}..."
#     RULE_CUSTOM=$(< "${RULE_CUSTOM_FILE}")
# fi

## all rules
# [[ -n "${RULE_CUSTOM}" ]] && RULES=$(echo -e "${RULE_CUSTOM}\n${RULES}")

## remove 2nd+ occurernce rules
# colorEcho "${BLUE}  Processing ${FUCHSIA}duplicate rules${BLUE}..."
# DUPLICATE_RULES=$(echo "${RULES}" | grep -Eao ",[a-zA-Z0-9./?=_%:-]*," \
#                     | sort -n | uniq -c | awk '{if($1>1) print $2}' | sort -rn)
# while read -r line; do
#     [[ -z "${line}" ]] && continue
#     DUPLICATE_ENTRY=$(echo "${line}" \
#         | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"]/\\&/g' \
#         | sed 's/]/\\&/g')

#     # https://stackoverflow.com/questions/30688682/how-to-remove-from-second-occurrence-until-the-end-of-the-file
#     RULES=$(echo "${RULES}" | sed "0,/${DUPLICATE_ENTRY}/b; /${DUPLICATE_ENTRY}/d")

#     ## https://stackoverflow.com/questions/16202900/using-sed-between-specific-lines-only
#     # ENTRY_FIRST_LINE=$(echo "${RULES}" | grep -Ean "${DUPLICATE_ENTRY}" | cut -d: -f1 | head -n1)
#     # [[ -z "${ENTRY_FIRST_LINE}" ]] && continue
#     # ENTRY_START_LINE=$((ENTRY_FIRST_LINE + 1))
#     # RULES=$(echo "${RULES}" | sed "${ENTRY_START_LINE},$ {/${DUPLICATE_ENTRY}/d;}")
# done <<<"${DUPLICATE_RULES}"


# Add contents to target config file
colorEcho "${BLUE}  Setting all config to ${FUCHSIA}${TARGET_CONFIG_FILE}${BLUE}..."
[[ -f "${TARGET_CONFIG_FILE}" ]] && rm -f "${TARGET_CONFIG_FILE}"

FILL_LINES=$(grep -Ean "^#-" "${CLASH_CONFIG}")
LINE_START=1
PROXY_LIST_FILTERED=()
while read -r READLINE || [[ "${READLINE}" ]]; do
    TARGET_LINE=$(cut -d':' -f1 <<<"${READLINE}")
    TARGET_TAG=$(cut -d'-' -f2 <<<"${READLINE}")
    TARGET_GROUP=$(cut -d'-' -f3 <<<"${READLINE}")
    TARGET_FILTER=$(cut -d'-' -f4 <<<"${READLINE}")

    LINE_END=$((TARGET_LINE - 1))

    [[ -n "${TARGET_FILTER}" ]] && MSG_INFO="${TARGET_FILTER}" || MSG_INFO="${TARGET_TAG}"
    colorEcho "${BLUE}    Generating ${FUCHSIA}${MSG_INFO}${BLUE}..."

    CONTENT_PREFIX=$(sed -n "${LINE_START},${LINE_END} p" "${CLASH_CONFIG}")
    CONTENT_TAG=""
    [[ -n "${TARGET_GROUP}" ]] && CONTENT_IS_GROUP="yes" || CONTENT_IS_GROUP="no"
    case "${TARGET_TAG}" in
        "proxies")
            CONTENT_TAG="${PROXIES_USE_ALL}"
            ;;
        "all")
            CONTENT_TAG="${PROXY_USE_ALL}"
            ;;
        "rules")
            # CONTENT_TAG="${RULES}"
            [[ -n "${CONTENT_PREFIX}" ]] && echo "${CONTENT_PREFIX}" | tee -a "${TARGET_CONFIG_FILE}" >/dev/null

            # if [[ -s "${RULE_CUSTOM_FILE}" ]]; then
            #     cat "${RULE_CUSTOM_FILE}" >> "${TARGET_CONFIG_FILE}"
            # fi

            # if [[ -s "${RULES_FILE_NAME}" ]]; then
            #     cat "${RULES_FILE_NAME}" >> "${TARGET_CONFIG_FILE}"
            # fi

            CONTENT_PREFIX=""
            ;;
        "type")
            # filter by protocol type
            PROXY_INDEX=-1
            for TargetName in "${PROXY_LIST_ALL[@]}"; do
                PROXY_INDEX=$((PROXY_INDEX + 1))

                if grep -Eaq "${TARGET_FILTER}" <<<"${PROXY_TYPE_ALL[$PROXY_INDEX]}"; then
                    [[ -n "${CONTENT_TAG}" ]] && \
                        CONTENT_TAG=$(echo -e "${CONTENT_TAG}\n      - ${TargetName}") || \
                        CONTENT_TAG="      - ${TargetName}"
                fi
            done
            ;;
        "OTHERS")
            for TargetName in "${PROXY_LIST_ALL[@]}"; do
                if [[ " ${PROXY_LIST_FILTERED[*]} " == *" ${TargetName} "* ]]; then
                    :
                else
                    [[ -n "${CONTENT_TAG}" ]] && \
                        CONTENT_TAG=$(echo -e "${CONTENT_TAG}\n      - ${TargetName}") || \
                        CONTENT_TAG="      - ${TargetName}"
                fi
            done
            ;;
        "otherbalance")
            CONTENT_TAG="#otherbalance"
            ;;
        *)
            MATCH_TAG="no"
            for TargetFile in "${FILELIST[@]}"; do
                if [[ "${TargetFile}" == "${TARGET_TAG}" && -s "${WORKDIR}/${TargetFile}.list" ]]; then
                    MATCH_TAG="yes"
                    # CONTENT_TAG=$(< "${WORKDIR}/${TargetFile}.list")
                    for TargetName in "${PROXY_LIST_ALL[@]}"; do
                        TargetName_Escape_GREP=$(echo "${TargetName}" \
                            | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"\(\)]/\\&/g' \
                            | sed 's/]/\\&/g')
                        if grep -Eaq "${TargetName_Escape_GREP}" "${WORKDIR}/${TargetFile}.list"; then
                            [[ -n "${CONTENT_TAG}" ]] && \
                                CONTENT_TAG=$(echo -e "${CONTENT_TAG}\n      - ${TargetName}") || \
                                CONTENT_TAG="      - ${TargetName}"
                            PROXY_LIST_FILTERED+=("${TargetName}")
                        fi
                    done
                fi
            done

            # Filter by country
            if [[ "${MATCH_TAG}" == "no" ]]; then
                for TargetName in "${PROXY_LIST_ALL[@]}"; do
                    if echo "${TargetName}" | grep -Eaq "${TARGET_TAG}"; then
                        [[ -n "${CONTENT_TAG}" ]] && \
                            CONTENT_TAG=$(echo -e "${CONTENT_TAG}\n      - ${TargetName}") || \
                            CONTENT_TAG="      - ${TargetName}"
                        PROXY_LIST_FILTERED+=("${TargetName}")
                    fi
                done
            fi
            ;;
    esac

    # delete empty group
    if [[ -z "${CONTENT_TAG}" && "${CONTENT_IS_GROUP}" == "yes" ]]; then
        PROXY_EMPTY_GROUP+=("${TARGET_GROUP}")
        CONTENT_PREFIX=$(sed "/name:\s*${TARGET_GROUP}$/,$ d" <<<"${CONTENT_PREFIX}" | sed "/^\s*\-\s*${TARGET_GROUP}$/d")
        sed -i "/^\s*\-\s*${TARGET_GROUP}$/d" "${TARGET_CONFIG_FILE}"
    fi

    [[ -n "${CONTENT_PREFIX}" ]] && echo "${CONTENT_PREFIX}" | tee -a "${TARGET_CONFIG_FILE}" >/dev/null
    [[ -n "${CONTENT_TAG}" ]] && echo "${CONTENT_TAG}" | tee -a "${TARGET_CONFIG_FILE}" >/dev/null

    LINE_START=$((TARGET_LINE + 1))
done <<<"${FILL_LINES}"

## auto-balance group for OTHER proxies
GROUP_OTHER_BALANCE_LINE=$(grep -E -n "^#otherbalance" "${TARGET_CONFIG_FILE}" | cut -d: -f1)
if [[ ${GROUP_OTHER_BALANCE_LINE} -gt 0 ]]; then
    colorEcho "${BLUE}    Processing ${FUCHSIA}auto-balance group for OTHER proxies${BLUE}..."
    # PROXY_OTHER=$(yq e ".proxy-groups[] | select(.name ==\"🏁 其他节点\") | .proxies[]" "${TARGET_CONFIG_FILE}")
    # PROXY_LIST_OTHER=()
    # while read -r list; do [[ -z "${list}" ]] && continue; PROXY_LIST_OTHER+=("${list}"); done <<<"${PROXY_OTHER}"
    # CURRENT_LINE=${GROUP_OTHER_BALANCE_LINE}

    for TargetName in "${PROXY_LIST_ALL[@]}"; do
        if [[ " ${PROXY_LIST_FILTERED[*]} " == *" ${TargetName} "* ]]; then
            :
        else
            sed -i "/^#otherbalance/i\      - ${TargetName}" "${TARGET_CONFIG_FILE}"
            # sed -i "${CURRENT_LINE}a\      - ${TargetName}" "${TARGET_CONFIG_FILE}"
            # CURRENT_LINE=$((CURRENT_LINE + 1))
        fi
    done

    sed -i "/^#otherbalance/d" "$TARGET_CONFIG_FILE"
fi

## Fix: invalid leading UTF-8 octet
## https://stackoverflow.com/questions/12999651/how-to-remove-non-utf-8-characters-from-text-file
## https://stackoverflow.com/questions/29465612/how-to-detect-invalid-utf8-unicode-binary-in-a-text-file
# echo -ne '\uFFFD' | hexdump -C
# python3 -c 'print("\uFFFD".encode("utf8"))'
INVALID_FILE="no"
if grep -q -axv '.*' "${TARGET_CONFIG_FILE}" 2>/dev/null; then
    INVALID_FILE="yes"
elif grep -q -P "\x{fffd}/u" "${TARGET_CONFIG_FILE}" 2>/dev/null; then
    INVALID_FILE="yes"
fi

if [[ "${INVALID_FILE}" == "yes" ]]; then
    colorEcho "${BLUE}    Fixing ${FUCHSIA}invalid leading UTF-8 octet${BLUE}..."
    iconv -f utf-8 -t utf-8 -c "${TARGET_CONFIG_FILE}" > "${TARGET_CONFIG_FILE}.tmp" && \
        rm "${TARGET_CONFIG_FILE}" && \
        mv "${TARGET_CONFIG_FILE}.tmp" "${TARGET_CONFIG_FILE}"
fi

## delete not exist proxies
## PROXY_LIST=$(yq e ".proxies[].name" "${TARGET_CONFIG_FILE}")
# PROXY_LIST=$(yq e ".proxy-groups[] | select(.name ==\"🌀 自动选择\") | .proxies[]" "${TARGET_CONFIG_FILE}")
colorEcho "${BLUE}    Processing ${FUCHSIA}not exist proxies${BLUE}..."
for TargetName in "${PROXY_LIST_ALL[@]}"; do
    [[ -z "${TargetName}" ]] && continue

    TargetName_Escape_GREP=$(echo "${TargetName}" \
        | sed 's/[\\\/\:\*\?\|\$\&\#\[\^\+\.\=\!\"\(\)]/\\&/g' \
        | sed 's/]/\\&/g')

    TargetProxies=$(grep -Ea "name:\s*${TargetName_Escape_GREP}," "${TARGET_CONFIG_FILE}")
    if [[ -z "${TargetProxies}" ]]; then
        sed -i "/^\s*\-\s*${TargetName_Escape_GREP}$/d" "${TARGET_CONFIG_FILE}"
    fi
done

# add Double quotes to `path`, `User-Agent`...
sed -ri 's/path:\s+([^,"\{\}]+)/path: "\1"/' "${TARGET_CONFIG_FILE}"
sed -ri 's/User-Agent:\s+([^:"\{\}]+)(,\s+[^[:space:]]+)([:"\{\}]+)/User-Agent: "\1"\2\3/' "${TARGET_CONFIG_FILE}"
sed -ri 's/User-Agent:\s+([^"\{\}]+)(["\{\}]+)/User-Agent: "\1"\2/' "${TARGET_CONFIG_FILE}"
sed -ri 's/Host:\s+([^,"\{\}]+)/Host: "\1"/' "${TARGET_CONFIG_FILE}"
sed -ri 's/host:\s+([^,"\{\}]+)/host: "\1"/' "${TARGET_CONFIG_FILE}"
sed -ri 's/alpn:\s+([^,"\{\}]+)/alpn: "\1"/' "${TARGET_CONFIG_FILE}"
sed -ri 's/grpc-service-name:\s+([^,"\{\}]+)/grpc-service-name: "\1"/' "${TARGET_CONFIG_FILE}"

# 'alpn', 'http-opts.path', 'http-opts.headers[Host]' is a slice
sed -i -e 's/"【/["/g' -e 's/】"/"]/g' "${TARGET_CONFIG_FILE}"

# delete empty group
colorEcho "${BLUE}    Processing ${FUCHSIA}empty proxy-groups${BLUE}..."
GROUP_CNT=$(yq e '.proxy-groups | length' "${TARGET_CONFIG_FILE}")
GROUP_DELETE_INDEX=()
for ((i=0; i < GROUP_CNT; ++i)); do
    GROUP_NAME=$(yq e ".proxy-groups[$i].name" "${TARGET_CONFIG_FILE}")
    GROUP_PROXIES=$(yq e ".proxy-groups[$i].proxies // \"\"" "${TARGET_CONFIG_FILE}")
    if [[ -z "${GROUP_PROXIES}" ]]; then
        PROXY_EMPTY_GROUP+=("${GROUP_NAME}")
        GROUP_DELETE_INDEX+=("$i")
    fi
done

for TargetGroup in "${PROXY_EMPTY_GROUP[@]}"; do
    [[ -z "${TargetGroup}" ]] && continue
    sed -i "/^\s*\-\s*${TargetGroup}$/d" "${TARGET_CONFIG_FILE}"

    GROUP_START_LINE=$(grep -E -n "name: ${TargetGroup}" "${TARGET_CONFIG_FILE}" | cut -d: -f1)
    if [[ ${GROUP_START_LINE} -gt 0 ]]; then
        GROUP_END_LINE=$((GROUP_START_LINE + 6))
        sed -i "${GROUP_START_LINE},${GROUP_END_LINE}d" "${TARGET_CONFIG_FILE}"
    fi
done

# for TargetIndex in "${GROUP_DELETE_INDEX[@]}"; do
#     yq e -i "del(.proxy-groups[${TargetIndex}])" "${TARGET_CONFIG_FILE}"
# done

# rules
colorEcho "${BLUE}    Generating ${FUCHSIA}rules${BLUE}..."
if [[ -s "${RULE_CUSTOM_FILE}" ]]; then
    cat "${RULE_CUSTOM_FILE}" >> "${TARGET_CONFIG_FILE}"
fi

if [[ -s "${RULES_FILE_NAME}" ]]; then
    cat "${RULES_FILE_NAME}" >> "${TARGET_CONFIG_FILE}"
fi

# Copy to dir
if [[ -n "${COPY_TO_DIR}" ]]; then
    COPY_TO_FILE="${COPY_TO_DIR}/${TARGET_CONFIG_NAME}"
    cp -f "${TARGET_CONFIG_FILE}" "${COPY_TO_FILE}"

    if [[ -n "${PROXIES_PRIVATE}" ]]; then
        if [[ ! -s "${COPY_TO_FILE}.md5" ]]; then
            colorEcho "${BLUE}  Generating md5 for ${FUCHSIA}${COPY_TO_FILE}${BLUE}..."
            (openssl md5 -hex "${COPY_TO_FILE}" | cut -d" " -f2) > "${COPY_TO_FILE}.md5"
        fi
    fi

    # FILE_INDEX=-1
    # for TargetFile in "${FILELIST[@]}"; do
    #     FILE_INDEX=$((FILE_INDEX + 1))

    #     COPY_TO_FILE="${COPY_TO_DIR}/${TargetFile}.yml"
    #     cp -f "${WORKDIR}/${TargetFile}.yml" "${COPY_TO_FILE}"

    #     if [[ "${FILEOPTION[$FILE_INDEX]}" == *"private"* ]]; then
    #         if [[ ! -s "${COPY_TO_FILE}.md5" ]]; then
    #             colorEcho "${BLUE}  Gen md5 for ${FUCHSIA}${COPY_TO_FILE}${BLUE}..."
    #             (openssl md5 -hex "${COPY_TO_FILE}" | cut -d" " -f2) > "${COPY_TO_FILE}.md5"
    #         fi
    #     fi
    # done
fi


colorEcho "${BLUE}  Done!"
