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
# https://getlabsdone.com/how-to-install-windows-11-on-kvm/
# emulate the TPM
colorEcho "${BLUE}Installing ${FUCHSIA}QEMU tools${BLUE}..."
# TPM Emulator
sudo pacman --noconfirm --needed -S swtpm

# Enable secure-boot/UEFI on KVM
sudo pacman --noconfirm --needed -S edk2-ovmf

# Install the qemu package
sudo pacman --noconfirm --needed -S qemu-desktop
sudo pacman --noconfirm --needed -S libvirt virt-install virt-manager virt-viewer

sudo systemctl enable libvirtd && sudo systemctl start libvirtd

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
# sudo env EDITOR=nano virsh edit [name_of_vm]

## Interacting with virtual machines
## https://libvirt.org/manpages/virsh.html
# sudo virsh nodeinfo
# sudo virsh list --all
# sudo virsh domblklist [name_of_vm]
# sudo virsh start [name_of_vm]
# sudo virsh shutdown [name_of_vm]

## Convert libvirt xml into qemu command line
# sudo virsh domxml-to-native qemu-argv --domain [name_of_vm]

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
# sudo virsh autostart [name_of_vm]

## To destroy or forcefully power off virtual machine
# sudo virsh destroy [name_of_vm]

## To delete or removing virtual machine along with its disk file
## a) First shutdown the virtual machine
# sudo virsh shutdown [name_of_vm]
## b) Delete the virtual machine along with its associated storage file
# sudo virsh undefine [name_of_vm] --nvram –remove-all-storage

## rename KVM domain
# sudo virsh shutdown [name_of_vm]
# sudo virsh domrename [name_of_vm] [new_name_of_vm]
## or
# sudo virsh dumpxml [name_of_vm] > [new_name_of_vm].xml
## Edit the XML file and change the name between the <name></name>
# sudo virsh shutdown [name_of_vm]
# sudo virsh undefine [name_of_vm] --nvram
## import the edited XML file to define the VM bar
# sudo virsh define [new_name_of_vm].xml

## Snapshot
# sudo virsh snapshot-create-as -–domain [name_of_vm] --name "name_of_snapshot" --description "description_of_snapshot"
# sudo virsh snapshot-list [name_of_vm]
# sudo virsh snapshot-revert --doamin [name_of_vm] --snapshotname "name_of_snapshot" --running
# sudo virsh snapshot-delete --doamin [name_of_vm] --snapshotname "name_of_snapshot"

## Reduce the size of VM files
## https://pov.es/virtualisation/kvm/kvm-qemu-reduce-the-size-of-your-vm-files/
## Stop the VM and then process the VM file
# sudo qemu-img info /var/lib/libvirt/images/[name_of_vm].qcow2
# sudo qemu-img convert -O qcow2 /var/lib/libvirt/images/[name_of_vm].qcow2 /var/lib/libvirt/images/[name_of_vm]-compressed.qcow2
## An alternative way of reducing the VM size is by using virt-sparsify
# yay --noconfirm --needed -S flex guestfs-tools
# sudo virt-sparsify --in-place /var/lib/libvirt/images/[name_of_vm].qcow2

## Moving a VM to another KVM host
# sudo virsh shutdown [name_of_vm]
# sudo virsh dumpxml [name_of_vm] > [name_of_vm].xml
## List the network information for the VM
# sudo virsh domiflist [name_of_vm]
## If you have different network configurations between the two KVM hosts, dump the VM network information to a XML file
# sudo virsh net-dumpxml [network_source_name] > [network_source_name].xml
## Transferred these files to the destination system:
## /var/lib/libvirt/images/[name_of_vm].qcow2
## [name_of_vm].xml
## [network_source_name].xml
## After transferring the image file and XML file(s), create, if necessary, the network:
# sudo virsh net-define [network_source_name] [network_source_name].xml
# sudo virsh net-start [network_source_name]
# sudo virsh net-autostart [network_source_name]
## Edit the [name_of_vm].xml file, change the "source file" location
# grep "source file" [name_of_vm].xml
## Import the VM
# sudo virsh define [name_of_vm].xml

## Find the IP addresses of VMs
# sudo virsh net-info default
# sudo virsh net-dhcp-leases default
# sudo virsh domifaddr [name_of_vm]


cd "${CURRENT_DIR}" || exit
