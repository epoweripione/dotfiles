#!/usr/bin/env bash

## After install, but before starting the installed system

## Find mount point
echo 'Finding Btrfs mount point...'
BTRFS_MOUNT=$(sudo lsblk | grep -Eo '/tmp/calamares[^\/]+' | head -n1)

[[ -n "${BTRFS_MOUNT}" ]] && sudo umount "${BTRFS_MOUNT}"

BTRFS_DEV_LIST=$(sudo blkid -t TYPE="btrfs")
BTRFS_DEV_CNT=$(wc -l <<<"${BTRFS_DEV_LIST}") # count btrfs partitions

if [[ "${BTRFS_DEV_CNT}" == "1" ]]; then
	# use the one found
	BTRFS_DEV=$(cut -d: -f1 <<<"${BTRFS_DEV_LIST}")
else
	# let the user choose
	echo "Please select the btrfs root partition!"
	
	select SELECT_DEV in "${BTRFS_DEV_LIST}"; do
        BTRFS_DEV=$(cut -d: -f1 <<<"${SELECT_DEV}")
        if [[ -z "${BTRFS_DEV}" ]]; then
            echo "Please choose a partition!"
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
    echo 'Setting default subvolume...'
    # sudo btrfs subvol get-default /
    sudo btrfs subvolume set-default \
        "$(sudo btrfs subvolume list "${BTRFS_MOUNT}" | grep 'path @$' | awk '{print $2}')" "${BTRFS_MOUNT}"

    # move the pacman database to `/usr/var/pacman` to always reflect the state of the snapshot
    echo 'Moving the pacman database to `/usr/var/pacman`...'
    sudo mkdir -p "${BTRFS_MOUNT}/@/usr/var/pacman"
    sudo rsync -ah "${BTRFS_MOUNT}/@var/lib/pacman/" "${BTRFS_MOUNT}/@/usr/var/pacman/"
    sudo rm -r "${BTRFS_MOUNT}/@var/lib/pacman"
    sudo sed -i -e 's|^#DBPath.*|#DBPath = /var/lib/pacman/\nDBPath = /usr/var/pacman/|g' "${BTRFS_MOUNT}/@/etc/pacman.conf"

    # Disable copy-on-write(CoW) on `/var, /tmp` in order to speed up IO performance
    echo 'Disabling copy-on-write(CoW) on `/var, /tmp`...'
    sudo chattr +C "${BTRFS_MOUNT}/@var"
    sudo chattr +C "${BTRFS_MOUNT}/@tmp"
    sudo lsattr "${BTRFS_MOUNT}"

    # make sudo more user friendly
    # remove sudo timeout, make cache global, extend timeout
    echo 'Making sudo more user friendly...'
    sudo tee "${BTRFS_MOUNT}/@/etc/sudoers.d/20-password-timeout-0-ppid-60min" <<-'EOF'
Defaults passwd_timeout=0
Defaults timestamp_type="global"

# sudo only once for 60 minute
Defaults timestamp_timeout=60
EOF

    sudo chmod 440 "${BTRFS_MOUNT}/@/etc/sudoers.d/20-password-timeout-0-ppid-60min"

    echo "Btrfs on ${BTRFS_DEV}:"
    sudo btrfs filesystem show
    sudo btrfs subvolume list -p "${BTRFS_MOUNT}"

    echo "Mount point on ${BTRFS_DEV}:"
    sudo cat "${BTRFS_MOUNT}/@/etc/fstab"
    # sudo cat "${BTRFS_MOUNT}/@/etc/default/grub"
    # sudo cat "${BTRFS_MOUNT}/@/boot/grub/grub.cfg"

    sudo umount "${BTRFS_MOUNT}"

    echo 'Done. You can restart and login to the new installed Manjaro Desktop.'
fi
