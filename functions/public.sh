#!/usr/bin/env bash

# Colors
NOCOLOR='\033[0m'
RED='\033[0;31m'        # Error message
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'      # Success message
LIGHTGREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'     # Warning message
BLUE='\033[0;34m'       # Info message
LIGHTBLUE='\033[1;34m'
PURPLE='\033[0;35m'
FUCHSIA='\033[0;35m'
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHTCYAN='\033[1;36m'
DARKGRAY='\033[1;30m'
LIGHTGRAY='\033[0;37m'
WHITE='\033[1;37m'

# color echo with datetime
# export COLOR_ECHO_DATETIME_FORMAT="%F %T.%6N %:z" # [2000-01-01 12:00:00.123456 +00:00]
# export COLOR_ECHO_DATETIME_FORMAT="%FT%T%:z" # [2000-01-01T12:00:00+00:00]
function colorEcho() {
    local DATETIME
    [[ -n "${COLOR_ECHO_DATETIME_FORMAT}" ]] && DATETIME="[$(date +"${COLOR_ECHO_DATETIME_FORMAT}")] "

    if [[ $# -gt 1 ]]; then
        local COLOR=$1
        if [[ -n "${COLOR_ECHO_DATETIME_FORMAT}" ]]; then
            echo -e "${DATETIME}${COLOR}${@:2}${NOCOLOR}"
        else
            echo -e "${COLOR}${@:2}${NOCOLOR}"
        fi
    else
        if [[ -n "${COLOR_ECHO_DATETIME_FORMAT}" ]]; then
            echo -e "${DATETIME}${@:1}${NOCOLOR}"
        else
            echo -e "${@:1}${NOCOLOR}"
        fi
    fi
}

function colorEchoN() {
    local DATETIME
    [[ -n "${COLOR_ECHO_DATETIME_FORMAT}" ]] && DATETIME="[$(date +"${COLOR_ECHO_DATETIME_FORMAT}")] "

    if [[ $# -gt 1 ]]; then
        local COLOR=$1
        if [[ -n "${COLOR_ECHO_DATETIME_FORMAT}" ]]; then
            echo -e -n "${DATETIME}${COLOR}${@:2}${NOCOLOR}"
        else
            echo -e -n "${COLOR}${@:2}${NOCOLOR}"
        fi
    else
        if [[ -n "${COLOR_ECHO_DATETIME_FORMAT}" ]]; then
            echo -e -n "${DATETIME}${@:1}${NOCOLOR}"
        else
            echo -e -n "${@:1}${NOCOLOR}"
        fi
    fi
}

function colorEchoAllColor() {
    colorEchoN "${RED}red ${GREEN}green ${YELLOW}yellow ${BLUE}blue ${ORANGE}orange ${PURPLE}purple ${FUCHSIA}fuchsia ${CYAN}cyan "
    colorEchoN "${LIGHTRED}lightred ${LIGHTGREEN}lightgreen ${LIGHTBLUE}lightblue ${LIGHTPURPLE}lightpurple ${LIGHTCYAN}lightcyan "
    colorEcho "${LIGHTGRAY}lightgray ${DARKGRAY}darkgray ${WHITE}white"
}

# running SHELL
function get_running_shell() {
    unset INFO_SHELL_RUNNING

    INFO_SHELL_RUNNING=$(ps -p $$ -o cmd='',comm='',fname='' 2>/dev/null | sed 's/^-//' | grep -oE '\w+' | head -n1)
}

# read array options
function Get_Read_Array_Options() {
    local runShell

    READ_ARRAY_OPTS=()
    runShell=$(ps -p $$ -o cmd='',comm='',fname='' 2>/dev/null | sed 's/^-//' | grep -oE '\w+' | head -n1)
    [[ "${runShell}" == "zsh" ]] && READ_ARRAY_OPTS=(-A) || READ_ARRAY_OPTS=(-a)
}

# version compare functions
function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; } # >
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" = "$1"; } # >=
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; } # <
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" = "$1"; } # <=

function version_compare() {
    local VERSION1=$1
    local VERSION2=$2
    if version_gt "${VERSION1}" "${VERSION2}"; then
        echo "$VERSION1 is greater than $VERSION2"
    fi

    if version_le "${VERSION1}" "${VERSION2}"; then
        echo "$VERSION1 is less than or equal to $VERSION2"
    fi

    if version_lt "${VERSION1}" "${VERSION2}"; then
        echo "$VERSION1 is less than $VERSION2"
    fi

    if version_ge "${VERSION1}" "${VERSION2}"; then
        echo "$VERSION1 is greater than or equal to $VERSION2"
    fi
}

# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash/49351294#49351294
function ver_compare() {
    # Compare two version strings [$1: version string 1 (v1), $2: version string 2 (v2), $3: version regular expressions (regex)]
    # Return values:
    #   0: v1 == v2
    #   1: v1 > v2
    #   2: v1 < v2
    # Based on: https://stackoverflow.com/a/4025065 by Dennis Williamson

    # Trivial v1 == v2 test based on string comparison
    [[ "$1" == "$2" ]] && return 0

    # Local variables
    local regex=${3:-"^(.*)-r([0-9]*)$"} va1=() vr1=0 va2=() vr2=0 len i IFS="."

    # Split version strings into arrays, extract trailing revisions
    if [[ "$1" =~ ${regex} ]]; then
        va1=("${BASH_REMATCH[1]}")
        [[ -n "${BASH_REMATCH[2]}" ]] && vr1=${BASH_REMATCH[2]}
    else
        va1=("$1")
    fi

    if [[ "$2" =~ ${regex} ]]; then
        va2=("${BASH_REMATCH[1]}")
        [[ -n "${BASH_REMATCH[2]}" ]] && vr2=${BASH_REMATCH[2]}
    else
        va2=("$2")
    fi

    # Bring va1 and va2 to same length by filling empty fields with zeros
    (( ${#va1[@]} > ${#va2[@]} )) && len=${#va1[@]} || len=${#va2[@]}
    for ((i=0; i < len; ++i)); do
        [[ -z "${va1[i]}" ]] && va1[i]="0"
        [[ -z "${va2[i]}" ]] && va2[i]="0"
    done

    # Append revisions, increment length
    va1+=("$vr1")
    va2+=("$vr2")
    len=$((len + 1))

    # *** DEBUG ***
    #echo "TEST: '${va1[@]} (?) ${va2[@]}'"

    # Compare version elements, check if v1 > v2 or v1 < v2
    for ((i=0; i < len; ++i)); do
        if (( 10#${va1[i]} > 10#${va2[i]} )); then
            return 1
        elif (( 10#${va1[i]} < 10#${va2[i]} )); then
            return 2
        fi
    done

    # All elements are equal, thus v1 == v2
    return 0
}

function ver_compare_eq() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 0 ]] && return 0 || return 1
}

function ver_compare_gt() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 1 ]] && return 0 || return 1
}

function ver_compare_ge() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 0 || $exitStatus -eq 1 ]] && return 0 || return 1
}

