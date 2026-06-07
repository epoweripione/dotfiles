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

# [Run Windows apps on Linux with WinApps](https://github.com/winapps-org/winapps)

## Installation
## Step 1: Configure a Windows VM
## - [Creating a Windows VM with Docker or Podman](https://github.com/winapps-org/winapps/blob/main/docs/docker.md)
## - [Windows inside a Docker container](https://github.com/dockur/windows)
# cd "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro" && docker compose --file winapps_compose.yml up -d
## Access the Windows virtual machine via a VNC connection to complete the Windows setup by navigating to:
## http://127.0.0.1:8006

## - [Creating a Windows VM with libvirt](https://github.com/winapps-org/winapps/blob/main/docs/libvirt.md)

# RDP settings
RDP_USER=${1:-"Win11"}
RDP_PASS=${2:-"PassWord@Win11"}

# libvirt settings
VM_NAME=${3:-"win11"}
# VM_IP=$(sudo virsh domifaddr "${VM_NAME}" | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}')

# Step 2: Install Dependencies
InstallList=(
    "curl"
    "dialog"
    "freerdp"
    "git"
    "iproute2"
    "libnotify"
    "openbsd-netcat"
    "yad"
)
InstallSystemPackages "" "${InstallList[@]}"

# Step 3: Create a WinApps Configuration File
mkdir -p "${HOME}/winapps/"
mkdir -p "$HOME/.config/winapps/"
tee "$HOME/.config/winapps/winapps.conf" >/dev/null <<-EOF
##################################
#   WINAPPS CONFIGURATION FILE   #
##################################

# INSTRUCTIONS
# - Leading and trailing whitespace are ignored.
# - Empty lines are ignored.
# - Lines starting with '#' are ignored.
# - All characters following a '#' are ignored.

# [WINDOWS USERNAME]
RDP_USER="${RDP_USER}"

# [WINDOWS PASSWORD]
# NOTES:
# - If using FreeRDP v3.9.0 or greater, you *have* to set a password
# - RDP_ASKPASS is provided as a more secure option to RDP_PASS:
#   - Calls an external command and uses its stdout as the password
#   - The password is not passed on the command line to freerdp, keeping it out of logs
#   - If specified, takes precedence over RDP_PASS
#   - Examples to use this:
#     - RDP_ASKPASS="~/some-custom-command"
#     - RDP_ASKPASS="bash -c 'cat ~/.some-secret-file'"
#     - RDP_ASKPASS="bash -c 'kwallet-query --folder winapps --read-password rdp kdewallet'"
#
RDP_PASS="${RDP_PASS}"
# RDP_ASKPASS="bash -c 'kwallet-query --folder winapps --read-password rdp kdewallet'"

# [WINDOWS DOMAIN]
# DEFAULT VALUE: '' (BLANK)
RDP_DOMAIN=""

# [WINDOWS IPV4 ADDRESS]
# NOTES:
# - If using 'libvirt', 'RDP_IP' will be determined by WinApps at runtime if left unspecified.
# DEFAULT VALUE:
# - 'docker': '127.0.0.1'
# - 'podman': '127.0.0.1'
# - 'libvirt': '' (BLANK)
RDP_IP="127.0.0.1"

# [RDP PORT]
# NOTES:
# - For Docker and Podman, this is the host port mapped to Windows port 3389.
# - If you changed the host-side RDP port in compose.yaml, set this to match.
# DEFAULT VALUE: '3389'
RDP_PORT="3389"

# [VM NAME]
# NOTES:
# - Only applicable when using 'libvirt'
# - The libvirt VM name must match so that WinApps can determine VM IP, start the VM, etc.
# DEFAULT VALUE: 'RDPWindows'
VM_NAME="${VM_NAME}"

# [WINAPPS BACKEND]
# DEFAULT VALUE: 'docker'
# VALID VALUES:
# - 'docker'
# - 'podman'
# - 'libvirt'
# - 'manual'
WAFLAVOR="docker"

