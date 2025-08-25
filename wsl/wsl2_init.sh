#!/usr/bin/env bash

## https://docs.microsoft.com/zh-cn/windows/wsl/
## https://docs.microsoft.com/zh-cn/windows/wsl/wsl-config

## Please make sure that virtualization is enabled inside BIOS

## https://learn.microsoft.com/en-us/windows/wsl/install
## 1. run PowerShell as Admin
# wsl --list --online
## wsl --install -d <DistroName>
# wsl --install -d Debian
# wsl --status

# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
# Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
## or:
# dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
# dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
## 2. restart computer
## 3. make WSL 2 as default architecture
# wsl --set-default-version 2
## 4. install distro from Microsoft Store (https://aka.ms/wslstore)
## 5. list installed distro
# wsl -l
## 6. set a distro to be backed by WSL 2
# wsl --set-version Debian 2
## 5. verify what versions of WSL each distro is using
# wsl -l -v
## set default distro
# wsl --set-default Debian
## restart wsl in PowerShell
# Restart-Service -Name LxssManager
# net stop "LxssManager"; net start "LxssManager"

## Uninstall distro
# wsl --set-default Ubuntu
# wsl --unregister Debian
## Then uninstall `Debian` from `Start Menu`
## Restart Computer

## Sharing your WSL2 environment with Linux
## https://www.nmelnick.com/2020/07/sharing-your-wsl2-environment-with-linux/
# sudo apt install -y libguestfs-tools
# sudo yum install -y libguestfs libguestfs-tools
## `WSL2` also need a kernel
# sudo apt install -y linux-image-generic
## Virtual machine disk image file:
## Ubuntu distro: /mnt/c/Users/<username>/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/ext4.vhdx
## Debian distro: /mnt/c/Users/<username>/AppData/Local/Packages/TheDebianProject.DebianGNULinux_76v4gfsz19hv4/LocalState/ext4.vhdx
## list distro filesystems
# sudo virt-filesystems -a <image file>
## mount Debian distro
# sudo mkdir -p /mnt/wslDebian
# sudo guestmount -o allow_other \
#     -a /mnt/c/Users/<username>/AppData/Local/Packages/TheDebianProject.DebianGNULinux_76v4gfsz19hv4/LocalState/ext4.vhdx \
#     -i /mnt/wslDebian
## unmount Debian distro
# sudo guestunmount /mnt/wslDebian


