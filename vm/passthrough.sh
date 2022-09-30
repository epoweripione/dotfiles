#!/usr/bin/env bash

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

# [PCI passthrough via OVMF](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
# [manjaro-gpu-passthrough](https://gist.github.com/vwxyzjn/ab94cb5d759360f252b0441bf8d998b4)
# [gpu-passthrough-tutorial](https://github.com/bryansteiner/gpu-passthrough-tutorial)
# [Running Windows 10 on Linux using KVM with VGA Passthrough](https://www.heiko-sieger.info/running-windows-10-on-linux-using-kvm-with-vga-passthrough/)
# [国光的 PVE 生产环境配置优化记录](https://www.sqlsec.com/2022/04/pve.html)
# [双显卡笔记本独显直通](https://www.codeplayer.org/Blog/%E5%8F%8C%E6%98%BE%E5%8D%A1%E7%AC%94%E8%AE%B0%E6%9C%AC%E7%8B%AC%E6%98%BE%E7%9B%B4%E9%80%9A.html)

## enable IOMMU in the BIOS
# Reboot your PC and enter the BIOS setup menu
# Search for IOMMU, VT-d, SVM, or "virtualisation technology for directed IO" or whatever it may be called on your system. Turn on VT-d/IOMMU.
# Save and Exit BIOS and boot into Linux.

# Find the Device IDs
# The first value (26:00.0) is the BDF ID, and the last [1002:6810] is the Device ID
lspci -nn | grep "VGA\|Audio"

# Enable Iommu
. "/etc/default/grub"
if [[ -n "${GRUB_CMDLINE_LINUX}" ]]; then
    GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt ${GRUB_CMDLINE_LINUX}"
    sudo sed -i "s/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"${GRUB_CMDLINE_LINUX}\"/" "/etc/default/grub"
else
    echo 'GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt"' | sudo tee -a "/etc/default/grub" >/dev/null
fi

sudo update-grub
# sudo grub-mkconfig -o /boot/grub/grub.cfg

# reboot
# sudo dmesg | grep -i -e DMAR -e IOMMU


# Check how your various PCI devices are mapped to IOMMU groups
for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
    echo "IOMMU Group ${g##*/}:"
    for d in "$g"/devices/*; do
        echo -e "\t$(lspci -nns "${d##*/}")"
    done
done