function ver_compare_lt() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 2 ]] && return 0 || return 1
}

function ver_compare_le() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 0 || $exitStatus -eq 2 ]] && return 0 || return 1
}

## ProgressBar
# bar=''
# for ((i=0;$i<=100;i++)); do
#     printf "Progress:[%-100s]%d%%\r" $bar $i
#     sleep 0.1
#     bar=#$bar
# done
# echo
function draw_progress_bar() {
    # https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
    # progress bar length in characters
    [[ -z "$PROGRESS_BAR_WIDTH" ]] && PROGRESS_BAR_WIDTH=50

    # Arguments: current value, max value, unit of measurement (optional)
    local __value=$1
    local __max=$2
    local __unit=${3:-""}  # if unit is not supplied, do not display it

    # Calculate percentage
    if (( __max < 1 )); then __max=1; fi  # anti zero division protection
    local __percentage=$(( 100 - (__max*100 - __value*100) / __max ))

    # Rescale the bar according to the progress bar width
    local __num_bar=$(( __percentage * PROGRESS_BAR_WIDTH / 100 ))

    # Draw progress bar
    printf "["
    for b in $(seq 1 $__num_bar); do printf "#"; done
    for s in $(seq 1 $(( PROGRESS_BAR_WIDTH - __num_bar ))); do printf " "; done
    if [[ -n "$__unit" ]]; then
        printf "] $__percentage%% ($__value / $__max $__unit)\r"
    else
        printf "] $__percentage%% ($__value / $__max)\r"
    fi
}
## Usage:
# PROGRESS_CNT=100
# PROGRESS_CUR=1
# while true; do
#     PROGRESS_CUR=$((PROGRESS_CUR+1))
#     # Draw a progress bar
#     draw_progress_bar $PROGRESS_CUR $PROGRESS_CNT "files"
#     # Check if we reached 100%
#     [[ $PROGRESS_CUR == $PROGRESS_CNT ]] && break
#     # sleep 0.1  # Wait before redrawing
# done
# # Go to the newline at the end of progress
# printf "\n"

## Sort an array
## https://gist.github.com/suewonjp/7150f3fe449a58b2ce6cbb456882bed6
## tmp=( c d a e b )
## sort_array tmp
## echo ${tmp[*]} ### a b c d e
# function sort_array() {
#     if [[ -n "$1" ]]; then
#         local IFS=$'\n'
#         eval "local arr=( \${$1[*]} )"
#         arr=( $( sort <<<"${arr[*]}" ) )
#         eval "$1=( \${arr[*]} )"
#     fi
# }

## https://askubuntu.com/questions/597924/wrong-behavior-of-sort-command
# function sort_array_lc() {
#     if [[ -n "$1" ]]; then
#         local IFS=$'\n'
#         eval "local arr=( \${$1[*]} )"
#         arr=( $( LC_ALL=C sort <<<"${arr[*]}" ) )
#         eval "$1=( \${arr[*]} )"
#     fi
# }