[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

if ! check_os_wsl; then
    colorEcho "${RED}Please run this script in ${FUCHSIA}WSL(Windows Subsystem for Linux)${RED}!"
    exit 0
fi

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# Check & set global proxy
setGlobalProxies

# Custom WSL settings
colorEcho "${BLUE}Custom WSL settings..."
# [Advanced settings configuration in WSL](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)
# make drives mounted at /c or /e instead of /mnt/c and /mnt/e.
if ! grep -q "automount" /etc/wsl.conf 2>/dev/null; then
    sudo tee /etc/wsl.conf >/dev/null <<-'EOF'
[automount]
enabled = true
root = /
options = "metadata,umask=22,fmask=11"
mountFsTab = false

[interop]
enabled = true
appendWindowsPath = false

[boot]
systemd = true
command = export PATH="$PATH:/c/Windows/System32"
# command = export PATH="$PATH:/c/Users/${USERPROFILE}/AppData/Local/Programs/Microsoft VS Code/bin"
EOF
fi

# colorEcho "${BLUE}map localhost to \`vEthernet (WSL)\` ip${BLUE}..."
# source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/wsl/wsl2-map-win-localhost.sh"


# Install packages
# Use apt mirror & Install pre-requisite packages
[[ -z "${MIRROR_PACKAGE_MANAGER_APT}" ]] && MIRROR_PACKAGE_MANAGER_APT="mirrors.sustech.edu.cn"
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    colorEcho "${BLUE}Setting apt mirror..."
    [[ -f "/etc/apt/sources.list" ]] && \
        sudo sed -i \
            -e "s|ftp.debian.org|${MIRROR_PACKAGE_MANAGER_APT}|g" \
            -e "s|deb.debian.org|${MIRROR_PACKAGE_MANAGER_APT}|g" \
            -e "s|security.debian.org/debian-security|${MIRROR_PACKAGE_MANAGER_APT}/debian-security|g" \
            -e "s|security.debian.org |${MIRROR_PACKAGE_MANAGER_APT}/debian-security |g" "/etc/apt/sources.list"

    [[ -f "/etc/apt/sources.list.d/debian.sources" ]] && \
        sudo sed -i \
            -e "s|ftp.debian.org|${MIRROR_PACKAGE_MANAGER_APT}|g" \
            -e "s|deb.debian.org|${MIRROR_PACKAGE_MANAGER_APT}|g" "/etc/apt/sources.list.d/debian.sources"
fi

colorEcho "${BLUE}Installing ${FUCHSIA}pre-requisite packages${BLUE}..."
sudo apt update && \
    sudo apt install -y apt-transport-https apt-utils ca-certificates \
        lsb-release software-properties-common curl wget gnupg2 sudo

# Add custom repositories
colorEcho "${BLUE}Add ${FUCHSIA}custom repositories${BLUE}..."
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    # Use https mirror
    [[ -f "/etc/apt/sources.list" ]] && \
        sudo sed -i "s|http://${MIRROR_PACKAGE_MANAGER_APT}|https://${MIRROR_PACKAGE_MANAGER_APT}|g" "/etc/apt/sources.list"

    [[ -f "/etc/apt/sources.list.d/debian.sources" ]] && \
        sudo sed -i "s|http://${MIRROR_PACKAGE_MANAGER_APT}|https://${MIRROR_PACKAGE_MANAGER_APT}|g" "/etc/apt/sources.list.d/debian.sources"

    sudo apt update
fi

## [Share Environment Vars between WSL and Windows](https://devblogs.microsoft.com/commandline/share-environment-vars-between-wsl-and-windows/)
## cmd
# setx WSLENV USERPROFILE/p:APPDATA/p:
## powershell
# [Environment]::SetEnvironmentVariable("WSLENV", $env:WSLENV + "USERPROFILE/p:APPDATA/p:", [System.EnvironmentVariableTarget]::User)

# [wslu - A collection of utilities for WSL](https://github.com/wslutilities/wslu)
if [[ ! -x "$(command -v wslfetch)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}wslu${BLUE}..."
    # wget -O - https://pkg.wslutiliti.es/public.key | sudo tee -a "/etc/apt/trusted.gpg.d/wslu.asc" >/dev/null
    # if ! grep -q "^deb https://pkg.wslutiliti.es/debian" "/etc/apt/sources.list" 2>/dev/null; then
    #     RELEASE_CODENAME=$(lsb_release -c | awk '{print $2}')
    #     # RELEASE_CODENAME=$(dpkg --status tzdata | grep Provides | cut -f2 -d'-')
    #     echo "deb https://pkg.wslutiliti.es/debian ${RELEASE_CODENAME} main" | sudo tee -a "/etc/apt/sources.list" >/dev/null
    # fi
    curl -sL https://raw.githubusercontent.com/wslutilities/wslu/master/extras/scripts/wslu-install | bash
fi

## git lfs
## https://github.com/git-lfs/git-lfs/wiki/Tutorial
# if [[ ! -e "/etc/apt/sources.list.d/github_git-lfs.list" ]]; then
#     curl -fsSL "https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh" | sudo bash

#     # echo 'Acquire::http::Proxy::packagecloud-repositories.s3.dualstack.us-west-1.amazonaws.com "http://127.0.0.1:7890/";' \
#     #     | sudo tee -a /etc/apt/apt.conf.d/99proxy >/dev/null
# fi

## .NET Core SDK
## https://docs.microsoft.com/zh-cn/dotnet/core/install/linux-debian
# if [[ ! -e "/etc/apt/sources.list.d/microsoft-prod.list" ]]; then
#     curl "${CURL_DOWNLOAD_OPTS[@]}" -o packages-microsoft-prod.deb "https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb" && \
#         sudo dpkg -i packages-microsoft-prod.deb && \
#         rm packages-microsoft-prod.deb

#     # echo 'Acquire::http::Proxy::packages.microsoft.com "http://127.0.0.1:7890/";' \
#     #     | sudo tee -a /etc/apt/apt.conf.d/99proxy >/dev/null
# fi

## yarn
## https://yarnpkg.com/zh-Hans/docs/install
# if [[ ! -e "/etc/apt/sources.list.d/yarn.list" ]]; then
#     curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
#     echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
# fi


# Update all repositories & Upgrade
colorEcho "${BLUE}Updating ${FUCHSIA}all repositories & Upgrade${BLUE}..."
sudo apt update && sudo apt upgrade -y


# Install useful packages
colorEcho "${BLUE}Installing ${FUCHSIA}Pre-requisite packages${BLUE}..."
sudo apt install -y binutils build-essential di dnsutils g++ gcc keychain \
    git htop iproute2 make net-tools netcat-openbsd p7zip-full psmisc tree unzip zip

## Login with SSH Key
# pssh -i -H "host01 host02" -l root \
#     -x "-o StrictHostKeyChecking=no -i $HOME/.ssh/id_ecdsa" \
#     "hostname -i && uname -a"
## Login with Passphrase Protected SSH Key ( all hosts in ~/.ssh/config )
# pssh -i -H "host01 host02" -A -l root "hostname -i && uname -a"


## Enable broadcast WINS
# colorEcho "${BLUE}Enable broadcast ${FUCHSIA}WINS${BLUE}..."
# sudo apt install -y libnss-winbind
# if ! grep -q "wins" "/etc/nsswitch.conf" 2>/dev/null; then
#     sudo sed -i 's/ dns$/ wins dns/' "/etc/nsswitch.conf"
# fi
# sudo service winbind start # /etc/init.d/winbind start


# fix ping: socket: Operation not permitted
sudo chmod u+s /bin/ping


## wslu
## https://github.com/wslutilities/wslu
# sudo apt install -y gnupg2 apt-transport-https && \
#     wget -O - https://access.patrickwu.space/wslu/public.asc | sudo apt-key add - && \
#     echo "deb https://access.patrickwu.space/wslu/debian buster main" | sudo tee -a /etc/apt/sources.list && \
#     sudo apt update && \
#     sudo apt install -y wslu

## translate from a Windows path to a WSL path
# wslpath 'c:\users'


# colorEcho "${BLUE}Install git lfs${BLUE}..."
# sudo apt install -y git-lfs && git lfs install

[[ -s "${MY_SHELL_SCRIPTS}/installer/git-lfs_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/git-lfs_installer.sh"

[[ -s "${MY_SHELL_SCRIPTS}/installer/gitflow_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/gitflow_installer.sh"

[[ -s "${MY_SHELL_SCRIPTS}/installer/cargo_rust_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/cargo_rust_installer.sh"

[[ -s "${MY_SHELL_SCRIPTS}/installer/goup_go_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/goup_go_installer.sh"

[[ -s "${MY_SHELL_SCRIPTS}/nodejs/nvm_node_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/nodejs/nvm_node_installer.sh"

[[ -s "${MY_SHELL_SCRIPTS}/installer/python_pip_config.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/python_pip_config.sh"

# Parallel SSH Tools
# https://github.com/lilydjwg/pssh
# https://www.escapelife.site/posts/8c0f83d.html
pip_Package_Install git+https://github.com/lilydjwg/pssh

# colorEcho "${BLUE}Installing ${FUCHSIA}.NET Core SDK${BLUE}..."
## sudo apt install -y dotnet-sdk-5.0
## https://docs.microsoft.com/zh-cn/dotnet/core/tools/dotnet-install-script
# curl -fsSL -o "$HOME/dotnet-install.sh" "https://dot.net/v1/dotnet-install.sh" && \
#     chmod +x "$HOME/dotnet-install.sh" && \
#     sudo "$HOME/dotnet-install.sh"
# [[ -f "$HOME/dotnet-install.sh" ]] && rm -f "$HOME/dotnet-install.sh"

# colorEcho "${BLUE}Installing ${FUCHSIA}yarn${BLUE}..."
# sudo apt install -y yarn --no-install-recommends


# SSH
if [[ ! -d "$HOME/.ssh" ]]; then
    mkdir -p "$HOME/.ssh" && chmod -R 700 "$HOME/.ssh" # && chmod 600 "$HOME/.ssh/"*
fi


# Change default editor to nano
if [[ -x "$(command -v nano)" ]]; then
    sudo update-alternatives --install /usr/bin/editor editor "$(which nano)" 100
    # sudo update-alternatives --config editor
fi


# make sudo more user friendly
# remove sudo timeout, make cache global, extend timeout
colorEcho "${BLUE}Making sudo more user friendly..."
sudo tee "/etc/sudoers.d/20-password-timeout-0-ppid-60min" >/dev/null <<-'EOF'
Defaults passwd_timeout=0
Defaults timestamp_type="global"

# sudo only once for 60 minute
Defaults timestamp_timeout=60
EOF

## Allow members of the group sudo to execute any command without password prompt
## `sudo visudo` OR `sudo EDITOR=nano visudo`
# sudo sed -i 's/%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers
CommandList=(
    service
    apt
    apt-get
    pacman
    pacapt
    pacaptr
)
for TargetCommand in "${CommandList[@]}"; do
    [[ -x "$(command -v "${TargetCommand}")" ]] && \
        echo "%sudo ALL=NOPASSWD:$(which "${TargetCommand}")" \
            | sudo tee "/etc/sudoers.d/nopasswd_sudo_command_${TargetCommand}" >/dev/null && \
        sudo chmod 440 "/etc/sudoers.d/nopasswd_sudo_command_${TargetCommand}"
done

## Allow user sudo to execute any command without password prompt
# sudo sed "/^# User privilege specification/a $(whoami) ALL=(ALL:ALL) NOPASSWD:ALL,\!/bin/su" /etc/sudoers
# echo "$(whoami) ALL=(ALL:ALL) NOPASSWD:ALL,\!/bin/su" | sudo tee "/etc/sudoers.d/nopasswd_sudo_$(whoami)" >/dev/null && \
#     sudo chmod 440 "/etc/sudoers.d/nopasswd_sudo_$(whoami)"

## Command alias
# sudo tee "/etc/sudoers.d/cmdalias_sudo" >/dev/null <<-'EOF'
# Cmnd_Alias     SHUTDOWN = /sbin/shutdown,/usr/bin/poweroff,/sbin/poweroff
# Cmnd_Alias     HALT = /usr/sbin/halt
# Cmnd_Alias     REBOOT = /usr/bin/reboot,/sbin/reboot,/sbin/init
# Cmnd_Alias     SHELLS = /bin/sh,/bin/bash,/usr/bin/csh, /usr/bin/ksh, \
#                         /usr/local/bin/tcsh, /usr/bin/rsh, \
#                         /usr/local/bin/zsh
# Cmnd_Alias     NETWORK = /etc/init.d/network,/sbin/ifconfig,/sbin/ip,/bin/hostname,/sbin/ifup,/sbin/ifdown
# Cmnd_Alias     PASSWORD = /usr/bin/passwd
# Cmnd_Alias     USERS = /usr/sbin/usermod,/usr/sbin/adduser,/usr/sbin/userdel,/usr/sbin/useradd,/usr/sbin/vipw,/usr/sbin/visudo,/usr/bin/gpasswd
# Cmnd_Alias     DISKS = /sbin/fdisk,/sbin/parted
# EOF
# sudo chmod 440 "/etc/sudoers.d/cmdalias_sudo"
# echo "%minsu ALL=(ALL) NOPASSWD:ALL,\!SHELLS,\!HALT,\!SHUTDOWN,\!REBOOT,\!NETWORK,\!PASSWORD,\!DISKS,\!USERS" \
#     | sudo tee "/etc/sudoers.d/nopasswd_sudo_minsu" >/dev/null && \
#     sudo chmod 440 "/etc/sudoers.d/nopasswd_sudo_minsu"

# check sudo file for config and other errors
sudo visudo -c

# Clear bash history
cat /dev/null > "$HOME/.bash_history"


colorEcho "${GREEN}WSL init done, please restart WSL!"