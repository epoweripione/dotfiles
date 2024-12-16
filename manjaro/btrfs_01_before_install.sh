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

## Install using Calamares on Manjaro Live CD
## Run `spice-vdagent` to copy-and-paste functionality between host and guest vm

# Editing Calamares
colorEcho "${BLUE}Setting default filesystem type to ${FUCHSIA}BTRFS${BLUE}..."
sudo sed -i 's/^defaultFileSystemType:.*/defaultFileSystemType:  "btrfs"/' "/usr/share/calamares/modules/partition.conf"

colorEcho "${BLUE}Setting LUKS generation to ${FUCHSIA}LUKS2${BLUE}..."
sudo sed -i 's/^luksGeneration:.*/luksGeneration: luks2/' "/usr/share/calamares/modules/partition.conf"

# Resize the size of the EFI system partition to store System Rescue ISOs
colorEcho "${BLUE}Setting the size of the EFI system partition to ${FUCHSIA}10240MiB{BLUE}..."
sudo sed -i 's/recommendedSize:.*/recommendedSize:    10240MiB/' "/usr/share/calamares/modules/partition.conf"

# Btrfs mount options
colorEcho "${BLUE}Setting Btrfs mount options..."
sudo sed -i 's/# btrfs:.*/btrfs: noatime,nodiratime,compress=zstd,space_cache=v2/' "/usr/share/calamares/modules/fstab.conf"
sudo sed -i 's/btrfs: defaults/# btrfs: defaults/' "/usr/share/calamares/modules/fstab.conf"

# Btrfs Flat layout
echo 'Setting Btrfs layout...'
# - toplevel (subvolid=5)
# | - @           (subvolume, to be mounted at /)
# | - @home       (subvolume, to be mounted at /home)
# | - @local      (subvolume, to be mounted at /usr/local)
# | - @opt        (subvolume, to be mounted at /opt)
# | - @srv        (subvolume, to be mounted at /srv)
# | - @var        (subvolume, to be mounted at /var)
# | - @tmp        (subvolume, to be mounted at /tmp)
# | - @rootsnaps  (subvolume, to be mounted at /.snapshots)
# | - @homesnaps  (subvolume, to be mounted at /home/.snapshots)

sudo sed -i -e 's|.*/var/cache|# &|g' \
    -e 's|.*/@cache|# &|g' \
    -e 's|.*/var/log|# &|g' \
    -e 's|.*/@log|# &|g' \
    "/usr/share/calamares/modules/mount.conf"

sudo tee -a "/usr/share/calamares/modules/mount.conf" >/dev/null <<-'EOF'
#     - mountPoint: /usr/local
#       subvolume: /@local
    - mountPoint: /opt
      subvolume: /@opt
    - mountPoint: /srv
      subvolume: /@srv
    - mountPoint: /var
      subvolume: /@var
    - mountPoint: /tmp
      subvolume: /@tmp
    - mountPoint: /.snapshots
      subvolume: /@rootsnaps
    - mountPoint: /home/.snapshots
      subvolume: /@homesnaps
EOF

# /usr/share/calamares/modules/umount.conf

# Start the Manjaro Calamares installer to Install Manjaro
colorEcho "${BLUE}Done. Now start the Manjaro installer, remember partition disk to ${FUCHSIA}Btrfs${BLUE}."
sudo -E "/usr/bin/calamares"
