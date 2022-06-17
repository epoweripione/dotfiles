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
## spice-guest-tools
## https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe
## spice-webdavd
## https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi
# sudo virt-viewer

## Shared folder
## https://techpiezo.com/linux/shared-folder-in-qemu-virtual-machine-windows/
# qemu-system-x86_64 -net nic -net user,smb=<shared_folder_path> ...
## Custom Network Location: \\10.0.2.4\qemu\

## Add physical disk to kvm virtual machine
# sudo env EDITOR=nano virsh edit [name_of_vm]

## Interacting with virtual machines
## https://libvirt.org/manpages/virsh.html
# sudo virsh nodeinfo
# sudo virsh list --all
# sudo virsh domxml-to-native qemu-argv --domain [name_of_vm]
# sudo virsh domblklist [name_of_vm]
# sudo virsh start [name_of_vm]
# sudo virsh shutdown [name_of_vm]

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


## Run Windows apps
## https://github.com/Osmium-Linux/winapps
# Git_Clone_Update_Branch "Osmium-Linux/winapps" "$HOME/winapps"

## Set up KVM to run as your user instead of root and allow it through AppArmor
# sudo sed -i "s/#user = \"root\"/user = \"$(id -un)\"/g" "/etc/libvirt/qemu.conf"
# sudo sed -i "s/#group = \"root\"/group = \"$(id -gn)\"/g" "/etc/libvirt/qemu.conf"
# sudo usermod -a -G kvm "$(id -un)"
# sudo usermod -a -G libvirt "$(id -un)"
# sudo systemctl restart libvirtd
## sudo ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
# sleep 5
## Marked network default as autostarted
# sudo virsh net-autostart default
# sudo virsh net-start default

# mkdir -p "$HOME/.config/winapps/"
# tee "$HOME/.config/winapps/winapps.conf" >/dev/null <<-EOF
# RDP_USER="MyWindowsUser"
# RDP_PASS="MyWindowsPassword"
# #RDP_DOMAIN="MYDOMAIN"
# #RDP_IP="192.168.123.111"
# #RDP_SCALE=100
# #RDP_FLAGS=""
# #MULTIMON="true"
# #DEBUG="true"
# #VIRT_MACHINE_NAME="machine-name"
# #VIRT_NEEDS_SUDO="true"
# #RDP_SECRET="account"
# EOF

## add the RDP password for lookup using secret tool
# secret-tool store --label='winapps' winapps account

# if [[ -d "$HOME/winapps" ]]; then
#     cd "$HOME/winapps" && bin/winapps check
#     ./installer.sh --user
# fi


cd "${CURRENT_DIR}" || exit
