#!/usr/bin/env bash

# rsync daemon: ${MY_SHELL_SCRIPTS}/installer/lsyncd_installer.sh -t rsyncd -m backup -d /data/backup -u rsyncuser -w PassW0rd
# lsyncd + rsyncssh: ${MY_SHELL_SCRIPTS}/installer/lsyncd_installer.sh -t rsyncssh -s /opt/oracle/backup -d /data/backup -h 172.10.1.1 -u root -i $HOME/.ssh/id_rsa
while getopts ":t:s:d:h:p:u:i:m:w:f:e" OPTNAME; do
    case "${OPTNAME}" in
        t)
            SYNC_TYPE="${OPTARG}"
            ;;
        s)
            SYNC_SRC="${OPTARG}"
            ;;
        d)
            SYNC_TARGET="${OPTARG}"
            RSYNC_PATH="${OPTARG}"
            ;;
        h)
            SSH_HOST="${OPTARG}"
            ;;
        p)
            SSH_PORT="${OPTARG}"
            ;;
        u)
            SSH_USER="${OPTARG}"
            RSYNC_USER="${OPTARG}"
            ;;
        i)
            SSH_PRIVATE_FILE="${OPTARG}"
            ;;
        m)
            RSYNC_MODULE="${OPTARG}"
            ;;
        w)
            RSYNC_PASSWORD="${OPTARG}"
            ;;
        f)
            RSYNC_PASS_FILE="${OPTARG}"
            ;;
        e)
            RSYNC_EXCLUDE_FILE="${OPTARG}"
            ;;
        :)
            echo "No argument value for option ${OPTARG}!"
            exit 1
            ;;
        ?)
            echo "Unknown option ${OPTARG}!"
            exit 1
            ;;
        *)
            echo "Unknown error while processing options!"
            exit 1
            ;;
    esac
    # echo "-${OPTNAME}=${OPTARG} index=${OPTIND}"
done

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


# https://www.xiebruce.top/919.html
# https://linux.cn/article-5849-1.html
# https://segmentfault.com/a/1190000022046589
if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        rsync
        lsyncd
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi


# rsync config
# https://man7.org/linux/man-pages/man5/rsyncd.conf.5.html
RSYNC_MODULE=${RSYNC_MODULE:-"backup"}
RSYNC_PATH=${RSYNC_PATH:-"/tmp/dest"}
RSYNC_USER=${RSYNC_USER:-"rsyncuser"}
RSYNC_PASS_FILE=${RSYNC_PASS_FILE:-"/etc/rsync_password.lst"}
RSYNC_EXCLUDE_FILE=${RSYNC_EXCLUDE_FILE:-"/etc/rsync_exclude.lst"}

echo "${RSYNC_PASSWORD:-RSYNC-PassW0rd}" | tee "${RSYNC_PASS_FILE}" >/dev/null

if [[ ! -s "${RSYNC_EXCLUDE_FILE}" ]]; then
    sudo tee "${RSYNC_EXCLUDE_FILE}" >/dev/null <<-'EOF'
*.log
*.swp
logs
EOF
fi


# sync config
SYNC_TYPE=${SYNC_TYPE:-"direct"}
SYNC_SRC=${SYNC_SRC:-"/tmp/src"}
SYNC_TARGET=${SYNC_TARGET:-"/tmp/dest"}
# SYNC_TARGET="rsyncuser@10.10.1.1::backup" # rsyncd daemon

SSH_HOST=${SSH_HOST:-""}
SSH_PORT=${SSH_PORT:-"22"}
SSH_USER=${SSH_USER:-"$USER"}
SSH_PRIVATE_FILE=${SSH_PRIVATE_FILE:-"$HOME/.ssh/id_rsa"}

mkdir -p "/var/log/rsyncd"
mkdir -p "/var/log/lsyncd"

if [[ "${SYNC_TYPE}" == "rsyncd" ]]; then
    # rsyncd daemon
    # rsync config: /etc/rsyncd.conf
    # https://download.samba.org/pub/rsync/rsyncd.conf.html
    sudo tee "/etc/rsyncd.conf" >/dev/null <<-EOF
uid = root
gid = root
use chroot = yes
max connections = 0
log file=/var/log/rsyncd/rsyncd.log
pid file=/var/run/rsyncd.pid
lock file=/var/run/rsyncd.lock
transfer logging = yes
timeout = 900
ignore nonreadable = yes

