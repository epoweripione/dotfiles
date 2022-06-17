#!/usr/bin/env bash

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

# https://<ip>:8006

# Storage config: /etc/pve/storage.cfg
# local-lvm → /dev/pve
# local → /var/lib/vz/template/iso

## Upload ssh public key
## echo '<public key>' >> ~/.ssh/authorized_keys
# ssh-copy-id -i ~/.ssh/id_ed25519.pub root@<ip>

# pveversion --verbose
OS_CODENAME=$(cat /etc/os-release |grep CODENAME |cut -d"=" -f2)

apt install -y apt-transport-https apt-utils ca-certificates \
    lsb-release software-properties-common sudo curl wget

# Disable `No valid subscription` msg
NO_VALID_LINE=$(grep -n ".data.status.toLowerCase() !== 'active" "/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js" | cut -d: -f1) && \
    NO_VALID_START_LINE=$((NO_VALID_LINE - 1)) && \
    sed -i.bak "${NO_VALID_START_LINE}d" "/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js" && \
    sed -i "s#.data.status.toLowerCase() !== 'active'#if(false#g" "/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

systemctl restart pveproxy

# Disable pve-enterprise
# sed -e '/^[^#]/ s/\(^.*pve-enterprise.*$\)/#\ \1/' -i "/etc/apt/sources.list.d/pve-enterprise.list"
sed -e '/pve-enterprise/ s/^[^#]/#\ &/g' -i "/etc/apt/sources.list.d/pve-enterprise.list"

## proxmox mirror
# PROXMOX_MIRROR_URL="download.proxmox.wiki"
PROXMOX_MIRROR_URL="mirrors.ustc.edu.cn/proxmox"
wget "https://${PROXMOX_MIRROR_URL}/debian/proxmox-release-${OS_CODENAME}.gpg" -O "/etc/apt/trusted.gpg.d/proxmox-release-${OS_CODENAME}.gpg" && \
    echo "deb https://${PROXMOX_MIRROR_URL}/debian/pve ${OS_CODENAME} pve-no-subscription" | tee "/etc/apt/sources.list.d/pve-no-subscription.list" >/dev/null && \
    echo "deb https://${PROXMOX_MIRROR_URL}/debian/ceph-pacific ${OS_CODENAME} main" | tee "/etc/apt/sources.list.d/ceph.list" >/dev/null && \
    sed -i.bak "s#http://download.proxmox.com#https://${PROXMOX_MIRROR_URL}#g" "/usr/share/perl5/PVE/CLI/pveceph.pm"

# CT Templates
sed -i.bak 's|http://download.proxmox.com|https://mirrors.ustc.edu.cn/proxmox|g' "/usr/share/perl5/PVE/APLInfo.pm"

## apt mirror
# APT_MIRROR_URL="mirrors.tuna.tsinghua.edu.cn"
# APT_MIRROR_URL="mirrors.ustc.edu.cn"
APT_MIRROR_URL="mirror.sjtu.edu.cn"
sudo sed -i \
    -e "s|ftp.debian.org|${APT_MIRROR_URL}|g" \
    -e "s|deb.debian.org|${APT_MIRROR_URL}|g" \
    -e "s|security.debian.org/debian-security|${APT_MIRROR_URL}/debian-security|g" \
    -e "s|security.debian.org |${APT_MIRROR_URL}/debian-security |g" "/etc/apt/sources.list"

sudo sed -i "s|http://${APT_MIRROR_URL}|https://${APT_MIRROR_URL}|g" "/etc/apt/sources.list"

apt update && apt upgrade -y && apt dist-upgrade -y


## cgroups v2
# grep cgroup2 /proc/filesystems
# ls /sys/fs/cgroup
## If the files are prefixed with cgroup. you are running cgroups v2, if not, its still v1.

