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

# [Enable LUKS2 and Argon2 support for Grub in Manjaro/Arch](https://mdleom.com/blog/2022/11/27/grub-luks2-argon2/)
EFI_BOOT_DISK=$1 # /dev/sda1, /dev/nvme0n1p1
ROOT_DISK=$2 # /dev/sda2, /dev/nvme0n1p2
SWAP_DISK=$3 # /dev/sda3, /dev/nvme0n1p3
[[ -z "${ROOT_DISK}" ]] && colorEcho "${RED}Please specify the disk to convert!" && exit 1

ROOT_CRYPT_POINT="root"
ROOT_MOUNT_POINT="/mnt"
EFI_BOOT_POINT="${ROOT_MOUNT_POINT}/boot/efi"

SWAP_CRYPT_POINT="swap"

## Check if using UEFI or BIOS
# sudo efibootmgr
# [[ ! -d "/sys/firmware/efi/efivars" ]] && colorEcho "${RED}Not BOOT as UEFI mode!" && exit 1

if ! sudo lsblk -no PARTTYPENAME --fs "${EFI_BOOT_DISK}" | grep -q -i 'EFI\sSystem'; then
    colorEcho "${FUCHSIA}${EFI_BOOT_DISK}${RED} is not a EFI Partition!"
    exit 1
fi

# sudo cryptsetup luksDump "${ROOT_DISK}"
# sudo lsblk --fs | grep -i 'LUKS'
if ! sudo cryptsetup isLuks "${ROOT_DISK}"; then
    colorEcho "${FUCHSIA}${ROOT_DISK}${RED} is not encrypted with LUKS!"
    exit 1
fi

if ! sudo lsblk -no FSTYPE,FSVER --fs "${ROOT_DISK}" | grep -q -i 'LUKS\s1'; then
    colorEcho "${FUCHSIA}${ROOT_DISK}${RED} is not encrypted with LUKS1!"
    exit 1
fi

if [[ -n "${SWAP_DISK}" ]]; then
    if ! sudo cryptsetup isLuks "${SWAP_DISK}"; then
        colorEcho "${FUCHSIA}${SWAP_DISK}${RED} is not encrypted with LUKS!"
        exit 1
    fi

    if ! sudo lsblk -no FSTYPE,FSVER --fs "${SWAP_DISK}" | grep -q -i 'LUKS\s1'; then
        colorEcho "${FUCHSIA}${SWAP_DISK}${RED} is not encrypted with LUKS1!"
        exit 1
    fi

    sudo cryptsetup open "${SWAP_DISK}" "${SWAP_CRYPT_POINT}"
    if ! sudo lsblk -no LABEL --fs "${SWAP_DISK}" | grep -q -i 'swap'; then
        colorEcho "${FUCHSIA}${SWAP_DISK}${RED} is not a SWAP partition!"
        sudo cryptsetup close "${SWAP_CRYPT_POINT}"
        exit 1
    fi
    sudo cryptsetup close "${SWAP_CRYPT_POINT}"
fi

if [[ -n "${SWAP_DISK}" ]]; then
    colorEchoN "${ORANGE}Convert ${FUCHSIA}${ROOT_DISK} & ${SWAP_DISK}${ORANGE} to ${GREEN}LUKS2${ORANGE}?[y/${CYAN}N${ORANGE}]: "
else
    colorEchoN "${ORANGE}Convert ${FUCHSIA}${ROOT_DISK}${ORANGE} to ${GREEN}LUKS2${ORANGE}?[y/${CYAN}N${ORANGE}]: "
fi
read -r CONVERT_LUKS
[[ "${CONVERT_LUKS^^}" != "Y" ]] && exit 1

## Backup & Restore
# sudo cryptsetup luksHeaderBackup "${ROOT_DISK}" --header-backup-file "/tmp/luksheader${ROOT_DISK//\//-}"
# sudo cryptsetup luksHeaderRestore "${ROOT_DISK}" --header-backup-file "/tmp/luksheader${ROOT_DISK//\//-}"

## LUKS1 to LUKS2 conversion
## If you want to revert back to LUKS1
# sudo cryptsetup convert --type luks1 "${ROOT_DISK}"
## Before reverting back to LUKS1, the keyslot must be using PBKDF2 not Argon2, 
## otherwise you will encounter “Cannot convert to LUKS1 format” error.
# sudo cryptsetup luksConvertKey --pbkdf pbkdf2 "${ROOT_DISK}"
colorEchoN "${BLUE}Converting ${FUCHSIA}${ROOT_DISK}${BLUE} to LUKS2..."
if ! sudo cryptsetup convert --type luks2 "${ROOT_DISK}"; then
    colorEcho "Convert ${FUCHSIA}${ROOT_DISK}${RED} to LUKS2 failed!"
    exit 1
fi

if [[ -n "${SWAP_DISK}" ]]; then
    colorEchoN "${BLUE}Converting ${FUCHSIA}${SWAP_DISK}${BLUE} to LUKS2..."
    if ! sudo cryptsetup convert --type luks2 "${SWAP_DISK}"; then
        colorEcho "Convert ${FUCHSIA}${SWAP_DISK}${RED} to LUKS2 failed!"
        exit 1
    fi
