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

# fix the "sparse file not allowed" error message on startup
colorEcho "${BLUE}Setting ${FUCHSIA}GRUB${BLUE}..."
sudo sed -i -e 's/^GRUB_SAVEDEFAULT=true/#GRUB_SAVEDEFAULT=true/g' \
    -e 's/^#GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/g' \
    -e 's/^GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/g' \
    -e 's/^GRUB_HIDDEN_TIMEOUT=0/#GRUB_HIDDEN_TIMEOUT=0/g' \
    -e 's/^GRUB_TIMEOUT=[[:digit:]]/GRUB_TIMEOUT=3/g' /etc/default/grub

if ! grep -q '^GRUB_REMOVE_LINUX_ROOTFLAGS=true' /etc/default/grub; then
    echo "GRUB_REMOVE_LINUX_ROOTFLAGS=true" | sudo tee -a /etc/default/grub >/dev/null
fi

## [GRUB/Tips and tricks](https://wiki.archlinux.org/title/GRUB/Tips_and_tricks)
## [Grub menu working but hidden, can't make it visible](https://askubuntu.com/questions/1142167/grub-menu-working-but-hidden-cant-make-it-visible)
# sudo sed -i -e 's/^MODULES=(/MODULES=(i915 /'  -e 's/ )/)/g' -e 's/^MODULES="/MODULES="i915 /'  -e 's/ "/"/g' /etc/mkinitcpio.conf
# sudo sed -i -e 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=640x480/g' /etc/default/grub
# sudo sed -i -e 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=1024x768x32/g' /etc/default/grub
# sudo sed -i -e '/^prefix/i\echo "videoinfo"' /etc/grub.d/00_header
if ! grep -q 'sleep .5' /etc/grub.d/00_header; then
    # sudo sed -i -e '/^[[:space:]]\+load_video/i\  sleep .5' /etc/grub.d/00_header
    sudo sed -i -e '/^\s\+load_video/i\  sleep .5' /etc/grub.d/00_header
fi

## If grub graphical mode still not showing, enable console mode
# sudo sed -i -e 's/^#GRUB_TERMINAL_INPUT=console/GRUB_TERMINAL_INPUT=console/g' /etc/default/grub
# sudo sed -i -e 's/^#GRUB_TERMINAL_OUTPUT=console/GRUB_TERMINAL_OUTPUT=console/g' /etc/default/grub

# Load LUKS2 Grub module
ROOT_DEV=$(df -hT | grep '/$' | awk '{print $1}')
ROOT_TYPE=$(sudo lsblk -no TYPE "${ROOT_DEV}")
if [[ "${ROOT_TYPE}" == "crypt" ]]; then
    # sudo sed -i -e 's/GRUB_PRELOAD_MODULES=.*/GRUB_PRELOAD_MODULES="part_gpt part_msdos argon2 gcry_sha512"/g' /etc/default/grub
    if ! grep -q '^GRUB_ENABLE_CRYPTODISK=y' /etc/default/grub; then
        echo "GRUB_ENABLE_CRYPTODISK=y" | sudo tee -a /etc/default/grub >/dev/null
    fi
fi

# grub language
colorEcho "${BLUE}Setting ${FUCHSIA}GRUB language${BLUE}..."
GRUB_LANG=$(localectl status | grep 'LANG=' | cut -d= -f2 | cut -d. -f1)
if [[ -z "${GRUB_LANG}" ]]; then
    GRUB_LANG=$(grep '^LANG=' /etc/locale.conf | cut -d= -f2 | cut -d. -f1)
fi

if [[ -n "${GRUB_LANG}" ]]; then
    sudo sed -i "s/grub_lang=.*/grub_lang=\"${GRUB_LANG}\"/" "/etc/grub.d/00_header"
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
    sudo sed -i -e "s/menuentry '\$LABEL'/menuentry '\$LABEL' --class efi/" "/etc/grub.d/30_uefi-firmware"
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
