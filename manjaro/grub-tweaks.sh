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

## [Black Screen with Plymouth - Cause and Solution](https://forum.manjaro.org/t/black-screen-with-plymouth-cause-and-solution/156980)
## New installations
# ISO released with 2024 has late KMS enabled by default
# Using Nvidia you need to add a module to the kernel command line
# Early KMS can be enabled by adding the driver to `MODULES=()` array - usually you don’t need this with `gpus` that have kernel drivers.
## Existing installations
# Edit the file `/etc/mkinitcpio.conf` and apply changes according to your GPU
### Too boot a system showing blackscreen with `Nvidia`
# access the `grub` menu `Esc` - press `e` on the boot entry and add `nvidia_drm.modeset=1 nvidia_drm.fbdev=1` to kernel command line.
# Press `F10` to continue boot.
### All GPU (open source kernel driver)
# AMD, ATI, Intel, Nouveau
# HOOKS=(... kms ...)
# Optional
# MODULES=(... amdgpu ...)
# MODULES=(... radeon ...)
# MODULES=(... i915 ...)
# MODULES=(... nouveau ...)
# Rebuild initramfs
# `sudo mkinitcpio -P`
### Nvidia GPU (proprietary driver)
# Tests by the team shows that editing the default grub config in `/etc/default/grub` adding should be enough
# `GRUB_CMDLINE_LINUX_DEFAULT="... nvidia_drm.modeset=1  ..."`
# Rebuild your grub configuration
# `sudo grub-mkconfig -o /boot/grub/grub.cfg`
# If the above is not enough add this in addition to the above and rebuild the grub config
# `GRUB_CMDLINE_LINUX_DEFAULT="... nvidia_drm.fbdev=1 ..."`

# fix the "sparse file not allowed" error message on startup
colorEcho "${BLUE}Setting ${FUCHSIA}GRUB${BLUE}..."
sudo sed -i -e 's/^GRUB_SAVEDEFAULT=true/#GRUB_SAVEDEFAULT=true/g' \
    -e 's/^#GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/g' \
    -e 's/^GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/g' \
    -e 's/^GRUB_HIDDEN_TIMEOUT=0/#GRUB_HIDDEN_TIMEOUT=0/g' \
    -e 's/^GRUB_TIMEOUT=[[:digit:]]/GRUB_TIMEOUT=3/g' \
    -e 's/^#GRUB_REMOVE_LINUX_ROOTFLAGS=.*/GRUB_REMOVE_LINUX_ROOTFLAGS=true/g' \
    -e 's/^GRUB_REMOVE_LINUX_ROOTFLAGS=false/GRUB_REMOVE_LINUX_ROOTFLAGS=true/g' \
    -e 's/^#GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/g' \
    -e 's/^GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub

# if ! grep -q '^GRUB_DEFAULT=saved' /etc/default/grub; then
#     echo "GRUB_DEFAULT=saved" | sudo tee -a /etc/default/grub >/dev/null
# fi

# if ! grep -q '^GRUB_SAVEDEFAULT=true' /etc/default/grub; then
#     echo "GRUB_SAVEDEFAULT=true" | sudo tee -a /etc/default/grub >/dev/null
# fi

if ! grep -q '^GRUB_TIMEOUT_STYLE=menu' /etc/default/grub; then
    echo "GRUB_TIMEOUT_STYLE=menu" | sudo tee -a /etc/default/grub >/dev/null
fi

if ! grep -q '^GRUB_REMOVE_LINUX_ROOTFLAGS=true' /etc/default/grub; then
    echo "GRUB_REMOVE_LINUX_ROOTFLAGS=true" | sudo tee -a /etc/default/grub >/dev/null
fi

if ! grep -q '^GRUB_DISABLE_OS_PROBER=false' /etc/default/grub; then
    echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub >/dev/null
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
# colorEcho "${BLUE}Installing ${FUCHSIA}grub-customizer${BLUE}..."
# yay --noconfirm --needed -S aur/grub-customizer-git

# [A pack of GRUB2 themes for different Linux distributions and OSs](https://github.com/AdisonCavani/distro-grub-themes)
# Git_Clone_Update_Branch "AdisonCavani/distro-grub-themes" "$HOME/.config/grub-themes"

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
[[ -f "/etc/grub.d/60_memtest86+" ]] && sudo sed -i -e 's/--class memtest86/--class memtest/' "/etc/grub.d/60_memtest86+"
[[ -f "/etc/grub.d/60_memtest86+-efi" ]] && sudo sed -i -e 's/--class memtest86/--class memtest/' "/etc/grub.d/60_memtest86+-efi"

# Replace double quotes menuentry with single quotes
MenuEntry=$(sed -rn 's/.*menuentry "([^"]+).*/\1/ip' "/etc/grub.d/60_memtest86+" 2>/dev/null)
if [[ -n "${MenuEntry}" ]]; then
    sudo sed -i -e "s/\"${MenuEntry}\"/'${MenuEntry}'/g" "/etc/grub.d/60_memtest86+"
fi

MenuEntry=$(sed -rn 's/.*menuentry "([^"]+).*/\1/ip' "/etc/grub.d/60_memtest86+-efi" 2>/dev/null)
if [[ -n "${MenuEntry}" ]]; then
    sudo sed -i -e "s/\"${MenuEntry}\"/'${MenuEntry}'/g" "/etc/grub.d/60_memtest86+-efi"
fi

## [GRUB_OS_PROBER_SKIP_LIST](https://www.gnu.org/software/grub/manual/grub/html_node/Simple-configuration.html)
## List of space-separated FS UUIDs of filesystems to be ignored from os-prober output. For efi chainloaders it’s <UUID>@<EFI FILE>
## grep 'efi' /etc/fstab
## sudo ls -la /boot/efi/EFI
# sudo tee -a /etc/default/grub >/dev/null <<-EOF
# GRUB_OS_PROBER_SKIP_LIST="d32ccad4-bedd-40d3-9e40-b62a4c8a09ec@/dev/sda2 58EE-F18B@/efi/Microsoft/Boot/bootmgfw.efi"
# EOF

colorEcho "${BLUE}Regenerate ${FUCHSIA}GRUB2 configuration${BLUE}..."
sudo mkinitcpio -P
# sudo update-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