fi

## PBKDF2 to Argon2 conversion
# cryptsetup benchmark
colorEchoN "${BLUE}Converting ${FUCHSIA}algorithm${BLUE} to Argon2${BLUE}..."
sudo cryptsetup luksConvertKey --pbkdf argon2id "${ROOT_DISK}"
# sudo cryptsetup luksConvertKey --pbkdf argon2id --hash sha512 "${ROOT_DISK}"

if [[ -n "${SWAP_DISK}" ]]; then
    sudo cryptsetup luksConvertKey --pbkdf argon2id "${SWAP_DISK}"
    # sudo cryptsetup luksConvertKey --pbkdf argon2id --hash sha512 "${SWAP_DISK}"
fi

# Enable TRIM and disable workqueue for SSD performance (optional)
colorEchoN "${BLUE}Enable TRIM and disable workqueue for SSD performance..."
sudo cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent open "${ROOT_DISK}" "${ROOT_CRYPT_POINT}"
sudo cryptsetup close "${ROOT_CRYPT_POINT}"
sudo cryptsetup luksDump "${ROOT_DISK}" | grep Flags # Verify the flags are set

if [[ -n "${SWAP_DISK}" ]]; then
    sudo cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent open "${SWAP_DISK}" "${SWAP_CRYPT_POINT}"
    sudo cryptsetup close "${SWAP_CRYPT_POINT}"
    sudo cryptsetup luksDump "${SWAP_DISK}" | grep Flags
fi

# Load LUKS2 Grub module
# At this stage, the Grub bootloader (not the package) cannot unlock the LUKS2 partition yet. 
# It needs to be reinstalled so that it can detect LUKS2 partition and load the relevant module.
# First, unlock the partition and mount it.
colorEcho "${BLUE}Regenerate ${FUCHSIA}GRUB2 configuration${BLUE}..."
sudo cryptsetup open "${ROOT_DISK}" "${ROOT_CRYPT_POINT}"

# /etc/fstab, /etc/crypttab, /etc/openswap.conf, /etc/default/grub
if sudo mount -o subvol=@ "/dev/mapper/${ROOT_CRYPT_POINT}" "${ROOT_MOUNT_POINT}"; then
    # EFI
    sudo mount "${EFI_BOOT_DISK}" "${EFI_BOOT_POINT}"

    ## HOOKS
    # sudo grep '^HOOKS' "${ROOT_MOUNT_POINT}/etc/mkinitcpio.conf"

    ## GRUB modules
    # ls /usr/lib/grub/x86_64-efi

    # sudo grep '^GRUB_' "${ROOT_MOUNT_POINT}/etc/default/grub"
    if [[ -s "${ROOT_MOUNT_POINT}/etc/default/grub" ]]; then
        # sudo sed -i -e 's/GRUB_PRELOAD_MODULES=.*/GRUB_PRELOAD_MODULES="part_gpt part_msdos argon2 gcry_sha512"/g' "${ROOT_MOUNT_POINT}/etc/default/grub"
        if ! grep -q '^GRUB_ENABLE_CRYPTODISK=y' "${ROOT_MOUNT_POINT}/etc/default/grub"; then
            echo "GRUB_ENABLE_CRYPTODISK=y" | sudo tee -a "${ROOT_MOUNT_POINT}/etc/default/grub" >/dev/null
        fi
    fi

    # sudo grep 'insmod luks' "${ROOT_MOUNT_POINT}/boot/grub/grub.cfg"
    if [[ -s "${ROOT_MOUNT_POINT}/boot/grub/grub.cfg" ]]; then
        # sudo manjaro-chroot "${ROOT_MOUNT_POINT}" /bin/bash
        # grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=manjaro --recheck
        # grub-mkconfig -o /boot/grub/grub.cfg

        sudo manjaro-chroot "${ROOT_MOUNT_POINT}" 'grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=manjaro --recheck'
        sudo manjaro-chroot "${ROOT_MOUNT_POINT}" 'grub-mkconfig -o /boot/grub/grub.cfg'
    fi

    sudo umount "${EFI_BOOT_POINT}"
    sudo umount "${ROOT_MOUNT_POINT}"
fi
sudo cryptsetup close "${ROOT_CRYPT_POINT}"

## Faster unlock in Grub
## This step can be done while the drive is mounted (as in not in live USB)
## Due to lack of cryptography acceleration, Grub takes half a minute to unlock LUKS. For faster unlock, Argon2 parameters can be tuned to less security.
## To start off, have a try with these parameters: 4 iterations, 256MB memory cost
# sudo cryptsetup luksConvertKey "${ROOT_DISK}" --pbkdf-force-iterations 4 --pbkdf-memory 262100
## sudo cryptsetup luksConvertKey "${ROOT_DISK}" --pbkdf-force-iterations 4 --pbkdf-memory 262100 --key-file /crypto_keyfile.bin
## This [page](https://leo3418.github.io/collections/gentoo-config-luks2-grub-systemd/tune-parameters.html#change-the-parameters) explains why keyfile also needs to be updated.
