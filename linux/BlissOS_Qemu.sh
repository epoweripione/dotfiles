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

# [Bliss OS for PC - Android for your PC](https://blissos.org/)
# [VirtualBox (VDI) / VMware (VMDK)](https://www.osboxes.org/bliss-os/)
# [pve 安装 Bliss OS - Android-x86 并配置显卡直通](https://linkzz.org/posts/pve-bliss-os/)
QCOW_IMAGE_PATH="$HOME/kvm/BlissOS"
QCOW_IMAGE_FILE="${QCOW_IMAGE_PATH}/BlissOS.qcow2"

[[ ! -d "${QCOW_IMAGE_PATH}" ]] && mkdir -p "${QCOW_IMAGE_PATH}"

# [Download BlissOS](https://sourceforge.net/projects/blissos-x86/files/Official/)
INSTALL_ISO_FILE="${QCOW_IMAGE_PATH}/BlissOS.iso"
# curl -fSL -o "${INSTALL_ISO_FILE}" "<url>"

# Make the image
[[ ! -f "${QCOW_IMAGE_FILE}" ]] && qemu-img create -f qcow2 "${QCOW_IMAGE_FILE}" 20G

# Run the VM
qemu-system-x86_64 \
    -enable-kvm \
    -M q35 \
    -m 4096 -smp 4 -cpu host \
    -bios /usr/share/ovmf/x64/OVMF.fd \
    -drive file="${QCOW_IMAGE_FILE}",if=virtio \
    -cdrom "${INSTALL_ISO_FILE}" \
    -usb \
    -device virtio-tablet \
    -device virtio-keyboard \
    -device qemu-xhci,id=xhci \
    -machine vmport=off \
    -device virtio-vga-gl -display sdl,gl=on \
    -audiodev pa,id=snd0 -device AC97,audiodev=snd0 \
    -net nic,model=virtio-net-pci -net user,hostfwd=tcp::4444-:5555
