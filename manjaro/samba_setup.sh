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

# samba
# https://www.samba.org/samba/
# https://wiki.archlinux.org/title/samba
colorEcho "${BLUE}Installing ${FUCHSIA}samba${BLUE}..."
sudo pacman --noconfirm --needed -S samba nautilus-share manjaro-settings-samba

colorEcho "${BLUE}Setting share folder to ${FUCHSIA}${HOME}/share${BLUE}..."
sudo mv "/etc/samba/smb.conf" "/etc/samba/smb.conf.bak"

# Create a Linux user `guest` which anonymous Samba users will be mapped to
[[ $(id guest 2>/dev/null) ]] && sudo useradd guest -s /bin/nologin

SAMBA_WORKGROUP=${1:-"WORKGROUP"}
SAMBA_NETBIOS_NAME=$(uname -n 2>/dev/null)

sudo tee "/etc/samba/smb.conf" >/dev/null <<-EOF
[global]
workgroup = ${SAMBA_WORKGROUP}
netbios name = ${SAMBA_NETBIOS_NAME}
server min protocol = SMB2
client min protocol = SMB2
security = user
map to guest = bad user
guest account = guest
dns proxy = no

[printers]
comment = All Printers
browseable = no
path = /var/spool/samba
printable = yes
guest ok = yes
read only = yes
create mask = 0700

[print$]
comment = Printer Drivers
path = /var/lib/samba/printers
browseable = yes
read only = yes
guest ok = no

[share]
path = ${HOME}/share
browsable = yes
writable = yes
guest ok = yes
create mask = 0777
directory mask = 0777
EOF

mkdir -p "${HOME}/share" && chmod 777 -R "${HOME}/share"

colorEcho "${BLUE}Setting ${FUCHSIA}samba user${BLUE}..."
sudo smbpasswd -a "$(id -un)"

colorEcho "${BLUE}Enabling ${FUCHSIA}samba${BLUE} service..."
sudo systemctl enable smb && sudo systemctl start smb


# winbind
colorEcho "${BLUE}Enabling ${FUCHSIA}winbind${BLUE} service..."
# sudo usermod -a -G sambashare "$(whoami)"

sudo systemctl enable winbind

if ! grep -q "wins" "/etc/nsswitch.conf" 2>/dev/null; then
    sudo sed -i 's/ dns$/ wins dns/' "/etc/nsswitch.conf"
fi

if [[ -s "/usr/lib/systemd/system/winbind.service" ]]; then
    sudo sed -i 's/^After=.*/After=network-online.target nmbd.service/' "/usr/lib/systemd/system/winbind.service"
    sudo sed -i '/^After/a\Wants=network-online.target' "/usr/lib/systemd/system/winbind.service"
fi

sudo systemctl start winbind


## pdbedit
## https://www.samba.org/samba/docs/current/man-html/pdbedit.8.html
# sudo pdbedit -a -u <username> # add a user
# sudo pdbedit -x -u <username> # delete a user
# sudo pdbedit -L # lists all user accounts
# sudo pdbedit –c "[D]" –u <username> # disable user account
# sudo pdbedit –c "[]" –u <username> # enable user account

## smbclient
# smbclient -L 127.0.0.1
# smbclient //<server>/<sharename>
## access the shared folder as guest (anonymous login)
# smbclient -N //<server>/<sharename>


## Access Shared Folders or Map Network Drives from Windows
## http://woshub.com/cannot-access-smb-network-shares-windows-10-1709/
## Make sure your computers are joined to the same workgroup.
## The name of the workgroup on the computer can be found using `PowerShell`
# (Get-WmiObject Win32_ComputerSystem).domain

## Change the settings to allow access to shared network folders under the guest account.
## This method should be used only as a temporary workaround, 
## because access to folders without authentication significantly reduces your computer security.
# Group Policy Editor(gpedit.msc)
# Computer Configuration→Administrative templates→Network→Lanman Workstation→Enable insecure guest logons →Enabled
## or
# reg add HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters /v AllowInsecureGuestAuth /t reg_dword /d 00000001 /f
# reg add HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation /v AllowInsecureGuestAuth /t reg_dword /d 00000001 /f

## Disable the SMB 1 protocol and enable SMBv2 On Windows 7/Windows Server 2008 R2
# Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" SMB1 -Type DWORD -Value 0 –Force
# Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" SMB2 -Type DWORD -Value 1 –Force

