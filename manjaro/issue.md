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
ROOT_MOUNT_POINT=/mnt && sudo mount -o subvol=@ "/dev/mapper/${ROOT_CRYPT_POINT}" "${ROOT_MOUNT_POINT}"
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

## [System rollback the 'Arch Way'](https://wiki.archlinux.org/title/Snapper#Restoring_/_to_its_previous_snapshot)
```bash
# Boot from the Manjaro USB in Live mode

# Mount the toplevel subvolume (subvolid=5). That is, omit any subvolid or subvol mount flags.
# example: an encrypted device map labelled `cryptdev`...
sudo mount /dev/mapper/<cryptdev> /mnt
# or
sudo mount -o subvolid=5 /dev/<device-id> /mnt

## Move the broken @ subvolume out of the way ...
# sudo mv /mnt/@ /mnt/@.broken
## Or simply delete the subvolume ...
sudo btrfs subvolume delete /mnt/@

# Find the number of the snapshot that you want to recover ...
sudo grep -r '<date>' /mnt/@rootsnaps/*/info.xml

# Create a read-write snapshot of the read-only snapshot taken by Snapper ...
sudo btrfs subvolume snapshot /mnt/@rootsnaps/<number>/snapshot /mnt/@
# Where `number` is the snapshot you wish to restore as the new @

# Set the default subvolume for the (mounted) filesystem
btrfs subvolume set-default /mnt/@

# Unmount /mnt
sudo umount /mnt

# Reboot and rollback
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
# [Baloo](https://wiki.archlinux.org/title/Baloo)
balooctl6 disable && balooctl6 purge && balooctl6 enable
balooctl6 status
```

## [Disable Baloo - the file indexing and file search framework for KDE Plasma](https://askubuntu.com/questions/1267830/what-does-baloo-file-extractor-do)
## File search in Dolphin works after disabling Baloo, but file search in KRunner does not work anymore
## System Settings→Search→File Search→Disable File Search
`balooctl6 disable && balooctl6 purge`

## [Reinstall GRUB](https://wiki.manjaro.org/index.php/GRUB/Restore_the_GRUB_Bootloader/en#Reinstall_GRUB)
```bash
sudo mv /etc/grub.d /etc/grub.d.gc
sudo pacman -S grub
# sudo grub-mkconfig -o /boot/grub/grub.cfg

# grub-btrfs
sudo pacman --noconfirm -S snap-pac grub-btrfs snapper-gui
sudo sed -i -e 's/#GRUB_BTRFS_SUBMENUNAME="Arch Linux snapshots"/GRUB_BTRFS_SUBMENUNAME="Select snapshot"/g' /etc/default/grub-btrfs/config

yay -aS --sudoloop --noredownload --norebuild --noconfirm --noeditmenu snap-pac-grub

"${MY_SHELL_SCRIPTS}/manjaro/grub-tweaks.sh"
```

## [Error: failed to commit transaction (invalid or corrupted package (PGP signature))](https://forum.manjaro.org/t/error-failed-to-commit-transaction-invalid-or-corrupted-package-pgp-signature/150830/5)
```bash
sudo rm -r /etc/pacman.d/gnupg && sudo pacman-key --init && sudo pacman-key --refresh-keys && sudo pacman-key --populate
# sudo pacman-key --populate archlinux manjaro archlinuxcn
sudo pacman -Sy archlinux-keyring manjaro-keyring archlinuxcn-keyring
sudo pacman -Scc && sudo pacman -Syyu
```

## Fix aur package `ERROR: One or more files did not pass the validity check!`
```bash
yay --mflags "--skipchecksums --skippgpcheck"
yay --mflags "--skipinteg"
# makepkg -si --skipinteg
# makepkg -si --skipchecksums --skippgpcheck

# or update checksums
AppInstallList=("package_name")
for TargetApp in "${AppInstallList[@]}"; do
    if checkPackageNeedInstall "${TargetApp}"; then
        TargetApp=${TargetApp##*/}
        if [[ -d "$HOME/.cache/yay/${TargetApp}" ]]; then
            colorEcho "${BLUE}Installing ${FUCHSIA}${TargetApp}${BLUE}..."
            yay -G "${TargetApp}" && cd "$HOME/.cache/yay/${TargetApp}" && updpkgsums && makepkg -si
            # makepkg -g
        fi
    fi
done
```

## [How to Encrypt and Decrypt Files and Directories Using Tar and OpenSSL](https://www.tecmint.com/encrypt-decrypt-files-tar-openssl-linux/)
```bash
# Encrypt Files
tar -czf - * | openssl enc -e -aes256 -out secured.tar.gz

# Decrypt Files
openssl enc -d -aes256 -in secured.tar.gz | tar xz -C test
```

## [How to create and apply a Git patch file with git diff and git apply commands](https://everythingdevops.dev/how-to-create-and-apply-a-git-patch-with-git-diff-and-git-apply-commands/)
```bash
# Creating a Git patch file
git diff > patch_file.diff
git diff filename > patch_file.diff
git diff commit_id1 commit_id2 > patch_file.diff
git diff branch_1_name branch_2_name > patch_file.diff

# Applying a Git patch file
git apply patch_file.diff
```

## [Switching Branches](https://wiki.manjaro.org/index.php/Switching_Branches)
```bash
# Which branch currently on
pacman-mirrors -G

# Changing to another branch: stable, testing or unstable
sudo pacman-mirrors --api --set-branch stable

# Rebuild the mirrorlist
sudo pacman-mirrors -i -c Taiwan,China -m rank

# Update cache & packages
sudo --noconfirm pacman -Syy && sudo --noconfirm pacman -Syu
```