# [DISPLAY SCALING FACTOR]
# NOTES:
# - If an unsupported value is specified, a warning will be displayed.
# - If an unsupported value is specified, WinApps will use the closest supported value.
# DEFAULT VALUE: '100'
# VALID VALUES:
# - '100'
# - '140'
# - '180'
RDP_SCALE="100"

# [MOUNTING REMOVABLE PATHS FOR FILES]
# NOTES:
# - By default, 'udisks' (which you most likely have installed) uses /run/media for mounting removable devices.
#   This improves compatibility with most desktop environments (DEs).
# ATTENTION: The Filesystem Hierarchy Standard (FHS) recommends /media instead. Verify your system's configuration.
# - To manually mount devices, you may optionally use /mnt.
# REFERENCE: https://wiki.archlinux.org/title/Udisks#Mount_to_/media
REMOVABLE_MEDIA="/run/media"

# [ADDITIONAL FREERDP FLAGS & ARGUMENTS]
# NOTES:
# - You can try adding /network:lan to these flags in order to increase performance, however, some users have faced issues with this.
#   If this does not work or if it does not work without the flag, you can try adding /nsc and /gfx.
# DEFAULT VALUE: '/cert:tofu /sound /microphone +home-drive'
# VALID VALUES: See https://github.com/awakecoding/FreeRDP-Manuals/blob/master/User/FreeRDP-User-Manual.markdown
RDP_FLAGS="/cert:tofu /sound /microphone +home-drive"

# [NON FULL WINDOWS RDP FLAGS]
# NOTES:
# - Use these flags to pass specific flags to the freerdp command when you are starting a non-full RDP session (any other command than winapps windows)
# DEFAULT_VALUES: ''
# VALID_VALUES: See https://github.com/awakecoding/FreeRDP-Manuals/blob/master/User/FreeRDP-User-Manual.markdown
RDP_FLAGS_NON_WINDOWS=""

# [FULL WINDOWS RDP FLAGS]
# NOTES:
# - Use these flags to pass specific flags to the freerdp command when you are starting a full RDP session (winapps windows)
# DEFAULT_VALUES: ''
# VALID_VALUES: See https://github.com/awakecoding/FreeRDP-Manuals/blob/master/User/FreeRDP-User-Manual.markdown
RDP_FLAGS_WINDOWS=""

# [DEBUG WINAPPS]
# NOTES:
# - Creates and appends to ~/.local/share/winapps/winapps.log when running WinApps.
# DEFAULT VALUE: 'true'
# VALID VALUES:
# - 'true'
# - 'false'
DEBUG="true"

# [AUTOMATICALLY PAUSE WINDOWS]
# NOTES:
# - This is currently INCOMPATIBLE with 'manual'.
# DEFAULT VALUE: 'off'
# VALID VALUES:
# - 'on'
# - 'off'
AUTOPAUSE="off"

# [AUTOMATICALLY PAUSE WINDOWS TIMEOUT]
# NOTES:
# - This setting determines the duration of inactivity to tolerate before Windows is automatically paused.
# - This setting is ignored if 'AUTOPAUSE' is set to 'off'.
# - The value must be specified in seconds (to the nearest 10 seconds e.g., '30', '40', '50', etc.).
# - For RemoteApp RDP sessions, there is a mandatory 20-second delay, so the minimum value that can be specified here is '20'.
# - Source: https://techcommunity.microsoft.com/t5/security-compliance-and-identity/terminal-services-remoteapp-8482-session-termination-logic/ba-p/246566
# DEFAULT VALUE: '300'
# VALID VALUES: >=20
AUTOPAUSE_TIME="300"

# [FREERDP COMMAND]
# NOTES:
# - WinApps will attempt to automatically detect the correct command to use for your system.
# DEFAULT VALUE: '' (BLANK)
# VALID VALUES: The command required to run FreeRDPv3 on your system (e.g., 'xfreerdp', 'xfreerdp3', etc.).
FREERDP_COMMAND=""

