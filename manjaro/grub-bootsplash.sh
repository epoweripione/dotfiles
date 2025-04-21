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

if [[ ! -x "$(command -v yay)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}yay${BLUE}..."
    sudo pacman --noconfirm --needed -S yay

    if [[ ! -x "$(command -v yay)" ]]; then
        colorEcho "${FUCHSIA}yay${RED} is not installed!"
        exit 1
    fi
fi

AppBootsplashInstallList=(
    # [Manjaro Bootsplash Manager](https://github.com/parov0z/bootsplash-manager)
    "bootsplash-manager"
    "bootsplash-systemd"
    "bootsplash-theme-manjaro"
    "lightdm-settings"
    "lightdm-slick-greeter"
    "plymouth"
    "plymouth-theme-manjaro-circle"
    "plymouth-theme-manjaro-elegant"
    "plymouth-theme-manjaro-extra-elegant"
    "terminus-font"
    ## [mkinitcpio-firmware](https://wiki.archlinux.org/title/Mkinitcpio#Possibly_missing_firmware_for_module_XXXX)
    ## Identify if you need the Firmware: `sudo dmesg | grep module_name`
    # sudo dmesg | grep xhci_pci
    "mkinitcpio-firmware"
)
InstallSystemPackages "" "${AppBootsplashInstallList[@]}"

if [[ ! -x "$(command -v bootsplash-manager)" ]]; then
    colorEcho "${FUCHSIA}bootsplash-manager${RED} is not installed!"
    exit 1
fi

# change login greeter to slick-greeter
sudo sed -i 's/greeter-session=lightdm-gtk-greeter/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf

## Fix: `WARNING: Possibly missing firmware for module: module_name`
## https://wiki.archlinux.org/title/Mkinitcpio#Possibly_missing_firmware_for_module_XXXX


# Fix: `loadkeys: Unable to open file: cn: No such file or directory`
# https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration
# /etc/vconsole.conf
# /usr/share/kbd/keymaps/
# /usr/share/kbd/consolefonts/
# localectl list-keymaps
sudo sed -i -e 's/KEYMAP=.*/KEYMAP=us/' -e 's/FONT=.*/FONT=tcvn8x16/' /etc/vconsole.conf

if ! grep -q '^KEYMAP=' /etc/vconsole.conf; then
    echo 'KEYMAP=us' | sudo tee -a /etc/vconsole.conf >/dev/null
fi

if ! grep -q '^FONT=' /etc/vconsole.conf; then
    echo 'FONT=tcvn8x16' | sudo tee -a /etc/vconsole.conf >/dev/null
fi

# Fix: `ERROR: module not found: bochs_drm` in KVM
if check_os_virtualized; then
    if grep -q ' bochs_drm ' /etc/mkinitcpio.conf; then
        sudo sed -i 's/ bochs_drm / /' /etc/mkinitcpio.conf
    fi
fi

# [Plymouth](https://wiki.manjaro.org/index.php/Plymouth)
# [Plymouth](https://wiki.archlinux.org/title/Plymouth)
# https://github.com/adi1090x/plymouth-themes
# /etc/plymouth/plymouthd.conf
# /usr/share/plymouth/themes
colorEcho "${BLUE}Setting ${FUCHSIA}Plymouth${BLUE}..."
if ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
    sudo sed -i 's/HOOKS="[^"]*/& plymouth/' /etc/mkinitcpio.conf
fi

if ! grep 'GRUB_CMDLINE_LINUX_DEFAULT' /etc/default/grub | grep -q 'splash'; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash/' /etc/default/grub
    # sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& systemd.show_status=1/' /etc/default/grub
    # sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet /GRUB_CMDLINE_LINUX_DEFAULT="/' /etc/default/grub
fi

## [on 64bit systems, install the kernel bootsplash](https://forum.manjaro.org/t/howto-enable-bootsplash-provided-by-the-kernel/119869)
## aren’t working anymore on Linux `6.4` and above
# if [[ "$(uname -m)" == "x86_64" ]]; then
#     ## Enable bootsplash-ask-password-console.path if encrypted disk is used
#     # sudo systemctl enable bootsplash-ask-password-console.path

#     # set boot splash
#     [[ -x "$(command -v bootsplash-manager)" ]] && sudo bootsplash-manager -s manjaro

#     # if ! grep -q 'bootsplash' /etc/mkinitcpio.conf; then
#     #     colorEcho "${BLUE}Setting ${FUCHSIA}kernel bootsplash${BLUE}..."
#     #     sudo sed -i 's/HOOKS="[^"]*/& bootsplash-manjaro/' /etc/mkinitcpio.conf
#     #     sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& bootsplash.bootfile=bootsplash-themes\/manjaro\/bootsplash/' /etc/default/grub
#     #     sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet /GRUB_CMDLINE_LINUX_DEFAULT="/' /etc/default/grub
#     # fi
# fi

# disable tmp.mount
colorEcho "${BLUE}Disabling ${FUCHSIA}tmp.mount${BLUE}..."
# sudo systemctl status tmp.mount && sudo systemctl is-enabled tmp.mount
sudo systemctl disable tmp.mount
sudo systemctl mask tmp.mount
sudo sed -i -e 's/^tmpfs.*/# &/g' /etc/fstab

## List plymouth themes
# ls /usr/share/plymouth/themes
# plymouth-set-default-theme -l

## Preview themes
# sudo plymouthd; sudo plymouth --show-splash; sleep 5; sudo plymouth --quit

# Change plymouth default theme
sudo plymouth-set-default-theme -R manjaro-circle
# sudo sed -i 's/ShowDelay=.*/ShowDelay=5/' /etc/plymouth/plymouthd.conf

## https://wiki.archlinux.org/title/mkinitcpio
# presets=()
# for file in "/etc/mkinitcpio.d/"*; do
#     presets+=("-p")
#     presets+=("$(sed 's/.preset//g' <<<"${file}")")
# done
# sudo mkinitcpio "${presets[@]}"

# sudo mkinitcpio -P
# sudo update-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
