#!/usr/bin/env bash

# rsync auto sync script with inotify
# from http://seanlook.com/2014/12/12/rsync_inotify_setup/

# variables
current_date=$(date +%Y%m%d_%H%M%S)
source_path=/tmp/src/
log_file=/var/log/rsync_client.log

# rsync settings
rsync_server=172.0.0.1
rsync_user=rsync_vuser
rsync_pwd=/etc/rsync.pwd
rsync_module=rsync

# exclude rules
INOTIFY_EXCLUDE='(.*/*\.log|.*/*\.swp)$'

tee /etc/rsync_exclude.lst <<'EOF'
*.log
*.swp
logs
EOF

RSYNC_EXCLUDE='/etc/rsync_exclude.lst'

# rsync client pwd check
if [ ! -e ${rsync_pwd} ];then
    echo -e "rsync client passwod file ${rsync_pwd} does does not exist!"
    exit 0
fi

# inotify_function

# rsync options
# -a, --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
# -u, --update                skip files that are newer on the receiver
# -v, --verbose               increase verbosity
# -r, --recursive             recurse into directories
# -t, --times                 preserve modification times
# -z, --compress              compress file data during the transfer
# -o, --owner                 preserve owner (super-user only)
# -p, --perms                 preserve permissions
# -g, --group                 preserve group
# -P                          same as --partial --progress
# --progress                  show progress during transfer
# --partial                   keep partially transferred files
# --bwlimit=RATE              limit socket I/O bandwidth

inotify_fun(){
    /usr/bin/inotifywait -mrq --timefmt '%Y/%m/%d-%H:%M:%S' --format '%T %w %f' \
        --exclude "${INOTIFY_EXCLUDE}" -e modify,delete,create,move,attrib "${source_path}" \
        | while read -r file; do
                /usr/bin/rsync -auvrtzopgP \
                    --exclude-from="${RSYNC_EXCLUDE}" \
                    --password-file="${rsync_pwd}" \
                    "${source_path}" \
                    "${rsync_user}@${rsync_server}::${rsync_module}"
                # --bwlimit=2048
            done
}

# inotify log
inotify_fun >> ${log_file} 2>&1 &
