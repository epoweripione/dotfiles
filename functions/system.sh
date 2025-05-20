#!/usr/bin/env bash

# load SSH keys with Passphrase Protected
# https://www.funtoo.org/Keychain
# http://unix.stackexchange.com/questions/90853/how-can-i-run-ssh-add-automatically-without-password-prompt
# https://www.cyberciti.biz/faq/ssh-passwordless-login-with-keychain-for-scripts/
function load_ssh_keys() {
    local IdentityFiles

    [[ ! -x "$(command -v keychain)" ]] && PackagesList=(keychain) && InstallSystemPackages "" "${PackagesList[@]}"

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

    # snapper_configs=$(sudo snapper list-configs --columns=config | sed '1,/--/ d')
    snapper_configs=$(sudo snapper list-configs --columns=config | sed '1,2 d')

    keep_snapshot=$((keep_snapshot + 1))
    while read -r current_config; do
        start_id=$(sudo snapper -c "${current_config}" list | awk '{print $1}' | grep -v '\*' | grep -Eo '[[:digit:]]+' | grep -wv '0' | head -n1)
        end_id=$(sudo snapper -c "${current_config}" list | awk '{print $1}' | grep -v '\*' | grep -Eo '[[:digit:]]+'| grep -wv '0' | tail -n "${keep_snapshot}" | head -n1)
        if [[ -n "${start_id}" && -n "${end_id}" ]]; then
            [[ start_id -lt end_id ]] && sudo snapper -c "${current_config}" delete --sync "${start_id}-${end_id}"
        fi
    done <<<"${snapper_configs}"

    sudo snapper list -a

    colorEcho "${BLUE}Updating ${FUCHSIA}GRUB2 configuration${BLUE}..."
    sudo update-grub
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

# make sudo more user friendly
# remove sudo timeout, make cache global, extend timeout
function setSudoTimeout() {
    sudo tee "/etc/sudoers.d/20-password-timeout-0-ppid-60min" <<-'EOF'
Defaults passwd_timeout=0
Defaults timestamp_type="global"

# sudo only once for 60 minute
Defaults timestamp_timeout=60
EOF

    sudo chmod 440 "/etc/sudoers.d/20-password-timeout-0-ppid-60min"
}

# Wayland IME for WPS Office
function setWaylandIMEWPSOffice() {
    [[ -f "/usr/lib/office6/wpscloudsvr" ]] && sudo chmod -x "/usr/lib/office6/wpscloudsvr"

    if [[ -f "/usr/bin/wps" ]]; then
        if ! grep -q "export QT_IM_MODULE=" "/usr/bin/wps"; then
            sudo sed -i -e '2a export QT_IM_MODULE="fcitx"' -e '2a export XMODIFIERS="@im=fcitx"' "/usr/bin/wps"
        fi
    fi

    if [[ -f "/usr/bin/wpp" ]]; then
        if ! grep -q "export QT_IM_MODULE=" "/usr/bin/wpp"; then
            sudo sed -i -e '2a export QT_IM_MODULE="fcitx"' -e '2a export XMODIFIERS="@im=fcitx"' "/usr/bin/wpp"
        fi
    fi

    if [[ -f "/usr/bin/et" ]]; then
        if ! grep -q "export QT_IM_MODULE=" "/usr/bin/et"; then
            sudo sed -i -e '2a export QT_IM_MODULE="fcitx"' -e '2a export XMODIFIERS="@im=fcitx"' "/usr/bin/et"
        fi
    fi
}

# Wayland IME for Chrome
# [Chromium](https://wiki.archlinux.org/title/chromium)
# %U --ozone-platform-hint=auto --enable-wayland-ime --gtk-version=4
function setWaylandIMEChrome() {
    if [[ -f "/usr/share/applications/google-chrome.desktop" ]]; then
        if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/google-chrome.desktop"; then
            sudo sed -i -e 's|/usr/bin/google-chrome-stable|/usr/bin/google-chrome-stable --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/google-chrome.desktop"
        fi
    fi

    if [[ -f "/usr/share/applications/google-chrome-beta.desktop" ]]; then
        if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/google-chrome-beta.desktop"; then
            sudo sed -i -e 's|/usr/bin/google-chrome-beta|/usr/bin/google-chrome-beta --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/google-chrome-beta.desktop"
        fi
    fi

    if [[ -f "/usr/share/applications/google-chrome-unstable.desktop" ]]; then
        if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/google-chrome-unstable.desktop"; then
            sudo sed -i -e 's|/usr/bin/google-chrome-unstable|/usr/bin/google-chrome-unstable --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/google-chrome-unstable.desktop"
        fi
    fi
}

# Wayland IME for VSCode
# --ozone-platform-hint=auto --enable-wayland-ime
function setWaylandIMEVSCode() {
    if [[ -f "/usr/share/applications/code.desktop" ]]; then
        if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/code.desktop"; then
            sudo sed -i -e 's|/usr/bin/code|/usr/bin/code --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/code.desktop"
        fi
    fi

    if [[ -f "/usr/share/applications/code-url-handler.desktop" ]]; then
        if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/code-url-handler.desktop"; then
            sudo sed -i -e 's|/usr/bin/code|/usr/bin/code --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/code-url-handler.desktop"
        fi
    fi
}

# Mount NFTS Drive & fix read-only mount NFTS Drive
function mountReadonlyNTFSDrive() {
    local NTFSDrive=$1
    local NTFSMountPath NTFSDriveUUID

    if [[ -z "${NTFSDrive}" ]]; then
        colorEcho "${BLUE}Usage: ${FUCHSIA}mountReadonlyNTFSDrive${BLUE} Disk-Partition"
        colorEcho "${BLUE}How to find disk partition:"
        colorEcho "  ${FUCHSIA}sudo lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME,UUID -e7"
        colorEcho "${BLUE}eg: ${FUCHSIA}mountReadonlyNTFSDrive${YELLOW} /dev/sdc3"
        return 1
    fi

    NTFSMountPath=$(basename "${NTFSDrive}")
    [[ -z "${NTFSMountPath}" ]] && return 1

    NTFSMountPath="/mnt/${NTFSMountPath}"
    [[ ! -d "${NTFSMountPath}" ]] && sudo mkdir -p "${NTFSMountPath}"

    sudo ntfsfix "${NTFSDrive}"
    if sudo mount -t ntfs-3g "${NTFSDrive}" "${NTFSMountPath}" 2>/dev/null; then
        colorEcho "${FUCHSIA}${NTFSDrive}${GREEN} successfully mounted to ${ORANGE}${NTFSMountPath}"
    else
        return 1
    fi

    # Automount
    NTFSDriveUUID=$(sudo blkid | grep "${NTFSDrive}" | grep -Eo '\s+UUID="[^"]*"' | cut -d\" -f2)
    echo
    colorEcho "${BLUE}Auto mount ${FUCHSIA}${NTFSDrive}${BLUE} on boot using following command:"
    colorEcho "  ${FUCHSIA}echo \"UUID=${NTFSDriveUUID} ${NTFSMountPath} ntfs-3g defaults 0 0\" | sudo tee -a /etc/fstab"

    # sudo findmnt
    # sudo umount "${NTFSMountPath}"
}

# Build GLIBC latest version
# fix: version `GLIBC_x.xx' not found
function buildGLIBC() {
    local GLIBC_REMOTE_VERSION=$1
    local GLIBC_CURRENT_VERSION GLIBC_FILE GLIBC_URL GLIBC_BUILD_DIR GLIBC_INSTALL_DIR

    if [[ -z "${GLIBC_REMOTE_VERSION}" ]]; then
        colorEcho "${BLUE}Checking ${FUCHSIA}GLIBC${BLUE}..."
        INSTALLER_CHECK_URL="http://ftp.gnu.org/gnu/glibc/"
        App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}" "glibc-.*\.tar\.gz"
        GLIBC_REMOTE_VERSION="${INSTALLER_VER_REMOTE}"
    fi

    GLIBC_CURRENT_VERSION=$(ldd --version | awk 'NR==1{print $NF}')
    if version_le "${GLIBC_REMOTE_VERSION}" "${GLIBC_CURRENT_VERSION}"; then
        colorEcho "${FUCHSIA}${GLIBC_CURRENT_VERSION}${RED} already installed or has a compatible version!"
        return 1
    fi

    [[ -z "${OS_PACKAGE_MANAGER}" ]] && get_os_package_manager

    if [[ -x "$(command -v pacman)" ]]; then
        PackagesList=(
            "build-essential"
            "libssl-dev"
            "libgdbm-dev"
            "libdb-dev"
            "libexpat-dev"
            "libncurses5-dev"
            "libbz2-dev"
            "zlib1g-dev"
            "gawk"
            "bison"
        )
        InstallSystemPackages "${BLUE}Checking Pre-requisite packages for ${FUCHSIA}GLIBC${BLUE}..." "${PackagesList[@]}"
    fi

    if [[ "${OS_PACKAGE_MANAGER}" == "dnf" ]]; then
        sudo dnf -y groupinstall "Development Tools"
    fi

    GLIBC_FILE="/tmp/glibc-${GLIBC_REMOTE_VERSION}.tar.gz"
    GLIBC_URL="http://ftp.gnu.org/gnu/glibc/${GLIBC_FILE}"

    GLIBC_BUILD_DIR="/tmp/glibc-${GLIBC_REMOTE_VERSION}"
    GLIBC_INSTALL_DIR="/opt/glibc-${GLIBC_REMOTE_VERSION}"

    if [[ -d "${GLIBC_INSTALL_DIR}" ]]; then
        colorEcho "${FUCHSIA}${GLIBC_INSTALL_DIR}${RED} already exist!"
        return 1
    fi

    colorEcho "${BLUE}Downloading ${FUCHSIA}GLIBC${BLUE} from ${ORANGE}${GLIBC_URL}${BLUE}..."
    [[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
    [[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${GLIBC_FILE}" "${GLIBC_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "$${GLIBC_FILE}" "${GLIBC_URL}"
    curl_rtn_code=$?
    if [[ ${curl_rtn_code} -eq 0 ]]; then
        tar -xzf "${GLIBC_FILE}" -C "/tmp"
    fi

    cd "${GLIBC_BUILD_DIR}" || return 1
    colorEcho "${BLUE}Building ${FUCHSIA}GLIBC ${ORANGE}${GLIBC_REMOTE_VERSION}${BLUE}..."
    mkdir build && \
        cd build && \
        ../configure --prefix="${GLIBC_INSTALL_DIR}" >/dev/null && \
        make -j"$(nproc)" >/dev/null && \
        sudo make install >/dev/null

    if [[ -d "${GLIBC_INSTALL_DIR}/lib" ]]; then
        colorEcho "${FUCHSIA}GLIBC ${ORANGE}${GLIBC_REMOTE_VERSION}${GREEN} successfully compiled to ${YELLOW}${GLIBC_INSTALL_DIR}/lib${GREEN}!"
    fi

    ## Update the system with the path of the new library
    # if [[ -d "${GLIBC_INSTALL_DIR}/lib" ]]; then
    #     # export LD_LIBRARY_PATH=${GLIBC_INSTALL_DIR}/lib:${LD_LIBRARY_PATH}
    #     echo "${GLIBC_INSTALL_DIR}/lib" | sudo tee "/etc/ld.so.conf.d/glibc-${GLIBC_REMOTE_VERSION}.conf" >/dev/null
    #     sudo ldconfig
    #     colorEcho "${FUCHSIA}${GLIBC_INSTALL_DIR}${GREEN} successfully installed!"
    # fi

    # Cleanup
    rm -rf "${GLIBC_BUILD_DIR}" && rm -f "${GLIBC_FILE}"
}
