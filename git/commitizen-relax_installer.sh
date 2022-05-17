#!/usr/bin/env bash

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

if [[ ! -x "$(command -v npm)" && ! -x "$(command -v npx)" ]]; then
    colorEcho "${RED}Please install ${FUCHSIA}nodejs & npm & npx${RED} first!"
    exit 0
fi

# cz-relax: One-click to configured commitizen
# https://github.com/qiqihaobenben/commitizen-relax
# https://github.com/Zhengqbbb/cz-git
IS_INSTALL="yes"

if [[ ! -d "${CURRENT_DIR}/.git" ]]; then
    IS_INSTALL="no"
    colorEcho "${FUCHSIA}${CURRENT_DIR}${RED} not a valid git repository!"
else
    colorEchoN "${ORANGE}Install and run ${FUCHSIA}Commitizen ${ORANGE}in ${FUCHSIA}${CURRENT_DIR}${ORANGE}?[y/${CYAN}N${ORANGE}]: "
    read -r CHOICE
    [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]] && IS_INSTALL="yes" || IS_INSTALL="no"
fi

[[ "${IS_INSTALL}" == "no" ]] && exit 0

npm install -g commitizen

npm install cz-relax --save-dev

[[ -d "${CURRENT_DIR}/.husky" ]] && npx cz-relax init --force || npx cz-relax init


# commitTypes
CommitTypesFile="${WORKDIR}/commitTypes.json"

JqArgs=".\"config\".\"cz-emoji\".\"types\"[] | \
{value: .name, \
name: (.name + \": \" + (.name | \" \" * (12 - length)) + .emoji + \" \" + .description), \
emoji: .emoji}"

jq -r "[${JqArgs}] | tojson" cz-emoji-types.json \
    | jq --tab \
    | sed -e 's/^\[/var commitTypes = \[/' -e 's/^\]/\]\;/' > "${CommitTypesFile}"

CommitTypesStartLine=$(grep -E -n "^var commitTypes" "${CURRENT_DIR}/.commitlintrc.js" | cut -d: -f1)
CommitTypesEndLine=$(grep -E -n "^\]\;" "${CURRENT_DIR}/.commitlintrc.js" | cut -d: -f1)

if [[ -n "${CommitTypesStartLine}" && -s "${CommitTypesFile}" ]]; then
    sed -i "${CommitTypesStartLine},${CommitTypesEndLine}d" "${CURRENT_DIR}/.commitlintrc.js"
    sed -i "$((CommitTypesStartLine - 1))r ${CommitTypesFile}" "${CURRENT_DIR}/.commitlintrc.js"
fi