## Disable cgroups v2 with the systemd kernel flag: systemd.unified_cgroup_hierarchy=0
## As of November 2020, cgroups v2 seems to break Docker inside systemd-nspawn.
## If you want to use Docker in this way, do not set the kernel parameter systemd.unified_cgroup_hierarchy=1.
# . "/etc/default/grub"
# if [[ -n "${GRUB_CMDLINE_LINUX_DEFAULT}" ]]; then
#     GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} systemd.unified_cgroup_hierarchy=0"
#     sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"${GRUB_CMDLINE_LINUX_DEFAULT}\"/" "/etc/default/grub"
# else
#     echo 'GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=0"' | sudo tee -a "/etc/default/grub" >/dev/null
# fi
# sudo grub-mkconfig -o /boot/grub/grub.cfg
# reboot


## Use Systemd-nspawn to install OpenMediaVault
## Systemd-nspawn
## https://wiki.debian.org/nspawn
## https://wiki.archlinux.org/title/Systemd-nspawn
## https://64mb.org/2021/02/05/systemd-nspawn/
## https://hub.nspawn.org/images/
# Host Preparation
apt install -y systemd-container debootstrap

mkdir -p "/etc/systemd/nspawn"

## Network
## Enable systemd-networkd in host
## https://wiki.archlinux.org/title/Systemd-networkd
## /etc/systemd/network/
systemctl disable network && systemctl stop network
systemctl disable networking && systemctl stop networking
systemctl disable NetworkManager && systemctl stop NetworkManager

[[ -s "/etc/network/interfaces" ]] && mv "/etc/network/interfaces" "/etc/network/interfaces.save"

systemctl enable systemd-networkd && systemctl start systemd-networkd
systemctl enable systemd-resolved && systemctl start systemd-resolved
# ln -sf "/run/systemd/resolve/resolv.conf" "/etc/resolv.conf"

# enable unprivileged user namespaces
# sysctl -a | grep 'kernel.unprivileged'
echo 'kernel.unprivileged_userns_clone=1' > "/etc/sysctl.d/nspawn.conf"
systemctl restart systemd-sysctl.service

# Creating a Debian Container
CONTAINER_NAME=${1:-"omv"}
CONTAINER_PATH="/var/lib/machines/${CONTAINER_NAME}"
debootstrap --include=systemd-container --arch=amd64 stable "${CONTAINER_PATH}" "https://${APT_MIRROR_URL}/debian/"

# login to the newly created container and make some changes to allow root logins
systemd-nspawn -D "${CONTAINER_PATH}" --machine "${CONTAINER_NAME}"
## set root password
# passwd
## allow login via local tty
# echo 'pts/1' >> /etc/securetty  # May need to set 'pts/0' instead
## logout from container
# logout

mkdir -p "/etc/systemd/system/systemd-nspawn@${CONTAINER_NAME}.service.d"

# Run docker in systemd-nspawn
# sed -i "/^\[Service\]/a\Environment=SYSTEMD_NSPAWN_USE_CGNS=0" "/etc/systemd/system/systemd-nspawn@${CONTAINER_NAME}.service.d/override.conf"
tee -a "/etc/systemd/system/systemd-nspawn@${CONTAINER_NAME}.service.d/override.conf" >/dev/null <<-'EOF'
[Service]
Environment=SYSTEMD_NSPAWN_USE_CGNS=0
EOF

tee -a "/etc/systemd/nspawn/${CONTAINER_NAME}.nspawn" >/dev/null <<-'EOF'
[Exec]
Capability=all
SystemCallFilter=add_key keyctl
PrivateUsers=no

[Files]
Bind=/sys/fs/cgroup
EOF

## Port mapping
## proto:host-port:container-port
# iptables -L -t nat
# omv: 80
# Portainer: 8000 9000
# Yacht: 8001 admin@yacht.local:pass
tee -a "/etc/systemd/nspawn/${CONTAINER_NAME}.nspawn" >/dev/null <<-'EOF'

[Network]
VirtualEthernet=yes
Port=tcp:8080:80
Port=tcp:8043:443
Port=tcp:8000:8000
Port=tcp:9000:9000
Port=tcp:8001:8001
EOF

