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

# [grub-customizer](https://launchpad.net/grub-customizer)
colorEcho "${BLUE}Installing ${FUCHSIA}grub-customizer${BLUE}..."
yay --noconfirm --needed -S aur/grub-customizer-git

# [A pack of GRUB2 themes for different Linux distributions and OSs](https://github.com/AdisonCavani/distro-grub-themes)
Git_Clone_Update_Branch "AdisonCavani/distro-grub-themes" "$HOME/.config/grub-themes"

# [GRUB tweaks](https://github.com/VandalByte/grub-tweaks)

# grep 'GRUB_THEME' /etc/default/grub # GRUB_THEME="/usr/share/grub/themes/manjaro/theme.txt"
# ls /usr/share/grub/themes/manjaro/icons
[[ ! -s "/usr/share/grub/themes/manjaro/icons/memtest86.png" ]] && \
    sudo cp "/usr/share/grub/themes/manjaro/icons/memtest.png" "/usr/share/grub/themes/manjaro/icons/memtest86.png"

# Adding icons for Submenus
colorEcho "${BLUE}Adding icons for GRUB Submenus..."
# Advanced options
if ! grep -q "class os \\\\\$menuentry_id_option 'gnulinux-advanced-\$boot_device_id'" "/etc/grub.d/10_linux"; then
    sudo sed -i -e "s/\\\\\$menuentry_id_option 'gnulinux-advanced-\$boot_device_id'/--class manjaro --class gnu-linux --class gnu --class os \\\\\$menuentry_id_option 'gnulinux-advanced-\$boot_device_id'/" "/etc/grub.d/10_linux"
fi

# UEFI
if ! grep -q "menuentry '\$LABEL' --class efi" "/etc/grub.d/30_uefi-firmware"; then
    sudo sed -i -e "s/^menuentry '\$LABEL'/menuentry '\$LABEL' --class efi/" "/etc/grub.d/30_uefi-firmware"
fi

# Select snapshot
if ! grep -q "submenu '\${submenuname}' --class recovery" "/etc/grub.d/41_snapshots-btrfs"; then
    sudo sed -i -e "s/^submenu '\${submenuname}'/submenu '\${submenuname}' --class recovery/" "/etc/grub.d/41_snapshots-btrfs"
fi

# Memory Tester
sudo sed -i -e 's/--class memtest86/--class memtest/' "/etc/grub.d/60_memtest86+"
sudo sed -i -e 's/--class memtest86/--class memtest/' "/etc/grub.d/60_memtest86+-efi"

colorEcho "${BLUE}Regenerate ${FUCHSIA}GRUB2 configuration${BLUE}..."
sudo mkinitcpio -P
# sudo update-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
