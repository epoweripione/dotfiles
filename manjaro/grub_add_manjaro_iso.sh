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

## [Multiboot USB drive](https://wiki.archlinux.org/title/Multiboot_USB_drive#Boot_entries)
## [How to Boot ISO Files From GRUB2 Boot Loader](https://www.linuxbabe.com/desktop-linux/boot-from-iso-files-using-grub2-boot-loader)
## [Boot Arch Linux ISOs from Grub](https://blog.hiebl.cc/qa/arch-iso-in-grub/)
# sudo parted -l print
# sudo fdisk -l
# sudo blkid | grep vfat | grep -i efi
# sudo lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME,UUID -e7

WTG_EFI_DISK=$1
if [[ -z "${WTG_EFI_DISK}" ]]; then
    colorEcho "${BLUE}Usage: ${FUCHSIA}$(basename "$0")${BLUE} ISO-Storing-Directory Partition-TYPE Partition-UUID ISO-FileSystem-Directory GRUB-Partition-Number"
    colorEcho "${BLUE}Partition Type & UUID:"
    colorEcho "  ${FUCHSIA}sudo lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME,UUID -e7"
    colorEcho "${BLUE}GRUB-Partition-Number:"
    colorEcho "${BLUE}  Restart"
    colorEcho "${BLUE}  Press ${FUCHSIA}C${BLUE} when ${FUCHSIA}GRUB boot menu${BLUE} appears to open the ${FUCHSIA}GRUB command shell"
    colorEcho "${BLUE}  Then use ${FUCHSIA}ls${BLUE} to check Partition Number:"
    colorEcho "  ${FUCHSIA}ls"
    colorEcho "  ${FUCHSIA}ls (hd0,gpt2)"
    colorEcho "${BLUE}eg: ${FUCHSIA}$(basename "$0")${YELLOW} /run/media/$USER/0C5446025445EF50/iso NTFS 0C5446025445EF50 /iso"
    colorEcho "${BLUE}eg: ${FUCHSIA}$(basename "$0")${YELLOW} /opt/iso BTRFS d32ccad4-bedd-40d3-9e40-b62a4c8a09ec /@opt/iso \"(hd0,gpt2)\""
    exit 1
fi

ISO_STORING_DIR="$1"
ISO_PARTITION_TYPE="$2"
ISO_PARTITION_UUID="$3"
ISO_FS_DIR="$4"
GRUB_PARTITION_NUMBER="$5"

# temporary mount path for scanning the iso images
TMP_MOUNT_PATH="/mnt/grub-isos"

ISO_FS_PATH="/dev/disk/by-uuid/${ISO_PARTITION_UUID}"
ISO_MENUENTRY_FILE="/etc/grub.d/40_custom_isos"

# sudo mkdir -p "${TMP_MOUNT_PATH}"
# if ! sudo mount -o ro "${ISO_FS_PATH}" "${TMP_MOUNT_PATH}" >/dev/null ; then
#     colorEcho "${RED}Failed to mount partition containing ISO images, skipping ISOs..."
#     exit 1
# fi

colorEcho "${BLUE}Generating ISO image boot entries to ${FUCHSIA}${ISO_MENUENTRY_FILE}${BLUE}..."
if [[ ! -f "${ISO_MENUENTRY_FILE}" ]]; then
    sudo tee "${ISO_MENUENTRY_FILE}" >/dev/null <<-'EOF'
#!/bin/sh
exec tail -n +3 $0

# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
EOF
fi

ISO_PARTITION_TYPE=$(tr '[:upper:]' '[:lower:]' <<<"${ISO_PARTITION_TYPE}")
for isofile in "${ISO_STORING_DIR}"/*.iso ; do
    ISO_NAME=$(basename "${isofile}")
    echo "Found ISO image: ${ISO_NAME}" >&2
    case "${ISO_PARTITION_TYPE}" in
        btrfs)
            colorEcho "${FUCHSIA}BTRFS ${RED}Not supported."
            exit 1
#             sudo tee -a "${ISO_MENUENTRY_FILE}" >/dev/null <<-EOF
# menuentry "[ISO] ${ISO_NAME}" --class SystemRescueCD {
#     insmod btrfs

#     set isofile="${ISO_FS_DIR}/${ISO_NAME}"

#     search --no-floppy -f --set=iso_partition \${isofile}
#     probe -u \${iso_partition} --set=iso_partition_uuid
#     set imgdevpath="/dev/disk/by-uuid/\${iso_partition_uuid}"
#     loopback loop0 (\${iso_partition})\${isofile}

#     linux (loop0)/boot/vmlinuz-x86_64 img_dev=\${imgdevpath} img_loop=\${isofile} earlymodules=loop driver=free tz=Asia/Shanghai lang=zh_CN keytable=en copytoram
#     initrd (loop0)/boot/intel_ucode.img (loop0)/boot/amd_ucode.img (loop0)/boot/initramfs-x86_64.img
# }

# EOF
            ;;
		ntfs)
            sudo tee -a "${ISO_MENUENTRY_FILE}" >/dev/null <<-EOF
menuentry "[ISO] ${ISO_NAME}" --class SystemRescueCD {
    insmod ntfs

    set isofile="${ISO_FS_DIR}/${ISO_NAME}"

    search --no-floppy -f --set=iso_partition \${isofile}
    probe -u \${iso_partition} --set=iso_partition_uuid
    set imgdevpath="/dev/disk/by-uuid/\${iso_partition_uuid}"
    loopback loop0 (\${iso_partition})\${isofile}

    linux (loop0)/boot/vmlinuz-x86_64 img_dev=\${imgdevpath} img_loop=\${isofile} earlymodules=loop driver=free tz=Asia/Shanghai lang=zh_CN keytable=en copytoram
    initrd (loop0)/boot/intel_ucode.img (loop0)/boot/amd_ucode.img (loop0)/boot/initramfs-x86_64.img
}

EOF
            ;;
		*)
            sudo tee -a "${ISO_MENUENTRY_FILE}" >/dev/null <<-EOF
menuentry "[ISO] ${ISO_NAME}" --class SystemRescueCD {
    insmod ext2

    set isofile="${ISO_FS_DIR}/${ISO_NAME}"

    search --no-floppy -f --set=iso_partition \${isofile}
    probe -u \${iso_partition} --set=iso_partition_uuid
    set imgdevpath="/dev/disk/by-uuid/\${iso_partition_uuid}"
    loopback loop0 (\${iso_partition})\${isofile}

    linux (loop0)/boot/vmlinuz-x86_64 img_dev=\${imgdevpath} img_loop=\${isofile} earlymodules=loop driver=free tz=Asia/Shanghai lang=zh_CN keytable=en copytoram
    initrd (loop0)/boot/intel_ucode.img (loop0)/boot/amd_ucode.img (loop0)/boot/initramfs-x86_64.img
}

EOF
            ;;
    esac
done

sudo chmod +x "${ISO_MENUENTRY_FILE}"

# sudo umount "${TMP_MOUNT_PATH}"

colorEcho "${BLUE}ISOs on ${FUCHSIA}${ISO_FS_DIR}${BLUE} has been added to GRUB."
sudo cat "${ISO_MENUENTRY_FILE}"

colorEcho "${BLUE}Regenerate ${FUCHSIA}GRUB2 configuration${BLUE}..."
sudo mkinitcpio -P
# sudo update-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
