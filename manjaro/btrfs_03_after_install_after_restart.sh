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

## after the first start

# [Btrfs snapshots with snapper, with easy rollback](https://github.com/hrotkogabor/manjaro-btrfs)
# [Manjaro 21.0 with btrfs + snapper + grub-btrfs](https://theduckchannel.github.io/post/2021/08/27/manjaro-21.0-with-btrfs-+-snapper-+-grub-btrfs/)
# [Snapper](https://wiki.archlinux.org/title/snapper)

# remove timeshift, as we do it with snapper
colorEcho "${BLUE}Removing ${FUCHSIA}timeshift${BLUE}..."
sudo pacman --noconfirm -R timeshift-autosnap-manjaro timeshift

# enable AUR
colorEcho "${BLUE}Enabling ${FUCHSIA}AUR${BLUE}..."
if grep -q "#EnableAUR" /etc/pamac.conf; then
    sudo sed -i -e 's/#EnableAUR/EnableAUR/g' /etc/pamac.conf
    #enable color
    sudo sed -i -e 's/#Color/Color/g' /etc/pacman.conf
fi

# try to set up the fastest mirror
# https://wiki.manjaro.org/index.php/Pacman-mirrors
colorEcho "${BLUE}Setting ${FUCHSIA}pacman mirrors${BLUE}..."
# sudo pacman-mirrors -i -c China -m rank
# sudo pacman-mirrors -i --continent --timeout 2 -m rank
sudo pacman-mirrors -i --geoip --timeout 2 -m rank

# do full upgrade
colorEcho "${BLUE}Doing ${FUCHSIA}full upgrade${BLUE}..."
sudo pacman --noconfirm -Syu

# sync system time
colorEcho "${BLUE}Syncing ${FUCHSIA}system time${BLUE}..."
sudo pacman --noconfirm --needed -S ntp chrony

if ! grep -q "pool ntp.aliyun.com iburst" /etc/chrony.conf; then
    sudo sed -i -e "s/^pool/# &/g" \
        -e "/^# pool/a\pool ntp.aliyun.com iburst" \
        -e "/^# pool/a\pool ntp.tencent.com iburst" /etc/chrony.conf
fi

sudo timedatectl set-ntp yes

sudo systemctl enable chronyd
sudo systemctl start chronyd

# chronyc activity
chronyc sourcestats -v
chronyc tracking
# timedatectl set-timezone Asia/Shanghai
timedatectl status

colorEcho "${BLUE}Installing ${FUCHSIA}yay${BLUE}..."
sudo pacman --noconfirm --needed -S yay

colorEcho "${BLUE}Installing ${FUCHSIA}manjaro-tools-base, zenity, inotify-tools${BLUE}..."
sudo pacman --noconfirm --needed -S manjaro-tools-base zenity inotify-tools

# [compsize](https://github.com/kilobyte/compsize)
colorEcho "${BLUE}Installing ${FUCHSIA}compsize${BLUE}..."
sudo pacman --noconfirm --needed -S compsize
# sudo compsize -x /

# change login greeter to slick-greeter
colorEcho "${BLUE}Changing login greeter to ${FUCHSIA}slick-greeter${BLUE}..."
sudo pacman --noconfirm --needed -S lightdm-settings lightdm-slick-greeter
sudo sed -i 's/greeter-session=lightdm-gtk-greeter/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf

# [Enable LUKS2 and Argon2 support for Grub in Manjaro/Arch](https://mdleom.com/blog/2022/11/27/grub-luks2-argon2/)
ROOT_DEV=$(df -hT | grep '/$' | awk '{print $1}')
ROOT_TYPE=$(sudo lsblk -no TYPE "${ROOT_DEV}")

# sudo dmsetup info "${ROOT_DEV}" # /dev/dm-0
ROOT_LUKS=""
ROOT_DISK=$(sudo blkid -t TYPE="crypto_LUKS" | grep 'PARTLABEL="root"' | cut -d: -f1)
if sudo lsblk -no FSTYPE,FSVER --fs "${ROOT_DISK}" 2>/dev/null | grep -q -i 'LUKS\s1'; then
    ROOT_LUKS="luks1"
fi

if [[ "${ROOT_TYPE}" == "crypt" && "${ROOT_LUKS}" == "luks1" ]]; then
    [[ ! -s "/etc/default/grub.luks1" ]] && sudo cp "/etc/default/grub" "/etc/default/grub.luks1"

    colorEcho "${BLUE}Installing ${FUCHSIA}Build deps${BLUE}..."
    sudo pacman --noconfirm --needed -S base-devel cmake patch pkg-config automake

    colorEcho "${BLUE}Installing ${FUCHSIA}grub-improved-luks2-git${BLUE}..."
    yay --needed -S grub-improved-luks2-git

    sudo cp "/etc/default/grub.luks1" "/etc/default/grub"
