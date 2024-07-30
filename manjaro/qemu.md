# KVM & QEMU
[QEMU](https://wiki.archlinux.org/title/QEMU)
[Virt-manager](https://wiki.manjaro.org/index.php/Virt-manager)
[Install KVM, QEMU and Virt Manager on Arch Linux / Manjaro](https://computingforgeeks.com/install-kvm-qemu-virt-manager-arch-manjar/)
[Windows 11 on KVM – How to Install Step by Step?](https://getlabsdone.com/how-to-install-windows-11-on-kvm/)
```bash
# ISO image at: /var/lib/libvirt/images
# change default location of libvirt VM images
sudo virsh pool-dumpxml default > libvirt_pool.xml
sed -i 's|/var/lib/libvirt/images|/data/libvirt/images|' libvirt_pool.xml
sudo mkdir -p "/data/libvirt/images"
sudo virsh pool-destroy default
sudo virsh pool-create libvirt_pool.xml
```

## SPICE
- Using `virt-manager` (on host) change the guest VM configuration:
- Change the 'Video model' to 'QXL'
- Set the 'Display' to 'Spice'
- Add a 'spicevmc' Channel (via 'Add Hardware')

## Linux guest
```bash
sudo pacman --noconfirm --needed -S spice-vdagent xf86-video-qxl
echo -e '# auto start spice-vdagent\nspice-vdagent' | tee -a "$HOME/.xprofile"
```

## Windows guest
[spice-guest-tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe)
[spice-webdavd](https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi)
```bash
sudo virt-viewer
```

## [Shared folder](https://techpiezo.com/linux/shared-folder-in-qemu-virtual-machine-windows/)
```bash
qemu-system-x86_64 -net nic -net user,smb=<shared_folder_path> ...
# Custom Network Location: \\10.0.2.4\qemu\
```

## [Sharing files with Virtiofs](https://libvirt.org/kbase/virtiofs.html)
- `mkdir -p /mnt/share && chmod a+w /mnt/share`
- Add the following domain XML elements to share the host directory /path with the guest
```xml
    <filesystem type="mount" accessmode="passthrough">
      <driver type="virtiofs" queue="1024"/>
      <source dir="/mnt/share"/>
      <target dir="share"/>
      <address type="pci" domain="0x0000" bus="0x08" slot="0x00" function="0x0"/>
    </filesystem>
```

## Boot the guest and mount the filesystem
```bash
sudo mkdir -p /mnt/share && sudo mount -t virtiofs share /mnt/share
```

## [How to install virtiofs drivers on Windows](https://virtio-fs.gitlab.io/howto-windows.html)
- Installing the virtiofs PCI device driver(virtio-win.iso):
    * virtio-win-guest-tools.exe 
    * Device Manager→Other devices→Mass Storage Controller→Update driver
- Installing [WinFsp](https://github.com/billziss-gh/winfsp/releases/latest)
- Installing the virtiofs service
    * Run as administrator the Command Prompt and execute the following command:
    ```powershell
    sc create VirtioFsSvc binpath="C:\Program Files\Virtio-Win\VioFS\virtiofs.exe" start=auto depend="WinFsp.Launcher/VirtioFsDrv" DisplayName="Virtio FS Service"
    sc config VirtioFsSvc start=auto
    sc start VirtioFsSvc
    ```

## Add physical disk to kvm virtual machine
```bash
sudo env EDITOR=nano virsh edit ${VM_NAME}
```

## [Interacting with virtual machines](https://libvirt.org/manpages/virsh.html)
```bash
sudo virsh nodeinfo
sudo virsh list --all
sudo virsh domblklist ${VM_NAME}
sudo virsh start ${VM_NAME}
sudo virsh shutdown ${VM_NAME}
```

## Convert libvirt xml into qemu command line
```bash
sudo virsh domxml-to-native qemu-argv --domain ${VM_NAME}
```

## Network
[Libvirtd and dnsmasq](https://wiki.libvirt.org/page/Libvirtd_and_dnsmasq)
```bash
# On linux host servers, libvirtd uses dnsmasq to service the virtual networks, such as the default network.
# A new instance of dnsmasq is started for each virtual network, only accessible to guests in that specific network.
# If you are running your own "global" dnsmasq, then this can cause your own dnsmasq to fail to start 
# (or for libvirtd to fail to start its dnsmasq and the given virtual network).
# This happens because both instances of dnsmasq might try to bind to the same port number on the same network interfaces.
# You have to change the global `/etc/dnsmasq.conf` as follows:
# Either:
# interface=eth0
# or
# listen-address=192.168.0.1
# (Replace interface or listen-address with the interfaces or addresses you want your global dnsmasq to answer queries on).
# And uncomment this line to tell dnsmasq to only bind specific interfaces, not try to bind all interfaces:
# bind-interfaces
cat /etc/dnsmasq.conf | grep -i -E 'interface|listen-address'

brctl show
sudo virsh net-list --all
sudo virsh net-info default
sudo virsh net-dumpxml default
```

## [Create a new libvirt network](https://kashyapc.fedorapeople.org/virt/create-a-new-libvirt-bridge.txt)
```bash 
virsh net-define [new_name_of_network].xml
```

## remove the network named default
```bash
sudo virsh net-autostart default --disable
sudo virsh net-destroy default
sudo virsh net-undefine default
```

# autostart vm
sudo virsh autostart ${VM_NAME}

## To destroy or forcefully power off virtual machine
```bash
sudo virsh destroy ${VM_NAME}
```

## To delete or removing virtual machine along with its disk file
```bash
# First shutdown the virtual machine
sudo virsh shutdown ${VM_NAME}

# Delete the virtual machine along with its associated storage file
sudo virsh undefine ${VM_NAME} --nvram -remove-all-storage
```

## Rename KVM domain
```bash
sudo virsh shutdown ${VM_NAME}
sudo virsh domrename ${VM_NAME} ${VM_NEW_NAME}
# or
sudo virsh dumpxml ${VM_NAME} > ${VM_NEW_NAME}.xml

# Edit the XML file and change the name between the <name></name>
sudo virsh shutdown ${VM_NAME}
sudo virsh undefine ${VM_NAME} --nvram

# import the edited XML file to define the VM bar
sudo virsh define ${VM_NEW_NAME}.xml
```

## Snapshot for pflash based firmware
[KVM: creating and reverting libvirt external snapshots](https://fabianlee.org/2021/01/10/kvm-creating-and-reverting-libvirt-external-snapshots/)
```bash
# Look at '<disk>' types, should be just 'file' types
virsh dumpxml ${VM_NAME} | grep '<disk' -A5

# Create snapshot in default pool location
sudo virsh snapshot-create-as ${VM_NAME} --name "name_of_snapshot" --description "description_of_snapshot"  --disk-only
sudo virsh snapshot-list ${VM_NAME}
sudo virsh domblklist ${VM_NAME}
```

## Reverting external snapshot
```bash
# snapshot points to backing file, which is original disk
SNAPSHOT_NAME=$(sudo virsh dumpxml ${VM_NAME} | grep '<disk' -A5 | grep "device='disk'" -A5 | grep 'source file' | cut -d"'" -f2)

# sudo qemu-img info ${SNAPSHOT_NAME} -U --backing-chain
BACKING_FILE=$(sudo qemu-img info ${SNAPSHOT_NAME} -U | grep -Po 'backing file:\s\K(.*)')

# To do the revert we need to modify the domain xml back to the original qcow2 file, 
# delete the snapshot metadata, and finally the snapshot file
# stop VM
sudo virsh destroy ${VM_NAME}

# edit disk path back to original qcow2 disk
VM_DISK=$(sudo virsh dumpxml ${VM_NAME} | grep '<disk' -A5 | grep "device='disk'" -A5 | grep 'target dev' | cut -d"'" -f2)
sudo virt-xml ${VM_NAME} --edit target=${VM_DISK} --disk path=${BACKING_FILE} --update

# validate that we are now pointing back at original qcow2 disk
sudo virsh domblklist ${VM_NAME}

# delete snapshot metadata
sudo virsh snapshot-delete --metadata ${VM_NAME} ${SNAPSHOT_NAME}

# delete snapshot qcow2 file
sudo rm ${SNAPSHOT_NAME}

# start guest domain
sudo virsh start ${VM_NAME}

# The guest domain should now be in the original state
```

## Extend KVM guest OS disk
```bash
# Locate guest OS disk path
sudo virsh domblklist ${VM_NAME}
VM_DISK_PATH=$(sudo virsh dumpxml ${VM_NAME} | grep '<disk' -A5 | grep "device='disk'" -A5 | grep 'source file' | cut -d"'" -f2)
sudo qemu-img resize ${VM_DISK_PATH} +20G

# resize with `virsh` command when domain in running
sudo virsh blockresize ${VM_NAME} ${VM_DISK_PATH} 100G
```

## [Reduce the size of VM files](https://pov.es/virtualisation/kvm/kvm-qemu-reduce-the-size-of-your-vm-files/)
```bash
# Stop the VM and then process the VM file
sudo qemu-img info /var/lib/libvirt/images/${VM_NAME}.qcow2
sudo qemu-img convert -O qcow2 /var/lib/libvirt/images/${VM_NAME}.qcow2 /var/lib/libvirt/images/${VM_NAME}-compressed.qcow2
# An alternative way of reducing the VM size is by using virt-sparsify
yay --noconfirm --needed -S flex guestfs-tools
sudo virt-sparsify --in-place /var/lib/libvirt/images/${VM_NAME}.qcow2

# Moving a VM to another KVM host
sudo virsh shutdown ${VM_NAME}
sudo virsh dumpxml ${VM_NAME} > ${VM_NAME}.xml
# List the network information for the VM
sudo virsh domiflist ${VM_NAME}
# If you have different network configurations between the two KVM hosts, dump the VM network information to a XML file
sudo virsh net-dumpxml [network_source_name] > [network_source_name].xml
# Transferred these files to the destination system:
# /var/lib/libvirt/images/${VM_NAME}.qcow2
# ${VM_NAME}.xml
# [network_source_name].xml
# After transferring the image file and XML file(s), create, if necessary, the network:
sudo virsh net-define [network_source_name] [network_source_name].xml
sudo virsh net-start [network_source_name]
sudo virsh net-autostart [network_source_name]
# Edit the ${VM_NAME}.xml file, change the "source file" location
grep "source file" ${VM_NAME}.xml
# Import the VM
sudo virsh define ${VM_NAME}.xml
```

## Find the IP addresses of VMs
```bash
sudo virsh net-info default
sudo virsh net-dhcp-leases default
sudo virsh domifaddr ${VM_NAME}
```

## [Dual boot with Windows](https://wiki.archlinux.org/title/Dual_boot_with_Windows)
- Create NTFS file systems on the disk
- Add `TPM 2.0` to VM
- Add `Windows11.iso` as CD-ROM to VM
- Add `virtio-win.iso` as CD-ROM to VM
- Strat VM
- Load storage drivers from `virtio-win.iso`
- Bypass NRO: `Shfit + F10` -> `oobe\BypassNRO.cmd`
- Install `Virtio-win-guest-tools`
    * [spice-guest-tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe)
    * [spice-webdavd](https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi)
- Disable Fast Startup and disable hibernation: `powercfg.exe /hibernate off`

## [Restoring grub after installing windows](https://wiki.manjaro.org/index.php/GRUB/Restore_the_GRUB_Bootloader#Reinstall_GRUB)
```bash
# Boot into `Manjaro LiveCD`
ROOT_DEV='/dev/vda2'
ROOT_DEV_PARENT=$(lsblk -no pkname "${ROOT_DEV}")
sudo mount "${ROOT_DEV}" /mnt
sudo manjaro-chroot /mnt 'mount /usr/local && mount /var && mount /boot/efi && grub-mkconfig -o /boot/grub/grub.cfg'
```

## Remove broken Grub boot entries
```bash
sudo efibootmgr
sudo efibootmgr -Bb <entry_number>
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## [How to Fix Install Error - 0x800f0922 Windows 11?](https://www.minitool.com/backup-tips/install-error-0x800f0922-windows-11-10.html)
- Run `appwiz.cpl` -> Turn Windows features on or off
- Tick the checkbox of `.NET Framework 3.5 (includes .NET 2.0 and 3.0)`
- Besides, expand this item:
- Tick the checkbox of `Windows Communication Foundation HTTP Activation`
- Tick the checkbox of `Windows Communication Foundation Non-HTTP Activation`
- Click OK to save the change
- Then, check for `Windows updates` to see if install error - 0x800f0922 is removed from Windows 11

## Boot physical windows using Virt-Manager and KVM/QEMU
[Boot a Windows Partition From Linux Using KVM](https://simgunz.org/posts/2021-12-12-boot-windows-partition-from-linux-kvm/)

### Check the disk ID location
```bash
ls -l /dev/disk/by-id
```

### Assigning the disk by ID location in VM’s xml like below (using the entire disk)
```xml
    <disk type="block" device="disk">
        <driver name="qemu" type="raw" cache="none" io="native"/>
        <source dev="/dev/disk/by-id/wwn-0x50004cf209bd73c7"/>
        <target dev="vda" bus="virtio"/>
        <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
    </disk>
```

## [ARM QEMU VM on Linux](https://www.willhaley.com/blog/debian-arm-qemu/)
```bash
sudo pacman --noconfirm --needed -S qemu-system-aarch64 qemu-system-arm-firmware dpkg guestfs-tools

# Supported ARM Board
qemu-system-aarch64 -M help

# Supported CPU
qemu-system-aarch64 -M virt --cpu help

# Using Debian Official Kernel and initrd
curl -fSL -o "$HOME/kvm/debian12arm/linux" "http://ftp.debian.org/debian/dists/bookworm/main/installer-arm64/current/images/netboot/debian-installer/arm64/linux"
curl -fSL -o "$HOME/kvm/debian12arm/initrd.gz" "http://ftp.debian.org/debian/dists/bookworm/main/installer-arm64/current/images/netboot/debian-installer/arm64/initrd.gz"
qemu-img create -f qcow2 "$HOME/kvm/debian12arm/debian12-arm64.qcow2" 20G

# Run virtual machine to start the installation
qemu-system-aarch64 -M virt -cpu max -smp 8 -m 4G \
    -initrd "$HOME/kvm/debian12arm/initrd.gz" \
    -kernel "$HOME/kvm/debian12arm/linux" \
    -drive if=virtio,file="$HOME/kvm/debian12arm/debian12-arm64.qcow2" \
    -nic user,model=e1000 \
    -nographic

# After the installation finishes the vm will restart
pkill qemu

# Booting the image with newly installed kernel image in partition `/dev/sda1` and `"root=/dev/sda2"`
sudo modprobe nbd
sudo qemu-nbd --connect=/dev/nbd0 "$HOME/kvm/debian12arm/debian12-arm64.qcow2"
ls /dev/nbd*
mkdir /mnt/nbd
sudo mount /dev/nbd0p1 /mnt/nbd
ls /mnt/nbd
cp /mnt/nbd/initrd.img-* "$HOME/kvm/debian12arm/initrd.img"
cp /mnt/nbd/vmlinuz-* "$HOME/kvm/debian12arm/vmlinuz"
sudo umount /mnt/nbd
sudo qemu-nbd -d /dev/nbd0

# Boot with the new kernel
qemu-system-aarch64 -M virt -cpu max -smp 8 -m 4G \
    -initrd "$HOME/kvm/debian12arm/initrd.img" \
    -kernel "$HOME/kvm/debian12arm/vmlinuz" -append "root=/dev/sda2" \
    -drive id=hd0,media=disk,if=none,file="$HOME/kvm/debian12arm/debian12-arm64.qcow2" \
    -device virtio-scsi-pci \
    -device scsi-hd,drive=hd0 \
    -nic user,model=virtio,hostfwd=tcp::2222-:22,hostfwd=tcp::8000-:80 \
    -nographic

# Using Debian Official Cloud ARM Images(.qcow2)
mkdir -p "$HOME/kvm/debian12arm"
curl -fSL -o "$HOME/kvm/debian12arm/debian12-arm64.qcow2" "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-arm64.qcow2"

# QEMU_EFI.fd
curl -fSL -o "$HOME/kvm/debian12arm/qemu-efi-aarch64.deb" "https://ftp.debian.org/debian/pool/main/e/edk2/qemu-efi-aarch64_2022.11-6%2Bdeb12u1_all.deb"
dpkg -X "$HOME/kvm/debian12arm/qemu-efi-aarch64.deb" "$HOME/kvm/debian12arm" && \
    find "$HOME/kvm/debian12arm" -type f -name "QEMU_EFI.fd" -exec cp {} "$HOME/kvm/debian12arm" \;

## Modify `root` password to `RootPassW0rd` using `libguestfs`
# virt-customize -a "$HOME/kvm/debian12arm/debian12-arm64.qcow2" --root-password password:RootPassW0rd

# Resize img
qemu-img resize "$HOME/kvm/debian12arm/debian12-arm64.qcow2" +10G

# Run virtual machine without GUI
qemu-system-aarch64 -M virt -cpu cortex-a710 -smp 8 -m 4G \
    -bios "$HOME/kvm/debian12arm/QEMU_EFI.fd" \
    -drive id=hd0,media=disk,if=none,file="$HOME/kvm/debian12arm/debian12-arm64.qcow2" \
    -device virtio-scsi-pci \
    -device scsi-hd,drive=hd0 \
    -nic user,model=virtio,hostfwd=tcp::2222-:22,hostfwd=tcp::8000-:80 \
    -nographic

# [Network bridge](https://wiki.archlinux.org/title/network_bridge)
NETWORK_INTERFACE_DEFAULT=$(ip route 2>/dev/null | grep default | sed -e "s/^.*dev.//" | awk '{print $1}' | head -n1)
NETWORK_INTERFACE_WIRELESS=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -n1)

# TUN/TAP Network
BridgeName="virbr0"

# sudo ip link add name "${BridgeName:-virbr0}" type bridge
# sudo ip addr add 192.168.100.1/24 brd + dev "${BridgeName:-virbr0}"
# sudo ip link set "${BridgeName:-virbr0}" up
# sudo iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT

## configure iptables/nftables to forward traffic across the bridge network
## sudo sysctl -w net.ipv4.ip_forward=1
## sudo iptables -t filter -A FORWARD -i "${BridgeName:-virbr0}" -j ACCEPT
## sudo iptables -t filter -A FORWARD -o "${BridgeName:-virbr0}" -j ACCEPT

## Enable NAT for network interface
# while read -r iface; do
#     sudo iptables -t nat -A POSTROUTING -o "${iface}" -j MASQUERADE;
# done <<< "$(ip link 2>/dev/null | grep -Ev "lo|vir|docker|^[^0-9]" | cut -d: -f2 | sed 's/[\s\t ]//g')"

## Bridged network
# while read -r iface; do
#     sudo ip link set "${iface}" master "${BridgeName:-virbr0}";
# done <<< "$(ip link 2>/dev/null | grep -Ev "lo|vir|docker|^[^0-9]" | cut -d: -f2 | sed 's/[\s\t ]//g')"

sudo tee "/etc/systemd/system/qemu-bridge-network.service" >/dev/null <<-EOF
[Unit]
Description=Setup qemu network bridging
After=network-online.target

[Service]
Type=oneshot
Restart=on-failure
ExecStart=ip link add name ${BridgeName:-virbr0} type bridge
ExecStart=ip addr add 192.168.100.1/24 brd + dev ${BridgeName:-virbr0}
ExecStart=ip link set ${BridgeName:-virbr0} up
ExecStart=iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT
ExecStart=iptables -t nat -A POSTROUTING -o "${NETWORK_INTERFACE_DEFAULT:-enp3s0}" -j MASQUERADE
ExecStart=iptables -t nat -A POSTROUTING -o "${NETWORK_INTERFACE_WIRELESS:-wlp2s0}" -j MASQUERADE

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now "qemu-bridge-network"

echo "allow "${BridgeName:-virbr0}"" | sudo tee >> "/etc/qemu/bridge.conf" 2>/dev/null
sudo chown root:kvm "/etc/qemu/bridge.conf" && sudo chmod 0660 "/etc/qemu/bridge.conf"
sudo chmod u+s "/usr/lib/qemu/qemu-bridge-helper"

# Delete a bridge
sudo ip link set dev "${BridgeName:-virbr0}" down
sudo brctl delbr "${BridgeName:-virbr0}"

# Run virtual machine with NAT without GUI
qemu-system-aarch64 -M virt -cpu cortex-a710 -smp 8 -m 4G \
    -bios "$HOME/kvm/debian12arm/QEMU_EFI.fd" \
    -drive id=hd0,media=disk,if=none,file="$HOME/kvm/debian12arm/debian12-arm64.qcow2" \
    -device virtio-scsi-pci \
    -device scsi-hd,drive=hd0 \
    -nic bridge,model=virtio,br="${BridgeName:-virbr0}" \
    -nographic

# Network in guest OS
sudo systemctl enable --now systemd-networkd
sudo systemctl enable --now systemd-resolved

# echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8" | sudo tee -a "/etc/resolv.conf"
sudo mkdir -p "/etc/systemd/resolved.conf.d"
sudo tee "/etc/systemd/resolved.conf.d/dns_servers.conf" >/dev/null <<-'EOF'
[Resolve]
DNS=1.1.1.1
FallbackDNS=8.8.8.8
EOF

sudo systemctl restart systemd-resolved
resolvectl status

# Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf >/dev/null
sysctl -p

# Static ip in guest OS
NETWORK_INTERFACE_DEFAULT=$(ip route 2>/dev/null | grep default | sed -e "s/^.*dev.//" | awk '{print $1}' | head -n1)
# sudo ip addr add 192.168.100.2/24 brd + dev "${NETWORK_INTERFACE_DEFAULT:-enp0s1}"
# sudo ip route add default via 192.168.100.1 dev "${NETWORK_INTERFACE_DEFAULT:-enp0s1}"
sudo tee "/etc/systemd/system/static-ip-${NETWORK_INTERFACE_DEFAULT:-enp0s1}.service" >/dev/null <<-EOF
[Unit]
Description=Setup static ip for ${NETWORK_INTERFACE_DEFAULT:-enp0s1}
After=network-online.target

[Service]
Type=oneshot
Restart=on-failure
ExecStart=ip addr add 192.168.100.2/24 brd + dev ${NETWORK_INTERFACE_DEFAULT:-enp0s1}
ExecStart=ip route add default via 192.168.100.1 dev ${NETWORK_INTERFACE_DEFAULT:-enp0s1}

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now "static-ip-${NETWORK_INTERFACE_DEFAULT:-enp0s1}"

# apt mirrors
tee "/etc/apt/sources.list.d/debian.sources" >/dev/null <<-EOF
Types: deb
URIs: https://mirrors.ustc.edu.cn/debian
Suites: bookworm bookworm-updates bookworm-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Types: deb-src
# URIs: https://mirrors.ustc.edu.cn/debian
# Suites: bookworm bookworm-updates bookworm-backports
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://mirrors.ustc.edu.cn/debian-security
Suites: bookworm-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Types: deb-src
# URIs: https://mirrors.ustc.edu.cn/debian-security
# Suites: bookworm-security
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

sudo apt-get update && sudo apt-get upgrade -y

# SSH
sudo apt-get install -y openssh-server rsync

# ssh key
# echo "ssh-ed25519 xxx" >> ~/.ssh/authorized_keys
curl -fsSL "http://<local computer ip>:8080/id_ed25519.pub" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/*

# Login with ssh in Host
ssh -p 2222 -i ~/.ssh/id_ed25519 root@127.0.0.1
ssh -i ~/.ssh/id_ed25519 root@192.168.100.2

# [Resize root partition](https://askubuntu.com/questions/24027/how-can-i-resize-an-ext-root-partition-at-runtime)
sudo apt-get install -y cloud-utils
sfdisk -d /dev/sda > partition_sda_bak.dmp # backup partition table 
sudo growpart /dev/sda 1
sudo resize2fs -p /dev/sda1
sudo df -Th
```
