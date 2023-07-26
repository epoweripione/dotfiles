#!/usr/bin/env bash

# broot: a better tree optimizing for the height of the screen
function br_tree() {
    br -c :pt "$@"
}

# br with git status
function br_git_status() {
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/broot.toml" ]]; then
        br --conf "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/broot.toml" --git-status
    else
        br --git-status
    fi
}

# Send desktop notifications and reminders from Linux terminal
# https://opensource.com/article/22/1/linux-desktop-notifications
function remind() {
    local COUNT="$#"
    local COMMAND="$1"
    local MESSAGE="$1"
    local OP="$2"

    shift 2
    local WHEN="$*"

    # Display help if no parameters or help command
    if [[ $COUNT -eq 0 || "$COMMAND" == "help" || "$COMMAND" == "--help" || "$COMMAND" == "-h" ]]; then
        echo "COMMAND"
        echo "    remind <message> <time>"
        echo "    remind <command>"
        echo
        echo "DESCRIPTION"
        echo "    Displays notification at specified time"
        echo
        echo "EXAMPLES"
        echo '    remind "Hi there" now'
        echo '    remind "Time to wake up" in 5 minutes'
        echo '    remind "Dinner" in 1 hour'
        echo '    remind "Take a break" at noon'
        echo '    remind "Are you ready?" at 13:00'
        echo '    remind list'
        echo '    remind clear'
        echo '    remind help'
        echo
        return
    fi

    # Install notify-send
    if checkPackageNeedInstall "notify-send"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}notify-send${BLUE}..."
        sudo pacman --noconfirm -S notify-send
    fi

    # Install AT
    if checkPackageNeedInstall "at"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}at${BLUE}..."
        sudo pacman --noconfirm -S at
    fi

    # Check presence of notify-send command
    if ! which notify-send >/dev/null; then
        echo "remind: notify-send is required but not installed on your system. Install it with your package manager of choice, for example 'sudo apt install notify-send'."
        return
    fi

    # Check presence of AT command
    if ! which at >/dev/null; then
        echo "remind: AT utility is required but not installed on your system. Install it with your package manager of choice, for example 'sudo apt install at'."
        return
    fi

    # Run commands: list, clear
    if [[ $COUNT -eq 1 ]]; then
        if [[ "$COMMAND" == "list" ]]; then
        at -l
        elif [[ "$COMMAND" == "clear" ]]; then
        at -r "$(atq | cut -f1)"
        else
        echo "remind: unknown command $COMMAND. Type 'remind' without any parameters to see syntax."
        fi
        return
    fi

    # Determine time of notification
    if [[ "$OP" == "in" ]]; then
        local TIME="now + $WHEN"
    elif [[ "$OP" == "at" ]]; then
        local TIME="$WHEN"
    elif [[ "$OP" == "now" ]]; then
        local TIME="now"
    else
        echo "remind: invalid time operator $OP"
        return
    fi

    # Schedule the notification
    echo "notify-send '$MESSAGE' 'Reminder' -u critical" | at "$TIME" 2>/dev/null
    echo "Notification scheduled at $TIME"
}

# https://github.com/chubin/wttr.in
function get_weather() {
    local wttr_city=${1:-""}
    local wttr_format=${2:-""}
    local wttr_lang=${3:-"zh-cn"}
    local wttr_url

    if [[ -z "${wttr_format}" ]]; then
        wttr_url="wttr.in/${wttr_city}"
    else
        wttr_url="wttr.in/${wttr_city}?format=${wttr_format}"
    fi

    curl -fsL --connect-timeout 3 --max-time 10 \
        --noproxy '*' -H "Accept-Language: ${wttr_lang}" --compressed \
        "${wttr_url}"
}

function get_weather_custom() {
    local wttr_city=${1:-""}
    local wttr_format=${2:-""}
    local wttr_lang=${3:-"zh-cn"}
    local wttr_url
    local wttr_weather

    if [[ -z "${wttr_format}" ]]; then
        wttr_format="%l:+%c%C,+%F0%9F%8C%A1%t,+%E2%9B%86%h,+%F0%9F%8E%8F%w,+%E2%98%94%p+%o,+%P"
    fi

    wttr_url="wttr.in/${wttr_city}?format=${wttr_format}"

    wttr_weather=$(curl -fsL --connect-timeout 3 --max-time 10 \
        --noproxy '*' -H "Accept-Language: ${wttr_lang}" --compressed \
        "${wttr_url}")
    [[ -n "${wttr_weather}" ]] && colorEcho "${YELLOW}${wttr_weather}"
}

# Bash Function To Rename Files Without Typing Full Name Twice
function mv_rename() {
    if [ "$#" -ne 1 ] || [ ! -e "$1" ]; then
        command mv "$@"
        return
    fi

    read -rei "$1" newfilename
    command mv -v -- "$1" "$newfilename"
}

## Dateutils
# http://www.fresse.org/dateutils/
# apt install -y dateutils
# dateutils.dadd 2018-05-22 +120d
# Usage: date_diff 20201208 20180522
function date_diff() {
    if [[ $# -eq 2 ]]; then
        echo $(( ($(date -d "$1" +%s) - $(date -d "$2" +%s) )/(60*60*24) ))
    fi
}

#  Usage: get_zone_time Asia/Shanghai America/Los_Angeles America/New_York
function get_zone_time() {
    local TZONES CURRENT_UTC_TIME DISPLAY_FORMAT UTC_TIME LOCAL_TIME ZONE_TIME tz

    TZONES=("$@")
    [[ -z "${TZONES[*]}" ]] && TZONES=("Asia/Shanghai")
    # /usr/share/zoneinfo
    # Asia/Shanghai America/Los_Angeles America/New_York
    CURRENT_UTC_TIME=$(date -u)

    DISPLAY_FORMAT="%F %T %Z %z"

    UTC_TIME=$(date -u -d "$CURRENT_UTC_TIME" +"$DISPLAY_FORMAT")
    colorEcho "${YELLOW}UTC Time: ${UTC_TIME}"

    LOCAL_TIME=$(date -d "$CURRENT_UTC_TIME" +"$DISPLAY_FORMAT")
    colorEcho "${FUCHSIA}Local Time: ${LOCAL_TIME}"

    for tz in "${TZONES[@]}"; do
        ZONE_TIME=$(TZ="$tz" date -d "$CURRENT_UTC_TIME" +"$DISPLAY_FORMAT")
        colorEcho "${BLUE}${tz}: ${ZONE_TIME}"
    done
}