# [TIMEOUTS]
# NOTES:
# - These settings control various timeout durations within the WinApps setup.
# - Increasing the timeouts is only necessary if the corresponding errors occur.
# - Ensure you have followed all the Troubleshooting Tips in the error message first.

# PORT CHECK
# - The maximum time (in seconds) to wait when checking if the RDP port on Windows is open.
# - Corresponding error: "NETWORK CONFIGURATION ERROR" (exit status 13).
# DEFAULT VALUE: '5'
PORT_TIMEOUT="5"

# RDP CONNECTION TEST
# - The maximum time (in seconds) to wait when testing the initial RDP connection to Windows.
# - Corresponding error: "REMOTE DESKTOP PROTOCOL FAILURE" (exit status 14).
# DEFAULT VALUE: '30'
RDP_TIMEOUT="30"

# APPLICATION SCAN
# - The maximum time (in seconds) to wait for the script that scans for installed applications on Windows to complete.
# - Corresponding error: "APPLICATION QUERY FAILURE" (exit status 15).
# DEFAULT VALUE: '60'
APP_SCAN_TIMEOUT="60"

# WINDOWS BOOT
# - The maximum time (in seconds) to wait for the Windows VM to boot if it is not running, before attempting to launch an application.
# DEFAULT VALUE: '120'
BOOT_TIMEOUT="120"

# FREERDP RAIL HIDEF
# - This option controls the value of the 'hidef' option passed to the /app parameter of the FreeRDP command.
# - Setting this option to 'off' may resolve window misalignment issues related to maximized windows.
# DEFAULT VALUE: 'on'
HIDEF="on"
EOF

chown "$(whoami)":"$(whoami)" ~/.config/winapps/winapps.conf
chmod 600 ~/.config/winapps/winapps.conf


## Step 4: Test FreeRDP
# xfreerdp3 /u:"MyWindowsUser" /p:"MyWindowsPassword" /v:127.0.0.1:3389 /cert:tofu

## Or, if you are using Podman
# podman unshare --rootless-netns xfreerdp3 /u:"MyWindowsUser" /p:"MyWindowsPassword" /v:127.0.0.1:3389 /cert:tofu

## Or, if you installed FreeRDP using Flatpak
# flatpak run --command=xfreerdp com.freerdp.FreeRDP /u:"MyWindowsUser" /p:"MyWindowsPassword" /v:127.0.0.1:3389 /cert:tofu


# Step 5: Run the WinApps Installer
bash <(curl https://raw.githubusercontent.com/winapps-org/winapps/main/setup.sh)

# Once WinApps is installed, a list of additional arguments can be accessed by running:
winapps-setup --help


# Adding Additional Pre-defined Applications
# Adding your own applications with custom icons and MIME types to the installer is easy.
# Simply copy one of the application configurations in the apps folder located within the WinApps repository, and:
# - Modify the name and variables to reflect the appropriate/desired values for your application.
# - Replace icon.svg with an SVG for your application (ensuring the icon is appropriately licensed).
# - Remove and reinstall WinApps.
# - Submit a pull request to add your application to WinApps as a community tested application once you have tested and verified your configuration (optional, but encouraged).

# Running Applications Manually
# WinApps offers a manual mode for running applications that were not configured by the WinApps installer.
# This is completed with the manual flag. Executables that are in the Windows PATH do not require full path definition.
# - winapps manual "C:\my\directory\executableNotInPath.exe"
# - winapps manual executableInPath.exe

# Updating WinApps
# The installer can be run multiple times. To update your installation of WinApps:
# - Run the WinApps installer to remove WinApps from your system.
# - Pull the latest changes from the WinApps GitHub repository.
# - Re-install WinApps using the WinApps installer by running `winapps-setup`.


# [WinApps-Launcher](https://github.com/winapps-org/winapps-launcher)