fi

# on 64bit systems, install the kernel bootsplash
# https://forum.manjaro.org/t/howto-enable-bootsplash-provided-by-the-kernel/119869
if [[ "$(uname -m)" == "x86_64" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}kernel bootsplash${BLUE}..."
    sudo pacman --noconfirm --needed -S bootsplash-theme-manjaro bootsplash-systemd

    ## Enable bootsplash-ask-password-console.path if encrypted disk is used
    # sudo systemctl enable bootsplash-ask-password-console.path

    # [Manjaro Bootsplash Manager](https://github.com/parov0z/bootsplash-manager)
    colorEcho "${BLUE}Installing ${FUCHSIA}bootsplash-manager${BLUE}..."
    sudo pacman --noconfirm --needed -S bootsplash-manager

    # Fix: `WARNING: Possibly missing firmware for module: module_name`
    # https://wiki.archlinux.org/title/Mkinitcpio#Possibly_missing_firmware_for_module_XXXX
    # Identify if you need the Firmware: `sudo dmesg | grep module_name`
    colorEcho "${BLUE}Installing ${FUCHSIA}mkinitcpio-firmware${BLUE}..."
    # sudo dmesg | grep xhci_pci
    yay --noconfirm --needed -S mkinitcpio-firmware

    # Fix: `loadkeys: Unable to open file: cn: No such file or directory`
    # https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration
    # /etc/vconsole.conf
    # /usr/share/kbd/keymaps/
    # /usr/share/kbd/consolefonts/
    colorEcho "${BLUE}Installing ${FUCHSIA}terminus-font${BLUE}..."
    # localectl list-keymaps
    sudo pacman --noconfirm --needed -S terminus-font
    sudo sed -i -e 's/KEYMAP=.*/KEYMAP=us/' -e 's/FONT=.*/FONT=tcvn8x16/' /etc/vconsole.conf

    # Fix: `ERROR: module not found: bochs_drm` in KVM
    if check_os_virtualized; then
        sudo sed -i 's/ bochs_drm / /' /etc/mkinitcpio.conf
        sudo mkinitcpio -P
    fi

    # [Plymouth](https://wiki.manjaro.org/index.php/Plymouth)
    # https://github.com/adi1090x/plymouth-themes
    # /etc/plymouth/plymouthd.conf
    # /usr/share/plymouth/themes
    sudo pacman --noconfirm --needed -S plymouth plymouth-theme-manjaro-elegant
    if ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
        sudo sed -i 's/HOOKS="[^"]*/& plymouth/' /etc/mkinitcpio.conf
    fi

    # set boot splash
    sudo bootsplash-manager -s manjaro
    # if ! grep -q 'bootsplash' /etc/mkinitcpio.conf; then
    #     colorEcho "${BLUE}Setting ${FUCHSIA}kernel bootsplash${BLUE}..."
    #     sudo sed -i 's/HOOKS="[^"]*/& bootsplash-manjaro/' /etc/mkinitcpio.conf
    #     sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& bootsplash.bootfile=bootsplash-themes\/manjaro\/bootsplash/' /etc/default/grub
    #     sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet /GRUB_CMDLINE_LINUX_DEFAULT="/' /etc/default/grub

    #     ## https://wiki.archlinux.org/title/mkinitcpio
    #     # presets=()
    #     # for file in "/etc/mkinitcpio.d/"*; do
    #     #     presets+=("-p")
    #     #     presets+=("$(sed 's/.preset//g' <<<"${file}")")
    #     # done
    #     # sudo mkinitcpio "${presets[@]}"

    #     sudo mkinitcpio -P
    # fi
fi

# disable speaker
colorEcho "${BLUE}Disabling ${FUCHSIA}speaker${BLUE}..."
echo "blacklist pcspkr"  | sudo tee -a /etc/modprobe.d/nobeep.conf >/dev/null

# disable tmp.mount
colorEcho "${BLUE}Disabling ${FUCHSIA}tmp.mount${BLUE}..."
# sudo systemctl status tmp.mount && sudo systemctl is-enabled tmp.mount
sudo systemctl disable tmp.mount
sudo systemctl mask tmp.mount
sudo sed -i -e 's/^tmpfs.*/# &/g' /etc/fstab

# disable core dump
colorEcho "${BLUE}Disabling ${FUCHSIA}core dump${BLUE}..."
sudo mkdir -p /etc/systemd/coredump.conf.d && \
    sudo touch /etc/systemd/coredump.conf.d/custom.conf && \
    echo -e "[Coredump]\nStorage=none" | sudo tee /etc/systemd/coredump.conf.d/custom.conf >/dev/null && \
    sudo systemctl daemon-reload

## Snapper
# skip snapshots from updatedb
colorEcho "${BLUE}Installing ${FUCHSIA}mlocate${BLUE} & disabling ${FUCHSIA}btrfs snapshots from updatedb${BLUE}..."
sudo pacman --noconfirm --needed -S mlocate
if ! grep -q '.snapshots' /etc/updatedb.conf; then
    sudo sed -i -e 's/PRUNENAMES = "/PRUNENAMES = ".snapshots /g' /etc/updatedb.conf
fi

# disable cron integration
colorEcho "${BLUE}Disabling ${FUCHSIA}snapper cron integration${BLUE}..."
if ! grep -q '^NoExtract.*' /etc/pacman.conf; then
    sudo sed -i '0,/^#\s*NoExtract/{s/^#\s*NoExtract.*/NoExtract=/}' /etc/pacman.conf
fi

if grep -q '^NoExtract.*' /etc/pacman.conf; then
    NoExtract=$(grep '^NoExtract' /etc/pacman.conf | cut -d"=" -f2)
    if [[ -z "${NoExtract}" ]]; then
        sudo sed -i "s|^NoExtract.*|NoExtract=etc/cron.daily/snapper etc/cron.hourly/snapper|" /etc/pacman.conf
    elif [[ "${NoExtract}" != *"snapper"* ]]; then
        sudo sed -i "s|^NoExtract.*|NoExtract=${NoExtract} etc/cron.daily/snapper etc/cron.hourly/snapper|" /etc/pacman.conf
    fi
fi

## to see snapshot size in snapper list, this will slow down snapshot list
# sudo btrfs quota enable /

colorEcho "${BLUE}Installing ${FUCHSIA}snapper${BLUE}..."
sudo pacman --noconfirm --needed -S snapper

colorEcho "${BLUE}Creating ${FUCHSIA}snapper config${BLUE}..."
# Fix: `Creating config failed (creating btrfs subvolume .snapshots failed since it already exists)`
sudo umount /.snapshots && sudo rm -r /.snapshots
sudo umount /home/.snapshots && sudo rm -r /home/.snapshots

# /etc/conf.d/snapper
sudo snapper -c root create-config /
sudo snapper -c root set-config NUMBER_LIMIT=6 NUMBER_LIMIT_IMPORTANT=4

sudo snapper -c home create-config /home
sudo snapper -c home set-config NUMBER_LIMIT=6 NUMBER_LIMIT_IMPORTANT=4

## move snapshots to a separate subvolume
## already done in `btrfs_01_before_install.sh`
# ROOT_DEV=$(mount | grep ' on / ' | cut -d' ' -f1)
# sudo btrfs subvolume delete /.snapshots
# sudo btrfs subvolume delete /home/.snapshots
# sudo mount -o subvolid=0 "${ROOT_DEV}" /mnt
# sudo btrfs subvolume create /mnt/@rootsnaps
# sudo btrfs subvolume create /mnt/@homesnaps
# sudo mkdir -p /mnt/@/.snapshots
# sudo mkdir -p /mnt/@home/.snapshots
# sudo umount /mnt
# FSTAB_HOME=$(grep /home /etc/fstab | grep UUID)
# if [[ -n "${FSTAB_HOME}" ]]; then
#     echo "${FSTAB_HOME//home/.snapshots}" \
#         | sed 's|subvol=/@.snapshots|subvol=/@rootsnaps|' \
#         | sudo tee -a /etc/fstab >/dev/null
#     echo "${FSTAB_HOME//home/.snapshots}" \
#         | sed 's|subvol=/@.snapshots|subvol=/@homesnaps|' \
#         | sed 's|/.snapshots|/home/.snapshots|' \
#         | sudo tee -a /etc/fstab >/dev/null
# fi

sudo btrfs subvolume delete /.snapshots
sudo mkdir -p /.snapshots && sudo mount /.snapshots

sudo btrfs subvolume delete /home/.snapshots
sudo mkdir -p /home/.snapshots && sudo mount /home/.snapshots

# sudo chmod a+rx /.snapshots && sudo chown :"$(id -ng)" /.snapshots
sudo chmod 750 /.snapshots && sudo chown :wheel /.snapshots
sudo chmod 750 /home/.snapshots && sudo chown :wheel /home/.snapshots

# [Some BTRFS subvolumes not mounted at boot](https://bbs.archlinux.org/viewtopic.php?id=273161)
# [Adjust Mount Options](https://www.jwillikers.com/adjust-mount-options)
SUBVOL_NEST_LSIT=(
    "@home"
    # "@local"
    "@opt"
    "@srv"
    "@var"
    "@tmp"
    "@rootsnaps"
    "@homesnaps-/home"
)

# [How to set filesystems mount order on modern Linux distributions](https://linuxconfig.org/how-to-set-filesystems-mount-order-on-modern-linux-distributions)
for TargetVol in "${SUBVOL_NEST_LSIT[@]}"; do
    [[ -z "${TargetVol}" ]] && continue

    SUBVOL_NAME=$(awk -F'-' '{print $1}' <<<"${TargetVol}")
    SUBVOL_REQUIRES=$(awk -F'-' '{print $2}' <<<"${TargetVol}")
    [[ -z "${SUBVOL_REQUIRES}" ]] && SUBVOL_REQUIRES="/"
    if ! grep "subvol=/${SUBVOL_NAME}," /etc/fstab | grep -q 'requires-mounts-for'; then
        sudo sed -i -e "s|subvol=/${SUBVOL_NAME},|subvol=/${SUBVOL_NAME},x-systemd.requires-mounts-for=${SUBVOL_REQUIRES},|" /etc/fstab
    fi
done

## [Fstab - Use SystemD automount](https://wiki.manjaro.org/index.php/Fstab_-_Use_SystemD_automount)
# for TargetVol in "${SUBVOL_NEST_LSIT[@]}"; do
#     [[ -z "${TargetVol}" ]] && continue

#     SUBVOL_NAME=$(awk -F'-' '{print $1}' <<<"${TargetVol}")
#     if ! grep "subvol=/${SUBVOL_NAME}," /etc/fstab | grep -q 'noauto,x-systemd.automount'; then
#         sudo sed -i -e "s|subvol=/${SUBVOL_NAME},|subvol=/${SUBVOL_NAME},noauto,x-systemd.automount,|" /etc/fstab
#     fi
# done

sudo systemctl daemon-reload
# sudo systemctl restart local-fs.target
# systemctl list-unit-files -t mount

# install btrfs stuff
# https://github.com/Antynea/grub-btrfs
colorEcho "${BLUE}Installing ${FUCHSIA}snap-pac, grub-btrfs, snapper-gui${BLUE}..."
sudo pacman --noconfirm --needed -S snap-pac grub-btrfs snapper-gui
sudo sed -i -e 's/#GRUB_BTRFS_SUBMENUNAME="Arch Linux snapshots"/GRUB_BTRFS_SUBMENUNAME="Select snapshot"/g' /etc/default/grub-btrfs/config

## rollback to a previous state
# If you want to go back to a previous state of the system, 
# you must reboot, and select the snapshot from the grub menu (under 'Select snapshot') to boot into. 
# After you login, a window will warn you, that this is a read only snapshot. 
# It also give you the command to do the rollback. 
# After you are sure that you want to rollback to that state, 
# you should run: `sudo btrfs_snapper_do_rollback.sh` from the terminal, 
# as this script is installed on the system already.
# After the reboot, you will get back the selected state of your system, like a time travel.
# Note: The user's /home partition is not contained in the snapshot.
colorEcho "${BLUE}Installing ${FUCHSIA}btrfs scripts${BLUE}..."
sudo mkdir -p /usr/local/bin

if [[ -d "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro" ]]; then
    sudo cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/btrfs_ro_alert.sh" /usr/local/bin
    sudo cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/btrfs_snapper_do_rollback.sh" /usr/local/bin
    sudo cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/btrfs_grub_install_chroot.sh" /usr/local/bin
elif [[ -s "${CURRENT_DIR}/btrfs_ro_alert.sh" ]]; then
    sudo cp "${CURRENT_DIR}/btrfs_ro_alert.sh" /usr/local/bin
    sudo cp "${CURRENT_DIR}/btrfs_snapper_do_rollback.sh" /usr/local/bin
    sudo cp "${CURRENT_DIR}/manjaro/btrfs_grub_install_chroot.sh" /usr/local/bin
fi

[[ -s "/usr/local/bin/btrfs_ro_alert.sh" ]] && sudo chmod +x "/usr/local/bin/btrfs_ro_alert.sh"
[[ -s "/usr/local/bin/btrfs_snapper_do_rollback.sh" ]] && sudo chmod +x "/usr/local/bin/btrfs_snapper_do_rollback.sh"
[[ -s "/usr/local/bin/btrfs_grub_install_chroot.sh" ]] && sudo chmod +x "/usr/local/bin/btrfs_grub_install_chroot.sh"

# run btrfs read-only check after login
colorEcho "${BLUE}Installing script for ${FUCHSIA}btrfs read-only check after login${BLUE}..."
echo '[Desktop Entry]
Type=Application
Encoding=UTF-8
Exec=/usr/local/bin/btrfs_ro_alert.sh
Name=Btrfs read only check
NoDisplay=true
X-GNOME-AutoRestart=true
Terminal=false
X-GNOME-Autostart-Delay=5' | sudo tee /etc/xdg/autostart/btrfs-ro-alert.desktop >/dev/null

# multi thread compression
colorEcho "${BLUE}Installing ${FUCHSIA}lbzip2, pigz${BLUE} & enabling ${FUCHSIA}multi thread compression${BLUE}..."
sudo pacman --noconfirm --needed -S lbzip2 pigz
cd /usr/local/bin && \
    sudo ln -s /usr/bin/lbzip2 bzip2 && \
    sudo ln -s /usr/bin/lbzip2 bunzip2 && \
    sudo ln -s /usr/bin/lbzip2 bzcat && \
    sudo ln -s /usr/bin/pigz gzip

# Start the snapper services
colorEcho "${BLUE}Starting the ${FUCHSIA}snapper${BLUE} services..."
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
# sudo systemctl enable --now snapper-boot.timer
sudo systemctl enable --now grub-btrfsd.service

colorEcho "${BLUE}List ${FUCHSIA}snapper configs${BLUE}..."
snapper list-configs

# Access for non-root users
# Set snapshot limits: only 5 hourly snapshots, 7 daily ones, no monthly and no yearly ones
colorEcho "${BLUE}Setting ${FUCHSIA}snapper configs${BLUE}..."
sudo sed -i -e 's/ALLOW_GROUPS=.*/ALLOW_GROUPS="wheel"/' \
        -e 's/TIMELINE_MIN_AGE=.*/TIMELINE_MIN_AGE="1800"/' \
        -e 's/TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' \
        -e 's/TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
        -e 's/TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' \
        -e 's/TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' \
        -e 's/TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
    /etc/snapper/configs/root

sudo sed -i -e 's/ALLOW_GROUPS=.*/ALLOW_GROUPS="wheel"/' \
        -e 's/TIMELINE_MIN_AGE=.*/TIMELINE_MIN_AGE="1800"/' \
        -e 's/TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' \
        -e 's/TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
        -e 's/TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' \
        -e 's/TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' \
        -e 's/TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
    /etc/snapper/configs/home

colorEcho "${BLUE}List snapshots on ${FUCHSIA}/${BLUE}..."
sudo snapper -c root list

colorEcho "${BLUE}List snapshots on ${FUCHSIA}/home${BLUE}..."
sudo snapper -c home list

## Manual Single snapshots
# snapper -c home create -c number
# snapper -c home create -c timeline

## Delete a snapshot
## To delete a snapshot number N do:
# snapper -c config delete N
# snapper -c root delete 65 70
# snapper -c root delete 65-70
## To free the space used by the snapshot(s) immediately, use --sync:
# snapper -c root delete --sync 65
# Note: When deleting a `pre` snapshot, you should always delete its corresponding `post` snapshot and vice versa.

# install snap-pac-grub from AUR
colorEcho "${BLUE}Installing ${FUCHSIA}snap-pac-grub${BLUE} from AUR..."
# mkdir -p "$HOME/aur" && export GNUPGHOME="$HOME/aur"
yay -aS --sudoloop --noredownload --norebuild --noconfirm --noeditmenu snap-pac-grub

# GRUB tweaks & Regenrate GRUB2 configuration
[[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/grub-tweaks.sh" ]] && source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/grub-tweaks.sh"

# colorEcho "${BLUE}Regenerate ${FUCHSIA}GRUB2 configuration${BLUE}..."
# sudo mkinitcpio -P
# # sudo update-grub
# sudo grub-mkconfig -o /boot/grub/grub.cfg

echo ""
colorEcho "${BLUE}Btrfs with snapper and grub ready. You should restart."
# read -r
