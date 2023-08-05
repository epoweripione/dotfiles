# Boot
## boot status
```bash
sudo bootctl status
```

## boot logs
```bash
journalctl --boot=-1 --priority=3
journalctl -xb -p 1..3
journalctl -xb | grep -i -E 'error|failed'
```

## [GRUB/Restore the GRUB Bootloader](https://wiki.manjaro.org/index.php/GRUB/Restore_the_GRUB_Bootloader)
```bash
# Boot from the Manjaro USB in Live mode

# After booting, open a terminal/console and run this command to automatically mount Manjaro installation
# It should search the installation and do all the steps needed to enter it
sudo manjaro-chroot -a

## With a BTRFS filesystem
# Identify partitions
sudo lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME -e7
sudo blkid -t TYPE="btrfs"

## For example: `/dev/sda1` as EFI partition and `/dev/sda2` as ROOT partition
## BTRFS partition without encrypted
# mount root partition
ROOT_DISK=/dev/sda2 && ROOT_MOUNT_POINT=/mnt && sudo mount -o subvol=@ "${ROOT_DISK}" "${ROOT_MOUNT_POINT}"
# mount EFI partition
EFI_DISK=/dev/sda1 && EFI_BOOT_POINT=/mnt/boot/efi && sudo mount "${EFI_DISK}" "${EFI_BOOT_POINT}"

## BTRFS partition encrypted with LUKS
# Unlock
ROOT_DISK=/dev/sda2 && ROOT_CRYPT_POINT="root" && sudo cryptsetup open "${ROOT_DISK}" "${ROOT_CRYPT_POINT}"
# mount unlock root partition
sudo mount -o subvol=@ "/dev/mapper/${ROOT_CRYPT_POINT}" "${ROOT_MOUNT_POINT}"
# mount EFI partition
EFI_DISK=/dev/sda1 && EFI_BOOT_POINT=/mnt/boot/efi && sudo mount "${EFI_DISK}" "${EFI_BOOT_POINT}"

# Manual chroot
sudo manjaro-chroot "${ROOT_MOUNT_POINT}" /bin/bash

## Install grub loader in BIOS or UEFI mode
# UEFI mode
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=manjaro --recheck
# BIOS mode
grub-install --force --target=i386-pc --boot-directory=/boot --recheck

# Make sure that the file at `/etc/default/grub` have the following variables (without a `#` in front of)
GRUB_TIMEOUT_STYLE=menu
GRUB_DISABLE_OS_PROBER=false
GRUB_REMOVE_LINUX_ROOTFLAGS=true
# Just open it with an editor, change these variables and save it
nano /etc/default/grub

# Update the grub configuration
grub-mkconfig -o /boot/grub/grub.cfg

# Type `exit` to leave the chroot and reboot
```

## Failed to find module 'xxx'
Find the entry in the module lists and remove it:

/lib/modules-load.d
/usr/lib/modules-load.d
/usr/local/lib/modules-load.d
/etc/modules-load.d
/run/modules-load.d


## [Failed to start pkgfile database update](https://forum.manjaro.org/t/failed-failed-to-start-pkgfile-database-update/31731/46)
`sudo sed -i '/^\[Timer\]/a\OnBootSec=10min' "/usr/lib/systemd/system/pkgfile-update.timer"`


## SamInfo3_for_guest: Unable to locate guest account
`id guest 2>/dev/null || sudo useradd guest -s /bin/nologin`


## [Unit dbus-org.freedesktop.home1.service not found](https://forum.manjaro.org/t/systemd-homed-annoyance-when-disabled-the-journal-log-is-literally-spammed/32498)
`sudo sed -i "/pam_systemd_home.so/ s/^\(.*\)$/#\1/" /etc/pam.d/system-auth`

or
```bash
sudo "/usr/lib/security/pam_systemd_home.so" "/usr/lib/security/pam_systemd_home.so.bak"
for i in homed.service userdbd.service userdbd.socket; do
    sudo systemctl disable --now systemd-${i}
    sudo systemctl mask systemd-${i}
done
```

## [Bluetooth errors](https://www.reddit.com/r/archlinux/comments/yu9az9/bluetooth_errors_since_2_days_ago/)
```bash
# bluetoothd: profiles/audio/vcp.c:vcp_init() D-Bus experimental not enabled
# bluetoothd: src/plugin.c:plugin_init() Failed to init vcp plugin
# bluetoothd: profiles/audio/mcp.c:mcp_init() D-Bus experimental not enabled
# bluetoothd: src/plugin.c:plugin_init() Failed to init mcp plugin
# bluetoothd: profiles/audio/bap.c:bap_init() D-Bus experimental not enabled
# bluetoothd: src/plugin.c:plugin_init() Failed to init bap plugin
sudo pacman --noconfirm --needed -S bluez-utils
sudo systemctl status bluetooth
sudo sed -i -e 's/^#Experimental.*/Experimental = true/' -e 's/^#KernelExperimental.*/KernelExperimental = true/' /etc/bluetooth/main.conf
```

## Fix `konsole: kf.xmlgui: Shortcut for action  "" set with QAction::setShortcut()! Use KActionCollection::setDefaultShortcut(s) instead.`
`rm $HOME/.config/QtProject.conf`

## [Fix Windows and Linux Showing Different Time When Dual Booting](https://windowsloop.com/fix-windows-and-linux-showing-different-time-when-dual-booting/)
- Windows Settings (Win+I)→Time & language→Date and Time→Turn off "Set time automatically"
- Start menu→Search and open "Registry Editor"→HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation→Add new "DWORD" value "RealTimeIsUniversal" and set "Value Data" to "1"
`reg add HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation /v RealTimeIsUniversal /t reg_dword /d 00000001 /f`
- Reboot the computer


## [Baloo still crashing](https://forum.manjaro.org/t/baloo-still-crashing/130024)
```bash
balooctl disable && balooctl purge && balooctl enable
balooctl status
```

## [Disable Baloo - the file indexing and file search framework for KDE Plasma](https://askubuntu.com/questions/1267830/what-does-baloo-file-extractor-do)
## File search in Dolphin works after disabling Baloo, but file search in KRunner does not work anymore
## System Settings→Search→File Search→Disable File Search
`balooctl disable && balooctl purge`
