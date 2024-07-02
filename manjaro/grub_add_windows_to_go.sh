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

## [Add "Windows To Go" external HDD to grub2 boot menu](https://askubuntu.com/questions/805021/add-windows-to-go-external-hdd-to-grub2-boot-menu)
## [How to add a GRUB2 menu entry for booting installed Ubuntu on a USB drive?](https://askubuntu.com/questions/344125/how-to-add-a-grub2-menu-entry-for-booting-installed-ubuntu-on-a-usb-drive)
# sudo parted -l print
# sudo fdisk -l
# sudo blkid | grep vfat | grep -i efi

WTG_EFI_DISK=$1
if [[ -z "${WTG_EFI_DISK}" ]]; then
    colorEcho "${BLUE}Usage: ${FUCHSIA}$(basename "$0")${BLUE} WTG-efi-filesystem-partition"
    colorEcho "${BLUE}Use ${FUCHSIA}sudo blkid | grep vfat | grep -i efi${BLUE} to check efi partition on WTG disk"
    colorEcho "${BLUE}eg: ${FUCHSIA}$(basename "$0")${YELLOW} /dev/sdc1"
    exit 1
fi

WTG_EFI_MOUNT="/mnt/wtgefi" && sudo mkdir -p "${WTG_EFI_MOUNT}"

if ! sudo mount "${WTG_EFI_DISK}" "${WTG_EFI_MOUNT}" 2>/dev/null; then
    colorEcho "${RED}Can't mount efi filesystem on ${FUCHSIA}${WTG_EFI_DISK}${RED}."
    exit 1
fi

WTG_FS_UUID=$(sudo grub-probe --target=fs_uuid "${WTG_EFI_MOUNT}/EFI/Microsoft/Boot/bootmgfw.efi" 2>/dev/null)
WTG_HINTS_STRING=$(sudo grub-probe --target=hints_string "${WTG_EFI_MOUNT}/EFI/Microsoft/Boot/bootmgfw.efi" 2>/dev/null)

sudo umount "${WTG_EFI_MOUNT}"

[[ -z "${WTG_FS_UUID}" || -z "${WTG_HINTS_STRING}" ]] && colorEcho "${RED}Can't find valid efi filesystem on ${FUCHSIA}${WTG_EFI_DISK}${RED}." && exit 1

ADD_WTG_MENUENTRY="N"
colorEchoN "${ORANGE}Add WTG menu entry on ${FUCHSIA}${WTG_EFI_DISK}${ORANGE} to GRUB?[y/${CYAN}N${ORANGE}]: "
read -r ADD_WTG_MENUENTRY
[[ "${ADD_WTG_MENUENTRY^^}" != "Y" ]] && exit 1

sudo tee -a "/etc/grub.d/40_custom" >/dev/null <<-EOF
menuentry 'Microsoft Windows WTG' --class windows {
    insmod part_gpt
    insmod fat
    insmod search_fs_uuid
    insmod chain
    search --fs-uuid --set=root ${WTG_HINTS_STRING} ${WTG_FS_UUID}
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
EOF

colorEcho "${BLUE}Please check the menuentry in ${FUCHSIA}/etc/grub.d/40_custom${BLUE}."
sudo nano "/etc/grub.d/40_custom"

colorEcho "${BLUE}Regenerate ${FUCHSIA}GRUB2 configuration${BLUE}..."
sudo mkinitcpio -P
# sudo update-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

colorEcho "${BLUE}Windows To Go on ${FUCHSIA}${WTG_EFI_DISK}${BLUE} has been added to GRUB."
sudo cat "/etc/grub.d/40_custom"
