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

# KVM & QEMU
# https://wiki.archlinux.org/title/QEMU
# https://wiki.manjaro.org/index.php/Virt-manager
# https://computingforgeeks.com/install-kvm-qemu-virt-manager-arch-manjar/
# https://getlabsdone.com/how-to-install-windows-11-on-kvm/
# emulate the TPM
colorEcho "${BLUE}Installing ${FUCHSIA}QEMU tools${BLUE}..."
# TPM Emulator
sudo pacman --noconfirm --needed -S --asdeps swtpm

# Enable secure-boot/UEFI on KVM
sudo pacman --noconfirm --needed -S edk2-ovmf

sudo pacman --noconfirm --needed -S vde2 bridge-utils openbsd-netcat

# sudo pacman --noconfirm --needed -S iptables-nft
sudo pacman --noconfirm --needed -S dnsmasq ebtables iptables

# Install the qemu package
sudo pacman --noconfirm --needed -S libvirt qemu-desktop virt-manager virt-install virt-viewer
sudo pacman --noconfirm --needed -S libguestfs

## Run and enable boot up start libvirtd daemon
# sudo systemctl enable libvirtd.service
# sudo systemctl start libvirtd.service
sudo systemctl enable --now libvirtd.service

# Enable normal user account to use KVM
sudo sed -i 's/^unix_sock_group.*/unix_sock_group = "libvirt"/g' "/etc/libvirt/libvirtd.conf"
sudo sed -i 's/^unix_sock_rw_perms.*/unix_sock_rw_perms = "0770"/g' "/etc/libvirt/libvirtd.conf"

## Add user to the kvm and libvirt groups
# sudo usermod -a -G libvirt "$(whoami)"
# newgrp libvirt
sudo gpasswd -a "$(whoami)" kvm
sudo gpasswd -a "$(whoami)" libvirt

sudo systemctl restart libvirtd.service

# Enable Nested Virtualization (Optional)
CPU_VENDOR=$(lscpu | grep Vendor | awk '{print $NF}')
if grep -q 'Intel' <<<"${CPU_VENDOR}"; then
    # Intel Processor
    echo "options kvm_intel nested=1" | sudo tee "/etc/modprobe.d/kvm_intel.conf" >/dev/null
elif grep -q 'AMD' <<<"${CPU_VENDOR}"; then
    # AMD Processor
    echo "options kvm_amd nested=1" | sudo tee "/etc/modprobe.d/kvm_amd.conf" >/dev/null
fi

## ISO image at: /var/lib/libvirt/images
## change default location of libvirt VM images
# sudo virsh pool-dumpxml default > libvirt_pool.xml
# sed -i 's|/var/lib/libvirt/images|/data/libvirt/images|' libvirt_pool.xml
# sudo mkdir -p "/data/libvirt/images"
# sudo virsh pool-destroy default
# sudo virsh pool-create libvirt_pool.xml
sudo pacman --noconfirm --needed -S virtio-win

## SPICE
# Using `virt-manager` (on host) change the guest VM configuration:
# Change the 'Video model' to 'QXL'
# Set the 'Display' to 'Spice'
# Add a 'spicevmc' Channel (via 'Add Hardware')

## Linux guest
# sudo pacman --noconfirm --needed -S spice-vdagent xf86-video-qxl
# echo -e '# auto start spice-vdagent\nspice-vdagent' | tee -a "$HOME/.xprofile"

## Windows guest
## spice-guest-tools
## https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe
## spice-webdavd
## https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi
# sudo virt-viewer

## Shared folder
## https://techpiezo.com/linux/shared-folder-in-qemu-virtual-machine-windows/
# qemu-system-x86_64 -net nic -net user,smb=<shared_folder_path> ...
## Custom Network Location: \\10.0.2.4\qemu\

## [Sharing files with Virtiofs](https://libvirt.org/kbase/virtiofs.html)
## mkdir -p /mnt/share && chmod a+w /mnt/share
## Add the following domain XML elements to share the host directory /path with the guest
#     <filesystem type="mount" accessmode="passthrough">
#       <driver type="virtiofs" queue="1024"/>
#       <source dir="/mnt/share"/>
#       <target dir="share"/>
#       <address type="pci" domain="0x0000" bus="0x08" slot="0x00" function="0x0"/>
#     </filesystem>

## Boot the guest and mount the filesystem
# sudo mkdir -p /mnt/share && sudo mount -t virtiofs share /mnt/share

## [How to install virtiofs drivers on Windows](https://virtio-fs.gitlab.io/howto-windows.html)
## 1. Installing the virtiofs PCI device driver(virtio-win.iso):
##    virtio-win-guest-tools.exe 
##    Device Manager→Other devices→Mass Storage Controller→Update driver
## 2. Installing [WinFsp](https://github.com/billziss-gh/winfsp/releases/latest)
## 3. Installing the virtiofs service
##    Run as administrator the Command Prompt and execute the following command:
## sc create VirtioFsSvc binpath="C:\Program Files\Virtio-Win\VioFS\virtiofs.exe" start=auto depend="WinFsp.Launcher/VirtioFsDrv" DisplayName="Virtio FS Service"
## sc config VirtioFsSvc start=auto
## sc start VirtioFsSvc

