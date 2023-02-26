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

## Boot physical windows using Virt-Manager and KVM/QEMU
## Check the disk ID location
# ls -l /dev/disk/by-id
## Assigning the disk by ID location in VM’s xml like below (using the entire disk):
#     <disk type="block" device="disk">
#         <driver name="qemu" type="raw" cache="none" io="native"/>
#         <source dev="/dev/disk/by-id/wwn-0x50004cf209bd73c7"/>
#         <target dev="vda" bus="virtio"/>
#         <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
#     </disk>

## [Boot a Windows Partition From Linux Using KVM](https://simgunz.org/posts/2021-12-12-boot-windows-partition-from-linux-kvm/)
: '
## Identify the name of the Windows partition, e.g., /dev/nvme0n1p3
# sudo fdisk -l
# ls -l /dev/disk/by-id
VM_WIN_DEVICE=$1
[[ -z "${VM_WIN_DEVICE}" ]] && exit 1

VM_WIN_DIR="${2:-"$HOME/kvm/win11wtg"}"

# Create two partitions for the efi bootloader
mkdir -p "${VM_WIN_DIR}" && cd "${VM_WIN_DIR}" || exit
dd if=/dev/zero of=efi1 bs=1M count=100
dd if=/dev/zero of=efi2 bs=1M count=1

# Create a script `start_md0` to build the disk
tee "${VM_WIN_DIR}/start_md0" >/dev/null <<-EOF
#!/usr/bin/env bash

WIN=${VM_WIN_DEVICE}
EFIDIR=$(cd $(dirname "\${BASH_SOURCE[0]}") && pwd)

set -e

if [[ -e /dev/md0 ]]; then
    echo "/dev/md0 already exists"
    exit 1
fi

if mountpoint -q -- "\${WIN}"; then
    echo "Unmounting \${WIN}..."
    umount \${WIN}
fi

modprobe loop
modprobe linear

LOOP1=\$(losetup -f)
losetup \${LOOP1} "\${EFIDIR}/efi1"

LOOP2=\$(losetup -f)
losetup \${LOOP2} "\${EFIDIR}/efi2"

mdadm --build --verbose /dev/md0 --chunk=512 --level=linear --raid-devices=3 \${LOOP1} \${WIN} \${LOOP2}
chown \$USER:disk /dev/md0

echo "\$LOOP1 \$LOOP2" > "\${EFIDIR}/.win-loop-devices"
EOF

# Create a script `stop_md0`
tee "${VM_WIN_DIR}/stop_md0" >/dev/null <<-EOF
#!/usr/bin/env bash

EFIDIR=$(cd $(dirname "\${BASH_SOURCE[0]}") && pwd)

mdadm --stop /dev/md0
xargs losetup -d < "\${EFIDIR}/.win-loop-devices"
EOF

# Test the scripts
chmod +x "${VM_WIN_DIR}/start_md0"
chmod +x "${VM_WIN_DIR}/stop_md0"
# sudo "${VM_WIN_DIR}/start_md0"
# ls /dev/md0
# sudo "${VM_WIN_DIR}/stop_md0"

# Create a partition table on the virtual disk
sudo "${VM_WIN_DIR}/start_md0"
if ! ls /dev/md0 >/dev/null 2>&1; then
    exit 1
fi

sudo parted /dev/md0
# (parted) unit s
# (parted) mktable gpt
# (parted) mkpart primary fat32 2048 204799    # depends on size of efi1 file
# (parted) mkpart primary ntfs 204800 -2049    # depends on size of efi1 and efi2 files
# (parted) set 1 boot on
# (parted) set 1 esp on
# (parted) set 2 msftdata on
# (parted) name 1 EFI
# (parted) name 2 Windows
# (parted) quit

# Write a BCD entry on the UEFI boot menu
# Download a Windows 11 DVD ISO & Boot the DVD
sudo qemu-system-x86_64 \
    -enable-kvm \
    -bios /usr/share/ovmf/x64/OVMF_CODE.fd \
    -drive file=/dev/md0,media=disk,format=raw \
    -cpu host \
    -m 4G \
    -cdrom "${VM_WIN_DIR}/windows_11_business_editions_22h2_x64.iso"

## Click `Shift + F10` to open a shell, Assign a letter to the EFI partition
# diskpart
# DISKPART> list disk
# DISKPART> select disk 0    # Select the disk
# DISKPART> list volume      # Find EFI volume (partition) number
# DISKPART> select volume 2  # Select EFI volume
# DISKPART> assign letter=B  # Assign B: to EFI volume
# DISKPART> exit
## Write a Boot Configuration Data (BCD) entry
# bcdboot C:\Windows /s B: /f ALL

# Boot the system the first time
sudo qemu-system-x86_64 \
    -enable-kvm \
    -bios /usr/share/ovmf/x64/OVMF_CODE.fd \
    -drive file=/dev/md0,media=disk,format=raw,if=virtio \
    -cpu host \
    -m 4G

## Install spice guest tools (with virtio drivers)
# Install [spice guest tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe) inside the Windows VM
# Reboot Windows

# Boot Windows with disk virtio driver
# Windows should look for the driver in the cdrom and figure out it should load it at boot time
sudo qemu-system-x86_64 \
    -enable-kvm \
    -bios /usr/share/ovmf/x64/OVMF_CODE.fd \
    -drive file=/dev/md0,media=disk,format=raw,if=virtio \
    -cpu host \
    -m 4G \
    -cdrom /var/lib/libvirt/images/virtio-win.iso

# Load the qxl graphics driver
# Load the networking virtio driver
# Optimize the performance
sudo qemu-system-x86_64 \
    -enable-kvm \
    -bios /usr/share/ovmf/x64/OVMF_CODE.fd \
    -drive file=/dev/md0,media=disk,format=raw,if=virtio,aio=native,cache=none \
    -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
    -smp 4,sockets=1,cores=2,threads=2 \
    -m 4G \
    -vga qxl -display sdl,gl=on \
    -nic user,model=virtio-net-pci \
    -device virtio-balloon
'

cd "${CURRENT_DIR}" || exit
