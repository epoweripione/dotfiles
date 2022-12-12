#!/usr/bin/env bash

# this script will do a snapper rollback, and then upfdate and re-install grub to use the proper snapshot

echo "calling snapper rollback"
sudo snapper --ambit classic rollback

echo "updating and re-installing grub"
ROOT_DEV=$(mount | grep ' on / ' | cut -d' ' -f1)
ROOT_DEV_PARENT=$(lsblk -no pkname "${ROOT_DEV}")

echo "Using ${ROOT_DEV}, and /dev/${ROOT_DEV_PARENT} as parent."

sudo mount "${ROOT_DEV}" /mnt

sudo manjaro-chroot /mnt 'mount /usr/local'
sudo manjaro-chroot /mnt "/usr/local/bin/btrfs_grub_install_chroot.sh ${LANG} /dev/${ROOT_DEV_PARENT}"

echo -e "\nGrub updated. You can reboot now to the restored snapshot."
read -r
