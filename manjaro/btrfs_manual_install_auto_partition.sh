#!/usr/bin/env bash

# Auto partitioning before manual install
# PARTED_DEVICE="/dev/vda"
PARTED_DEVICE="$1"
[[ -z "${PARTED_DEVICE}" ]] && PARTED_DEVICE="NOT_A_REAL_DISK"
if sudo fdisk -l | grep -q -i -E "Disk\s+${PARTED_DEVICE}"; then
    echo "Auto partitioning disk ${PARTED_DEVICE}, all data on this disk will be lost after repartitioning, confirm?[y/N] "
    read -r CHOICE
    if [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]]; then
        echo "Partitioning disk ${PARTED_DEVICE}..."
        sudo parted "${PARTED_DEVICE}" unit MiB mklabel gpt
        sudo parted "${PARTED_DEVICE}" unit MiB mkpart "BIOS_GRUB" 1MiB 9MiB
        sudo parted "${PARTED_DEVICE}" unit MiB set 1 bios_grub on
        sudo parted "${PARTED_DEVICE}" unit MiB mkpart "EFI" 9MiB 521MiB
        sudo parted "${PARTED_DEVICE}" unit MiB set 2 boot on
        sudo parted "${PARTED_DEVICE}" unit MiB set 2 esp on
        sudo parted "${PARTED_DEVICE}" unit MiB mkpart "Swap" 521MiB 8713MiB
        sudo parted "${PARTED_DEVICE}" unit MiB mkpart "Manjaro" 8713M 100%

        echo "Formatting partitions..."
        sudo mkfs.fat -F32 "${PARTED_DEVICE}2"
        sudo mkswap "${PARTED_DEVICE}3"
        sudo mkfs.btrfs -L "Manjaro" -f "${PARTED_DEVICE}4"

        echo "Creating btrfs subvolumes on ${PARTED_DEVICE}4..."
        sudo mkdir -p /mnt/btrfs
        sudo mount "${PARTED_DEVICE}4" /mnt/btrfs

        sudo btrfs subvolume create /mnt/btrfs/@
        sudo btrfs subvolume create /mnt/btrfs/@home
        sudo btrfs subvolume create /mnt/btrfs/@opt
        sudo btrfs subvolume create /mnt/btrfs/@srv
        sudo btrfs subvolume create /mnt/btrfs/@var
        sudo btrfs subvolume create /mnt/btrfs/@tmp
        sudo btrfs subvolume create /mnt/btrfs/@rootsnaps
        sudo btrfs subvolume create /mnt/btrfs/@homesnaps

        sudo chattr +C /mnt/btrfs/@var
        sudo chattr +C /mnt/btrfs/@tmp

        echo ""
        echo "Partitioning disk ${PARTED_DEVICE} done."
        sudo fdisk -l "${PARTED_DEVICE}"

        echo ""
        echo "Btrfs on ${PARTED_DEVICE}4: "
        sudo btrfs filesystem show

        echo ""
        echo "Subvolumes on ${PARTED_DEVICE}4: "
        sudo btrfs subvolume list -p /mnt/btrfs

        sudo umount /mnt/btrfs
    fi
fi

# [Install Manjaro using CLI only](https://forum.manjaro.org/t/root-tip-how-to-do-a-manual-manjaro-installation/12507)
