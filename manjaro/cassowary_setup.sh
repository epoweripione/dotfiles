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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# Cassowary: Run Windows Applications on Linux as if they are native
# https://github.com/casualsnek/cassowary
APP_INSTALL_NAME="cassowary"
GITHUB_REPO_NAME="casualsnek/cassowary"

CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)


## Setting up a Windows VM with virt-manager
## https://github.com/casualsnek/cassowary/blob/main/docs/1-virt-manager.md
## CPU configuration
# <clock offset="localtime">
#   <timer name="hpet" present="yes"/>
#   <timer name="hypervclock" present="yes"/>
# </clock>
## In the `SATA Disk 1` tab set the Disk bus to `VirtIO`
## Move over to `NIC` section and set Device model to `virtio`
## Login to `Windows desktop` then open `This PC` and browse to virtio-win CD drive and install `virtio-win-gt-x64.exe`
## It's also suggested to install the `spice guest tools` to also enable copy-paste between host and guest
## Shut down the VM and from the menubar select `View` and then Details
## Go to `Display Spice` section and set `Listen Type` to None; also check the `OpenGL` option and click Apply
## Go to `Video QXL` section and set Model to `VirtIO` and check the `3D acceleration` option


# On Windows (guest)
# Open Settings, click on System, scroll to bottom and click on `Remote desktop` then click on `Enable Remote Desktop` and click confirm
# Download latest .zip from the release page
# https://github.com/casualsnek/cassowary/releases/download/${REMOTE_VERSION}/cassowary-${REMOTE_VERSION}-winsetup.zip
# Extract the downloaded .zip file
# Double click on setup.bat located on extracted directory
# Logout and login again to windows session


# On Linux (host)
# Python
[[ -s "${MY_SHELL_SCRIPTS}/installer/python_pip_config.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/python_pip_config.sh"

# Cassowary
colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
DOWNLOAD_FILENAME="${WORKDIR}/cassowary-${REMOTE_VERSION}-py3-none-any.whl"
DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/${REMOTE_VERSION}/cassowary-${REMOTE_VERSION}-py3-none-any.whl"

colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
curl_download_status=$?

if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
    DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
    curl_download_status=$?
fi

if [[ ${curl_download_status} -eq 0 ]]; then
    sudo pacman --noconfirm --needed -S freerdp libvirt-python

    python3 -m pip install --user -U PyQt5

    pip install "${DOWNLOAD_FILENAME}"
fi

# $HOME/.config/casualrdh/config.json
# $HOME/.config/casualrdh/casualrdh.log

## Launch cassowary configuration utility with:
# python3 -m cassowary -a

## Head over to Misc tab and click on "Setup Autostart" and "Create".
## This will bring cassowary to your application menu and setup background service autostart;
## Enter the VM name from the VM setup step;
## Click on "Save changes" and then on "Autodetect", this should automatically fill up the VM IP;
## Click "Save changes" again then click "Autofill host/username" then enter the password you set during the windows setup.
## Then click "Save changes" again;
## Now goto "Guest app" tab and create shortcut for any application you want.

## Now you can find application on your application menu 
## which you can use to launch apps easily You can explore other commandline usage of cassowary by running:
# python -m cassowary -h

## Launch VM
# xfreerdp /d:"{domain}" /u:"{user}" /p:"{passd}" /v:"{ip}" \
#     +auto-reconnect +clipboard +decorations -wallpaper \
#     /f /floatbar:sticky:on,default:visible,show:always \
#     /a:drive,root,"$HOME"  \
#     /cert-ignore /span /wm-class:"cassowary" 1>/dev/null 2>&1 &

# Installing desktop menu items
# https://linux.die.net/man/1/xdg-desktop-menu
mkdir -p "$HOME/.local/share/desktop-directories"
tee "$HOME/.local/share/desktop-directories/CasualRDH-apps.directory" >/dev/null <<-'EOF'
[Desktop Entry]
Version=1.0
Type=Directory
Name=CasualRDH
Name[zh_CN]=CasualRDH 应用
Icon=distributor-logo-windows
EOF

grep -E 'Cassowary|CasualRDH;' "$HOME/.local/share/applications/"* | cut -d: -f1 \
    | xargs --no-run-if-empty -n1 xdg-desktop-menu install --noupdate \
        "$HOME/.local/share/desktop-directories/CasualRDH-apps.directory"

xdg-desktop-menu forceupdate


cd "${CURRENT_DIR}" || exit