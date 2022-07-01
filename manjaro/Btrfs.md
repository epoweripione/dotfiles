## [Btrfs](https://wiki.archlinux.org/title/btrfs)

[Arch Linux with BTRFS Installation](https://www.nishantnadkarni.tech/posts/arch_installation/)

[https://zhuanlan.zhihu.com/p/388400709](https://zhuanlan.zhihu.com/p/388400709)

[https://blog.kaaass.net/archives/1748](https://blog.kaaass.net/archives/1748)

### Partitions

```bash
fdisk -l
fdisk </dev/sdx or /dev/nvme0nx>

# +8MB→unformatted→BIOS_GRUB
# +512MB→fat32→EFI
# +8192MB→linux-swap→Swap
# +...→Btrfs

mkfs.fat -F32 </dev/sdx2>
mkswap </dev/sdx3>
mkfs.btrfs -f </dev/sdx4>
```

### Subvolumes

```bash
mount </dev/sdx4> /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@usr
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@home

# Disable copy-on-write(CoW) on `/var` in order to speed up IO performance
chattr +C /mnt/@var

umount /mnt
```

### Mounting the partitions and subvolumes

```bash
mount </dev/sdx4> /mnt -o subvol=@

mkdir /mnt/boot
mkdir /mnt/usr
mkdir /mnt/var
mkdir /mnt/home

mount </dev/sdx2> /mnt/boot

mount </dev/sdx4> /mnt/usr -o subvol=@usr
mount </dev/sdx4> /mnt/var -o subvol=@var
mount </dev/sdx4> /mnt/home -o subvol=@home

swapon </dev/sdx3>

lsblk
```

### Add btrfs module to `mkinitcpio` after install `Arch`

```bash
sudo sed -i 's/MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
mkinitcpio -P
```