## Disable SMBv1, allow SMBv2 and SMBv3 On Windows 8.1/Windows Server 2012 R2
# Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol"
# Set-SmbServerConfiguration –EnableSMB2Protocol $true

## Make sure you are using the correct username and password to access the network folder.
## If you’re not prompted for a username and password, 
## try removing saved (cached) credentials for remote shares in Windows Credential Manager.
## Control Panel→User Accounts→Credential Manager
## Or run the command:
# rundll32.exe keymgr.dll, KRShowKeyMgr
## and delete cached credentials for the remote computer you are trying to access.

## Remove current network connections in `cmd`
# net use
# net use * /delete /yes

## Windows Cannot Access Shared Folders
# Test-NetConnection -ComputerName <IP or ComputerName> -Port 445
## If the cmdlet returns `TcpTestSucceeded : False`, 
## this means that access to the network folder on the remote computer is being blocked by the firewall.
## create a firewall rule with `PowerShell`
# New-NetFirewallRule -DisplayName "Allow_SBM-FileSharing_In" -Direction Inbound -Protocol TCP –LocalPort 445 -Action Allow

## Windows Cannot Access Shared Folder: You Don’t Have Permissions
## Check the share permissions on the remote host using `PowerShell`
# Get-SmbConnection
# Get-SmbShare
# Get-SmbShareAccess -Name "tools"
# get-acl "C:\tools" | fl


## How to share files between a Linux and Windows computer
## https://www.computerhope.com/issues/ch001636.htm
## Using Nautilus(GNOME) or Dolphin(KDE)
# smb://<IP or ComputerName>/<ShareName>

## Using the `smbclient` command line
# smbclient //<IP or ComputerName>/<ShareName> -U <Username>

## And on a Mac with the `smbutil`  command line
# smbutil view [-options] //[domain;][user[:password]@]server

## List all shares without authentication(anonymous)
# smbclient -L <hostname> -U "*" --password "*"


## Mount windows shared folder
# SHARE_NAME="myshare" && SHARE_WORKGROUP="WORKGROUP" && \
#     SHARE_PATH="//<SERVER>/<sharename>" && SHARE_MOUNTPOINT="$HOME/${SHARE_NAME}" && \
#     SHARE_UID=$(id -u) && SHARE_GID=$(id -g) && \
#     mkdir -p "${SHARE_MOUNTPOINT}"

## To mount a Windows share without authentication, use "username=*"
# sudo mount -t cifs "${SHARE_PATH}" "${SHARE_MOUNTPOINT}" \
#     -o "username=*,password=*,workgroup=${SHARE_WORKGROUP},iocharset=utf8,uid=${SHARE_UID},gid=${SHARE_GID}"

## To mount a Windows share with authentication
# sudo mkdir -p "/etc/samba/credentials" && sudo chown root:root "/etc/samba/credentials" && sudo chmod 700 "/etc/samba/credentials"
# SHARE_USER="myuser" && SHARE_PASS="mypass" && \
#     echo -e "username=${SHARE_USER}\npassword=${SHARE_PASS}" | sudo tee "/etc/samba/credentials/${SHARE_NAME}" >/dev/null
# sudo chmod 600 "/etc/samba/credentials/${SHARE_NAME}"

# sudo mount -t cifs "${SHARE_PATH}" "${SHARE_MOUNTPOINT}" \
#     -o "credentials=/etc/samba/credentials/${SHARE_NAME},workgroup=${SHARE_WORKGROUP},iocharset=utf8,uid=${SHARE_UID},gid=${SHARE_GID}"

## automount
# echo "${SHARE_PATH} ${SHARE_MOUNTPOINT} cifs rw,username=*,password=*,workgroup=${SHARE_WORKGROUP},iocharset=utf8,uid=${SHARE_UID},gid=${SHARE_GID} 0 0" | sudo tee -a "/etc/fstab"

## unmount cifs
# sudo umount -l "${SHARE_MOUNTPOINT}"


## CUPS & Printers
## https://wiki.archlinux.org/title/CUPS
## https://www.cups.org/doc/admin.html
## https://blog.lincloud.pro/archives/6.html
## /etc/cups/cupsd.conf
## Any special characters in the printer URIs need to be appropriately quoted, 
## or, if your Windows printer name or user passwords have spaces, 
## CUPS will throw a lpadmin: Bad device-uri error.
## For example, smb://BEN-DESKTOP/HP Color LaserJet CP1510 series PCL6 
## becomes smb://BEN-DESKTOP/HP%20Color%20LaserJet%20CP1510%20series%20PCL6.
## This result string can be obtained by running the following command:
## python -c 'from urllib.parse import quote; print("smb://" + quote("BEN-DESKTOP/HP Color LaserJet CP1510 series PCL6"))'

