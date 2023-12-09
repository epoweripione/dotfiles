#!/usr/bin/env bash

# load SSH keys with Passphrase Protected
# https://www.funtoo.org/Keychain
# http://unix.stackexchange.com/questions/90853/how-can-i-run-ssh-add-automatically-without-password-prompt
# https://www.cyberciti.biz/faq/ssh-passwordless-login-with-keychain-for-scripts/
function load_ssh_keys() {
    local IdentityFiles

    if checkPackageNeedInstall "keychain"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}keychain${BLUE}..."
        sudo pacman --noconfirm -S keychain
    fi

    if [[ ! -x "$(command -v keychain)" ]]; then
        colorEcho "${FUCHSIA}keychain${RED} is not installed!"
        return 1
    fi

    # /usr/bin/keychain --list
    # /usr/bin/keychain --clear

    if [[ -s "$HOME/.ssh/config" ]]; then
        IdentityFiles=$(grep 'IdentityFile' "$HOME/.ssh/config" \
            | sed -e 's/IdentityFile//' -e "s/^\s*//" -e "s/\s$//" -e "s|~|$HOME|" \
            | sort | uniq)
        for TargetFile in "${IdentityFiles[@]}"; do
            /usr/bin/keychain "${TargetFile}"
        done
    fi

    [[ -z "$HOSTNAME" ]] && HOSTNAME=$(uname -n)
    if [[ -s "$HOME/.keychain/$HOSTNAME-sh" ]]; then
        source "$HOME/.keychain/$HOSTNAME-sh"
        /usr/bin/keychain --list
    fi

    # Improve the security of keychain, need to re-enter any passphrases when log in
    if ! grep -q '/usr/bin/keychain --clear' ~/.zshrc >/dev/null 2>&1; then
        {
            echo ''
            echo '# Improve the security of keychain'
            echo '# User need to re-enter any passphrases when log in'
            echo '[[ -x "$(command -v keychain)" ]] && /usr/bin/keychain --clear >/dev/null 2>&1'
        } >> ~/.zshrc
    fi

    if ! grep -q '/usr/bin/keychain --clear' ~/.bash_profile >/dev/null 2>&1; then
        {
            echo ''
            echo '# Improve the security of keychain'
            echo '# User need to re-enter any passphrases when log in'
            echo '[[ -x "$(command -v keychain)" ]] && /usr/bin/keychain --clear >/dev/null 2>&1'
        } >> ~/.bash_profile
    fi
}

# add job to cron
function Install_cron_job() {
    local cronjob=${1:-""}
    local cronline

    [[ -z "${cronjob}" ]] && return 0

    (crontab -l 2>/dev/null || true; echo "${cronjob}") | crontab - || {
        colorEcho "${RED}  cron job install failed!"
        return 1
    }

    cronline=$(crontab -l | wc -l)

    colorEcho "${FUCHSIA}${cronjob} ${GREEN}installed!"
    colorEcho "${YELLOW}  How to delete this job:"
    colorEcho "${FUCHSIA}  (crontab -l 2>/dev/null | sed \"${cronline}d\") | crontab -"
}

