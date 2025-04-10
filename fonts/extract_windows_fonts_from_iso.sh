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

# [Microsoft fonts](https://wiki.archlinux.org/title/Microsoft_fonts)
# [ttf-ms-win11-auto](https://aur.archlinux.org/packages/ttf-ms-win11-auto)
if [[ $# -lt 2 ]]; then
    echo "Usage: $(basename "$0") windows-iso-file extract-to-directory"
    echo "eg: $(basename "$0") \$HOME/windows_11_business_editions_version_24h2.iso \$HOME/windows_fonts"
    exit 1
fi

isoFile=$1
extractDir=$2
[[ ! -d "${extractDir}" ]] && mkdir -p "${extractDir}"

yay --noconfirm --need -S udisks2 7zip httpdirfs fuse2 udftools wimlib

loopDev=$(udisksctl loop-setup -r -f "${isoFile}" --no-user-interaction 2>&1 | grep -oE "'.*'" | sed -e "s/'//g")

# Wait for the loop device to be automatically mounted
sleep 5

# Mount the loop device if not automatically mounted
if ! grep -qs "${loopDev}" /proc/mounts; then
    echo "  - Mounting loop device: ${loopDev}"
    udisksctl mount -t udf -b "${loopDev}" --no-user-interaction
fi

isoMountpoint=$(findmnt -nfr -o target -S "${loopDev}")
echo "  - Loop device mounted as ISO at: ${isoMountpoint}"

echo "  - Extracting files from online Windows installation image"
# 7z e -aoa "${isoMountpoint}/sources/install.wim" \
#     -o"${extractDir}" \
#     Windows/{Fonts/"*".{ttf,ttc},System32/Licenses/neutral/"*"/"*"/license.rtf}

## List the images contained in the WIM archive
# wiminfo "${isoMountpoint}/sources/install.wim"

# 3=Windows 11 Pro
wimextract "${isoMountpoint}/sources/install.wim" 3 \
    --dest-dir "${extractDir}" \
    /Windows/{Fonts/"*".{ttf,ttc},System32/Licenses/neutral/"*"/"*"/license.rtf}

echo "  - Unmounting loop device ${loopDev} as ISO at: ${isoMountpoint}"
udisksctl unmount -b "${loopDev}" --no-user-interaction

echo "  - Deleting loop device: ${loopDev}"
udisksctl loop-delete -b "${loopDev}" --no-user-interaction