## Use SNMP to find a URI:
# /usr/lib/cups/backend/snmp <ip_address>

## Print cups status information
# lpstat -v

## Printer Drivers and PPDs
# lpinfo -m

## Add printer shared by Windows
## /etc/cups/printers.conf
## DEVICE URI: https://man.archlinux.org/man/smbspool.8
## smb://server[:port]/printer
## smb://workgroup/server[:port]/printer
## smb://username:password@server[:port]/printer
## smb://username:password@workgroup/server[:port]/printer
# lpadmin -p "HP_LaserJet_Professional_M1136_MFP" \
#     -E -v "smb://<WORKGROUP>/<username>:<password>@<server>/HP%20LaserJet%20Professional%20M1136%20MFP" \
#     -m "drv:///hp/hpcups.drv/hp-laserjet_professional_m1136_mfp.ppd"

## For a driver-less queue (Apple AirPrint or IPP Everywhere):
# lpadmin -p AirPrint -E -v "ipp://10.0.1.25/ipp/print" -m everywhere

## For a raw queue; no PPD or filter:
# lpadmin -p SHARED_PRINTER -m raw

# PDF printer
# /etc/cups/cups-pdf.conf
# http://distro.ibiblio.org/smeserver/contribs/rvandenaker/testing/smeserver-cups/documentation/howtos/cups-pdf-printer.html
if ! lpstat -v 2>/dev/null | grep -q 'Print_to_PDF:'; then
    PDF_OUTPUT_DIR="$(xdg-user-dir DOCUMENTS)"
    if [[ -d "${PDF_OUTPUT_DIR}" ]]; then
        sudo sed -i "s|^[#]*Out .*|Out ${PDF_OUTPUT_DIR}|" "/etc/cups/cups-pdf.conf"
        sudo systemctl restart cups
    fi

    [[ -d "/var/spool/cups-pdf/ANONYMOUS" ]] && \
        ln -s "/var/spool/cups-pdf/ANONYMOUS" "${PDF_OUTPUT_DIR}/PrintedPDF"

    lpadmin -p "Print_to_PDF" -E -v "cups-pdf:/" -m "CUPS-PDF_opt.ppd"
fi

# Printer Sharing
# http://www.cups.org/doc/sharing.html
# enable printer sharing
cupsctl --share-printers
# tag each printer that you want to share
lpadmin -p "Print_to_PDF" -o printer-is-shared=true

## Add printer from Windows with URL:
# http://<PrinterServer>:631/printers/Print_to_PDF

## Test prints using `lpr`:
# lpr /usr/share/cups/data/testprint
# echo 'Hello, world!' | lpr -p

## Command line printing
## https://www.samba.org/samba/docs/using_samba/ch10.html
# smbclient -U <user> //server/printer -c "print <filename>.txt"
# lpr -r -P "<PrinterName>" "<filename>"

## Remove a printer:
# queue_name="HP_LaserJet_Professional_M1136_MFP" && cupsreject "${queue_name}" && cupsdisable "${queue_name}" && lpadmin -x "${queue_name}"
# queue_name="Print_to_PDF" && cupsreject "${queue_name}" && cupsdisable "${queue_name}" && lpadmin -x "${queue_name}"

## Troubleshooting
## https://wiki.archlinux.org/title/CUPS/Troubleshooting
# sudo sed -i 's/LogLevel.*/LogLevel debug/' /etc/cups/cupsd.conf
# sudo sed -i 's/LogLevel.*/LogLevel warn/' /etc/cups/cupsd.conf
# tail -n 100 -f /var/log/cups/error_log


## Setup a HP printer
# hp-setup -u -i
# hp-setup -u

## `systemctl status cups` with error: prnt/hpcups/HPCupsFilter.cpp: m_Job initialization failed with error = 48
# sudo hp-check
# sudo python -m pip install -U notify2
# sudo hp-plugin
# sudo systemctl restart cups


# Scanner
# https://wiki.archlinux.org/title/SANE
# https://wiki.archlinux.org/title/SANE/Scanner-specific_problems
# https://blog.tangbao.me/2019/09/rpi-printer-scanner-server/
yay --noconfirm --needed -S sane sane-airscan
# sudo sane-find-scanner
# sudo scanimage -L


cd "${CURRENT_DIR}" || exit
