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

## After install, but before starting the installed system

## Find mount point
colorEcho "${BLUE}Finding Btrfs mount point..."
BTRFS_MOUNT=$(sudo lsblk | grep -Eo '/tmp/calamares[^\/]+' | head -n1)

[[ -n "${BTRFS_MOUNT}" ]] && sudo umount "${BTRFS_MOUNT}"

BTRFS_DEV_LIST=$(sudo blkid -t TYPE="btrfs")
BTRFS_DEV_CNT=$(wc -l <<<"${BTRFS_DEV_LIST}") # count btrfs partitions

if [[ "${BTRFS_DEV_CNT}" == "1" ]]; then
	# use the one found
	BTRFS_DEV=$(cut -d: -f1 <<<"${BTRFS_DEV_LIST}")
else
	# let the user choose
	colorEcho "${RED}Please select the btrfs root partition!"
	
	select SELECT_DEV in "${BTRFS_DEV_LIST}"; do
        BTRFS_DEV=$(cut -d: -f1 <<<"${SELECT_DEV}")
        if [[ -z "${BTRFS_DEV}" ]]; then
            colorEcho "${RED}Please choose a partition!"
            exit 0
        fi
        break
	done
fi

if [[ -n "${BTRFS_DEV}" ]]; then
    BTRFS_MOUNT="/mnt"
    sudo mkdir -p "${BTRFS_MOUNT}"

    sudo mount "${BTRFS_DEV}" "${BTRFS_MOUNT}"

    ## set default subvolume
    colorEcho "${BLUE}Setting default subvolume on ${FUCHSIA}${BTRFS_DEV}${BLUE}..."
    # sudo btrfs subvol get-default /
    sudo btrfs subvolume set-default \
        "$(sudo btrfs subvolume list "${BTRFS_MOUNT}" | grep 'path @$' | awk '{print $2}')" "${BTRFS_MOUNT}"

    # move the pacman database to `/usr/var/pacman` to always reflect the state of the snapshot
    colorEcho "${BLUE}Moving the pacman database to ${FUCHSIA}/usr/var/pacman${BLUE}..."
    sudo mkdir -p "${BTRFS_MOUNT}/@/usr/var/pacman"
    sudo rsync -ah "${BTRFS_MOUNT}/@var/lib/pacman/" "${BTRFS_MOUNT}/@/usr/var/pacman/"
    sudo rm -r "${BTRFS_MOUNT}/@var/lib/pacman"
    sudo sed -i -e 's|^#DBPath.*|#DBPath = /var/lib/pacman/\nDBPath = /usr/var/pacman/|g' "${BTRFS_MOUNT}/@/etc/pacman.conf"

    # Disable copy-on-write(CoW) on `/var, /tmp` in order to speed up IO performance
    colorEcho "${BLUE}Disabling copy-on-write(CoW) on ${FUCHSIA}/var, /tmp${BLUE}..."
    sudo chattr +C "${BTRFS_MOUNT}/@var"
    sudo chattr +C "${BTRFS_MOUNT}/@tmp"
    sudo lsattr "${BTRFS_MOUNT}"

    # make sudo more user friendly
    # remove sudo timeout, make cache global, extend timeout
    colorEcho "${BLUE}Making sudo more user friendly..."
    sudo tee "${BTRFS_MOUNT}/@/etc/sudoers.d/20-password-timeout-0-ppid-60min" <<-'EOF'
Defaults passwd_timeout=0
Defaults timestamp_type="global"

# sudo only once for 60 minute
Defaults timestamp_timeout=60
EOF

    sudo chmod 440 "${BTRFS_MOUNT}/@/etc/sudoers.d/20-password-timeout-0-ppid-60min"

    colorEcho "${BLUE}Btrfs on ${FUCHSIA}${BTRFS_DEV}${BLUE}:"
    sudo btrfs filesystem show
    sudo btrfs subvolume list -p "${BTRFS_MOUNT}"

    colorEcho "${BLUE}Mount point on ${FUCHSIA}${BTRFS_DEV}${BLUE}:"
    sudo cat "${BTRFS_MOUNT}/@/etc/fstab"
    # sudo cat "${BTRFS_MOUNT}/@/etc/default/grub"
    # sudo cat "${BTRFS_MOUNT}/@/boot/grub/grub.cfg"

    sudo umount "${BTRFS_MOUNT}"

    colorEcho "${BLUE}Done. You can restart and login to the new installed Manjaro Desktop."
fi