## systemd-nspawn service
# /lib/systemd/system/systemd-nspawn@.service
# /etc/systemd/system/machines.target.wants/systemd-nspawn@${CONTAINER_NAME}.service
# nspawn service by default adds -U argument that turns on private users support 
# and shifts all UID/GID-s up some random amount.
# If you plan on sharing files between containers then this will mess up yout file owners.
# You can enable mymachines nsswitch module that will do user and group id translation 
# between host and container private users.
# https://www.freedesktop.org/software/systemd/man/nss-mymachines.html
# systemctl edit "systemd-nspawn@${CONTAINER_NAME}"
sed -i 's/--network-veth -U/--network-veth/' "/lib/systemd/system/systemd-nspawn@.service"
# tee -a "/etc/systemd/system/systemd-nspawn@${CONTAINER_NAME}.service.d/override.conf" >/dev/null <<-'EOF'
# ExecStart=
# ExecStart=systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --network-veth --settings=override --machine=%i
# EOF

# Enable container to start at boot
# systemctl enable "systemd-nspawn@${CONTAINER_NAME}"
machinectl enable "${CONTAINER_NAME}"

# Booting a Container
# systemd-nspawn -bD "${CONTAINER_PATH}"
# systemctl start "systemd-nspawn@${CONTAINER_NAME}"
machinectl start "${CONTAINER_NAME}"

# Hostname & Network in container
CONTAINER_SCRIPT="machine_init-${CONTAINER_NAME}.sh"
tee "$PWD/${CONTAINER_SCRIPT}" >/dev/null <<-'EOF'
#!/usr/bin/env bash

echo ${CONTAINER_NAME} >/etc/hostname

systemctl enable systemd-networkd && systemctl start systemd-networkd
systemctl enable systemd-resolved && systemctl start systemd-resolved
EOF
machinectl copy-to "${CONTAINER_NAME}" "$PWD/${CONTAINER_SCRIPT}" "/root/${CONTAINER_SCRIPT}"
machinectl shell "root@${CONTAINER_NAME}" /bin/bash -c "chmod +x /root/${CONTAINER_SCRIPT} && /root/${CONTAINER_SCRIPT}"

## Fix `Operation not permitted` in container
# systemd-nspawn -D "${CONTAINER_PATH}" --private-users=0 --private-users-chown

## Using host networking
# sed -i "/^\[Network\]/a\VirtualEthernet=no" "/etc/systemd/nspawn/${CONTAINER_NAME}.nspawn"

## systemd-nspawn containers with working FUSE
## https://gist.github.com/logarytm/c94d38eb91563c33a7cae7ac83ca3793
# sudo machinectl status "${CONTAINER_NAME}" >> /dev/null 2>&1 && \
#     sudo machinectl shell "root@${CONTAINER_NAME}" /bin/bash || \
#     sudo systemd-nspawn \
#         --bind=/media/usb-drive:/media/usb-drive \
#         --property DeviceAllow='/dev/fuse rwm' \
#         --machine="${CONTAINER_NAME}"
#         -bD "${CONTAINER_PATH}" "$@"
# # and then run this in container
# sudo mknod -m 666 /dev/fuse c 10 229

## Logging into a Container
# machinectl login "${CONTAINER_NAME}"
# machinectl shell "root@${CONTAINER_NAME}"

## Enable systemd-networkd in container
# systemctl enable systemd-networkd && \
#     systemctl start systemd-networkd && \
#     systemctl enable systemd-resolved && \
#     systemctl start systemd-resolved

## Disable IPv6 in container
# echo 'net.ipv6.conf.all.disable_ipv6 = 1' | tee -a "/etc/sysctl.conf" >/dev/null
# echo 'net.ipv6.conf.default.disable_ipv6 = 1' | tee -a "/etc/sysctl.conf" >/dev/null

# Checking Container State
machinectl list

# stop the container from within the guest OS by running `halt`

