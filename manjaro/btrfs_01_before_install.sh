#!/usr/bin/env bash

## Install using Calamares on Manjaro Live CD
## Run `spice-vdagent` to copy-and-paste functionality between host and guest vm

# Editing Calamares
# Btrfs mount options
echo 'Setting Btrfs mount options...'
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
    - mountPoint: /usr/local
      subvolume: /@local
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
echo 'Done. Now start the Manjaro installer, remember partition disk to `Btrfs`.'
sudo -E "/usr/bin/calamares"