## Add physical disk to kvm virtual machine
# sudo env EDITOR=nano virsh edit ${VM_NAME}

## Interacting with virtual machines
## https://libvirt.org/manpages/virsh.html
# sudo virsh nodeinfo
# sudo virsh list --all
# sudo virsh domblklist ${VM_NAME}
# sudo virsh start ${VM_NAME}
# sudo virsh shutdown ${VM_NAME}

## Convert libvirt xml into qemu command line
# sudo virsh domxml-to-native qemu-argv --domain ${VM_NAME}

## network
# brctl show
# sudo virsh net-list --all
# sudo virsh net-info default
# sudo virsh net-dumpxml default

## Create a new libvirt network
## https://kashyapc.fedorapeople.org/virt/create-a-new-libvirt-bridge.txt
# virsh net-define [new_name_of_network].xml

# Marked network default as autostarted
sudo virsh net-autostart default
sudo virsh net-start default

## remove the network named default
# sudo virsh net-autostart default --disable
# sudo virsh net-destroy default
# sudo virsh net-undefine default

## autostart vm
# sudo virsh autostart ${VM_NAME}

## To destroy or forcefully power off virtual machine
# sudo virsh destroy ${VM_NAME}

## To delete or removing virtual machine along with its disk file
## a) First shutdown the virtual machine
# sudo virsh shutdown ${VM_NAME}
## b) Delete the virtual machine along with its associated storage file
# sudo virsh undefine ${VM_NAME} --nvram –remove-all-storage

## rename KVM domain
# sudo virsh shutdown ${VM_NAME}
# sudo virsh domrename ${VM_NAME} ${VM_NEW_NAME}
## or
# sudo virsh dumpxml ${VM_NAME} > ${VM_NEW_NAME}.xml
## Edit the XML file and change the name between the <name></name>
# sudo virsh shutdown ${VM_NAME}
# sudo virsh undefine ${VM_NAME} --nvram
## import the edited XML file to define the VM bar
# sudo virsh define ${VM_NEW_NAME}.xml

## Snapshot for pflash based firmware
## [KVM: creating and reverting libvirt external snapshots](https://fabianlee.org/2021/01/10/kvm-creating-and-reverting-libvirt-external-snapshots/)
## Look at '<disk>' types, should be just 'file' types
# virsh dumpxml ${VM_NAME} | grep '<disk' -A5

## Create snapshot in default pool location
# sudo virsh snapshot-create-as ${VM_NAME} --name "name_of_snapshot" --description "description_of_snapshot"  --disk-only
# sudo virsh snapshot-list ${VM_NAME}
# sudo virsh domblklist ${VM_NAME}

## Reverting external snapshot
## snapshot points to backing file, which is original disk
# SNAPSHOT_NAME=$(sudo virsh dumpxml ${VM_NAME} | grep '<disk' -A5 | grep "device='disk'" -A5 | grep 'source file' | cut -d"'" -f2)
## sudo qemu-img info ${SNAPSHOT_NAME} -U --backing-chain
# BACKING_FILE=$(sudo qemu-img info ${SNAPSHOT_NAME} -U | grep -Po 'backing file:\s\K(.*)')
## To do the revert we need to modify the domain xml back to the original qcow2 file, 
## delete the snapshot metadata, and finally the snapshot file
## stop VM
# sudo virsh destroy ${VM_NAME}
## edit disk path back to original qcow2 disk
# VM_DISK=$(sudo virsh dumpxml ${VM_NAME} | grep '<disk' -A5 | grep "device='disk'" -A5 | grep 'target dev' | cut -d"'" -f2)
# sudo virt-xml ${VM_NAME} --edit target=${VM_DISK} --disk path=${BACKING_FILE} --update
## validate that we are now pointing back at original qcow2 disk
# sudo virsh domblklist ${VM_NAME}
## delete snapshot metadata
# sudo virsh snapshot-delete --metadata ${VM_NAME} ${SNAPSHOT_NAME}
## delete snapshot qcow2 file
# sudo rm ${SNAPSHOT_NAME}
## start guest domain
# sudo virsh start ${VM_NAME}
# The guest domain should now be in the original state

## Extend KVM guest OS disk
## Locate guest OS disk path
# sudo virsh domblklist ${VM_NAME}
# VM_DISK_PATH=$(sudo virsh dumpxml ${VM_NAME} | grep '<disk' -A5 | grep "device='disk'" -A5 | grep 'source file' | cut -d"'" -f2)
# sudo qemu-img resize ${VM_DISK_PATH} +20G

