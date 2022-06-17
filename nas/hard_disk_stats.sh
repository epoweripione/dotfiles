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

if [[ -x "$(command -v pacman)" ]]; then
    # Pre-requisite packages
    PackagesList=(
        smartmontools
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi

# https://zhuanlan.zhihu.com/p/398819857
# sudo fdisk -l
# shellcheck disable=SC2010
dsk=$(ls /dev/sd* | grep -Po 'sd(a{2}|[a-z]+)$')

date +"%F %T %Z %z"

printf "%-11s %-10s %-40s %-10s\n" Disk Stats DiskLable Capacity

standby=0
active=0
unknown=0
c=0

for i in $dsk; do
    printf "%-11s" "/dev/$i:"

    stats=$(smartctl -i -n standby /dev/"$i" | grep "mode" | awk '{print $4}')

    if [[ $stats == STANDBY || $stats == ACTIVE || $stats == IDLE_A ]]; then
        for s in $stats; do
            if [[ $s == STANDBY ]]; then
                echo -e -n "\033[30;42mSTANDBY\033[0m"
                printf "%-5s" ""
                let standby=$standby+1
            else
                echo -e -n "\033[37;41mACTIVE \033[0m"
                printf "%-5s" ""
                let active=$active+1
            fi
        done
    else
        echo -e -n "\033[30;47mUNKNOWN\033[0m"
        printf "%-5s" ""
        unknown=$unknown+1
        for un in $i; do
            list[c]=$un
            ((c++))
        done
    fi

    mountpoint=$(lsblk "/dev/$i" | grep "/srv/dev-disk-by-label-" | awk '{print $7}');
    if [[ $mountpoint == */srv/dev* ]]; then
        printf "%-40s" "$(lsblk "/dev/$i" | grep "/srv/dev-disk-by-label-" | awk '{print $7}')"
    else
        echo -n "Not Mounted!"
    fi

    printf "%-10s\n" "$(lsblk "/dev/$i" | grep "/srv/dev-disk-by-label-" | awk '{print $4}')"
done

echo -e "\n"
echo -e "\033[37;41mActive  Disk in Total=$active  \033[0m"
echo -e "\033[30;42mStandby Disk in Total=$standby  \033[0m"
echo -e "\033[30;47mUnknown Disk in Total=$unknown   \033[0m"

echo -e "Unknown Disk list: "
for ((b=0;b<=c;b++)); do
    if [[ $b -lt $c ]]; then
        echo "/dev/${list[b]}"
    fi
done

echo -e "\n"

exit