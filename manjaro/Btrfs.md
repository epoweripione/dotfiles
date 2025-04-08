## [Btrfs](https://wiki.archlinux.org/title/btrfs)
[Btrfs](https://wiki.archlinux.org/index.php/Btrfs)

[BTRFS FILESYSTEM CHEATSHEET](https://studiofreya.com/programming-basics/btrfs/)

[Arch Linux with BTRFS Installation](https://www.nishantnadkarni.tech/posts/arch_installation/)

[https://zhuanlan.zhihu.com/p/388400709](https://zhuanlan.zhihu.com/p/388400709)

[https://blog.kaaass.net/archives/1748](https://blog.kaaass.net/archives/1748)

[https://blog.zrlab.org/posts/arch-btrfs](https://blog.zrlab.org/posts/arch-btrfs)

[https://www.cnblogs.com/xiaoshiwang/p/12296336.html](https://www.cnblogs.com/xiaoshiwang/p/12296336.html)

### Test with file
```bash
# [truncate, ftruncate - truncate a file to a specified length](https://man7.org/linux/man-pages/man2/truncate.2.html)
truncate -s 10G "/tmp/btrfs.img"

# [fallocate - preallocate or deallocate space to a file](https://man7.org/linux/man-pages/man1/fallocate.1.html)
# fallocate -l 10G "/tmp/btrfs.img"

# sudo mkfs.btrfs -L test "/tmp/btrfs.img"
# sudo mkdir -p "/mnt/btrfs"
# sudo mount "/tmp/btrfs.img" "/mnt/btrfs"
# sudo umount "/mnt/btrfs"

parted "/tmp/btrfs.img" unit MiB print
parted "/tmp/btrfs.img"

# [How to format a partition inside of an img file?](https://unix.stackexchange.com/questions/209566/how-to-format-a-partition-inside-of-an-img-file)
fdisk -lu "/tmp/btrfs.img"
# sudo losetup --offset $((512*2048)) --sizelimit $((512*16384)) --show --find "/tmp/btrfs.img" # bios_grup
LOOP_BTRFS=$(sudo losetup --partscan --show --find "/tmp/btrfs.img")
sudo lsblk "${LOOP_BTRFS}"

sudo mkfs.fat -F32 "${LOOP_BTRFS}p2"
sudo mkswap "${LOOP_BTRFS}p3"
sudo mkfs.btrfs -L arch -f "${LOOP_BTRFS}p4"

parted "/tmp/btrfs.img" unit MiB print

sudo mkdir -p "/mnt/btrfs"
sudo mount "${LOOP_BTRFS}p4" "/mnt/btrfs"
sudo mount | grep btrfs

cd "/mnt/btrfs"
sudo btrfs subvolume create /mnt/btrfs/@
sudo btrfs subvolume create /mnt/btrfs/@home
sudo btrfs subvolume create /mnt/btrfs/@var
sudo btrfs subvolume create /mnt/btrfs/@tmp

sudo chattr +C /mnt/btrfs/@var
sudo chattr +C /mnt/btrfs/@tmp

sudo btrfs filesystem show
sudo btrfs filesystem usage "/mnt/btrfs"
sudo btrfs device stats "/mnt/btrfs"
sudo btrfs device usage "/mnt/btrfs"
sudo btrfs subvolume list -p "/mnt/btrfs"
sudo btrfs subvolume show "/mnt/btrfs/@"

fuser -mv "/mnt/btrfs"
lsof "/mnt/btrfs"

sudo umount "/mnt/btrfs"

sudo losetup -d "${LOOP_BTRFS}"
```

### Partitions
[Units misunderstanding in fdisk / gdisk / parted](https://superuser.com/questions/1194426/units-misunderstanding-in-fdisk-gdisk-parted)

```bash
## GParted
# +8MB→unformatted→BIOS_GRUB
# +512MB→fat32→EFI
# +8192MB→linux-swap→Swap
# +...→Btrfs

# fdisk
sudo fdisk -l
sudo fdisk </dev/sdx or /dev/nvme0nx>

# [Parted](https://wiki.archlinux.org/title/Parted)
sudo parted unit MiB -l

sudo parted </dev/sdx or /dev/nvme0nx> unit MiB print
sudo parted </dev/sdx or /dev/nvme0nx>

unit MiB

mklabel gpt

## bios_grub: 8 MiB
# mkpart "BIOS_GRUB" 2048s 9M
mkpart "BIOS_GRUB" 1MiB 9MiB
set 1 bios_grub on

# efi: 512 MiB
mkpart "EFI" 9MiB 521MiB
set 2 boot on
set 2 esp on

# swap: 8 GiB(8192 MiB)
mkpart "Swap" 521MiB 8713MiB

# Root filesystem: use all the remaining space
mkpart "Manjaro" 8713M 100%

quit
```

### Format partitions
```bash
sudo mkfs.fat -F32 </dev/sdx2>
sudo mkswap </dev/sdx3>

sudo mkfs.btrfs -L "Manjaro" -f </dev/sdx4>

sudo blkid -t TYPE="btrfs"
```

### Subvolumes

```bash
sudo mkdir -p /mnt/btrfs

sudo mount </dev/sdx4> /mnt/btrfs

sudo btrfs subvolume create /mnt/btrfs/@
sudo btrfs subvolume create /mnt/btrfs/@home

sudo btrfs subvolume create /mnt/btrfs/@var
# sudo btrfs subvolume create /mnt/btrfs/@docker # /var/lib/docker
# sudo btrfs subvolume create /mnt/btrfs/@virt # /var/lib/libvirt
# sudo btrfs subvolume create /mnt/btrfs/@cache # /var/cache
# sudo btrfs subvolume create /mnt/btrfs/@log # /var/log

sudo btrfs subvolume create /mnt/btrfs/@snapshots

sudo btrfs subvolume create /mnt/btrfs/@tmp

# Disable copy-on-write(CoW) on `/var, /tmp` in order to speed up IO performance
sudo chattr +C /mnt/btrfs/@var
# chattr +C /mnt/btrfs/@cache
# chattr +C /mnt/btrfs/@log
sudo chattr +C /mnt/btrfs/@tmp

sudo btrfs subvolume list -p /mnt/btrfs

sudo umount /mnt/btrfs
```

### Mounting the partitions and subvolumes

```bash
sudo mkdir {/btrfs/boot,/btrfs/var,/btrfs/opt,/btrfs/home,/btrfs/tmp}

sudo mount </dev/sdx2> /btrfs/boot
sudo swapon </dev/sdx3>

# [Solid state drive](https://wiki.archlinux.org/title/Solid_state_drive)
# verify TRIM support
sudo hdparm -I </dev/sdx> | grep TRIM

# Continuous TRIM for SSD: discard=async
# Auto defrag for HDD: autodefrag

## [Compression](https://btrfs.wiki.kernel.org/index.php/Compression)
## Algorithm levels  Default Description
## zlib      1-9     3       slow, good compression ratios, default method
## LZO       N/A     N/A     very fast, low compression ratios
## zstd      1-15    3       slow to very fast, good compression ratios at all levels

# sudo mount </dev/sdx4> /btrfs -o noatime,nodiratime,discard=async,ssd,compress=lzo,space_cache=v2,subvol=@
# sudo mount </dev/sdx4> /btrfs -o noatime,nodiratime,discard=async,ssd,compress=zstd:5,space_cache=v2,subvol=@
sudo mount </dev/sdx4> /btrfs -o noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@

sudo mount </dev/sdx4> /btrfs/var -o noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@var
sudo mount </dev/sdx4> /btrfs/opt -o noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@opt
sudo mount </dev/sdx4> /btrfs/home -o noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@home
sudo mount </dev/sdx4> /btrfs/tmp -o noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@tmp
```

## Mount by UUID
```bash
sudo lsblk
sudo blkid -t TYPE="btrfs"

# exclude loop block device, tmpfs and udev 
sudo lsblk -e7
df -TH -x squashfs -x tmpfs -x devtmpfs
df -TH | grep -v '^/dev/loop\|tmpfs'
sudo parted unit MiB -l
sudo fdisk -l | sed -e '/Disk \/dev\/loop/,+5d'

sudo findmnt -nt btrfs

sudo btrfs filesystem show

sudo mount --uuid <uuid> / -o noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@

# sudo nano /ect/fstab
# EFI
echo 'UUID=<uuid>	/boot/efi	vfat	umask=0077	0 0' | sudo tee -a /ect/fstab

# Swap
echo 'UUID=<uuid>	swap	swap	defaults	0 0' | sudo tee -a /ect/fstab

# SSD
echo 'UUID=<uuid>	/	btrfs	noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@	0 0' | sudo tee -a /ect/fstab
echo 'UUID=<uuid>	/var	btrfs	noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@var	0 0' | sudo tee -a /ect/fstab
echo 'UUID=<uuid>	/opt	btrfs	noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@opt	0 0' | sudo tee -a /ect/fstab
echo 'UUID=<uuid>	/home	btrfs	noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@home	0 0' | sudo tee -a /ect/fstab
echo 'UUID=<uuid>	/tmp	btrfs	noatime,nodiratime,discard=async,ssd,compress=zstd,space_cache=v2,subvol=@tmp	0 0' | sudo tee -a /ect/fstab

# HDD
echo 'UUID=<uuid>	/data	btrfs	noatime,nodiratime,autodefrag,compress=zstd,space_cache=v2,subvol=@	0 0' | sudo tee -a /ect/fstab
```

## Add btrfs module to `mkinitcpio` after install `Arch`

```bash
sudo sed -i 's/MODULES=( /MODULES=(btrfs /' /etc/mkinitcpio.conf
sudo mkinitcpio -P
```

## Timeshift
`yay --noconfirm --needed -S timeshift timeshift-autosnap grub-btrfs`

## [Using Btrfs with Multiple Devices](https://btrfs.wiki.kernel.org/index.php/Using_Btrfs_with_Multiple_Devices)
```bash
sudo mkfs.btrfs -L arch -m raid1 -d raid1 </dev/sdx4> </dev/sdx5>
```

### Convert to RAID1
```bash
sudo btrfs device add -f </dev/sdc> /
sudo btrfs device usage /
sudo btrfs balance start -dconvert=raid1 -mconvert=raid1
```

### Revert RAID1
```bash
sudo btrfs balance start -f -mconvert=single -dconvert=single /
sudo btrfs device delete </dev/sdc> /
```

### replacing failed devices
[btrfs replace](https://btrfs.readthedocs.io/en/latest/btrfs-replace.html)

## [Snapshots](https://btrfs.wiki.kernel.org/index.php/SysadminGuide#Snapshots)
```bash
mkdir -p /.snapshots

SNAPSHOT_TIME="$(date +%Y%m%d_%H%M%S)"
sudo btrfs subvolume snapshot /home "/.snapshots/home-${SNAPSHOT_TIME}"

sudo btrfs subvolume list /
sudo btrfs subvolume show "/.snapshots/home-${SNAPSHOT_TIME}"

# Recovering files from Snapshots
sudo cp -fv "/.snapshots/home-${SNAPSHOT_TIME}"/<filename> /home/<filename>

# Recovering all files/directories from Snapshots
sudo rm -rfv /home/*
sudo rsync -avzP "/.snapshots/home-${SNAPSHOT_TIME}/" /home

# Recover files/directories from the snapshot in mirror mode
sudo rsync -avzP --delete "/.snapshots/home-${SNAPSHOT_TIME}/" /home

# Updating a Snapshot
sudo cp -fv /home/<filename> "/.snapshots/home-${SNAPSHOT_TIME}"/<filename>

# Taking Read-Only Snapshots of a Subvolume
sudo btrfs subvolume snapshot -r /home "/.snapshots/home-${SNAPSHOT_TIME}"

# Removing a Snapshot
sudo btrfs subvolume delete "/.snapshots/home-${SNAPSHOT_TIME}"

# Rolling back a snapshot
sudo umount /home
sudo btrfs subvolume delete /home
sudo btrfs subvolume snapshot "/.snapshots/home-${SNAPSHOT_TIME}" /home
```

## Backup subvolume
`btrfs send /home | btrfs receive /path/to/other/disk`

## Recover data
### [btrfs-check](https://btrfs.readthedocs.io/en/latest/btrfs-check.html)

### [btrfs-rescue](https://btrfs.readthedocs.io/en/latest/btrfs-rescue.html)

### [btrfs-restore](https://btrfs.readthedocs.io/en/latest/btrfs-restore.html)

## Btrfs command
```bash
sudo btrfs check
sudo btrfs filesystem show

sudo btrfs filesystem df <MOUNT_POINT>
sudo btrfs filesystem usage <MOUNT_POINT>
sudo btrfs filesystem du -s <MOUNT_POINT>

# resize
sudo btrfs filesystem resize +10g <MOUNT_POINT>

# device
sudo btrfs device scan
sudo btrfs device stats <MOUNT_POINT>
sudo btrfs filesystem add DEVICE <MOUNT_POINT>
sudo btrfs device delete DEVICE <MOUNT_POINT>

# defragment
sudo btrfs filesystem defragment -r /

# balance
sudo btrfs blance status|start|pause|resume|cancel <MOUNT_POINT>
sudo btrfs balance start -dconvert=raid1 -mconvert=raid1 <MOUNT_POINT>

# shows % of balancing procedure
sudo btrfs balance status -v

# subvolume
sudo btrfs subvolume create <MOUNT_POINT>/DIR
sudo btrfs subvolume list <MOUNT_POINT>
sudo btrfs subvolume show <MOUNT_POINT>
sudo btrfs subvolume delete <MOUNT_POINT>/DIR

# [compsize](https://github.com/kilobyte/compsize)
yay --noconfirm --needed -S compsize
compsize <MOUNT_POINT>
```

## [Configure Docker to use the btrfs storage driver](https://docs.docker.com/storage/storagedriver/btrfs-driver/)


## Encrypt a Btrfs Filesystem
### [dm-crypt/Encrypting an entire system](https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system)
### [Enable LUKS2 and Argon2 support for Grub in Manjaro/Arch](https://mdleom.com/blog/2022/11/27/grub-luks2-argon2/)
### [Btrfs + LUKS2 + Secure Boot](https://wiki.archlinux.org/title/User:ZachHilman/Installation_-_Btrfs_%2B_LUKS2_%2B_Secure_Boot)
### [How to Encrypt a Btrfs Filesystem?](https://linuxhint.com/encrypt-a-btrfs-filesystem/)
```bash
# Boot with Manjaro official ISO

# Change disk to GPT: GParted > Device > Create Partition Table > GPT > Apply

# Change BTRFS layout with `konsole`
git clone --depth=1 "https://github.com/epoweripione/dotfiles.git" "$HOME/.dotfiles" && \
    find "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}" -type f -iname "*.sh" -exec chmod +x {} \;

"${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/btrfs_01_before_install.sh"

# Continue the installation process using `Graphical Installer`
# In the partitioning step, choose `btrfs` and ticked `Encrypt system`, Then enter a passphrase to encrypt the disk
# Continue to complete the remaining steps

# After the installation is complete, do not reboot
# start `konsole`
"${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/btrfs_02_after_install_before_restart.sh"

# Reboot

# After boot into the desktop, start `konsole`
git clone --depth=1 "https://github.com/epoweripione/dotfiles.git" "$HOME/.dotfiles" && \
    find "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}" -type f -iname "*.sh" -exec chmod +x {} \;

"${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/btrfs_03_after_install_after_restart.sh"

# Reboot into Manjaro live USB
git clone --depth=1 "https://github.com/epoweripione/dotfiles.git" "$HOME/.dotfiles" && \
    find "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}" -type f -iname "*.sh" -exec chmod +x {} \;

"${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/btrfs_convert_LUKS1_to_LUKS2.sh" "<EFI partition: /dev/sda1, /dev/nvme0n1p1>" "<encrypted LUKS1 root partition: /dev/sda2, /dev/nvme0n1p2>" "<encrypted LUKS1 swap partition: /dev/sda3, /dev/nvme0n1p3>"
```

## Move subvolume to a new disk
### [Move your BTRFS /home subvolume to a new disk](https://gist.github.com/jdoss/a8278844059ca125d0f443604fcedc30)
```bash
# Check old mount
df -h /home

# Create LUKS devices on new disk using `GParted`
sudo gparted

## Create the BTRFS file system on new disk
# RAID10 with 2 or more disks
sudo mkfs.btrfs -m raid10 -d raid10 /dev/mapper/luks-<new-disk1-UUID> /dev/mapper/luks-<new-disk2-UUID> -f
# Only 1 disk
sudo mkfs.btrfs /dev/mapper/luks-<new-disk-UUID> -f
# Take note of the UUID from the `mkfs.btrfs` output

# Create a mount point and mount new disk
sudo mkdir /mnt/btrfs-new

# Mount the UUID from the `mkfs.btrfs` command output
sudo mount /dev/disk/by-uuid/<new-BTRFS-UUID> /mnt/btrfs-new

# Create a read-only snapshot of the `/home` directory
sudo btrfs subvolume homesnaps -r /home "home_$(date '+%Y%m%d')"

# Send this read-only subvolume snapshot to the newly mounted BTRFS filesystem
sudo btrfs send "/home/.snapshots/home_$(date '+%Y%m%d')" | sudo btrfs receive /mnt/btrfs-new/

# Create another snapshot
sudo btrfs subvolume homesnaps "/mnt/btrfs-new/home_$(date '+%Y%m%d')" "/mnt/btrfs-new/home"

# Edit `/etc/fstab` with the UUID from the `mkfs.btrfs` of mount point `/home` and `/home/.snapshots`

# Reboot

# Check new mount
df -h /home
```

### [btrfs-clone](https://github.com/mwilck/btrfs-clone)
```bash
# btrfs-clone [options] <mount-point-of-existing-FS> <mount-point-of-new-FS>

# Check old mount
df -h /home

# Create LUKS devices on new disk using `GParted`
sudo gparted

## Create the BTRFS file system on new disk
# RAID10 with 2 or more disks
sudo mkfs.btrfs -m raid10 -d raid10 /dev/mapper/luks-<new-disk1-UUID> /dev/mapper/luks-<new-disk2-UUID> -f
# Only 1 disk
sudo mkfs.btrfs /dev/mapper/luks-<new-disk-UUID> -f
# Take note of the UUID from the `mkfs.btrfs` output

# Create a mount point and mount new disk
sudo mkdir /mnt/btrfs-new

# Mount the UUID from the `mkfs.btrfs` command output
sudo mount /dev/disk/by-uuid/<new-BTRFS-UUID> /mnt/btrfs-new

# Clone
btrfs-clone /home /mnt/btrfs-new

# Edit `/etc/fstab` with the UUID from the `mkfs.btrfs` of mount point `/home` and `/home/.snapshots`

# Reboot

# Check new mount
df -h /home
```