[${RSYNC_MODULE}]
path = ${RSYNC_PATH}
ignore errors
read only = no
list = yes
auth users = ${RSYNC_USER}
secrets file = ${RSYNC_PASS_FILE}
EOF

    # start rsyncd daemon
    # /usr/bin/rsync --port=873 --daemon
    # ps -ef | grep rsync

    [[ $(systemctl is-enabled "rsyncd_${RSYNC_MODULE}" 2>/dev/null) ]] || {
        Install_systemd_Service "rsyncd_${RSYNC_MODULE}" "/usr/bin/rsync --port=873 --daemon"
    }
    [[ $(systemctl is-enabled "rsyncd_${RSYNC_MODULE}" 2>/dev/null) ]] && sudo systemctl restart "rsyncd_${RSYNC_MODULE}"

    colorEcho "${FUCHSIA}rsyncd${GREEN} service successfully installed!"
    colorEcho "${FUCHSIA}rsyncd config file: ${GREEN}/etc/rsyncd.conf"
    colorEcho "${FUCHSIA}rsyncd log file: ${GREEN}/var/log/rsyncd/rsyncd.log"

    cat "/etc/rsyncd.conf"
else
    # lsyncd
    # lsyncd config: /etc/lsyncd.conf
    # https://lsyncd.github.io/lsyncd/
    sudo tee "/etc/lsyncd.conf" >/dev/null <<-EOF
settings {
    logfile     = "/var/log/lsyncd/lsyncd.log",
    statusFile  = "/var/log/lsyncd/lsyncd.status",
    inotifyMode = "CloseWrite",
    insist      = true
}

EOF

    case "${SYNC_TYPE}" in
        direct)
            # sync to local dir: direct(cp/rm/mv)
            sudo tee -a "/etc/lsyncd.conf" >/dev/null <<-EOF
sync {
    default.direct,
    source       = "${SYNC_SRC}",
    target       = "${SYNC_TARGET}",
    delay        = 1
    maxProcesses = 1
}

EOF
            ;;
        rsync)
            # local dir: target = /tmp/dest
            # remote + rsyncd daemon: target = syncuser@<remote>::module
            # remote + ssh shell: target = sshuser@<remote>:/remote/dest
            sudo tee -a "/etc/lsyncd.conf" >/dev/null <<-EOF
sync {
    default.rsync,
    source      = "${SYNC_SRC}",
    target      = "${SYNC_TARGET}",
    excludeFrom = "${RSYNC_EXCLUDE_FILE}",
    delay       = 0,
    rsync       = {
        binary        = "/usr/bin/rsync",
        password_file = "${RSYNC_PASS_FILE}",
        archive       = true,
        compress      = true,
        verbose       = false
    }
}
EOF
            ;;
        rsyncssh)
            # remote + ssh: host = sshuser@<remote>
            sudo tee -a "/etc/lsyncd.conf" >/dev/null <<-EOF
sync {
    default.rsyncssh,
    source      = "${SYNC_SRC}",
    host        = "${SSH_HOST}",
    targetdir   = "${SYNC_TARGET}",
    excludeFrom = "${RSYNC_EXCLUDE_FILE}",
    delay       = 0,
    rsync       = {
        binary        = "/usr/bin/rsync",
        archive       = true,
        compress      = true,
        verbose       = false,
        rsh = "/usr/bin/ssh -p ${SSH_PORT} -l ${SSH_USER} -i ${SSH_PRIVATE_FILE} -o StrictHostKeyChecking=no"
        --_extra = {"--bwlimit=200", "--omit-link-times"}
    }
}
EOF
            ;;
    esac

    ## start lsyncd service
    # lsyncd -nodaemon -delay 30 /etc/lsyncd.conf

    # [[ $(systemctl is-enabled "lsyncd_${RSYNC_MODULE}" 2>/dev/null) ]] || {
    #     Install_systemd_Service "lsyncd_${RSYNC_MODULE}" "/usr/bin/lsyncd /etc/lsyncd.conf"
    # }
    # [[ $(systemctl is-enabled "lsyncd_${RSYNC_MODULE}" 2>/dev/null) ]] && sudo systemctl restart "lsyncd_${RSYNC_MODULE}"
    # colorEcho "${FUCHSIA}lsyncd${GREEN} service successfully installed!"

    colorEcho "${FUCHSIA}lsyncd config file: ${GREEN}/etc/lsyncd.conf"
    colorEcho "${FUCHSIA}lsyncd log file: ${GREEN}/var/log/lsyncd/lsyncd.log"

    cat "/etc/lsyncd.conf"

    colorEcho ""
    colorEcho "${FUCHSIA}Run lsyncd in foreground: ${GREEN}lsyncd -nodaemon /etc/lsyncd.conf"
    colorEcho "${FUCHSIA}Run lsyncd in daemon mode: ${GREEN}lsyncd /etc/lsyncd.conf"

    # tail -f /var/log/lsyncd/lsyncd.log /var/log/rsyncd/rsyncd.log
    # if pgrep -f "lsyncd" >/dev/null 2>&1; then sudo pkill -f "lsyncd"; fi
fi


cd "${CURRENT_DIR}" || exit