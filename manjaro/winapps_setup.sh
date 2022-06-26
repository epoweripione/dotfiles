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

# Run Windows apps
# https://github.com/Osmium-Linux/winapps
Git_Clone_Update_Branch "Osmium-Linux/winapps" "$HOME/winapps"

## Set up KVM to run as your user instead of root and allow it through AppArmor
# sudo sed -i "s/#user = \"root\"/user = \"$(id -un)\"/g" "/etc/libvirt/qemu.conf"
# sudo sed -i "s/#group = \"root\"/group = \"$(id -gn)\"/g" "/etc/libvirt/qemu.conf"
# sudo usermod -a -G kvm "$(id -un)"
# sudo usermod -a -G libvirt "$(id -un)"
# sudo systemctl restart libvirtd
## sudo ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
# sleep 5

VM_NAME=${1:-"win11"}
RDP_USER=${2:-"Win11"}
RDP_PASS=${3:-"PassWord@Win11"}


VM_IP=$(sudo virsh domifaddr "${VM_NAME}" | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}')

mkdir -p "$HOME/.config/winapps/"
tee "$HOME/.config/winapps/winapps.conf" >/dev/null <<-EOF
RDP_USER="${RDP_USER}"
RDP_PASS="${RDP_PASS}"
#RDP_DOMAIN="MYDOMAIN"
RDP_IP="${VM_IP}"
#RDP_SCALE=100
#RDP_FLAGS=""
#MULTIMON="true"
#DEBUG="true"
#VIRT_MACHINE_NAME="machine-name"
#VIRT_NEEDS_SUDO="true"
#RDP_SECRET="account"
EOF

# add the RDP password for lookup using secret tool
secret-tool store --label='winapps' winapps account

if [[ -d "$HOME/winapps" ]]; then
    cd "$HOME/winapps" && bin/winapps check
    ./installer.sh --user
fi

# Keyboard layout
# xfreerdp /kbd-list | grep "Chinese"

## xfreerdp options
# if [[ -s "$HOME/.local/bin/winapps" ]]; then
#     sed -i 's|+clipboard|/floatbar:sticky:on,default:visible,show:always +clipboard|g' "$HOME/.local/bin/winapps"
#     sed -i 's/+clipboard/+clipboard +aero +menu-anims +gestures +multitouch/g' "$HOME/.local/bin/winapps"
# fi

## BIN_PATH="${HOME}/.local/bin"
## APP_PATH="${HOME}/.local/share/applications"
## SYS_PATH="${HOME}/.local/share/winapps"

## Run windows apps
## Microsoft Word (Office 365)
# cd "$HOME/winapps" && ./bin/winapps manual "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"


# Installing desktop menu items
# https://linux.die.net/man/1/xdg-desktop-menu
mkdir -p "$HOME/.local/share/desktop-directories"
tee "$HOME/.local/share/desktop-directories/WinApps-apps.directory" >/dev/null <<-'EOF'
[Desktop Entry]
Version=1.0
Type=Directory
Name=WinApps
Name[zh_CN]=Windows 应用
Icon=distributor-logo-windows
EOF

grep 'WinApps;' "$HOME/.local/share/applications/"* | cut -d: -f1 \
    | xargs --no-run-if-empty -n1 xdg-desktop-menu install --noupdate \
        "$HOME/.local/share/desktop-directories/WinApps-apps.directory"

xdg-desktop-menu forceupdate


cd "${CURRENT_DIR}" || exit