## Stopping a Container
# systemctl stop "systemd-nspawn@${CONTAINER_NAME}"
# machinectl poweroff "${CONTAINER_NAME}"

## Resource control
# systemd-cgtop
# systemctl set-property "systemd-nspawn@${CONTAINER_NAME}.service" MemoryMax=2G
# systemctl set-property "systemd-nspawn@${CONTAINER_NAME}.service" CPUQuota=200%

## machinectl
## https://man.archlinux.org/man/machinectl.1
# machinectl list
# machinectl show "${CONTAINER_NAME}"
# machinectl shell "root@${CONTAINER_NAME}"
# machinectl shell --setenv=SHELL=/usr/bin/zsh "root@${CONTAINER_NAME}" /usr/bin/zsh -l
# machinectl login "${CONTAINER_NAME}"
# machinectl start "${CONTAINER_NAME}"
# machinectl status "${CONTAINER_NAME}"
# machinectl reboot "${CONTAINER_NAME}"
# machinectl terminate "${CONTAINER_NAME}"
# machinectl poweroff "${CONTAINER_NAME}"
# machinectl remove "${CONTAINER_NAME}"

## systemd toolchain
## See journal logs for a particular machine:
# journalctl -M "${CONTAINER_NAME}"
## Show control group contents:
# systemd-cgls -M "${CONTAINER_NAME}"
## See startup time of container:
# systemd-analyze -M "${CONTAINER_NAME}"
## For an overview of resource usage:
# systemd-cgtop


## Install OpenMediaVault in container
## OpenMediaVault 6.x (shaitan)
## https://omv-extras.org/
tee "$PWD/rc-local.service" >/dev/null <<-'EOF'
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

CONTAINER_SCRIPT="omv-extras_installer-${CONTAINER_NAME}.sh"
tee "$PWD/${CONTAINER_SCRIPT}" >/dev/null <<-'EOF'
#!/usr/bin/env bash

# PROXY_ADDRESS="http://localhost:7890"
if [[ -n "${PROXY_ADDRESS}" ]]; then
    export {http,https,ftp,all}_proxy="${PROXY_ADDRESS}"
    export {HTTP,HTTPS,FTP,ALL}_PROXY="${PROXY_ADDRESS}"
fi

apt update
apt install -y curl wget gnupg postfix

# fix postfix install error
sed -i "s/^myhostname =.*/myhostname = ${HOSTNAME}/" /etc/postfix/main.cf

APT_MIRROR_URL="mirror.sjtu.edu.cn"
OMV_MIRROR_URL="mirrors.tuna.tsinghua.edu.cn"

DOWNLOAD_URL="https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install"
curl -fsSL -o "$HOME/omv_installer.sh" "${DOWNLOAD_URL}"

[[ ! -s "$HOME/omv_installer.sh" ]] && exit 1

chmod +x "$HOME/omv_installer.sh"

"$HOME/omv_installer.sh" -n

## Failed to configure repo 'deb https://openmediavault-plugin-developers.github.io/packages/debian shaitan main':
## Error: HTTP 599: Timeout while connecting reading https://openmediavault-plugin-developers.github.io/packages/debian/omvextras2026.asc
# OMV_EXTRAS_KEY="https://openmediavault-plugin-developers.github.io/packages/debian/omvextras2026.asc"
# curl -fsSL -o "$HOME/omvextras2026.asc" "${OMV_EXTRAS_KEY}"
# gpg --import "$HOME/omvextras2026.asc"
omv-salt deploy run omvextras

"$HOME/omv_installer.sh" -n

sed -i "s|download.docker.com|${APT_MIRROR_URL}/docker-ce|g" "/etc/apt/sources.list.d/omvextras.list"
sed -i "s|http://httpredir.debian.org|https://${APT_MIRROR_URL}|g" "/etc/apt/sources.list.d/openmediavault-kernel-backports.list"
sed -i "s|http://security.debian.org|https://${APT_MIRROR_URL}|g" "/etc/apt/sources.list.d/openmediavault-os-security.list"

apt update && apt upgrade -y

