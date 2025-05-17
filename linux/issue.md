# Issue for Linux

## [The GNU C Library](https://www.gnu.org/software/libc/)
### Build GLIBC
```bash
# System Installed version
ldd --version

find /usr /lib /lib64 -type f -name "libc.so.6"
strings "/lib64/libc.so.6" | grep -E 'GLIBC_[0-9.]+' | sort -rV
strings "/usr/lib/x86_64-linux-gnu/libc.so.6" | grep -E 'GLIBC_[0-9.]+' | sort -rV

# Build latest version
buildGLIBC

# Build specific version
buildGLIBC 2.41
```

### Manually recovery when updated GLIBC broke system
```bash
# Enter `Rescue Mode` using LiveCD
# Mount the root partition
mount /dev/sdaX /mnt

# Make a copy for new GLIBC directory
cp -r /mnt/opt/glibc-2.41 /mnt/opt/glibc-2.41-bak

# Overwrite with old GLIBC
for file in $(find /mnt/opt/glibc-2.41/lib -mindepth 1 -maxdepth 1 -type d); do name=$(basename "$file"); [[ -d "/mnt/lib64/$name" ]] && rm -rf "$file" && cp -rf "/mnt/lib64/$name/" "$file/"; done

for file in $(find /mnt/opt/glibc-2.41/lib -mindepth 1 -maxdepth 1 -type f); do name=$(basename "$file"); [[ -f "/mnt/lib64/$name" ]] && rm -f "$file" && cp -f "/mnt/lib64/$name" "$file"; done

# umount & reboot
umount /mnt
reboot

# Fallback without the new GLIBC library
sudo rm -f "/etc/ld.so.conf.d/glibc-2.41.conf"
sudo ldconfig

# Delete the new GLIBC libray
sudo rm -rf /opt/glibc-2.41*
```

## ip_local_port_range: prefer different parity for start/end values
```bash
cat /proc/sys/net/ipv4/ip_local_port_range
# echo 'net.ipv4.ip_local_port_range = 1024 65535' | sudo tee -a /etc/sysctl.conf
sudo sed -i 's/net.ipv4.ip_local_port_range.*/net.ipv4.ip_local_port_range = 1024 65535/' /etc/sysctl.conf
sudo sysctl -p
```

## [Conflicting requests after update to CentOS 9 Stream from 8](https://unix.stackexchange.com/questions/694789/conflicting-requests-after-update-to-centos-9-stream-from-8)
```bash
dnf module remove @modulefailsafe 2>&1 | grep nothing | perl -npe 's/.* by module ([^:]+):.*/\1/' | xargs dnf -y module reset
```

## [Regenerating the initramfs for Rocky Linux](https://docs.rockylinux.org/guides/kernel/regenerate_initramfs/)
```bash
# Backup the existing initramfs
sudo cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-$(date +%m-%d-%H%M%S).img

# Regenerate the initramfs
sudo dracut -f /boot/initramfs-$(uname -r).img $(uname -r)

# Regenerate the `initramfs` for a specific kernel
rpm -qa kernel # List installed kernel
sudo dracut --kver 5.14.0-503.40.1.el9_5.x86_64 --force

# Regenerate the GRUB configuration
# Check the `df -h` output for a `/boot/efi` directory. If present, you're likely using UEFI.
df -h
sudo grub2-mkconfig -o /boot/grub2/grub.cfg # BIOS
sudo grub2-mkconfig -o /boot/efi/EFI/rocky/grub.cfg # UEFI

# Reboot
sudo reboot
```