## resize with `virsh` command when domain in running
# sudo virsh blockresize ${VM_NAME} ${VM_DISK_PATH} 100G

## Reduce the size of VM files
## https://pov.es/virtualisation/kvm/kvm-qemu-reduce-the-size-of-your-vm-files/
## Stop the VM and then process the VM file
# sudo qemu-img info /var/lib/libvirt/images/${VM_NAME}.qcow2
# sudo qemu-img convert -O qcow2 /var/lib/libvirt/images/${VM_NAME}.qcow2 /var/lib/libvirt/images/${VM_NAME}-compressed.qcow2
## An alternative way of reducing the VM size is by using virt-sparsify
# yay --noconfirm --needed -S flex guestfs-tools
# sudo virt-sparsify --in-place /var/lib/libvirt/images/${VM_NAME}.qcow2

## Moving a VM to another KVM host
# sudo virsh shutdown ${VM_NAME}
# sudo virsh dumpxml ${VM_NAME} > ${VM_NAME}.xml
## List the network information for the VM
# sudo virsh domiflist ${VM_NAME}
## If you have different network configurations between the two KVM hosts, dump the VM network information to a XML file
# sudo virsh net-dumpxml [network_source_name] > [network_source_name].xml
## Transferred these files to the destination system:
## /var/lib/libvirt/images/${VM_NAME}.qcow2
## ${VM_NAME}.xml
## [network_source_name].xml
## After transferring the image file and XML file(s), create, if necessary, the network:
# sudo virsh net-define [network_source_name] [network_source_name].xml
# sudo virsh net-start [network_source_name]
# sudo virsh net-autostart [network_source_name]
## Edit the ${VM_NAME}.xml file, change the "source file" location
# grep "source file" ${VM_NAME}.xml
## Import the VM
# sudo virsh define ${VM_NAME}.xml

## Find the IP addresses of VMs
# sudo virsh net-info default
# sudo virsh net-dhcp-leases default
# sudo virsh domifaddr ${VM_NAME}


## [Dual boot with Windows](https://wiki.archlinux.org/title/Dual_boot_with_Windows)
# Create NTFS file systems on the disk
# Add `TPM 2.0` to VM
# Add `Windows11.iso` as CD-ROM to VM
# Add `virtio-win.iso` as CD-ROM to VM
# Strat VM
# Load storage drivers from `virtio-win.iso`
# Bypass NRO: `Shfit + F10` -> `oobe\BypassNRO.cmd`
# Install `Virtio-win-guest-tools`
# [spice-guest-tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe)
# [spice-webdavd](https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi)
# Disable Fast Startup and disable hibernation: `powercfg.exe /hibernate off`


## [Restoring grub after installing windows](https://wiki.manjaro.org/index.php/GRUB/Restore_the_GRUB_Bootloader#Reinstall_GRUB)
## Boot into `Manjaro LiveCD`
# ROOT_DEV='/dev/vda2'
# ROOT_DEV_PARENT=$(lsblk -no pkname "${ROOT_DEV}")
# sudo mount "${ROOT_DEV}" /mnt
# sudo manjaro-chroot /mnt 'mount /usr/local && mount /var && mount /boot/efi && grub-mkconfig -o /boot/grub/grub.cfg'


## Remove broken Grub boot entries
# sudo efibootmgr
# sudo efibootmgr -Bb <entry_number>
# sudo grub-mkconfig -o /boot/grub/grub.cfg


# [How to Fix Install Error – 0x800f0922 Windows 11?](https://www.minitool.com/backup-tips/install-error-0x800f0922-windows-11-10.html)
# Run `appwiz.cpl` -> Turn Windows features on or off
# Tick the checkbox of `.NET Framework 3.5 (includes .NET 2.0 and 3.0)`
# Besides, expand this item:
# Tick the checkbox of `Windows Communication Foundation HTTP Activation`
# Tick the checkbox of `Windows Communication Foundation Non-HTTP Activation`
# Click OK to save the change
# Then, check for `Windows updates` to see if install error – 0x800f0922 is removed from Windows 11


## Boot physical windows using Virt-Manager and KVM/QEMU
## [Boot a Windows Partition From Linux Using KVM](https://simgunz.org/posts/2021-12-12-boot-windows-partition-from-linux-kvm/)
## Check the disk ID location
# ls -l /dev/disk/by-id
## Assigning the disk by ID location in VM’s xml like below (using the entire disk):
#     <disk type="block" device="disk">
#         <driver name="qemu" type="raw" cache="none" io="native"/>
#         <source dev="/dev/disk/by-id/wwn-0x50004cf209bd73c7"/>
#         <target dev="vda" bus="virtio"/>
#         <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
#     </disk>


cd "${CURRENT_DIR}" || exit