# Enable /etc/rc.local with Systemd
printf '%s\n' '#!/bin/bash' '' 'exit 0' | tee -a /etc/rc.local
chmod +x /etc/rc.local
systemctl enable rc-local
systemctl start rc-local
# systemctl status rc-local
EOF

machinectl copy-to "${CONTAINER_NAME}" "$PWD/rc-local.service" "/etc/systemd/system/rc-local.service"
machinectl copy-to "${CONTAINER_NAME}" "$PWD/${CONTAINER_SCRIPT}" "/root/${CONTAINER_SCRIPT}"

# machinectl shell "root@${CONTAINER_NAME}" /bin/bash -c "sed -i '/^exit 0/i mkdir -p /run/php' /etc/rc.local"
machinectl shell "root@${CONTAINER_NAME}" /bin/bash -c "chmod +x /root/${CONTAINER_SCRIPT} && /root/${CONTAINER_SCRIPT}"

## OpenMediaVault 5.x (usul)
## https://openmediavault.readthedocs.io/en/5.x/installation/on_debian.html
# apt-get install --y gnupg
# wget -O "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc" "https://packages.openmediavault.org/public/archive.key"
# apt-key add "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc"

# OMV_MIRROR_URL="mirrors.tuna.tsinghua.edu.cn"
# cat <<EOF > /etc/apt/sources.list.d/openmediavault.list
# deb https://${OMV_MIRROR_URL}/OpenMediaVault/public usul main
# deb https://${OMV_MIRROR_URL}/OpenMediaVault/packages usul main
# ## Uncomment the following line to add software from the proposed repository.
# # deb https://${OMV_MIRROR_URL}/OpenMediaVault/public usul-proposed main
# # deb https://${OMV_MIRROR_URL}/OpenMediaVault/packages usul-proposed main
# ## This software is not part of OpenMediaVault, but is offered by third-party
# ## developers as a service to OpenMediaVault users.
# # deb https://${OMV_MIRROR_URL}/OpenMediaVault/public usul partner
# # deb https://${OMV_MIRROR_URL}/OpenMediaVault/packages usul partner
# EOF

# export LANG=C.UTF-8
# export DEBIAN_FRONTEND=noninteractive
# export APT_LISTCHANGES_FRONTEND=none
# apt-get update
# apt-get --yes --auto-remove --show-upgraded \
#     --allow-downgrades --allow-change-held-packages \
#     --no-install-recommends \
#     --option DPkg::Options::="--force-confdef" \
#     --option DPkg::Options::="--force-confold" \
#     install openmediavault-keyring openmediavault

# omv-confdbadm populate


## Auto poweroff on 23:00
# tee "$HOME/shutdown_cron.sh" >/dev/null <<-'EOF'
# #!/usr/bin/env bash
# CONTAINER_NAME="omv"
# CONTAINER_PATH="/var/lib/machines/${CONTAINER_NAME}"
# machinectl poweroff "${CONTAINER_NAME}"
# sync
# shutdown -h +5 "System will shutdown after 5 minutes"
# EOF
# (crontab -l 2>/dev/null || true; echo "0 23 * * * $HOME/shutdown_cron.sh") | crontab -

# sudo tee "/root/shutdown_cron.sh" >/dev/null <<-'EOF'
# #!/usr/bin/env bash
# sync
# shutdown -h +5 "System will shutdown after 5 minutes"
# EOF
# (sudo crontab -l -u root 2>/dev/null || true; echo "0 23 * * * /root/shutdown_cron.sh") | sudo crontab -u root -


## Fix: can’t lock file ‘/var/lock/qemu-server/lock-xxx.conf’ -got timeout
# rm /var/lock/qemu-server/lock-xxx.conf
# qm stop xxx


## Resize pve-root
# df -Th
## Delete local-lvm storage in gui
# lvremove /dev/pve/data
# lvresize -l +100%FREE /dev/pve/root
# resize2fs /dev/mapper/pve-root
## Check disk space after
# df -Th
