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

# try to set up the fastest mirror
# https://wiki.manjaro.org/index.php/Pacman-mirrors
if ! sudo test -f "/etc/pacman-mirrors.conf"; then
    colorEcho "${BLUE}Setting ${FUCHSIA}pacman mirrors${BLUE}..."
    # sudo pacman-mirrors -i -c China,Taiwan -m rank
    # sudo pacman-mirrors -i --continent --timeout 2 -m rank
    sudo pacman-mirrors -i --geoip --timeout 2 -m rank
fi

# Enable AUR, Snap, Flatpak in pamac
sudo sed -i -e 's|^#EnableAUR|EnableAUR|' \
    -e 's|^#EnableSnap|EnableSnap|' \
    -e 's|^#EnableFlatpak|EnableFlatpak|' /etc/pamac.conf

# Show colorful output on the terminal
sudo sed -i 's|^#Color|Color|' /etc/pacman.conf

# do full upgrade
colorEcho "${BLUE}Doing ${FUCHSIA}full upgrade${BLUE}..."
sudo pacman --noconfirm -Syu

if [[ ! -x "$(command -v yay)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}yay${BLUE}..."
    sudo pacman --noconfirm --needed -S yay

    if [[ ! -x "$(command -v yay)" ]]; then
        colorEcho "${FUCHSIA}yay${RED} is not installed!"
        exit 1
    fi
fi

AppSnapperInstallList=(
    # Build deps
    "automake"
    "base-devel"
    "cmake"
    "mlocate"
    "patch"
    "pkg-config"
    # [compsize - btrfs: find compression type/ratio on a file or set of files](https://github.com/kilobyte/compsize)
    "compsize"
    # [Btrfs Assistant](https://gitlab.com/btrfs-assistant/btrfs-assistant)
    "btrfs-assistant"
    # [grub-btrfs](https://github.com/Antynea/grub-btrfs)
    "grub-btrfs"
    # [snap-pac - Pacman hooks that use snapper to create pre/post btrfs snapshots](https://github.com/wesbarnett/snap-pac)
    "snap-pac"
    # [Snapper - helps with managing snapshots of Btrfs subvolumes and thin-provisioned LVM volumes](https://wiki.archlinux.org/title/Snapper)
    "snapper"
    "snapper-gui"
    ## [Limine - an advanced, portable, multiprotocol boot loader](https://wiki.archlinux.org/title/Limine)
    ## [Limine-Snapper-Sync: The tool syncs Limine boot entries with Snapper snapshots (Btrfs snapshots)](https://gitlab.com/Zesko/limine-snapper-sync)
    # "limine"
    # "limine-mkinitcpio-hook"
    # "limine-snapper-sync"
)
InstallSystemPackages "" "${AppSnapperInstallList[@]}"

if [[ ! -x "$(command -v snapper)" ]]; then
    colorEcho "${FUCHSIA}snapper${RED} is not installed!"
    exit 1
fi

# remove timeshift, as we do it with snapper
colorEcho "${BLUE}Removing ${FUCHSIA}timeshift${BLUE}..."
sudo pacman --noconfirm -R timeshift-autosnap-manjaro timeshift

# [Enable LUKS2 and Argon2 support for Grub in Manjaro/Arch](https://mdleom.com/blog/2022/11/27/grub-luks2-argon2/)
ROOT_DEV=$(df -hT | grep '/$' | awk '{print $1}')
ROOT_TYPE=$(sudo lsblk -no TYPE "${ROOT_DEV}")

# sudo dmsetup info "${ROOT_DEV}" # /dev/dm-0
ROOT_LUKS=""
ROOT_DISK=$(sudo blkid -t TYPE="crypto_LUKS" | grep 'PARTLABEL="root"' | cut -d: -f1)
if [[ -n "${ROOT_DISK}" ]]; then
    if sudo lsblk -no FSTYPE,FSVER --fs "${ROOT_DISK}" 2>/dev/null | grep -q -i 'LUKS\s1'; then
        ROOT_LUKS="luks1"
    fi
fi

if [[ "${ROOT_TYPE}" == "crypt" && "${ROOT_LUKS}" == "luks1" ]]; then
    [[ ! -s "/etc/default/grub.luks1" ]] && sudo cp "/etc/default/grub" "/etc/default/grub.luks1"

    colorEcho "${BLUE}Installing ${FUCHSIA}Build deps${BLUE}..."
    sudo pacman --noconfirm --needed -S base-devel cmake patch pkg-config automake

    # [grub-improved-luks2-git](https://aur.archlinux.org/packages/grub-improved-luks2-git)
    colorEcho "${BLUE}Installing ${FUCHSIA}grub-improved-luks2-git${BLUE}..."
    yay --needed -S grub-improved-luks2-git

    sudo cp "/etc/default/grub.luks1" "/etc/default/grub"
fi

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
colorEcho "${BLUE}Disabling ${FUCHSIA}btrfs snapshots from updatedb${BLUE}..."
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

colorEcho "${BLUE}Creating ${FUCHSIA}snapper config${BLUE}..."
# /etc/conf.d/snapper
if ! snapper list-configs 2>/dev/null | grep -q "root"; then
    # Fix: `Creating config failed (creating btrfs subvolume .snapshots failed since it already exists)`
    sudo umount /.snapshots && sudo rm -r /.snapshots

    sudo snapper -c root create-config /
    sudo snapper -c root set-config NUMBER_LIMIT=6 NUMBER_LIMIT_IMPORTANT=4

    sudo btrfs subvolume delete /.snapshots
    sudo mkdir -p /.snapshots && sudo mount /.snapshots
fi

if ! snapper list-configs 2>/dev/null | grep -q "home"; then
    sudo umount /home/.snapshots && sudo rm -r /home/.snapshots

    sudo snapper -c home create-config /home
    sudo snapper -c home set-config NUMBER_LIMIT=6 NUMBER_LIMIT_IMPORTANT=4

    sudo btrfs subvolume delete /home/.snapshots
    sudo mkdir -p /home/.snapshots && sudo mount /home/.snapshots
fi

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

## manual delete all `@homesnaps` snapshots
# ROOT_DEV=$(mount | grep ' on / ' | cut -d' ' -f1)
# sudo mount -o subvolid=0 "${ROOT_DEV}" /mnt
# sudo btrfs subvolume list -apt /mnt
# SNAPS_TO_DELETE=$(sudo btrfs subvolume list -apt / | grep 'homesnaps' | grep '<FS_TREE>' | awk '{print $NF}')
# SNAPS_LIST=()
# while read -r opts; do SNAPS_LIST+=("${opts}"); done < <(tr ' ' '\n'<<<"${SNAPS_TO_DELETE}")
# for Target in "${SNAPS_LIST[@]}"; do sudo btrfs subvolume delete "${Target/<FS_TREE>\///mnt/}"; done


## sudo chmod a+rx /.snapshots && sudo chown :"$(id -ng)" /.snapshots
# sudo chmod 750 /.snapshots && sudo chown :wheel /.snapshots
# sudo chmod 750 /home/.snapshots && sudo chown :wheel /home/.snapshots

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

# Grub menu `Select snapshot`
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
if ! sudo test -f "/etc/snapper/configs/root"; then
    sudo sed -i -e 's/ALLOW_GROUPS=.*/ALLOW_GROUPS="wheel"/' \
            -e 's/TIMELINE_MIN_AGE=.*/TIMELINE_MIN_AGE="1800"/' \
            -e 's/TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' \
            -e 's/TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
            -e 's/TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' \
            -e 's/TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' \
            -e 's/TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
        /etc/snapper/configs/root
fi

if ! sudo test -f "/etc/snapper/configs/home"; then
    sudo sed -i -e 's/ALLOW_GROUPS=.*/ALLOW_GROUPS="wheel"/' \
            -e 's/TIMELINE_MIN_AGE=.*/TIMELINE_MIN_AGE="1800"/' \
            -e 's/TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' \
            -e 's/TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
            -e 's/TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' \
            -e 's/TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' \
            -e 's/TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
        /etc/snapper/configs/home
fi

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

# GRUB bootsplash
[[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/grub-bootsplash.sh" ]] && source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/grub-bootsplash.sh"

# GRUB tweaks & Regenrate GRUB2 configuration
[[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/grub-tweaks.sh" ]] && source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/grub-tweaks.sh"

# colorEcho "${BLUE}Regenerate ${FUCHSIA}GRUB2 configuration${BLUE}..."
# sudo mkinitcpio -P
# # sudo update-grub
# sudo grub-mkconfig -o /boot/grub/grub.cfg

echo ""
colorEcho "${BLUE}Btrfs with snapper and grub ready. You should restart."
# read -r
