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

# https://wiki.archlinux.org/title/LVM
# https://wiki.debian.org/LVM
if [[ -x "$(command -v pacman)" ]]; then
    get_os_desktop

    PackagesList=("lvm2")
    # [[ -n "${OS_INFO_DESKTOP}" ]] && PackagesList+=("partitionmanager")
    # [[ -n "${OS_INFO_DESKTOP}" ]] && PackagesList+=("gnome-disk-utility")

    InstallSystemPackages "" "${PackagesList[@]}"
fi

## List of LVM commands
# lvmchange — Change attributes of the Logical Volume Manager.
# lvmdiskscan — Scan for all devices visible to LVM2.
# lvmdump — Create lvm2 information dumps for diagnostic purposes.

## List of PV commands
# pvchange — Change attributes of a Physical Volume.
# pvck — Check Physical Volume metadata.
# pvcreate — Initialize a disk or partition for use by LVM.
# pvdisplay — Display attributes of a Physical Volume.
# pvmove — Move Physical Extents.
# pvremove — Remove a Physical Volume.
# pvresize — Resize a disk or partition in use by LVM2.
# pvs — Report information about Physical Volumes.
# pvscan — Scan all disks for Physical Volumes.

## List of VG commands
# vgcfgbackup — Backup Volume Group descriptor area.
# vgcfgrestore — Restore Volume Group descriptor area.
# vgchange — Change attributes of a Volume Group.
# vgck — Check Volume Group metadata.
# vgconvert — Convert Volume Group metadata format.
# vgcreate — Create a Volume Group.
# vgdisplay — Display attributes of Volume Groups.
# vgexport — Make volume Groups unknown to the system.
# vgextend — Add Physical Volumes to a Volume Group.
# vgimport — Make exported Volume Groups known to the system.
# vgimportclone — Import and rename duplicated Volume Group (e.g. a hardware snapshot).
# vgmerge — Merge two Volume Groups.
# vgmknodes — Recreate Volume Group directory and Logical Volume special files
# vgreduce — Reduce a Volume Group by removing one or more Physical Volumes.
# vgremove — Remove a Volume Group.
# vgrename — Rename a Volume Group.
# vgs — Report information about Volume Groups.
# vgscan — Scan all disks for Volume Groups and rebuild caches.
# vgsplit — Split a Volume Group into two, moving any logical volumes from one Volume Group to another by moving entire Physical Volumes.

## List of LV commands
# lvchange — Change attributes of a Logical Volume.
# lvconvert — Convert a Logical Volume from linear to mirror or snapshot.
# lvcreate — Create a Logical Volume in an existing Volume Group.
# lvdisplay — Display the attributes of a Logical Volume.
# lvextend — Extend the size of a Logical Volume.
# lvreduce — Reduce the size of a Logical Volume.
# lvremove — Remove a Logical Volume.
# lvrename — Rename a Logical Volume.
# lvresize — Resize a Logical Volume.
# lvs — Report information about Logical Volumes.
# lvscan — Scan (all disks) for Logical Volumes.


## https://www.tecmint.com/extend-and-reduce-lvms-in-linux/
## https://gparted.org/livecd.php
## use `GParted LiveCD` to skip mount/umount

## Extend Logical Volume (LVM)
## add spaces -> lvresize -> e2fsck -> resize2fs

## use `fdisk` to create the LVM partition: 8e
# sudo fdisk /dev/sdb
# sudo fdisk -l /dev/sdb

## create new PV (Physical Volume)
# sudo pvcreate /dev/sdb1
# sudo pvs

## Extend Volume Group
# sudo vgextend <vg1> /dev/sdb1
# sudo vgs
# sudo pvscan
# sudo vgdisplay

## Check for the file-system error
# sudo e2fsck -ff /dev/vg1/lv1
## Must pass in every 5 steps of file-system check if not there might be some issue with your file-system.

## Extend Logical Volume
# sudo lvresize -l +100%FREE /dev/vg1/lv1
# sudo lvextend -L 100G /dev/vg1/lv1

## Re-size the file-system
# sudo resize2fs /dev/vg1/lv1

## Check the size of partition and files
# sudo lvdisplay
# sudo lsblk
# df -Th


## Reducing Logical Volume (LVM)
## umount -> e2fsck -> resize2fs -> lvresize -> mount

## First unmount the mount point
# sudo umount -v /mnt/lv_test/

## Check for the file-system error
# sudo e2fsck -ff /dev/vg1/lv1
## Must pass in every 5 steps of file-system check if not there might be some issue with your file-system.

## Reduce the file-system
# sudo resize2fs /dev/vg1/lv1 50G

## Reduce the Logical volume using GB size
# sudo lvreduce -L 50G /dev/vg1/lv1

## Re-size the file-system back, In this step if there is any error that means we have messed-up our file-system.
# sudo resize2fs /dev/vg1/lv1

## Mount the file-system back
# sudo mount /dev/vg1/lv1 /mnt/lv_test/

## Check the size of partition and files
# sudo lvdisplay
# sudo lsblk
# df -Th