# add systemd service
function Install_systemd_Service() {
    # Usage:
    # Install_systemd_Service "subconverter" "/srv/subconverter/subconverter"
    local service_name=$1
    local service_exec=$2
    local service_user=${3:-"nobody"}
    local service_workdir=${4:-""}
    local filename service_file

    [[ $# -lt 2 ]] && return 1

    [[ -z "${service_name}" ]] && return 1
    [[ -z "${service_exec}" ]] && return 1

    filename=$(awk '{print $1}' <<<"${service_exec}")
    [[ -z "${service_workdir}" ]] && service_workdir=$(dirname "$(readlink -f "$filename")")

    [[ ! -f "$filename" ]] && colorEcho "${FUCHSIA}${filename}${RED} doesn't exist!" && return 1
    [[ ! -d "${service_workdir}" ]] && colorEcho "${FUCHSIA}${service_workdir}${RED} doesn't exist!" && return 1

    service_file="/etc/systemd/system/${service_name}.service"
    if [[ -s "${service_file}" ]]; then
        colorEcho "${FUCHSIA}${service_file}${RED} already exist!" && return 1
    else
        sudo tee "${service_file}" >/dev/null <<-EOF
[Unit]
Description=${service_name}
After=network.target network-online.target nss-lookup.target

[Service]
Type=simple
StandardError=journal
User=${service_user}
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=${service_exec}
WorkingDirectory=${service_workdir}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=5s
# StandardOutput=append:/var/log/${service_name}.log
# StandardError=append:/var/log/${service_name}.log

[Install]
WantedBy=multi-user.target
EOF
    fi

    sudo systemctl enable "${service_name}" && sudo systemctl restart "${service_name}"
    if systemctl is-enabled "${service_name}" >/dev/null 2>&1; then
        colorEcho "${GREEN}  systemd service ${FUCHSIA}${service_name}${GREEN} installed!"
    else
        colorEcho "${RED}  systemd service ${FUCHSIA}${service_name}${RED} install failed!"
    fi
}

# Start new screen session and logging to ~/screenlog.*
function newScreenSession() {
    local SCREEN_SESSION_NAME=${1:-"default"}
    local SCREEN_SESSION_LOGGING=${2:-"no"}

    if [[ -x "$(command -v screen)" ]]; then
        if [[ -z "$STY" && -z "$TMUX" ]]; then
            mkdir -p "$HOME/.screen" && chmod 700 "$HOME/.screen" && export SCREENDIR="$HOME/.screen"
            if ! grep -q "^term " "$HOME/.screenrc" 2>/dev/null; then
                echo "term ${TERM}" >> "$HOME/.screenrc"
            fi

            if ! grep -q "^caption always " "$HOME/.screenrc" 2>/dev/null; then
                tee -a "$HOME/.screenrc" >/dev/null <<-'EOF'
# https://gist.github.com/onsails/1328005/dacbc9903fcea5385bb8ee2fde4e1a367d32889c
# caption always "%?%F%{-b bc}%:%{-b bb}%?%C|%D|%M %d|%H%?%F%{+u wb}%? %L=%-Lw%45>%{+b by}%n%f* %t%{-}%+Lw%-0<"
caption always "%{=}%{+b kR}%H %{+b kY}%M %d %{+b kG}%2c %{+b kB}%?%-Lw%?%{+b kW}%n*%f %kt%?(%u)%?%{+bkB}%?%+Lw%? | %{kR} Load: %l %{kB}"
EOF
            fi

            # logging
            if [[ "${SCREEN_SESSION_LOGGING}" == "yes" ]]; then
                screen -L -Logfile "$HOME/.screen/screen_$(date '+%Y%m%d_%H%M%S').log" -xRR "${SCREEN_SESSION_NAME}"
            else
                screen -xRR "${SCREEN_SESSION_NAME}"
            fi
        fi
    else
        colorEcho "${FUCHSIA}screen${RED} is not installed!"
        return 1
    fi
}

# Start new tmux session
function newTmuxSession() {
    local TMUX_SESSION_NAME=${1:-"default"}

    ## Logging in tmux session
    # script -f "$HOME/.tmux_logs/tmux_$(date '+%Y%m%d_%H%M%S').log" >/dev/null && exit

    ## tmux-logging
    ## https://github.com/tmux-plugins/tmux-logging
    # if [[ -s "$HOME/.tmux.conf.local" ]]; then
    #     if ! grep -q "tmux-logging" "$HOME/.tmux.conf.local" 2>/dev/null; then
    #         echo "set -g @plugin 'tmux-plugins/tmux-logging'" \
    #             | tee -a "$HOME/.tmux.conf.local" >/dev/null
    #     fi
    # fi

    if [[ "$(command -v tmux)" ]]; then
        if [[ -z "$STY" && -z "$TMUX" ]]; then
            if ! tmux attach -t "${TMUX_SESSION_NAME}" 2>/dev/null; then
                tmux new -s "${TMUX_SESSION_NAME}"
            fi
        fi
    else
        colorEcho "${FUCHSIA}tmux${RED} is not installed!"
        return 1
    fi
}

# zellij: List current sessions, attach to a running session, or create a new one
function newZellijSession() {
    local ZJ_SESSIONS NO_SESSIONS

    if [[ "$(command -v zellij)" ]]; then
        if [[ -z "${ZELLIJ}" && -z "${ZELLIJ_SESSION_NAME}" ]]; then
            ZJ_SESSIONS=$(zellij list-sessions 2>/dev/null)
            NO_SESSIONS=$(echo "${ZJ_SESSIONS}" | wc -l)

            if [ "${NO_SESSIONS}" -ge 2 ]; then
                if [[ "$(command -v fzf)" ]]; then
                    zellij attach "$(echo "${ZJ_SESSIONS}" | awk '{print $1}' | fzf)" options --default-mode=locked
                else
                    zellij attach "$(echo "${ZJ_SESSIONS}" | sk)" options --default-mode=locked
                fi
                # zellij attach "$(echo "${ZJ_SESSIONS}" | sk)" options --default-mode=locked --disable-mouse-mode
            else
                zellij attach -c options --default-mode=locked
                # zellij attach -c options --default-mode=locked --disable-mouse-mode
            fi
        fi
    else
        colorEcho "${FUCHSIA}zellij${RED} is not installed!"
        return 1
    fi
}

# zellij: List layout files saved in the default layout directory, opens the selected layout file
function newZellijLayout() {
    local ZJ_LAYOUT_DIR ZJ_LAYOUT

    if [[ "$(command -v zellij)" ]]; then
        ZJ_LAYOUT_DIR=$(zellij setup --check | grep "LAYOUT DIR" - | grep -o '".*"' - | tr -d '"')

        if [[ -d "${ZJ_LAYOUT_DIR}" ]];then
            if [[ "$(command -v fzf)" ]]; then
                ZJ_LAYOUT="$(fd --type file . "${ZJ_LAYOUT_DIR}" | sed 's|.*/||' | fzf || exit)"
            else
                ZJ_LAYOUT="$(fd --type file . "${ZJ_LAYOUT_DIR}" | sed 's|.*/||' | sk || exit)"
            fi
            zellij --layout "${ZJ_LAYOUT}"
        fi
    else
        colorEcho "${FUCHSIA}zellij${RED} is not installed!"
        return 1
    fi
}

# Clean snapper snapshots to keep the last N snapshots
function SnapperDeleteSnapshots() {
    local keep_snapshot=${1:-10}
    local snapper_configs current_config
    local start_id end_id

    snapper_configs=$(snapper list-configs --columns=config | sed '1,/--/ d')

    keep_snapshot=$((keep_snapshot + 1))
    while read -r current_config; do
        start_id=$(snapper -c "${current_config}" list | awk '{print $1}' | grep -E '[[:digit:]]+' | grep -wv '0' | head -n1)
        end_id=$(snapper -c "${current_config}" list | awk '{print $1}' | grep -E '[[:digit:]]+'| grep -wv '0' | tail -n "${keep_snapshot}" | head -n1)
        if [[ -n "${start_id}" && -n "${end_id}" ]]; then
            [[ start_id -lt end_id ]] && snapper -c "${current_config}" delete "${start_id}-${end_id}"
        fi
    done <<<"${snapper_configs}"

    snapper list -a
}

# fix "command not found" when running via cron
function FixSystemBinPath() {
    local DirList=()
    local TargetDir

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
}
