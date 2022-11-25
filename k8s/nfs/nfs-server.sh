#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

## Docker nfs server
## https://github.com/ehough/docker-nfs-server
# if [[ -x "$(command -v pacman)" ]]; then
#     PackagesList=(
#         apparmor-utils
#         lxc
#     )
#     for TargetPackage in "${PackagesList[@]}"; do
#         if checkPackageNeedInstall "${TargetPackage}"; then
#             colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
#             sudo pacman --noconfirm -S "${TargetPackage}"
#         fi
#     done
# fi

# sudo tee "/etc/apparmor/rpc_pipefs.conf" 2>/dev/null <<-'EOF'
# #include <tunables/global>
# profile erichough-nfs flags=(attach_disconnected,mediate_deleted) {
#   #include <abstractions/lxc/container-base>
#   mount fstype=nfs*,
#   mount fstype=rpc_pipefs,
# }
# EOF

# sudo apparmor_parser -r -W "/etc/apparmor/rpc_pipefs.conf"

## docker-compose up -d
## docker ps
## docker-compose logs

## sudo mount -v -t nfs <container-IP>:/some/export /some/local/path
## sudo mount -v -t nfs -o vers=3 192.168.0.200:/nfs /mnt/nfs


# https://wiki.archlinux.org/title/NFS
# https://www.cnblogs.com/pipci/p/9935572.html
if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        nfs-kernel-server
        nfs-common
        nfs-utils
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi

# sudo systemctl enable rpcbind nfs-server && sudo systemctl start rpcbind nfs-server

NFS_EXPORTS=$(< "${MY_SHELL_SCRIPTS}/k8s/nfs/exports")
NFS_EXPORTS=$(echo "${NFS_EXPORTS}" | grep -Ev '^#' | grep -Ev '^$')

while read -r nfs_export; do
    [[ -z "${nfs_export}" ]] && continue

    NFS_DIR=$(echo "${nfs_export}" | awk '{print $1}')
    [[ ! -e "${NFS_DIR}" ]] && sudo mkdir -p "${NFS_DIR}"

    # anonymous user
    ANON_UID=$(echo "${nfs_export}" | grep -Eo 'anonuid=[0-9]{1,}' | cut -d'=' -f2)
    ANON_GID=$(echo "${nfs_export}" | grep -Eo 'anongid=[0-9]{1,}' | cut -d'=' -f2)
    if [[ -n "${ANON_UID}" && -n "${ANON_GID}" ]]; then
        if ! grep -q "${ANON_UID}:${ANON_GID}" "/etc/passwd" 2>/dev/null; then
            # -M, --no-create-home: do not create the user's home directory
            groupadd -g "${ANON_GID}" "nfs-anon-${ANON_GID}"
            useradd -g "${ANON_GID}" -u "${ANON_UID}" -M "nfs-anon-${ANON_UID}"
            chown -R "${ANON_UID}:${ANON_GID}" "${NFS_DIR}"
        fi
    fi
done < <(echo "${NFS_EXPORTS}")

echo "${NFS_EXPORTS}" | sudo tee -a "/etc/exports" >/dev/null

# sudo systemctl restart rpcbind nfs-server
# sudo systemctl status rpcbind nfs-server

sudo exportfs -ar
sudo exportfs -v

# Ports: 111,2049 rpc.mountd,rpcbind
sudo ss -lntup | grep ':111\|:2049'
sudo rpcinfo -p

# sudo systemctl restart rpcbind nfs-server
# sudo systemctl stop rpcbind.socket rpcbind nfs-server


## mount nfs
# sudo showmount -e <nfs-server-ip>
sudo showmount -e 127.0.0.1

# sudo mount -v -t nfs -o nolock 127.0.0.1:/nfs /mnt/nfs
# sudo findmnt

## automount
# echo "127.0.0.1:/nfs /mnt/nfs nfs defaults 0 0" | sudo tee -a "/etc/fstab"

## unmount
# sudo umount -l /mnt/nfs
## If the remote NFS system isunreachable, use the -f (--force) option to force an unmount
# sudo umount -f /mnt/nfs


## mount nfs on windows
## For server operating system
# Install-WindowsFeature NFS-Client
## For Desktop operating system
# Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like '*nfs*'
# Enable-WindowsOptionalFeature -Online -FeatureName ServicesForNFS-ClientOnly,ClientForNFS-Infrastructure -NoRestart
# mount -o nolock \\<nfs-server-ip>\nfs z:
