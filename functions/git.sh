#!/usr/bin/env bash

function Get_Git_Clone_Options() {
    local opts

    [[ -z "${READ_ARRAY_OPTS[*]}" ]] && Get_Read_Array_Options

    [[ -z "${GIT_CLONE_DEFAULT_OPTION}" ]] && \
        GIT_CLONE_DEFAULT_OPTION="-c core.autocrlf=false -c core.filemode=false"

    GIT_CLONE_OPTS=()
    if ! IFS=" " read -r "${READ_ARRAY_OPTS[@]}" GIT_CLONE_OPTS <<<"${GIT_CLONE_DEFAULT_OPTION}" 2>/dev/null; then
        while read -r opts; do
            GIT_CLONE_OPTS+=("${opts}")
        done < <(echo "${GIT_CLONE_DEFAULT_OPTION}" | tr ' ' '\n')
    fi
}

function Git_Clone_Update() {
    local REPONAME=${1:-""}
    local REPODIR=${2:-""}
    local REPOURL=${3:-"github.com"}
    local GIT_COMMAND="git"
    local REPOREMOTE=""
    local CurrentDir

    if [[ -z "${REPONAME}" ]]; then
        colorEcho "${RED}Error! Repository name can't empty!"
        return 1
    fi

    if [[ "${REPONAME}" =~ ^(https?://|ssh://|git@) ]]; then
        REPOREMOTE="${REPONAME}"
        REPONAME=$(echo "${REPOREMOTE}" | sed 's|^http://||;s|^https://||;s|.git$||' | sed 's|.*[/:]\([^ ]*/[^ ]*\).*|\1|')
        REPOURL=$(echo "${REPOREMOTE}" | sed 's|.git$||' | sed "s|${REPONAME}||" | sed 's|[/:]$||')
    fi

    [[ -z "${REPODIR}" ]] && REPODIR=$(echo "${REPONAME}" | awk -F"/" '{print $NF}')

    REPOURL="${REPOURL%/}"
    if [[ "${REPOURL}" == "github.com" ]]; then
        [[ -n "${GITHUB_HUB_URL}" ]] && REPOURL=$(echo "${GITHUB_HUB_URL}" | sed 's|^http://||;s|^https://||')
        REPOREMOTE="https://${REPOURL}/${REPONAME}.git"
    else
        [[ "${REPOURL}" =~ ^(git@) ]] \
            && REPOREMOTE="${REPOURL}:${REPONAME}.git" \
            || REPOREMOTE="${REPOURL}/${REPONAME}.git"
    fi

    # check_url_exists "${REPOREMOTE}" \
    #     || colorEcho "${RED}  ${FUCHSIA}${REPOREMOTE}${RED} does not exist!"

    if [[ -d "${REPODIR}/.git" ]]; then
        CurrentDir=$(pwd)
        cd "${REPODIR}" || return

        REPOREMOTE=$(git config --get remote.origin.url | head -n1)

        colorEcho "${BLUE}  Updating ${FUCHSIA}${REPODIR}${BLUE} from ${ORANGE}${REPOREMOTE}${BLUE}..."

        ${GIT_COMMAND} pull

        cd "${CurrentDir}" || return
    else
        colorEcho "${BLUE}  Cloning ${ORANGE}${REPOREMOTE}${BLUE} to ${FUCHSIA}${REPODIR}${BLUE}..."
        [[ -z "${GIT_CLONE_OPTS[*]}" ]] && Get_Git_Clone_Options
        ${GIT_COMMAND} clone "${GIT_CLONE_OPTS[@]}" "${REPOREMOTE}" "${REPODIR}" || {
                colorEcho "${RED}  git clone of ${FUCHSIA}${REPONAME} ${RED}failed!"
                return 1
            }
    fi
}

function Git_Clone_Update_Branch() {
    local REPONAME=${1:-""}
    local REPODIR=${2:-""}
    local REPOURL=${3:-"github.com"}
    local BRANCH=${4:-""}
    local GIT_COMMAND="git"
    local REPOREMOTE=""
    local DEFAULTBRANCH=""
    local CurrentDir

    if [[ -z "${REPONAME}" ]]; then
        colorEcho "${RED}Error! Repository name can't empty!"
        return 1
    fi

    if [[ "${REPONAME}" =~ ^(https?://|ssh://|git@) ]]; then
        REPOREMOTE="${REPONAME}"
        REPONAME=$(echo "${REPOREMOTE}" | sed 's|^http://||;s|^https://||;s|.git$||' | sed 's|.*[/:]\([^ ]*/[^ ]*\).*|\1|')
        REPOURL=$(echo "${REPOREMOTE}" | sed 's|.git$||' | sed "s|${REPONAME}||" | sed 's|[/:]$||')
    fi

    [[ -z "${REPODIR}" ]] && REPODIR=$(echo "${REPONAME}" | awk -F"/" '{print $NF}')

    REPOURL="${REPOURL%/}"
    if [[ "${REPOURL}" == "github.com" ]]; then
        [[ -n "${GITHUB_HUB_URL}" ]] && REPOURL=$(echo "${GITHUB_HUB_URL}" | sed 's|^http://||;s|^https://||')
        REPOREMOTE="https://${REPOURL}/${REPONAME}.git"
    else
        [[ "${REPOURL}" =~ ^(git@) ]] \
            && REPOREMOTE="${REPOURL}:${REPONAME}.git" \
            || REPOREMOTE="${REPOURL}/${REPONAME}.git"
    fi

    # check_url_exists "${REPOREMOTE}" \
    #     || colorEcho "${RED}  ${FUCHSIA}${REPOREMOTE}${RED} does not exist!"

    if [[ -d "${REPODIR}/.git" ]]; then
        CurrentDir=$(pwd)
        cd "${REPODIR}" || return

        REPOREMOTE=$(git config --get remote.origin.url | head -n1)

        colorEcho "${BLUE}  Updating ${FUCHSIA}${REPODIR}${BLUE} from ${ORANGE}${REPOREMOTE}${BLUE}..."

        [[ -z "${BRANCH}" ]] && BRANCH=$(${GIT_COMMAND} symbolic-ref --short HEAD 2>/dev/null)
        [[ -z "${BRANCH}" ]] && BRANCH="master"

        if ! ${GIT_COMMAND} pull --rebase --stat origin "${BRANCH}"; then
            # pull error: fallback to default branch
            DEFAULTBRANCH=$(${GIT_COMMAND} ls-remote --symref "${REPOREMOTE}" HEAD \
                        | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
            if [[ -n "${DEFAULTBRANCH}" && "${DEFAULTBRANCH}" != "${BRANCH}" ]]; then
                git branch -m "${BRANCH}" "${DEFAULTBRANCH}"

                [[ -s "${REPODIR}/.git/config" ]] && \
                    sed -i "s|${BRANCH}|${DEFAULTBRANCH}|g" "${REPODIR}/.git/config"

                # git fetch origin
                # git branch --unset-upstream
                # git branch -u "origin/${DEFAULTBRANCH}" "${DEFAULTBRANCH}"
                # git symbolic-ref "refs/remotes/origin/HEAD" "refs/remotes/origin/${DEFAULTBRANCH}"

                ${GIT_COMMAND} pull --rebase --stat origin "${DEFAULTBRANCH}"
            fi
        fi

        ## master branch
        # git fetch --depth 1 && git reset --hard origin/master

        ## checkout other branch
        # git remote set-branches --add orgin "'${remote_branch_name}'"
        #     git fetch --depth 1 origin ${remote_branch_name} && \
        #     git checkout ${remote_branch_name}

        cd "${CurrentDir}" || return
    else
        colorEcho "${BLUE}  Cloning ${ORANGE}${REPOREMOTE}${BLUE} to ${FUCHSIA}${REPODIR}${BLUE}..."
        [[ -z "${BRANCH}" ]] && \
            BRANCH=$(${GIT_COMMAND} ls-remote --symref "${REPOREMOTE}" HEAD \
                    | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
        [[ -z "${BRANCH}" ]] && BRANCH="master"

        [[ -z "${GIT_CLONE_OPTS[*]}" ]] && Get_Git_Clone_Options
        ${GIT_COMMAND} clone "${GIT_CLONE_OPTS[@]}" \
            --depth=1 --branch "${BRANCH}" "${REPOREMOTE}" "${REPODIR}" || {
                colorEcho "${RED}  git clone of ${FUCHSIA}${REPONAME} ${RED}failed!"
                return 1
            }
    fi
}


# https://stackoverflow.com/questions/3497123/run-git-pull-over-all-subdirectories
function Git_Update_Repo_in_SubDir() {
    local SubDir=${1:-""}
    local FindDir TargetDir CurrentDir
    local REPOREMOTE REPONAME REPODIR REPOURL BRANCH
    local DIRLIST=()

    CurrentDir=$(pwd)

    [[ -z "${SubDir}" ]] && SubDir=${CurrentDir}
    [[ ! -d "${SubDir}" ]] && colorEcho "${FUCHSIA}${SubDir}${RED} does not exist or not a valid directory!" && return 0

    # find . -type d -name ".git" -execdir git pull --rebase --stat origin master \;

    while read -r FindDir; do
        FindDir="$(realpath "${FindDir}")"
        DIRLIST+=("${FindDir%/*}")
    done < <(find "${SubDir}" -type d -name ".git")

    for TargetDir in "${DIRLIST[@]}"; do
        REPODIR="${TargetDir}"
        cd "${REPODIR}" || return

        REPOREMOTE=$(git config --get remote.origin.url | head -n1)
        REPONAME=$(echo "${REPOREMOTE}" | sed 's|^http://||;s|^https://||;s|.git$||' | sed 's|.*[/:]\([^ ]*/[^ ]*\).*|\1|')
        REPOURL=$(echo "${REPOREMOTE}" | sed 's|.git$||' | sed "s|${REPONAME}||" | sed 's|[/:]$||')
        [[ "${REPOREMOTE}" == *"://github.com/"* ]] && REPOURL="github.com"

        BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
        [[ -z "${BRANCH}" ]] && BRANCH="master"

        [[ -z "${REPOREMOTE}" || -z "${REPONAME}" || -z "${REPOURL}" ]] && continue

        Git_Clone_Update_Branch "${REPONAME}" "${REPODIR}" "${REPOURL}" "${BRANCH}"
    done

    cd "${CurrentDir}" || return
}

function Git_Update_Repo_in_SubDir_Parallel() {
    local SubDir=${1:-""}
    local BRANCH=${2:-master}
    local FindDepth=${3:-""}

    [[ -z "${SubDir}" ]] && return 0
    [[ ! -d "${SubDir}" ]] && colorEcho "${FUCHSIA}${SubDir}${RED} does not exist or not a valid directory!" && return 0

    if [[ -z "${FindDepth}" ]]; then
        find "${SubDir}" -type d -name ".git" \
            | sed 's/\/.git//' \
            | xargs -P10 -I{} git --git-dir="{}/.git" --work-tree="{}" \
                pull --rebase --stat origin "${BRANCH}"
    else
        find "${SubDir}" -maxdepth "${FindDepth}" -type d -name ".git" \
            | sed 's/\/.git//' \
            | xargs -P10 -I{} git --git-dir="{}/.git" --work-tree="{}" \
                pull --rebase --stat origin "${BRANCH}"
    fi
}

function Git_Replace_Remote_Origin_URL() {
    # Usage: Git_Replace_Remote_Origin_URL $HOME "https://hub.fastgit.xyz" "https://github.com"
    local SubDir=${1:-""}
    local UrlOLD=$2
    local UrlNEW=$3
    local FindDir TargetDir CurrentDir
    local REPOREMOTE REPOREMOTE_NEW
    local DIRLIST=()

    [[ -z "${SubDir}" ]] && return 0
    [[ ! -d "${SubDir}" ]] && colorEcho "${FUCHSIA}${SubDir}${RED} does not exist or not a valid directory!" && return 0

    [[ -z "${UrlOLD}" || ! "${UrlOLD}" =~ ^(https?://|git@) ]] && colorEcho "${FUCHSIA}${UrlOLD}${RED} is not a valid url!" && return 0
    [[ -z "${UrlNEW}" || ! "${UrlNEW}" =~ ^(https?://|git@) ]] && colorEcho "${FUCHSIA}${UrlNEW}${RED} is not a valid url!" && return 0

    CurrentDir=$(pwd)

    while read -r FindDir; do
        FindDir="$(realpath "${FindDir}")"
        DIRLIST+=("${FindDir%/*}")
    done < <(find "${SubDir}" -type d -name ".git")

    [[ "${UrlOLD}" =~ ^(https?):// ]] && UrlOLD="${UrlOLD%/}/"
    [[ "${UrlNEW}" =~ ^(https?):// ]] && UrlNEW="${UrlNEW%/}/"

    for TargetDir in "${DIRLIST[@]}"; do
        # if grep -q "${UrlOLD}" "${TargetDir}/.git/config" 2>/dev/null; then
        #     sed -i "s|${UrlOLD}|${UrlNEW}|g" "${TargetDir}/.git/config"
        # fi
        cd "${TargetDir}" || return

        REPOREMOTE=$(git config --get remote.origin.url | head -n1)
        if [[ "${REPOREMOTE}" == *"${UrlOLD}"* ]]; then
            REPOREMOTE_NEW=$(echo "${REPOREMOTE}" | sed "s|${UrlOLD}|${UrlNEW}|")
            if [[ -n "${REPOREMOTE_NEW}" ]]; then
                colorEcho "${YELLOW}${TargetDir}${BLUE}: ${FUCHSIA}${REPOREMOTE}${BLUE} → ${GREEN}${REPOREMOTE_NEW}"
                git remote set-url origin "${REPOREMOTE_NEW}"
            fi
        fi
    done

    cd "${CurrentDir}" || return
}

function git_get_remote_default_branch() {
    local REPOREMOTE=${1:-""}

    if [[ -z "${REPOREMOTE}" && -d ".git" ]]; then
        REPO_DEFAULT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
    else
        [[ -z "${REPOREMOTE}" ]] && return 0
        REPO_DEFAULT_BRANCH=$(git ls-remote --symref "${REPOREMOTE}" HEAD \
                                | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
    fi
}
