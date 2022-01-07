#!/usr/bin/env bash

# Colors
NOCOLOR='\033[0m'
RED='\033[0;31m'        # Error message
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'      # Success message
LIGHTGREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'     # Warning message
BLUE='\033[0;34m'       # Info message
LIGHTBLUE='\033[1;34m'
PURPLE='\033[0;35m'
FUCHSIA='\033[0;35m'
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHTCYAN='\033[1;36m'
DARKGRAY='\033[1;30m'
LIGHTGRAY='\033[0;37m'
WHITE='\033[1;37m'

function colorEcho() {
    if [[ $# -gt 1 ]]; then
        local COLOR=$1
        echo -e "${COLOR}${@:2}${NOCOLOR}"
    else
        echo -e "${@:1}${NOCOLOR}"
    fi
}

function colorEchoN() {
    if [[ $# -gt 1 ]]; then
        local COLOR=$1
        echo -e -n "${COLOR}${@:2}${NOCOLOR}"
    else
        echo -e -n "${@:1}${NOCOLOR}"
    fi
}

function colorEchoAllColor() {
    colorEchoN "${RED}red ${GREEN}green ${YELLOW}yellow ${BLUE}blue ${ORANGE}orange ${PURPLE}purple ${FUCHSIA}fuchsia ${CYAN}cyan "
    colorEchoN "${LIGHTRED}lightred ${LIGHTGREEN}lightgreen ${LIGHTBLUE}lightblue ${LIGHTPURPLE}lightpurple ${LIGHTCYAN}lightcyan "
    colorEcho "${LIGHTGRAY}lightgray ${DARKGRAY}darkgray ${WHITE}white"
}

# hostname & hostip
[[ -z "${HOSTNAME}" ]] && HOSTNAME=$(uname -n 2>/dev/null)
[[ -z "${HOSTNAME}" ]] && HOSTNAME=$(hostname 2>/dev/null)
[[ -n "${HOSTNAME}" ]] && export HOSTNAME

[[ -z "${HOSTIP}" ]] && HOSTIP=$(hostname -I 2>/dev/null | cut -d' ' -f1)
[[ -n "${HOSTIP}" ]] && export HOSTIP

[[ -z "${HOSTIP_ALL}" ]] && HOSTIP_ALL=$(hostname -I 2>/dev/null)
[[ -n "${HOSTIP_ALL}" ]] && HOSTIP_ALL="${HOSTIP_ALL% }" && HOSTIP_ALL="${HOSTIP_ALL// /,}" && export HOSTIP_ALL

# no proxy lists
NO_PROXY_LISTS="localhost,127.0.0.1,.local,.localdomain,.internal,.corp"
[[ -n "${HOSTNAME}" ]] && NO_PROXY_LISTS="${NO_PROXY_LISTS},${HOSTNAME}"
[[ -n "${HOSTIP_ALL}" ]] && NO_PROXY_LISTS="${NO_PROXY_LISTS},${HOSTIP_ALL}"
NO_PROXY_LISTS="${NO_PROXY_LISTS},fastgit.org,gitclone.com,cnpmjs.org"
NO_PROXY_LISTS="${NO_PROXY_LISTS},ip.sb,ip-api.com,ident.me,ifconfig.co,icanhazip.com,ipinfo.io"


## Get OS type, architecture etc.
## https://en.wikipedia.org/wiki/Uname
# get os type: darwin, windows, linux, freebsd, openbsd, solaris
function get_os_type() {
    local osname ostype

    osname=$(uname)
    case "$osname" in
        Darwin)
            ostype="darwin"
            ;;
        MSYS_NT-* | MINGW* | CYGWIN_NT-*)
            ostype="windows"
            ;;
        SunOS)
            ostype='solaris'
            ;;
        *)
            ostype=$(echo "$osname" | sed 's/.*/\L&/')
            ;;
    esac

    OS_INFO_TYPE=$ostype
}

# get os release: linux, macos, windows, freebsd, openbsd, dragonfly, solaris, android
function get_os_release() {
    local osname os_release

    osname=$(uname)
    case "$osname" in
        Darwin)
            os_release='macos'
            ;;
        MSYS_NT-* | MINGW* | CYGWIN_NT-*)
            os_release='windows'
            ;;
        Linux)
            if [[ -r "/etc/os-release" ]]; then
                os_release="$(. /etc/os-release && echo "$ID")"
                [[ -z "$os_release" ]] && \
                    os_release="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release \
                                | cut -d'=' -f2 | sed 's/\"//g')"
            else
                os_release='linux'
            fi

            # Check if we're running on Android
            case $(uname -o 2>/dev/null) in
                Android)
                    os_release='android'
                    ;;
            esac
            ;;
        SunOS)
            os_release='solaris'
            ;;
        *)
            os_release=$(echo "$osname" | sed 's/.*/\L&/')
            ;;
    esac

    OS_INFO_RELEASE=$os_release
}

# get os release type: Linux, macOS, Windows, BSD, Solaris, Android
function get_os_release_type() {
    local osname os_wsl

    osname=$(uname)
    case "$osname" in
        Darwin)
            osname='macOS'
            ;;
        MSYS_NT-* | MINGW* | CYGWIN_NT-*)
            osname='Windows'
            ;;
        FreeBSD | OpenBSD | DragonFly)
            osname='BSD'
            ;;
        Linux)
            osname='Linux'
            # Check if we're running on Android
            case $(uname -o 2>/dev/null) in
                Android)
                    osname='Android'
                    ;;
            esac
            ;;
        SunOS)
            osname='Solaris'
            ;;
    esac

    os_wsl=$(uname -r)
    if [[ "$os_wsl" =~ "Microsoft" || "$os_wsl" =~ "microsoft" ]]; then
        osname='Windows'
    fi

    OS_INFO_RELEASE_TYPE=$osname
}

# Determine which desktop environment is installed from the shell
# OSDesktopENV=$(ps -e | grep -E -i "gnome|kde|mate|cinnamon|lxde|xfce|jwm")
function get_os_desktop() {
    local osdesktop

    if [[ -x "$(command -v wmctrl)" ]]; then
        osdesktop=$(wmctrl -m)
    else
        if [[ -z "$XDG_CURRENT_DESKTOP" ]]; then
            osdesktop=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(gnome\|kde\|mate\|cinnamon\|lxde\|xfce\|jwm\).*/\1/')
        else
            osdesktop=$XDG_CURRENT_DESKTOP
        fi
    fi

    # OS_INFO_DESKTOP="${osdesktop,,}" # to lowercase
    OS_INFO_DESKTOP="${osdesktop}"
}

function get_arch() {
	local architecture spruce_type

    architecture=$(uname -m)
	case "$architecture" in
		amd64 | x86_64)
			spruce_type='amd64'
			;;
		i?86 | x86)
			spruce_type='386'
			;;
		*armv7* | armv6l)
            spruce_type="arm"
            ;;
		*armv8* | aarch64)
            spruce_type="arm64"
            ;;
		*mips64le*)
            spruce_type="mips64le"
            ;;
		*mips64*)
            spruce_type="mips64"
            ;;
		*mipsle*)
            spruce_type="mipsle"
            ;;
		*mips*)
            spruce_type="mips"
            ;;
		*s390x*)
            spruce_type="s390x"
            ;;
		*ppc64le*)
            spruce_type="ppc64le"
            ;;
		*ppc64*)
            spruce_type="ppc64"
            ;;
        riscv64)
            spruce_type="riscv64"
            ;;
		*)
            spruce_type="$architecture"
            ;;
	esac

    OS_INFO_ARCH=$spruce_type
}

function get_sysArch() {
	local architecture VDIS

    architecture=$(uname -m)
    case "$architecture" in
        amd64 | x86_64)
            VDIS="64"
            ;;
		i?86 | x86)
            VDIS="32"
            ;;
		*armv7* | armv6l)
            VDIS="arm"
            ;;
		*armv8* | aarch64)
            VDIS="arm64"
            ;;
		*mips64le*)
            VDIS="mips64le"
            ;;
		*mips64*)
            VDIS="mips64"
            ;;
		*mipsle*)
            VDIS="mipsle"
            ;;
		*mips*)
            VDIS="mips"
            ;;
		*s390x*)
            VDIS="s390x"
            ;;
		*ppc64le*)
            VDIS="ppc64le"
            ;;
		*ppc64*)
            VDIS="ppc64"
            ;;
        riscv64)
            VDIS="riscv64"
            ;;
		*)
            VDIS="$architecture"
            ;;
    esac

    OS_INFO_VDIS=$VDIS
}

function get_arch_float() {
    # https://raspberrypi.stackexchange.com/questions/4677/how-can-i-tell-if-i-am-using-the-hard-float-or-the-soft-float-version-of-debian
    local dpkg_arch

    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    unset OS_INFO_FLOAT
    case "${OS_INFO_ARCH}" in
        arm | mips | mipsle)
            if [[ -x "$(command -v dpkg)" ]]; then
                dpkg_arch=$(dpkg --print-architecture 2>/dev/null)
                [[ "${dpkg_arch}" == "armhf" ]] && OS_INFO_FLOAT="hardfloat" || OS_INFO_FLOAT="softfloat"
            else
                [[ -d "/lib/arm-linux-gnueabihf" ]] && OS_INFO_FLOAT="hardfloat" || OS_INFO_FLOAT="softfloat"
            fi
            ;;
    esac
}

function get_os_icon() {
    local OS_ICON OS_RELEASE_ID os_wsl

    case $(uname) in
        Darwin)
            OS_ICON=$'\uF179'
            ;;
        MSYS_NT-* | MINGW* | CYGWIN_NT-*)
            OS_ICON=$'\uF17A'
            ;;
        FreeBSD | OpenBSD | DragonFly)
            OS_ICON=$'\uF30C'
            ;;
        Linux)
            OS_RELEASE_ID="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release 2>/dev/null | cut -d '=' -f2)"
            case "$OS_RELEASE_ID" in
                *arch*)
                    OS_ICON=$'\uF303'
                    ;;
                *debian*)
                    OS_ICON=$'\uF306'
                    ;;
                *ubuntu*)
                    OS_ICON=$'\uF31B'
                    ;;
                *elementary*)
                    OS_ICON=$'\uF309'
                    ;;
                *fedora*)
                    OS_ICON=$'\uF30A'
                    ;;
                *coreos*)
                    OS_ICON=$'\uF305'
                    ;;
                *gentoo*)
                    OS_ICON=$'\uF30D'
                    ;;
                *mageia*)
                    OS_ICON=$'\uF310'
                    ;;
                *centos*)
                    OS_ICON=$'\uF304'
                    ;;
                *opensuse* | *tumbleweed*)
                    OS_ICON=$'\uF314'
                    ;;
                *sabayon*)
                    OS_ICON=$'\uF317'
                    ;;
                *slackware*)
                    OS_ICON=$'\uF319'
                    ;;
                *linuxmint*)
                    OS_ICON=$'\uF30E'
                    ;;
                *alpine*)
                    OS_ICON=$'\uF300'
                    ;;
                *aosc*)
                    OS_ICON=$'\uF301'
                    ;;
                *nixos*)
                    OS_ICON=$'\uF313'
                    ;;
                *devuan*)
                    OS_ICON=$'\uF307'
                    ;;
                *manjaro*)
                    OS_ICON=$'\uF312'
                    ;;
                    *)
                    OS_ICON=$'\uF17C'
                    ;;
            esac

            # Check if we're running on Android
            case $(uname -o 2>/dev/null) in
                Android)
                    OS_ICON=$'\uF17B'
                    ;;
            esac
            ;;
        SunOS)
            OS_ICON=$'\uF185'
            ;;
        *)
            OS_ICON=''
            ;;
    esac

    os_wsl=$(uname -r)
    if [[ "$os_wsl" =~ "Microsoft" ]]; then
        OS_ICON=$'\uF17A'
    fi

    OS_INFO_ICON=$OS_ICON
}


## Get OS package manager
function check_os_package_manager() {
    # ref to: https://github.com/icy/pacapt/blob/ng/pacapt
    local _pacman

    _pacman="$1"; shift

    [[ "$(uname)" == "SunOS" ]] && OS_PACKAGE_MANAGER="$_pacman" && return
    grep -qis "$@" /etc/issue && OS_PACKAGE_MANAGER="$_pacman" && return
    grep -qis "$@" /etc/os-release && OS_PACKAGE_MANAGER="$_pacman" && return
}

function get_os_package_manager() {
    unset OS_PACKAGE_MANAGER

    # ref to: https://github.com/icy/pacapt/blob/ng/pacapt
    check_os_package_manager sun_tools "SunOS" && return
    check_os_package_manager pacman "Arch Linux" && return
    check_os_package_manager dpkg "Debian GNU/Linux" && return
    check_os_package_manager dpkg "Ubuntu" && return
    check_os_package_manager cave "Exherbo Linux" && return
    # check_os_package_manager dnf "CentOS Linux 8" && return
    # check_os_package_manager dnf "CentOS-8" && return
    # check_os_package_manager yum "CentOS" && return
    # check_os_package_manager yum "Red Hat" && return
    check_os_package_manager zypper "SUSE" && return
    check_os_package_manager pkg_tools "OpenBSD" && return
    check_os_package_manager pkg_tools "Bitrig" && return
    check_os_package_manager apk "Alpine Linux" && return
    check_os_package_manager opkg "OpenWrt" && return

    [[ -z "$OS_PACKAGE_MANAGER" ]] || return

    # Prevent a loop when this script is installed on non-standard system
    if [[ -x "/usr/bin/pacman" ]]; then
        # grep -q "pacapt" '/usr/bin/pacman' >/dev/null 2>&1
        # [[ $? -ge 1 ]] && OS_PACKAGE_MANAGER="pacman" && return
        if ! grep -q "pacapt" '/usr/bin/pacman' >/dev/null 2>&1; then
            OS_PACKAGE_MANAGER="pacman" && return
        fi
    fi

    [[ -x "/usr/bin/apt-get" ]] && OS_PACKAGE_MANAGER="dpkg" && return
    [[ -x "/data/data/com.termux/files/usr/bin/apt-get" ]] && OS_PACKAGE_MANAGER="dpkg" && return
    [[ -x "/usr/bin/cave" ]] && OS_PACKAGE_MANAGER="cave" && return
    [[ -x "/usr/bin/dnf" ]] && OS_PACKAGE_MANAGER="dnf" && return
    [[ -x "/usr/bin/yum" ]] && OS_PACKAGE_MANAGER="yum" && return
    [[ -x "/opt/local/bin/port" ]] && OS_PACKAGE_MANAGER="macports" && return
    [[ -x "/usr/bin/emerge" ]] && OS_PACKAGE_MANAGER="portage" && return
    [[ -x "/usr/bin/zypper" ]] && OS_PACKAGE_MANAGER="zypper" && return
    [[ -x "/usr/sbin/pkg" ]] && OS_PACKAGE_MANAGER="pkgng" && return
    # make sure pkg_add is after pkgng, FreeBSD base comes with it until converted
    [[ -x "/usr/sbin/pkg_add" ]] && OS_PACKAGE_MANAGER="pkg_tools" && return
    [[ -x "/usr/sbin/pkgadd" ]] && OS_PACKAGE_MANAGER="sun_tools" && return
    [[ -x "/sbin/apk" ]] && OS_PACKAGE_MANAGER="apk" && return
    [[ -x "/bin/opkg" ]] && OS_PACKAGE_MANAGER="opkg" && return
    [[ -x "/usr/bin/tazpkg" ]] && OS_PACKAGE_MANAGER="tazpkg" && return
    [[ -x "/usr/bin/swupd" ]] && OS_PACKAGE_MANAGER="swupd" && return

    command -v brew >/dev/null && OS_PACKAGE_MANAGER="homebrew" && return
}

function check_release_package_manager() {
    local checkType=$1
    local value=$2
    local release='' systemPackage='' osname

    osname=$(uname)
    if [[ -f /etc/redhat-release ]]; then
        if grep -Eqi "fedora" /etc/redhat-release 2>/dev/null; then
            release="fedora"
            systemPackage="dnf"
        # elif [[ $(cat /etc/redhat-release |grep "CentOS Linux release 8") ]]; then
        #     release="centos8"
        #     systemPackage="dnf"
        else
            release="centos"
            systemPackage="yum"
        fi
    elif [[ -f /etc/alpine-release ]]; then
        release="alpine"
        systemPackage="apk"
    elif [[ -f /etc/arch-release ]]; then
        release="arch"
        systemPackage="pacman"
    elif [[ $osname =~ "MSYS_NT" || $osname =~ "MINGW" ]]; then
        release="MSYS"
        systemPackage="pacman"
    elif [[ $osname =~ "CYGWIN_NT" ]]; then
        release="CYGWIN"
        systemPackage="apt-cyg"
    elif grep -Eqi "debian" /etc/issue 2>/dev/null; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue 2>/dev/null; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "raspbian" /etc/issue 2>/dev/null; then
        release="raspbian"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue 2>/dev/null; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian" /proc/version 2>/dev/null; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version 2>/dev/null; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version 2>/dev/null; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ ${checkType} == "sysRelease" ]]; then
        if [[ "$value" == "$release" ]]; then
            return 0
        else
            return 1
        fi
    elif [[ ${checkType} == "packageManager" ]]; then
        if [[ "$value" == "$systemPackage" ]]; then
            return 0
        else
            return 1
        fi
    fi
}


## version compare functions
function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; } # >
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" = "$1"; } # >=
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; } # <
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" = "$1"; } # <=

function version_compare() {
    local VERSION1=$1
    local VERSION2=$2
    if version_gt "${VERSION1}" "${VERSION2}"; then
        echo "$VERSION1 is greater than $VERSION2"
    fi

    if version_le "${VERSION1}" "${VERSION2}"; then
        echo "$VERSION1 is less than or equal to $VERSION2"
    fi

    if version_lt "${VERSION1}" "${VERSION2}"; then
        echo "$VERSION1 is less than $VERSION2"
    fi

    if version_ge "${VERSION1}" "${VERSION2}"; then
        echo "$VERSION1 is greater than or equal to $VERSION2"
    fi
}

# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash/49351294#49351294
function ver_compare() {
    # Compare two version strings [$1: version string 1 (v1), $2: version string 2 (v2), $3: version regular expressions (regex)]
    # Return values:
    #   0: v1 == v2
    #   1: v1 > v2
    #   2: v1 < v2
    # Based on: https://stackoverflow.com/a/4025065 by Dennis Williamson

    # Trivial v1 == v2 test based on string comparison
    [[ "$1" == "$2" ]] && return 0

    # Local variables
    local regex=${3:-"^(.*)-r([0-9]*)$"} va1=() vr1=0 va2=() vr2=0 len i IFS="."

    # Split version strings into arrays, extract trailing revisions
    if [[ "$1" =~ ${regex} ]]; then
        va1=("${BASH_REMATCH[1]}")
        [[ -n "${BASH_REMATCH[2]}" ]] && vr1=${BASH_REMATCH[2]}
    else
        va1=("$1")
    fi

    if [[ "$2" =~ ${regex} ]]; then
        va2=("${BASH_REMATCH[1]}")
        [[ -n "${BASH_REMATCH[2]}" ]] && vr2=${BASH_REMATCH[2]}
    else
        va2=("$2")
    fi

    # Bring va1 and va2 to same length by filling empty fields with zeros
    (( ${#va1[@]} > ${#va2[@]} )) && len=${#va1[@]} || len=${#va2[@]}
    for ((i=0; i < len; ++i)); do
        [[ -z "${va1[i]}" ]] && va1[i]="0"
        [[ -z "${va2[i]}" ]] && va2[i]="0"
    done

    # Append revisions, increment length
    va1+=("$vr1")
    va2+=("$vr2")
    len=$((len + 1))

    # *** DEBUG ***
    #echo "TEST: '${va1[@]} (?) ${va2[@]}'"

    # Compare version elements, check if v1 > v2 or v1 < v2
    for ((i=0; i < len; ++i)); do
        if (( 10#${va1[i]} > 10#${va2[i]} )); then
            return 1
        elif (( 10#${va1[i]} < 10#${va2[i]} )); then
            return 2
        fi
    done

    # All elements are equal, thus v1 == v2
    return 0
}

function ver_compare_eq() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 0 ]] && return 0 || return 1
}

function ver_compare_gt() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 1 ]] && return 0 || return 1
}

function ver_compare_ge() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 0 || $exitStatus -eq 1 ]] && return 0 || return 1
}

function ver_compare_lt() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 2 ]] && return 0 || return 1
}

function ver_compare_le() {
    local exitStatus

    ver_compare "$@"
    exitStatus=$?
    [[ $exitStatus -eq 0 || $exitStatus -eq 2 ]] && return 0 || return 1
}


## Get network interface, ipv4/ipv6 address
# Get local machine network interfaces
function get_network_interface_list() {
    unset NETWORK_INTERFACE_LIST
    if [[ -x "$(command -v ip)" ]]; then
        NETWORK_INTERFACE_LIST=$(ip link 2>/dev/null | awk -F: '$0 !~ "lo|vir|^[^0-9]" {print $2;getline}')
        # Without wireless
        # NETWORK_INTERFACE_LIST=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]" {print $2;getline}')
    else
        NETWORK_INTERFACE_LIST=$(ls /sys/class/net 2>/dev/null | tr "\t" "\n" | grep -Ev "lo|vir|^[0-9]")
    fi
}

function get_network_interface_default() {
    unset NETWORK_INTERFACE_DEFAULT
    if [[ -x "$(command -v ip)" ]]; then
        NETWORK_INTERFACE_DEFAULT=$(ip route 2>/dev/null | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//" -e "s/[ \t]//g" | head -n1)
        if [[ -z "${NETWORK_INTERFACE_DEFAULT}" ]]; then
            NETWORK_INTERFACE_DEFAULT=$(ip route | grep -Ev "^0\.|^127\.|^172\." | sed -e "s/^.*dev.//" -e "s/.proto.*//" -e "s/[ \t]//g" | head -n1)
        fi
    elif [[ -x "$(command -v netstat)" ]]; then
        NETWORK_INTERFACE_DEFAULT=$(netstat -rn 2>/dev/null | awk '/^0.0.0.0/ {thif=substr($0,74,10); print thif;} /^default.*UG/ {thif=substr($0,65,10); print thif;}')
    fi
}

# get local machine ip list
function get_network_local_ip_list() {
    unset NETWORK_LOCAL_IP_LIST

    get_network_interface_list
    [[ -z "$NETWORK_INTERFACE_LIST" ]] && return 0

    local net_interface_list net_interface net_ip list

    # net_interface_list=($(echo "$NETWORK_INTERFACE_LIST" | tr '\n' ' '))
    net_interface_list=()
    while read -r list; do
        net_interface_list+=("${list}")
    done <<<"${NETWORK_INTERFACE_LIST}"

    for net_interface in "${net_interface_list[@]}"; do
        if [[ -x "$(command -v ip)" ]]; then
            net_ip=$(ip addr show "${net_interface}" 2>/dev/null | grep "inet\|inet6" | awk '{print $2}' | cut -d'/' -f1)
        elif [[ -x "$(command -v ifconfig)" ]]; then
            net_ip=$(ifconfig "${net_interface}" 2>/dev/null | grep "inet\|inet6" |awk -F' ' '{print $2}' | awk '{print $1}')
        fi

        if [[ -n "${net_ip}" ]]; then
            net_ip=$(echo "${net_ip}" | grep -v "127.0.0.1" | grep -v "^::1" | grep -v "^fe80")
        fi

        [[ -z "${net_ip}" ]] && continue
        # net_ip="${net_interface}: ${net_ip}"

        [[ -z "$NETWORK_LOCAL_IP_LIST" ]] \
            && NETWORK_LOCAL_IP_LIST="${net_ip}" \
            || NETWORK_LOCAL_IP_LIST="${NETWORK_LOCAL_IP_LIST}\n${net_ip}"
    done
}

function get_network_local_ipv4_list() {
    unset NETWORK_LOCAL_IPV4_LIST

    get_network_local_ip_list
    [[ -z "$NETWORK_LOCAL_IP_LIST" ]] && return 0

    NETWORK_LOCAL_IPV4_LIST=$(echo "$NETWORK_LOCAL_IP_LIST" | grep -B1 "\.")

    NETWORK_LOCAL_IPV4_LIST=${NETWORK_LOCAL_IPV4_LIST//-/}
}

function get_network_local_ipv6_list() {
    unset NETWORK_LOCAL_IPV6_LIST

    get_network_local_ip_list
    [[ -z "$NETWORK_LOCAL_IP_LIST" ]] && return 0

    NETWORK_LOCAL_IPV6_LIST=$(echo "$NETWORK_LOCAL_IP_LIST" | grep -v "\.")
}


# get local machine default interface ip
function get_network_local_ip_default() {
    unset NETWORK_LOCAL_IP_DEFAULT

    get_network_interface_default
    [[ -z "$NETWORK_INTERFACE_DEFAULT" ]] && return 0

    local net_ip

    if [[ -x "$(command -v ip)" ]]; then
        net_ip=$(ip addr show "${NETWORK_INTERFACE_DEFAULT}" 2>/dev/null | grep "inet\|inet6" | awk '{print $2}' | cut -d'/' -f1)
    elif [[ -x "$(command -v ifconfig)" ]]; then
        net_ip=$(ifconfig "${NETWORK_INTERFACE_DEFAULT}" 2>/dev/null | grep "inet\|inet6" |awk -F' ' '{print $2}' | awk '{print $1}')
    fi

    NETWORK_LOCAL_IP_DEFAULT="${net_ip}"
}

function get_network_local_ipv4_default() {
    # https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x
    # LOCAL_NET_IF=$(netstat -rn | awk '/^0.0.0.0/ {thif=substr($0,74,10); print thif;} /^default.*UG/ {thif=substr($0,65,10); print thif;}')
    # LOCAL_NET_IP=$(ifconfig ${LOCAL_NET_IF} | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

    unset NETWORK_LOCAL_IPV4_DEFAULT

    get_network_local_ip_default
    [[ -z "$NETWORK_LOCAL_IP_DEFAULT" ]] && return 0

    NETWORK_LOCAL_IPV4_DEFAULT=$(echo "$NETWORK_LOCAL_IP_DEFAULT" | grep "\." | head -n1)
}

function get_network_local_ipv6_default() {
    unset NETWORK_LOCAL_IPV6_DEFAULT

    get_network_local_ip_default
    [[ -z "$NETWORK_LOCAL_IP_DEFAULT" ]] && return 0

    NETWORK_LOCAL_IPV6_DEFAULT=$(echo "$NETWORK_LOCAL_IP_DEFAULT" | grep ":" | head -n1)
}

# get wan ip
function get_network_wan_ipv4() {
    # https://guoyu841020.oschina.io/2017/02/23/linux%E8%8E%B7%E5%8F%96%E5%85%AC%E7%BD%91IP%E7%9A%84%E6%96%B9%E6%B3%95/
    # nginx:
    # https://www.jianshu.com/p/14320f300223
    # location /ip {
    #         default_type text/plain;
    #         return 200 "$remote_addr";
    # }

    # location /ipinfo {
    #         default_type application/json;
    #         return 200  '{"IP":"$remote_addr","PORT":"$remote_port","X-Forwarded-For":"$proxy_add_x_forwarded_for"}';
    # }
    # php:
    # <?php echo $_SERVER["REMOTE_ADDR"]; ?>
    # pacman -S --noconfirm html2text
    # curl -fsSL http://yourdomainname/getip.php | html2text
    # nodejs:
    # https://github.com/alsotang/externalip
    # https://github.com/sindresorhus/public-ip
    unset NETWORK_WAN_NET_IP

    local remote_host_list target_host

    remote_host_list=(
        "https://api-ipv4.ip.sb/ip"
        "http://ip-api.com/line/?fields=query"
        "https://v4.ident.me/"
        "http://icanhazip.com/"
        "http://ipinfo.io/ip"
        "https://ifconfig.co/"
    )

    for target_host in "${remote_host_list[@]}"; do
        NETWORK_WAN_NET_IP=$(curl -fsL -4 --connect-timeout 5 --max-time 10 "${target_host}" \
                        | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}' \
                        | head -n1)
        [[ -n "$NETWORK_WAN_NET_IP" ]] && break
    done
    # NETWORK_WAN_NET_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
}

function get_network_wan_ipv6() {
    unset NETWORK_WAN_NET_IPV6

    local remote_host_list target_host

    remote_host_list=(
        "https://api-ipv6.ip.sb/ip"
        "https://v6.ident.me/"
        "http://icanhazip.com/"
        "https://ifconfig.co/"
    )

    for target_host in "${remote_host_list[@]}"; do
        NETWORK_WAN_NET_IPV6=$(curl -fsL -6 --connect-timeout 5 --max-time 10 "${target_host}" \
                        | grep -Eo '^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$' \
                        | head -n1)
        [[ -n "$NETWORK_WAN_NET_IPV6" ]] && break
    done
}

function get_network_wan_geo() {
    unset NETWORK_WAN_NET_IP_GEO

    if [[ -x "$(command -v geoiplookup)" ]]; then
        get_network_wan_ipv4
        if [[ -n "$NETWORK_WAN_NET_IP" ]]; then
            NETWORK_WAN_NET_IP_GEO=$(geoiplookup "${NETWORK_WAN_NET_IP}" | head -n1 | cut -d':' -f2-)
        fi
    fi

    if [[ -z "$NETWORK_WAN_NET_IP_GEO" ]]; then
        NETWORK_WAN_NET_IP_GEO=$(curl -fsL -4 --connect-timeout 5 --max-time 10 \
            "https://api.ip.sb/geoip" | jq -r '.country//empty')
    fi

    if [[ -z "$NETWORK_WAN_NET_IP_GEO" ]]; then
        # Country lookup: China
        NETWORK_WAN_NET_IP_GEO=$(curl -fsL -4 --connect-timeout 5 --max-time 10 \
            "http://ip-api.com/line/?fields=country")
        if [[ -z "$NETWORK_WAN_NET_IP_GEO" ]]; then
            # Country lookup: CN
            NETWORK_WAN_NET_IP_GEO=$(curl -fsL -4 --connect-timeout 5 --max-time 10 \
                "http://ip-api.com/line/?fields=countryCode")
        fi
    fi
}

# display local machine ip info
function myip_lan_wan() {
    get_network_local_ipv4_default
    get_network_local_ipv6_default
    get_network_wan_ipv4
    get_network_wan_ipv6

    [[ -n "$NETWORK_LOCAL_IPV4_DEFAULT" ]] && echo -e "Local IP: ${NETWORK_LOCAL_IPV4_DEFAULT}"
    [[ -n "$NETWORK_LOCAL_IPV6_DEFAULT" ]] && echo -e "Local IPV6: ${NETWORK_LOCAL_IPV6_DEFAULT}"
    [[ -n "$NETWORK_WAN_NET_IP" ]] && echo -e "Public IP: ${NETWORK_WAN_NET_IP}"
    [[ -n "$NETWORK_WAN_NET_IPV6" ]] && echo -e "Public IPV6: ${NETWORK_WAN_NET_IPV6}"
}

function myip_lan() {
    get_network_local_ipv4_default
    get_network_local_ipv6_default

    [[ -n "$NETWORK_LOCAL_IPV4_DEFAULT" ]] && echo -e "Local IP: ${NETWORK_LOCAL_IPV4_DEFAULT}"
    [[ -n "$NETWORK_LOCAL_IPV6_DEFAULT" ]] && echo -e "Local IPV6: ${NETWORK_LOCAL_IPV6_DEFAULT}"
}

function myip_wan() {
    get_network_wan_ipv4
    get_network_wan_ipv6

    [[ -n "$NETWORK_WAN_NET_IP" ]] && echo -e "Public IP: ${NETWORK_WAN_NET_IP}"
    [[ -n "$NETWORK_WAN_NET_IPV6" ]] && echo -e "Public IPV6: ${NETWORK_WAN_NET_IPV6}"
}

function myip_wan_geo() {
    get_network_wan_ipv4
    get_network_wan_geo

    if [[ -n "$NETWORK_WAN_NET_IP_GEO" ]]; then
        echo -e "Public IP: ${NETWORK_WAN_NET_IP}\n${NETWORK_WAN_NET_IP_GEO}"
    else
        echo "Can't get GEO by WAN IP!"
    fi
}

# Get Opened Port on Android Device(No Root)
# https://null-byte.wonderhowto.com/forum/see-your-opened-port-your-android-device-no-root-0200475/
function nmap_scan_opened_port() {
    local ip_address=${1:-""}

    [[ -z "${ip_address}" ]] && get_network_local_ipv4_default && ip_address=${NETWORK_LOCAL_IPV4_DEFAULT}
    [[ -n "${ip_address}" ]] && nmap -Pn "${ip_address}"
}


## Proxy functions
function set_proxy() {
    # PROTOCOL://USERNAME:PASSWORD@HOST:PORT
    # http://127.0.0.1:8080
    # socks5h://127.0.0.1:8080
    # PASSWORD has special characters:
    # [@ %40] [: %3A] [! %21] [# %23] [$ %24]
    # F@o:o!B#ar$ -> F%40o%3Ao%21B%23ar%24
    local PROXY_ADDRESS=${1:-""}

    if [[ -z "${PROXY_ADDRESS}" && -n "${GLOBAL_PROXY_IP}" ]]; then
        if [[ -n "${GLOBAL_PROXY_SOCKS_PORT}" ]]; then
            PROXY_ADDRESS="${GLOBAL_PROXY_SOCKS_PROTOCOL}://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_SOCKS_PORT}"
        elif [[ -n "${GLOBAL_PROXY_MIXED_PORT}" ]]; then
            PROXY_ADDRESS="http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}"
        fi
    fi

    [[ -z "${PROXY_ADDRESS}" ]] && PROXY_ADDRESS="http://127.0.0.1:8080"

    export {http,https,ftp,all}_proxy=${PROXY_ADDRESS}
    export no_proxy="${NO_PROXY_LISTS}"
    # export no_proxy="localhost,127.0.0.0/8,*.local"

    # for curl
    export {HTTP,HTTPS,FTP,ALL}_PROXY=${PROXY_ADDRESS}
    export NO_PROXY="${NO_PROXY_LISTS}"
}

function get_proxy() {
    local proxy_output1 proxy_output2

    [[ -n "${http_proxy}" ]] && colorEcho "${BLUE}http_proxy=${FUCHSIA}${http_proxy}"
    [[ -n "${https_proxy}" ]] && colorEcho "${BLUE}https_proxy=${FUCHSIA}${https_proxy}"
    [[ -n "${ftp_proxy}" ]] && colorEcho "${BLUE}ftp_proxy=${FUCHSIA}${ftp_proxy}"
    [[ -n "${all_proxy}" ]] && colorEcho "${BLUE}all_proxy=${FUCHSIA}${all_proxy}"
    [[ -n "${no_proxy}" ]] && colorEcho "${BLUE}no_proxy=${FUCHSIA}${no_proxy}"

    [[ -n "${HTTP_PROXY}" ]] && colorEcho "${BLUE}HTTP_PROXY=${FUCHSIA}${HTTP_PROXY}"
    [[ -n "${HTTPS_PROXY}" ]] && colorEcho "${BLUE}HTTPS_PROXY=${FUCHSIA}${HTTPS_PROXY}"
    [[ -n "${FTP_PROXY}" ]] && colorEcho "${BLUE}FTP_PROXY=${FUCHSIA}${FTP_PROXY}"
    [[ -n "${ALL_PROXY}" ]] && colorEcho "${BLUE}ALL_PROXY=${FUCHSIA}${ALL_PROXY}"
    [[ -n "${NO_PROXY}" ]] && colorEcho "${BLUE}NO_PROXY=${FUCHSIA}${NO_PROXY}"

    if [[ -x "$(command -v git)" ]]; then
        proxy_output1=$(git config --global --list 2>/dev/null | grep -E "http\.proxy|https\.proxy|http\.http|https\.http")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}git proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -x "$(command -v node)" && -x "$(command -v npm)" ]]; then
        proxy_output1=$(npm config get proxy | grep -v "null")
        proxy_output2=$(npm config get https-proxy | grep -v "null")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}npm proxies:\n${FUCHSIA}${proxy_output1}"
        [[ -n "${proxy_output2}" ]] && colorEcho "${FUCHSIA}${proxy_output2}"
    fi

    if [[ -x "$(command -v yarn)" ]]; then
        proxy_output1=$(yarn config get proxy | grep -v "null")
        proxy_output2=$(yarn config get https-proxy | grep -v "null")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}yarn proxies:\n${FUCHSIA}${proxy_output1}"
        [[ -n "${proxy_output2}" ]] && colorEcho "${FUCHSIA}${proxy_output2}"
    fi

    if [[ -s "/etc/apt/apt.conf.d/80proxy" ]]; then
        proxy_output1=$(< "/etc/apt/apt.conf.d/80proxy")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}apt proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "/etc/yum.conf" ]]; then
        proxy_output1=$(grep "proxy=" "/etc/yum.conf")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}yum proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.wgetrc" ]]; then
        proxy_output1=$(< "$HOME/.wgetrc")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}wget proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.curlrc" ]]; then
        proxy_output1=$(< "$HOME/.curlrc")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}curl proxies(.curlrc):\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.curl_socks5" ]]; then
        proxy_output1=$(< "$HOME/.curl_socks5")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}curl proxies(.curl_socks5):\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.gradle/gradle.properties" ]]; then
        proxy_output1=$(grep "systemProp.http" "$HOME/.gradle/gradle.properties")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}gradle proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.gemrc" ]]; then
        proxy_output1=$(grep "http_proxy: " "$HOME/.gemrc")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}gem proxies:\n${FUCHSIA}${proxy_output1}"
    fi
}

function clear_proxy() {
    unset {http,https,ftp,all}_proxy
    unset {HTTP,HTTPS,FTP,ALL}_PROXY
}

function clear_all_proxy() {
    clear_proxy
    set_git_proxy
    set_curl_proxy
    # [[ -s "$HOME/.curl_socks5" ]] && set_curl_proxy "" "$HOME/.curl_socks5"
    set_special_socks5_proxy
    set_wget_proxy
}

function proxy_cmd() {
    [[ -z $* ]] && colorEcho "${GREEN}Set proxy for specific command." && return 0

    if [[ -n "${all_proxy}" ]]; then
        colorEcho "${GREEN}Using proxy: ${FUCHSIA}${all_proxy}"
        "$@"
    else
        if [[ -n "${GLOBAL_PROXY_IP}" ]]; then
            if [[ -n "${GLOBAL_PROXY_SOCKS_PORT}" ]]; then
                set_proxy "${GLOBAL_PROXY_SOCKS_PROTOCOL}://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_SOCKS_PORT}"
            elif [[ -n "${GLOBAL_PROXY_MIXED_PORT}" ]]; then
                set_proxy "http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}"
            fi
        fi

        [[ -n "${all_proxy}" ]] && colorEcho "${GREEN}Using proxy: ${FUCHSIA}${all_proxy}"
        "$@"
        [[ -n "${all_proxy}" ]] && clear_proxy && colorEcho "${GREEN}Proxy clear."
    fi
}

function noproxy_cmd() {
    [[ -z $* ]] && colorEcho "${GREEN}No proxy for specific command." && return 0

    if [[ -n "${all_proxy}" ]]; then
        http_proxy="" https_proxy="" ftp_proxy="" all_proxy="" \
            HTTP_PROXY="" HTTPS_PROXY="" FTP_PROXY="" ALL_PROXY="" \
            "$@"
    else
        "$@"
    fi
}

function proxy_socks5h_to_socks5() {
    # fix: golang - proxyconnect tcp: dial tcp: lookup socks5h: no such host
    # https://github.com/golang/go/issues/13454
    # https://github.com/golang/go/issues/24135
    [[ -z $* ]] && colorEcho "${GREEN}Use ${FUCHSIA}socks5${GREEN} proxy instead of ${BLUE}socks5h${GREEN} for specific command." && return 0

    if echo "${all_proxy}" | grep -q 'socks5h'; then
        colorEcho "${GREEN}Using proxy: ${FUCHSIA}${all_proxy/socks5h/socks5}"
        http_proxy=${http_proxy/socks5h/socks5} \
            https_proxy=${https_proxy/socks5h/socks5} \
            ftp_proxy=${ftp_proxy/socks5h/socks5} \
            all_proxy=${all_proxy/socks5h/socks5} \
            HTTP_PROXY=${HTTP_PROXY/socks5h/socks5} \
            HTTPS_PROXY=${HTTPS_PROXY/socks5h/socks5} \
            FTP_PROXY=${FTP_PROXY/socks5h/socks5} \
            ALL_PROXY=${ALL_PROXY/socks5h/socks5} \
            "$@"
    else
        [[ -n "${all_proxy}" ]] && colorEcho "${GREEN}Using proxy: ${FUCHSIA}${all_proxy}"
        "$@"
    fi
}

# SET_PROXY_FOR=('brew' 'git' 'apm')
# for cmd in $SET_PROXY_FOR; do
#     hash ${cmd} > /dev/null 2>&1 && alias ${cmd}="proxy_cmd ${cmd}"
# done

# Use proxy or mirror when some sites were blocked or low speed
function set_proxy_mirrors_env() {
    if check_webservice_up www.google.com; then
        export THE_WORLD_BLOCKED=false
    else
        export THE_WORLD_BLOCKED=true
    fi
}

## curl to check webservice is up
# https://stackoverflow.com/questions/12747929/linux-script-with-curl-to-check-webservice-is-up
function check_webservice_up() {
    # How to use:
    # if check_webservice_up www.google.com; then echo "ok"; else echo "something wrong"; fi
    local webservice_url=${1:-"www.google.com"}
    local http exitStatus=0

    http=$(curl -fsL --noproxy "*" --connect-timeout 3 --max-time 5 \
        -w "%{http_code}\\n" "${webservice_url}" -o /dev/null)
    case "${http}" in
        [2]*)
            ;;
        [3]*)
            # echo "${webservice_url} is REDIRECT with ${http}"
            ;;
        [4]*)
            exitStatus=4
            # echo "${webservice_url} is DENIED with ${http}"
            ;;
        [5]*)
            exitStatus=5
            # echo "${webservice_url} is ERROR with ${http}"
            ;;
        *)
            exitStatus=6
            # echo "${webservice_url} is NO RESPONSE with ${http}"
            ;;
    esac

    if [[ "${exitStatus}" -eq "0" ]]; then
        # echo "${webservice_url} is UP with ${http}"
        return 0
    else
        return 1
    fi
}

# Verify if a URL exists
function check_url_exists() {
    local url=$1
    local http exitStatus=0

    http=$(curl -fsL -I --connect-timeout 3 --max-time 5 \
        -w "%{http_code}\n" "${url}" -o /dev/null)
    case "${http}" in
        [2]*)
            ;;
        [3]*)
            # echo "${url} is REDIRECT with ${http}"
            ;;
        [4]*)
            exitStatus=4
            # echo "${url} is DENIED with ${http}"
            ;;
        [5]*)
            exitStatus=5
            # echo "${url} is ERROR with ${http}"
            ;;
        *)
            exitStatus=6
            # echo "${url} is NO RESPONSE with ${http}"
            ;;
    esac

    if [[ "${exitStatus}" -eq "0" ]]; then
        # echo "${webservice_url} is UP with ${http}"
        return 0
    else
        return 1
    fi
}

## curl to check webservice timeout
# https://stackoverflow.com/questions/18215389/how-do-i-measure-request-and-response-times-at-once-using-curl
#     time_namelookup:  %{time_namelookup}\n
#        time_connect:  %{time_connect}\n
#     time_appconnect:  %{time_appconnect}\n
#    time_pretransfer:  %{time_pretransfer}\n
#       time_redirect:  %{time_redirect}\n
#  time_starttransfer:  %{time_starttransfer}\n
#                     ----------\n
#          time_total:  %{time_total}\n
function check_webservice_timeout() {
    local webservice_url=${1:-"www.google.com"}
    local http_timeout

    http_timeout=$(curl -fsL --connect-timeout 5 --max-time 20 \
        -w "%{time_connect} + %{time_starttransfer} = %{time_total}\\n" \
        "${webservice_url}" -o /dev/null)

    echo "time_connect + time_starttransfer: ${http_timeout}"
}

# test the availability of a socks5 proxy
function check_socks5_proxy_up() {
    # How to use:
    # if check_socks5_proxy_up 127.0.0.1:1080 www.google.com; then echo "ok"; else echo "something wrong"; fi
    local PROXY_ADDRESS=${1:-""}
    local webservice_url=${2:-"www.google.com"}
    local exitStatus=0

    if [[ -z "${PROXY_ADDRESS}" && -n "${GLOBAL_PROXY_IP}" && -n "${GLOBAL_PROXY_SOCKS_PORT}" ]]; then
        PROXY_ADDRESS="${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_SOCKS_PORT}"
    fi

    [[ -z "${PROXY_ADDRESS}" ]] && PROXY_ADDRESS="127.0.0.1:1080"

    curl -fsL -I --connect-timeout 3 --max-time 5 \
        --socks5-hostname "${PROXY_ADDRESS}" \
        "${webservice_url}" >/dev/null 2>&1 || exitStatus=$?

    if [[ "$exitStatus" -eq "0" ]]; then
        return 0
    else
        return 1
    fi
}

# test the availability of a http proxy
function check_http_proxy_up() {
    # How to use:
    # if check_http_proxy_up 127.0.0.1:8080 www.google.com; then echo "ok"; else echo "something wrong"; fi
    local PROXY_ADDRESS=${1:-""}
    local webservice_url=${2:-"www.google.com"}
    local exitStatus=0

    if [[ -z "${PROXY_ADDRESS}" && -n "${GLOBAL_PROXY_IP}" && -n "${GLOBAL_PROXY_MIXED_PORT}" ]]; then
        PROXY_ADDRESS="${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}"
    fi

    [[ -z "${PROXY_ADDRESS}" ]] && PROXY_ADDRESS="127.0.0.1:8080"

    curl -fsL -I --connect-timeout 3 --max-time 5 \
        --proxy "${PROXY_ADDRESS}" \
        "${webservice_url}" >/dev/null 2>&1 || exitStatus=$?

    if [[ "$exitStatus" -eq "0" ]]; then
        return 0
    else
        return 1
    fi
}

# Set global git proxy
function set_git_proxy() {
    local PROXY_ADDRESS=$1

    if [[ -z "$PROXY_ADDRESS" ]]; then
        git config --global --unset http.proxy
        git config --global --unset https.proxy
    else
        git config --global http.proxy "${PROXY_ADDRESS}"
        git config --global https.proxy "${PROXY_ADDRESS}"
    fi
}

# Set socks5 proxy for certain git repos
function set_git_special_proxy() {
    # Usage: set_git_special_proxy github.com,gitlab.com 127.0.0.1:55880
    local GIT_REPO_LIST=$1
    local PROXY_ADDRESS=${2:-""}
    local Url_List=() TargetUrl list

    # Url_List=($(echo "${GIT_REPO_LIST}" | sed 's/,/ /g'))
    while read -r list; do
        Url_List+=("${list}")
    done <<<"${GIT_REPO_LIST}"

    for TargetUrl in "${Url_List[@]}"; do
        [[ -z "${TargetUrl}" ]] && continue

        if [[ -z "$PROXY_ADDRESS" ]]; then
            git config --global --unset "http.https://${TargetUrl}.proxy"
            git config --global --unset "https.https://${TargetUrl}.proxy"
        else
            git config --global "http.https://${TargetUrl}.proxy" "${PROXY_ADDRESS}"
            git config --global "https.https://${TargetUrl}.proxy" "${PROXY_ADDRESS}"
        fi
    done
}

# Set apt proxy
function set_apt_proxy() {
    local PROXY_ADDRESS=$1
    local APT_PROXY_CONFIG=${2:-"/etc/apt/apt.conf.d/80proxy"}

    [[ ! -x "$(command -v apt)" ]] && return 0

    if [[ -n "$PROXY_ADDRESS" ]]; then
        echo -e "Acquire::http::proxy \"http://${PROXY_ADDRESS}/\";" \
            | sudo tee "$APT_PROXY_CONFIG" >/dev/null
        echo -e "Acquire::https::proxy \"http://${PROXY_ADDRESS}/\";" \
            | sudo tee -a "$APT_PROXY_CONFIG" >/dev/null
        echo -e "Acquire::ftp::proxy \"http://${PROXY_ADDRESS}/\";" \
            | sudo tee -a "$APT_PROXY_CONFIG" >/dev/null
    else
        [[ -s "$APT_PROXY_CONFIG" ]] && \
            sudo rm -f "$APT_PROXY_CONFIG"
    fi
}

# Disable apt proxy
function disable_apt_proxy() {
    local APT_PROXY_CONFIG=${1:-"/etc/apt/apt.conf.d/95disable-proxy"}

    [[ ! -x "$(command -v apt)" ]] && return 0

    echo -e 'Acquire::http::Proxy "false";' | sudo tee "$APT_PROXY_CONFIG" >/dev/null
    echo -e 'Acquire::https::Proxy "false";' | sudo tee -a "$APT_PROXY_CONFIG" >/dev/null
    echo -e 'Acquire::ftp::Proxy "false";' | sudo tee -a "$APT_PROXY_CONFIG" >/dev/null
}

# Set yum proxy
function set_yum_proxy() {
    local PROXY_ADDRESS=${1:-"_none_"}
    local YUM_PROXY_CONFIG=${2:-"/etc/yum.conf"}

    [[ ! -x "$(command -v yum)" ]] && return 0

    # sudo sed -i "s/[#]*[ ]*proxy.*/proxy=_none_/" "$YUM_PROXY_CONFIG"
    sudo sed -i "/[#]*[ ]*proxy.*/d" "$YUM_PROXY_CONFIG"
    echo "proxy=socks5://${PROXY_ADDRESS}" | sudo tee -a "$YUM_PROXY_CONFIG" >/dev/null
}

# Set wget proxy
function set_wget_proxy() {
    local PROXY_ADDRESS=$1
    local WGET_CONFIG=${2:-"$HOME/.wgetrc"}

    [[ ! -x "$(command -v wget)" ]] && return 0

    if [[ -s "$WGET_CONFIG" ]]; then
        sed -i "/^use_proxy.*/d" "$WGET_CONFIG"
        sed -i "/^http_proxy.*/d" "$WGET_CONFIG"
        sed -i "/^https_proxy.*/d" "$WGET_CONFIG"
        sed -i "/^ftp_proxy.*/d" "$WGET_CONFIG"
        sed -i "/^no_proxy.*/d" "$WGET_CONFIG"
    fi

    if [[ -n "$PROXY_ADDRESS" ]]; then
        echo "use_proxy=on" >> "$WGET_CONFIG"
        echo "http_proxy=http://${PROXY_ADDRESS}/" >> "$WGET_CONFIG"
        echo "https_proxy=http://${PROXY_ADDRESS}/" >> "$WGET_CONFIG"
        echo "ftp_proxy=http://${PROXY_ADDRESS}/" >> "$WGET_CONFIG"
        echo "no_proxy=${NO_PROXY_LISTS}" >> "$WGET_CONFIG"
    fi
}

# Set curl proxy
function set_curl_proxy() {
    local PROXY_ADDRESS=$1
    local CURL_CONFIG=${2:-"$HOME/.curlrc"}

    [[ ! -x "$(command -v curl)" ]] && return 0

    if [[ -s "$CURL_CONFIG" ]]; then
        sed -i "/^socks5-hostname.*/d" "${CURL_CONFIG}"
        sed -i "/^noproxy.*/d" "${CURL_CONFIG}"
    fi

    if [[ -n "$PROXY_ADDRESS" ]]; then
        echo "socks5-hostname=${PROXY_ADDRESS}" >> "${CURL_CONFIG}"
        echo "noproxy=${NO_PROXY_LISTS}" >> "${CURL_CONFIG}"
    fi
}

# Set npm http proxy
function set_npm_proxy() {
    local PROXY_ADDRESS=$1

    [[ ! -x "$(command -v npm)" ]] && return 0

    if [[ -n "$PROXY_ADDRESS" ]]; then
        npm config set proxy "http://${PROXY_ADDRESS}"
        npm config set https-proxy "http://${PROXY_ADDRESS}"
    else
        npm config delete proxy
        npm config delete https-proxy
    fi
}

# Set yarn http proxy
function set_yarn_proxy() {
    local PROXY_ADDRESS=$1

    [[ ! -x "$(command -v yarn)" ]] && return 0

    if [[ -n "$PROXY_ADDRESS" ]]; then
        yarn config set proxy "http://${PROXY_ADDRESS}"
        yarn config set https-proxy "http://${PROXY_ADDRESS}"
    else
        yarn config delete proxy
        yarn config delete https-proxy
    fi
}

# Set gradle http proxy
function set_gradle_proxy() {
    local PROXY_HOST=$1
    local PROXY_PORT=$2
    local GRADLE_CONFIG=${3:-"$HOME/.gradle/gradle.properties"}

    [[ ! -x "$(command -v gradle)" ]] && return 0

    if [[ -s "$GRADLE_CONFIG" ]]; then
        sed -i "/^systemProp.http.proxyHost.*/d" "${GRADLE_CONFIG}"
        sed -i "/^systemProp.http.proxyPort.*/d" "${GRADLE_CONFIG}"
        sed -i "/^systemProp.https.proxyHost.*/d" "${GRADLE_CONFIG}"
        sed -i "/^systemProp.https.proxyPort.*/d" "${GRADLE_CONFIG}"
    fi

    if [[ -n "$PROXY_HOST" && -n "$PROXY_PORT" ]]; then
        echo "systemProp.http.proxyHost=${PROXY_HOST}" >> "${GRADLE_CONFIG}"
        echo "systemProp.http.proxyPort=${PROXY_PORT}" >> "${GRADLE_CONFIG}"
        echo "systemProp.https.proxyHost=${PROXY_HOST}" >> "${GRADLE_CONFIG}"
        echo "systemProp.https.proxyPort=${PROXY_PORT}" >> "${GRADLE_CONFIG}"
    fi
}

# Set ruby gem proxy
function set_gem_proxy() {
    local PROXY_ADDRESS=$1
    local GEM_CONFIG=${2:-"$HOME/.gemrc"}

    [[ ! -x "$(command -v gem)" ]] && return 0

    if [[ -s "$GEM_CONFIG" ]]; then
        sed -i "/^http_proxy.*/d" "$GEM_CONFIG"
    fi

    if [[ -n "$PROXY_ADDRESS" ]]; then
        echo "http_proxy: http://${PROXY_ADDRESS}" >> "$GEM_CONFIG"
    fi
}

# Set global proxy
function set_global_proxy() {
    local SOCKS_ADDRESS=${1:-""}
    local HTTP_ADDRESS=${2:-""}
    local SOCKS_PROTOCOL=${3:-"socks5"}

    # clear git special proxy
    set_git_special_proxy "github.com,gitlab.com"

    # clear special socks5 proxy(curl...)
    set_special_socks5_proxy

    if [[ -n "$SOCKS_ADDRESS" ]]; then
        set_proxy "${SOCKS_PROTOCOL}://${SOCKS_ADDRESS}"

        set_curl_proxy "${SOCKS_ADDRESS}"

        ## set git global proxy
        # set_git_proxy "${SOCKS_PROTOCOL}://${SOCKS_ADDRESS}"

        ## set special socks5 proxy(curl...)
        # set_special_socks5_proxy "${SOCKS_ADDRESS}"

        colorEcho "${GREEN}  :: Now using ${FUCHSIA}${SOCKS_PROTOCOL}://${SOCKS_ADDRESS} ${GREEN}for global socks5 proxy!"

        # wget must use http proxy
        if [[ -n "$HTTP_ADDRESS" ]]; then
            set_wget_proxy "${HTTP_ADDRESS}"
            colorEcho "${GREEN}  :: Now using ${FUCHSIA}${HTTP_ADDRESS} ${GREEN}for http proxy(wget etc.)!"
        else
            set_wget_proxy
        fi

        return 0
    else
        clear_all_proxy

        return 1
    fi
}

# Check & set global proxy
function check_set_global_proxy() {
    local SOCKS_PORT=${1:-"1080"}
    local MIXED_PORT=${2:-"8080"}
    local PROXY_IP
    local PROXY_SOCKS=""
    local SOCKS_PROTOCOL="socks5"
    local PROXY_HTTP=""
    local IP_LIST="127.0.0.1"
    local IP_WSL
    local PROXY_UP="NO"

    if [[ "$(uname -r)" =~ "microsoft" ]]; then
        # wsl2
        IP_LIST=$(ipconfig.exe | grep "IPv4" \
                    | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}' \
                    | grep -Ev "^0\.|^127\.|^172\.")
        IP_WSL=$(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}')
        IP_LIST=$(echo -e "${IP_LIST}\n${IP_WSL}" | uniq)
        # IP_LIST=$(echo -e "${IP_WSL}\n${IP_LIST}" | uniq)
    fi

    # unset GLOBAL_PROXY_IP
    # unset GLOBAL_PROXY_SOCKS_PROTOCOL
    # unset GLOBAL_PROXY_SOCKS_PORT
    # unset GLOBAL_PROXY_MIXED_PORT

    # {
    #     echo ''
    #     echo '# Global proxy settings'
    #     echo 'export GLOBAL_PROXY_IP=192.168.0.1'
    #     echo 'export GLOBAL_PROXY_SOCKS_PROTOCOL=socks5'
    #     echo 'export GLOBAL_PROXY_SOCKS_PORT=7890'
    #     echo 'export GLOBAL_PROXY_MIXED_PORT=7890'
    # } >> "$HOME/.zshenv"

    if [[ -n "${GLOBAL_PROXY_IP}" ]]; then
        IP_LIST=$(echo -e "${GLOBAL_PROXY_IP}\n${IP_LIST}" | uniq)
        SOCKS_PROTOCOL="${GLOBAL_PROXY_SOCKS_PROTOCOL:-${SOCKS_PROTOCOL}}"
        SOCKS_PORT="${GLOBAL_PROXY_SOCKS_PORT:-${SOCKS_PORT}}"
        MIXED_PORT="${GLOBAL_PROXY_MIXED_PORT:-${MIXED_PORT}}"
    fi

    # Set global proxy
    while read -r PROXY_IP; do
        if check_socks5_proxy_up "${PROXY_IP}:${MIXED_PORT}"; then
            SOCKS_PORT=${MIXED_PORT}
            PROXY_UP="YES"
        else
            if check_socks5_proxy_up "${PROXY_IP}:${SOCKS_PORT}"; then
                if ! check_http_proxy_up "${PROXY_IP}:${MIXED_PORT}"; then
                    MIXED_PORT=""
                fi
                PROXY_UP="YES"
            fi
        fi

        [[ "$PROXY_UP" == "YES" ]] && break
    done <<<"${IP_LIST}"

    if [[ "$PROXY_UP" == "YES" ]]; then
        [[ -n "${SOCKS_PORT}" ]] && PROXY_SOCKS="${PROXY_IP}:${SOCKS_PORT}"
        [[ -n "${MIXED_PORT}" ]] && PROXY_HTTP="${PROXY_IP}:${MIXED_PORT}"

        if set_global_proxy "${PROXY_SOCKS}" "${PROXY_HTTP}" "${SOCKS_PROTOCOL}"; then
            export GLOBAL_PROXY_IP=${PROXY_IP}
            export GLOBAL_PROXY_SOCKS_PROTOCOL=${SOCKS_PROTOCOL}
            export GLOBAL_PROXY_SOCKS_PORT=${SOCKS_PORT}
            export GLOBAL_PROXY_MIXED_PORT=${MIXED_PORT}

            [[ "$(uname -r)" =~ "microsoft" ]] && export GLOBAL_WSL2_HOST_IP=${PROXY_IP}

            return 0
        fi
    else
        set_global_proxy # clear global proxy

        return 1
    fi
}

# Set special app socks5 proxy (curl...)
function set_special_socks5_proxy() {
    local SOCKS5_PROXY=${1:-""}

    CURL_SPECIAL_CONFIG=${CURL_SPECIAL_CONFIG:-"$HOME/.curl_socks5"}

    if [[ -n "$SOCKS5_PROXY" ]]; then
        set_curl_proxy "${SOCKS5_PROXY}" "${CURL_SPECIAL_CONFIG}"
    else
        # cat /dev/null > "${CURL_SPECIAL_CONFIG}"
        [[ -f "${CURL_SPECIAL_CONFIG}" ]] && rm "${CURL_SPECIAL_CONFIG}"
    fi
}


## Flush dns cache
function flush_dns_cache() {
    [[ -s "/lib/systemd/system/systemd-resolved.service" ]] && \
        sudo ln -sf /lib/systemd/system/systemd-resolved.service \
            /etc/systemd/system/dbus-org.freedesktop.resolve1.service || true

    [[ -x "$(command -v systemd-resolve)" ]] && \
        sudo systemd-resolve --flush-caches >/dev/null 2>&1

    [[ -s "/etc/init.d/dns-clean" ]] && /etc/init.d/dns-clean start

    [[ $(systemctl is-enabled systemd-resolved 2>/dev/null) ]] && \
        sudo systemctl restart systemd-resolved.service >/dev/null 2>&1

    [[ $(systemctl is-enabled dnsmasq 2>/dev/null) ]] && \
        sudo systemctl restart dnsmasq.service >/dev/null 2>&1
}


## Download hosts from url
function download_hosts() {
    local hostsURL=${1:-""}
    local hostsFile=${2:-"/etc/hosts"}
    local exitStatus=0

    [[ -z "$hostsURL" ]] && return 1

    colorEcho "${BLUE}Downloading hosts from ${hostsURL}..."
    curl -fSL --connect-timeout 5 --max-time 20 \
        -o "/tmp/hosts" "$hostsURL" || exitStatus=$?
    if [[ "$exitStatus" -eq "0" ]]; then
        if [[ "${hostsFile}" == "/etc/hosts" ]]; then
            [[ ! -s "${hostsFile}.orig" ]] && \
                sudo cp -f "${hostsFile}" "${hostsFile}.orig"

            sudo cp -f "${hostsFile}" "${hostsFile}.bak" && \
                sudo mv -f "/tmp/hosts" "${hostsFile}" && \
                flush_dns_cache
        else
            cp -f "${hostsFile}" "${hostsFile}.bak" && \
                mv -f "/tmp/hosts" "${hostsFile}"
        fi

        return 0
    else
        return 1
    fi
}


function reset_hosts() {
    local hostsFile=${1:-"/etc/hosts"}

    [[ -s "${hostsFile}.orig" ]] && \
        sudo cp -f "${hostsFile}.orig" "${hostsFile}"
}


function Git_Clone_Update() {
    local REPONAME=${1:-""}
    local REPODIR=${2:-""}
    local REPOURL=${3:-"github.com"}
    local GIT_COMMAND="git"
    local REPOREMOTE=""
    local CurrentDir

    if [[ -z "${REPONAME}" ]]; then
        colorEcho "${RED}Error! Repository name can't empty!"
        return 1
    fi

    if [[ "${REPONAME}" =~ ^(https?://|git@) ]]; then
        REPOREMOTE="${REPONAME}"
        REPONAME=$(echo "${REPOREMOTE}" | sed 's|^http://||;s|^https://||;s|.git$||' | sed 's|.*[/:]\([^ ]*/[^ ]*\).*|\1|')
        REPOURL=$(echo "${REPOREMOTE}" | sed 's|.git$||' | sed "s|${REPONAME}||" | sed 's|[/:]$||')
    fi

    [[ -z "${REPODIR}" ]] && REPODIR=$(echo "${REPONAME}" | awk -F"/" '{print $NF}')

    REPOURL="${REPOURL%/}"
    if [[ "${REPOURL}" == "github.com" ]]; then
        # Accelerate the speed of accessing GitHub
        # https://www.gitclone.com/
        # https://fastgit.org/
        if [[ -n "${GITHUB_MIRROR_USE_CGIT}" && -x "$(command -v cgit)" ]]; then
            GIT_COMMAND="cgit"
        else
            [[ -n "${GITHUB_MIRROR_USE_FASTGIT}" ]] && REPOURL="hub.fastgit.org"
            [[ -n "${GITHUB_MIRROR_USE_GITCLONE}" ]] && REPOURL="gitclone.com/github.com"
            [[ -n "${GITHUB_MIRROR_USE_CNPMJS}" ]] && REPOURL="github.com.cnpmjs.org"
        fi

        REPOREMOTE="https://${REPOURL}/${REPONAME}"
    else
        [[ "${REPOURL}" =~ ^(git@) ]] \
            && REPOREMOTE="${REPOURL}:${REPONAME}.git" \
            || REPOREMOTE="${REPOURL}/${REPONAME}.git"
    fi

    # check_url_exists "${REPOREMOTE}" \
    #     || colorEcho "${RED}  ${FUCHSIA}${REPOREMOTE}${RED} does not exist!"

    if [[ -d "${REPODIR}/.git" ]]; then
        colorEcho "${BLUE}  Updating ${FUCHSIA}${REPOREMOTE}${BLUE}..."

        CurrentDir=$(pwd)

        cd "${REPODIR}" || return
        ${GIT_COMMAND} pull
        cd "${CurrentDir}" || return
    else
        colorEcho "${BLUE}  Cloning ${FUCHSIA}${REPOREMOTE}${BLUE}..."
        [[ -z "${GIT_CLONE_OPTS[*]}" ]] && Get_Git_Clone_Options
        ${GIT_COMMAND} clone "${GIT_CLONE_OPTS[@]}" "${REPOREMOTE}" "${REPODIR}" || {
                colorEcho "${RED}  git clone of ${FUCHSIA}${REPONAME} ${RED}failed!"
                return 1
            }
    fi
}

function Git_Clone_Update_Branch() {
    local REPONAME=${1:-""}
    local REPODIR=${2:-""}
    local REPOURL=${3:-"github.com"}
    local BRANCH=${4:-""}
    local GIT_COMMAND="git"
    local REPOREMOTE=""
    local DEFAULTBRANCH=""
    local CurrentDir

    if [[ -z "${REPONAME}" ]]; then
        colorEcho "${RED}Error! Repository name can't empty!"
        return 1
    fi

    if [[ "${REPONAME}" =~ ^(https?://|git@) ]]; then
        REPOREMOTE="${REPONAME}"
        REPONAME=$(echo "${REPOREMOTE}" | sed 's|^http://||;s|^https://||;s|.git$||' | sed 's|.*[/:]\([^ ]*/[^ ]*\).*|\1|')
        REPOURL=$(echo "${REPOREMOTE}" | sed 's|.git$||' | sed "s|${REPONAME}||" | sed 's|[/:]$||')
    fi

    [[ -z "${REPODIR}" ]] && REPODIR=$(echo "${REPONAME}" | awk -F"/" '{print $NF}')

    REPOURL="${REPOURL%/}"
    if [[ "${REPOURL}" == "github.com" ]]; then
        # Accelerate the speed of accessing GitHub
        # https://www.gitclone.com/
        # https://fastgit.org/
        if [[ -n "${GITHUB_MIRROR_USE_CGIT}" && -x "$(command -v cgit)" ]]; then
            GIT_COMMAND="cgit"
        else
            [[ -n "${GITHUB_MIRROR_USE_FASTGIT}" ]] && REPOURL="hub.fastgit.org"
            [[ -n "${GITHUB_MIRROR_USE_GITCLONE}" ]] && REPOURL="gitclone.com/github.com"
            [[ -n "${GITHUB_MIRROR_USE_CNPMJS}" ]] && REPOURL="github.com.cnpmjs.org"
        fi

        REPOREMOTE="https://${REPOURL}/${REPONAME}"
    else
        [[ "${REPOURL}" =~ ^(git@) ]] \
            && REPOREMOTE="${REPOURL}:${REPONAME}.git" \
            || REPOREMOTE="${REPOURL}/${REPONAME}.git"
    fi

    # check_url_exists "${REPOREMOTE}" \
    #     || colorEcho "${RED}  ${FUCHSIA}${REPOREMOTE}${RED} does not exist!"

    if [[ -d "${REPODIR}/.git" ]]; then
        colorEcho "${BLUE}  Updating ${FUCHSIA}${REPOREMOTE}${BLUE}..."

        CurrentDir=$(pwd)

        cd "${REPODIR}" || return
        [[ -z "${BRANCH}" ]] && BRANCH=$(${GIT_COMMAND} symbolic-ref --short HEAD 2>/dev/null)
        [[ -z "${BRANCH}" ]] && BRANCH="master"

        if ! ${GIT_COMMAND} pull --rebase --stat origin "${BRANCH}"; then
            # pull error: fallback to default branch
            DEFAULTBRANCH=$(${GIT_COMMAND} ls-remote --symref "${REPOREMOTE}" HEAD \
                        | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
            if [[ -n "${DEFAULTBRANCH}" && "${DEFAULTBRANCH}" != "${BRANCH}" ]]; then
                git branch -m "${BRANCH}" "${DEFAULTBRANCH}"

                [[ -s "${REPODIR}/.git/config" ]] && \
                    sed -i "s|${BRANCH}|${DEFAULTBRANCH}|g" "${REPODIR}/.git/config"

                # git fetch origin
                # git branch --unset-upstream
                # git branch -u "origin/${DEFAULTBRANCH}" "${DEFAULTBRANCH}"
                # git symbolic-ref "refs/remotes/origin/HEAD" "refs/remotes/origin/${DEFAULTBRANCH}"

                ${GIT_COMMAND} pull --rebase --stat origin "${DEFAULTBRANCH}"
            fi
        fi

        ## master branch
        # git fetch --depth 1 && git reset --hard origin/master

        ## checkout other branch
        # git remote set-branches --add orgin "'${remote_branch_name}'"
        #     git fetch --depth 1 origin ${remote_branch_name} && \
        #     git checkout ${remote_branch_name}

        cd "${CurrentDir}" || return
    else
        colorEcho "${BLUE}  Cloning ${FUCHSIA}${REPOREMOTE}${BLUE}..."
        [[ -z "${BRANCH}" ]] && \
            BRANCH=$(${GIT_COMMAND} ls-remote --symref "${REPOREMOTE}" HEAD \
                    | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
        [[ -z "${BRANCH}" ]] && BRANCH="master"

        [[ -z "${GIT_CLONE_OPTS[*]}" ]] && Get_Git_Clone_Options
        ${GIT_COMMAND} clone "${GIT_CLONE_OPTS[@]}" \
            --depth=1 --branch "${BRANCH}" "${REPOREMOTE}" "${REPODIR}" || {
                colorEcho "${RED}  git clone of ${FUCHSIA}${REPONAME} ${RED}failed!"
                return 1
            }
    fi
}


# https://stackoverflow.com/questions/3497123/run-git-pull-over-all-subdirectories
function Git_Update_Repo_in_SubDir() {
    local SubDir=${1:-""}
    local FindDir TargetDir CurrentDir
    local REPOREMOTE REPONAME REPODIR REPOURL BRANCH
    local DIRLIST=()

    CurrentDir=$(pwd)

    [[ -z "${SubDir}" ]] && SubDir=${CurrentDir}
    [[ ! -d "${SubDir}" ]] && colorEcho "${FUCHSIA}${SubDir}${RED} does not exist or not a valid directory!" && return 0

    # find . -type d -name ".git" -execdir git pull --rebase --stat origin master \;

    while read -r FindDir; do
        FindDir="$(realpath "${FindDir}")"
        DIRLIST+=("${FindDir%/*}")
    done < <(find "${SubDir}" -type d -name ".git")

    for TargetDir in "${DIRLIST[@]}"; do
        REPODIR="${TargetDir}"
        cd "${REPODIR}" || return

        REPOREMOTE=$(git config --get remote.origin.url | head -n1)
        REPONAME=$(echo "${REPOREMOTE}" | sed 's|^http://||;s|^https://||;s|.git$||' | sed 's|.*[/:]\([^ ]*/[^ ]*\).*|\1|')
        REPOURL=$(echo "${REPOREMOTE}" | sed 's|.git$||' | sed "s|${REPONAME}||" | sed 's|[/:]$||')
        [[ "${REPOREMOTE}" == *"://github.com/"* ]] && REPOURL="github.com"

        BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
        [[ -z "${BRANCH}" ]] && BRANCH="master"

        [[ -z "${REPOREMOTE}" || -z "${REPONAME}" || -z "${REPOURL}" ]] && continue

        Git_Clone_Update_Branch "${REPONAME}" "${REPODIR}" "${REPOURL}" "${BRANCH}"
    done

    cd "${CurrentDir}" || return
}

function Git_Update_Repo_in_SubDir_Parallel() {
    local SubDir=${1:-""}
    local BRANCH=${2:-master}
    local FindDepth=${3:-""}

    [[ -z "${SubDir}" ]] && return 0
    [[ ! -d "${SubDir}" ]] && colorEcho "${FUCHSIA}${SubDir}${RED} does not exist or not a valid directory!" && return 0

    if [[ -z "${FindDepth}" ]]; then
        find "${SubDir}" -type d -name ".git" \
            | sed 's/\/.git//' \
            | xargs -P10 -I{} git --git-dir="{}/.git" --work-tree="{}" \
                pull --rebase --stat origin "${BRANCH}"
    else
        find "${SubDir}" -maxdepth "${FindDepth}" -type d -name ".git" \
            | sed 's/\/.git//' \
            | xargs -P10 -I{} git --git-dir="{}/.git" --work-tree="{}" \
                pull --rebase --stat origin "${BRANCH}"
    fi
}

function Git_Replace_Remote_Origin_URL() {
    # Usage: Git_Replace_Remote_Origin_URL $HOME "https://hub.fastgit.org" "https://github.com"
    local SubDir=${1:-""}
    local UrlOLD=$2
    local UrlNEW=$3
    local FindDir TargetDir CurrentDir
    local REPOREMOTE REPOREMOTE_NEW
    local DIRLIST=()

    [[ -z "${SubDir}" ]] && return 0
    [[ ! -d "${SubDir}" ]] && colorEcho "${FUCHSIA}${SubDir}${RED} does not exist or not a valid directory!" && return 0

    [[ -z "${UrlOLD}" || ! "${UrlOLD}" =~ ^(https?://|git@) ]] && colorEcho "${FUCHSIA}${UrlOLD}${RED} is not a valid url!" && return 0
    [[ -z "${UrlNEW}" || ! "${UrlNEW}" =~ ^(https?://|git@) ]] && colorEcho "${FUCHSIA}${UrlNEW}${RED} is not a valid url!" && return 0

    CurrentDir=$(pwd)

    while read -r FindDir; do
        FindDir="$(realpath "${FindDir}")"
        DIRLIST+=("${FindDir%/*}")
    done < <(find "${SubDir}" -type d -name ".git")

    [[ "${UrlOLD}" =~ ^(https?):// ]] && UrlOLD="${UrlOLD%/}/"
    [[ "${UrlNEW}" =~ ^(https?):// ]] && UrlNEW="${UrlNEW%/}/"

    for TargetDir in "${DIRLIST[@]}"; do
        # if grep -q "${UrlOLD}" "${TargetDir}/.git/config" 2>/dev/null; then
        #     sed -i "s|${UrlOLD}|${UrlNEW}|g" "${TargetDir}/.git/config"
        # fi
        cd "${TargetDir}" || return

        REPOREMOTE=$(git config --get remote.origin.url | head -n1)
        if [[ "${REPOREMOTE}" == *"${UrlOLD}"* ]]; then
            REPOREMOTE_NEW=$(echo "${REPOREMOTE}" | sed "s|${UrlOLD}|${UrlNEW}|")
            if [[ -n "${REPOREMOTE_NEW}" ]]; then
                colorEcho "${YELLOW}${TargetDir}${BLUE}: ${FUCHSIA}${REPOREMOTE}${BLUE} → ${GREEN}${REPOREMOTE_NEW}"
                git remote set-url origin "${REPOREMOTE_NEW}"
            fi
        fi
    done

    cd "${CurrentDir}" || return
}

function git_get_remote_default_branch() {
    local REPOREMOTE=${1:-""}

    if [[ -z "${REPOREMOTE}" && -d ".git" ]]; then
        REPO_DEFAULT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
    else
        [[ -z "${REPOREMOTE}" ]] && return 0
        REPO_DEFAULT_BRANCH=$(git ls-remote --symref "${REPOREMOTE}" HEAD \
                                | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
    fi
}


function Install_cron_job() {
    local cronjob=${1:-""}
    local cronline

    [[ -z "${cronjob}" ]] && return 0

    (crontab -l 2>/dev/null || true; echo "${cronjob}") | crontab - || {
        colorEcho "${RED}  cron job install failed!"
        return 1
    }

    cronline=$(crontab -l | wc -l)

    colorEcho "${FUCHSIA}${cronjob} ${GREEN}installed!"
    colorEcho "${YELLOW}  How to delete this job:"
    colorEcho "${FUCHSIA}  (crontab -l 2>/dev/null | sed \"${cronline}d\") | crontab -"
}


function Install_systemd_Service() {
    # Usage:
    # Install_systemd_Service "subconverter" "/srv/subconverter/subconverter"
    local service_name=$1
    local service_exec=$2
    local service_user=${3:-"nobody"}
    local service_workdir=${4:-""}
    local filename
    local service_file

    [[ $# -lt 2 ]] && return 1
    [[ -z "$service_name" ]] && return 1
    [[ -z "$service_exec" ]] && return 1

    if [[ -z "$service_workdir" ]]; then
        filename=$(echo "${service_exec}" | cut -d" " -f1)
        service_workdir=$(dirname "$(readlink -f "$filename")")
    fi

    [[ -z "$filename" || ! -f "$filename" ]] && colorEcho "${FUCHSIA}${filename}${RED} doesn't exist!" && return 1
    [[ -z "$service_workdir" || ! -d "$service_workdir" ]]&& colorEcho "${FUCHSIA}${service_workdir}${RED} doesn't exist!" && return 1

    service_file="/etc/systemd/system/${service_name}.service"
    if [[ ! -s "$service_file" ]]; then
        sudo tee "$service_file" >/dev/null <<-EOF
[Unit]
Description=${service_name}
After=network.target network-online.target nss-lookup.target

[Service]
Type=simple
StandardError=journal
User=${service_user}
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=${service_exec}
WorkingDirectory=${service_workdir}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    fi

    sudo systemctl enable "$service_name" && sudo systemctl restart "$service_name"
    if [[ $(systemctl is-enabled "$service_name" 2>/dev/null) ]]; then
        colorEcho "${GREEN}  systemd service ${FUCHSIA}${service_name}${GREEN} installed!"
    else
        colorEcho "${RED}  systemd service ${FUCHSIA}${service_name}${RED} install failed!"
    fi
}


# asdf: Extendable version manager with support for Ruby, Node.js, Elixir, Erlang & more
# https://asdf-vm.com/
# https://github.com/asdf-vm/asdf
function asdf_App_Install() {
    # Usage:
    # asdf_App_Install neovim stable
    # asdf_App_Install java openjdk-11
    # asdf_App_Install nodejs lts
    local appName=$1
    local appVersion=${2:-"latest"}
    local allPlugin allVersion currentVersion latestVersion
    local appInstallStatus=0

    [[ ! "$(command -v asdf)" ]] && colorEcho "${FUCHSIA}asdf${RED} is not installed!" && return 1

    [[ -z "${appName}" ]] && \
        colorEcho "${FUCHSIA}asdf plugin${RED} name can't empty!" && \
        return 1

    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}asdf plugin ${ORANGE}${appName}${BLUE}..."
    # List All in Short-name Repository
    allPlugin=$(asdf plugin list all 2>/dev/null | awk '{print $1}')
    if [[ -z "${allPlugin}" ]]; then
        colorEcho "${RED}Get all ${FUCHSIA}asdf plugins${RED} list failed!"
        return 1
    fi

    if ! echo "${allPlugin}" | grep -q "^${appName}$"; then
        colorEchoN "${ORANGE}${appName}${RED} is not a valid ${FUCHSIA}asdf plugin${RED}!"
        colorEcho " More: ${FUCHSIA}https://asdf-vm.com/#/plugins-all"
        return 1
    fi

    # List Installed
    if ! asdf plugin list 2>/dev/null | grep -q "^${appName}$"; then
        asdf plugin add "${appName}"
    fi

    if ! asdf plugin list 2>/dev/null | grep -q "^${appName}$"; then
        colorEcho "${RED}Install ${FUCHSIA}asdf plugin ${ORANGE}${appName}${RED} failed!"
        return 1
    fi

    ## List All Available Versions
    # asdf list all "${appName}"
    # asdf list all "${appName}" "${appVersion}"
    # asdf list all java | cut -d'-' -f1 | sort -V | uniq

    # If `appVersion` is not a valid version, get latest version from all versions
    allVersion=$(asdf list all "${appName}" "${appVersion}" 2>/dev/null | grep -Ev 'alpha|beta|rc')
    [[ -z "${allVersion}" ]] && allVersion=$(asdf list all "${appName}" 2>/dev/null | grep -Ev 'alpha|beta|rc')
    # https://stackoverflow.com/questions/4493205/unix-sort-of-version-numbers
    # sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n
    # To reverse the order: sort -t. -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr
    [[ -n "${allVersion}" ]] && latestVersion=$(echo "${allVersion}" | sort -rV | head -n1)
    [[ -z "${latestVersion}" ]] && latestVersion="latest"

    # Current Version
    # currentVersion=$(asdf current "${appName}" 2>/dev/null | sed 's/  */ /g' | cut -d' ' -f2)
    # currentVersion=$(asdf current "${appName}" 2>/dev/null | tr -s ' ' | cut -d' ' -f2)
    currentVersion=$(asdf current "${appName}" 2>/dev/null | awk '{print $2}')

    if [[ "${latestVersion}" == "${currentVersion}" ]]; then
        colorEcho "${FUCHSIA}${appName} ${latestVersion}${GREEN} is already installed!"
        return 0
    fi

    colorEcho "${BLUE}  Installing ${FUCHSIA}${appName} ${YELLOW}${latestVersion}${BLUE}..."
    # Install Version
    if [[ "${appName}" == "nodejs" ]]; then
        [[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env
        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            NODEJS_CHECK_SIGNATURES="no" NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node/" \
                asdf install "${appName}" "${latestVersion}"
            appInstallStatus=$?
        else
            NODEJS_CHECK_SIGNATURES="no" asdf install "${appName}" "${latestVersion}"
            appInstallStatus=$?
        fi
    else
        asdf install "${appName}" "${latestVersion}"
        appInstallStatus=$?
    fi

    # Set Current Version
    if [[ ${appInstallStatus} -eq 0 ]]; then
        asdf global "${appName}" "${latestVersion}"
        # asdf shell "${appName}" "${latestVersion}"
        # asdf local "${appName}" "${latestVersion}"

        # [[ -n "${currentVersion}" ]] && asdf uninstall "${appName}" "${currentVersion}"
    fi

    ## Fallback to System Version
    # asdf local ${appName} system

    # View Current Version
    asdf current "${appName}"

    ## Show Latest Stable Version
    # asdf latest "${appName}"
    # asdf latest "${appName}" "${latestVersion}"

    ## List Installed Versions
    # asdf list "${appName}"

    ## Uninstall Installed Version
    # asdf uninstall "${appName}" "${latestVersion}"

    ## Update all
    # asdf plugin update --all
}

function asdf_App_Update() {
    # Usage:
    # asdf_App_Update all
    # asdf_App_Update neovim
    # asdf_App_Update nodejs lts
    local appName=${1:-"all"}
    local appVersion=$2
    local InstalledPlugins InstalledApp allVersion currentVersion currentVerNum majorVersion matchVersion latestVersion
    local appInstallStatus=0

    [[ ! "$(command -v asdf)" ]] && colorEcho "${FUCHSIA}asdf${RED} is not installed!" && return 1

    if [[ "${appName}" == "all" ]]; then
        colorEcho "${BLUE}Checking update for all installed ${FUCHSIA}asdf plugins${BLUE}..."
        InstalledPlugins=$(asdf plugin list 2>/dev/null)
    else
        colorEcho "${BLUE}Checking update for ${FUCHSIA}asdf plugin ${ORANGE}${appName}${BLUE}..."
        InstalledPlugins="${appName}"
    fi

    while read -r InstalledApp; do
        [[ -z "${InstalledApp}" ]] && continue
        colorEcho "${BLUE}  Checking latest version for ${FUCHSIA}${InstalledApp}${BLUE}..."

        appInstallStatus=0
        allVersion=""
        latestVersion=""
        currentVersion=$(asdf current "${InstalledApp}" 2>/dev/null | awk '{print $2}')
        [[ -z "${currentVersion}" ]] && continue # no installed version

        if [[ -n "${appVersion}" ]]; then
            matchVersion="${appVersion}"
        else
            currentVerNum=$(echo "${currentVersion}" | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}')
            if [[ -z "${currentVerNum}" ]]; then
                matchVersion="${currentVersion}"
            elif [[ "${currentVerNum}" == "${currentVersion}" ]]; then
                matchVersion=""
            else
                # fetch major version from current version string: {major}.{minor}.{revision}
                majorVersion=$(echo "${currentVerNum}" | cut -d'.' -f1)
                matchVersion="${currentVersion/${currentVerNum}/}${majorVersion}"
            fi
        fi

        [[ -n "${matchVersion}" ]] && allVersion=$(asdf list all "${InstalledApp}" "${matchVersion}" 2>/dev/null | grep -Ev 'alpha|beta|rc')

        [[ -z "${allVersion}" ]] && allVersion=$(asdf list all "${InstalledApp}" 2>/dev/null | grep -Ev 'alpha|beta|rc')

        [[ -n "${allVersion}" ]] && latestVersion=$(echo "${allVersion}" | sort -rV | head -n1)

        # [[ -z "${latestVersion}" ]] && latestVersion="latest"
        [[ -z "${latestVersion}" ]] && continue

        # Alwarys reinstall if specify appVersion (stable, lts...)
        [[ -z "${appVersion}" && "${latestVersion}" == "${currentVersion}" ]] && continue

        colorEcho "${BLUE}  Updating ${FUCHSIA}${InstalledApp}${BLUE} to ${YELLOW}${latestVersion}${BLUE}..."
        asdf plugin update "${InstalledApp}"

        if [[ "${appName}" == "nodejs" ]]; then
            [[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env
            if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
                NODEJS_CHECK_SIGNATURES="no" NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node/" \
                    asdf install "${InstalledApp}" "${latestVersion}"
                appInstallStatus=$?
            else
                NODEJS_CHECK_SIGNATURES="no" asdf install "${InstalledApp}" "${latestVersion}"
                appInstallStatus=$?
            fi
        else
            asdf install "${InstalledApp}" "${latestVersion}"
            appInstallStatus=$?
        fi

        if [[ ${appInstallStatus} -eq 0 ]]; then
            asdf uninstall "${InstalledApp}" "${currentVersion}"
            asdf global "${InstalledApp}" "${latestVersion}"
        fi
    done <<<"${InstalledPlugins}"
}


# goup (pronounced Go Up) is an elegant Go version manager
# https://github.com/owenthereal/goup
function goup_Upgrade() {
    [[ ! -x "$(command -v goup)" ]] && colorEcho "${FUCHSIA}goup${RED} is not installed!" && return 1

    colorEcho "${BLUE}Updating ${FUCHSIA} Go toolchains and goup${BLUE}..."
    # fix: proxyconnect tcp: dial tcp: lookup socks5h: no such host
    if echo "${all_proxy}" | grep -q 'socks5h'; then
        proxy_socks5h_to_socks5 sudo "$(which goup)" upgrade
        proxy_socks5h_to_socks5 goup install
    else
        sudo "$(which goup)" upgrade
        goup install
    fi
}


# Check pacakge is installed
function checkPackageInstalled() {
    local PackageName=${1:-""}
    local PackageLocalFiles=""
    local PackageInstalled="no"

    [[ -n "${PackageName}" ]] || return 1
    [[ -x "$(command -v pacman)" ]] || return 1

    if PackageLocalFiles=$(pacman -Ql "${PackageName}" 2>&1); then
        PackageInstalled="yes"
    else
        if [[ "${PackageLocalFiles}" == *"unimplemented"* ]]; then
            if pacman -Qi "${PackageName}" >/dev/null 2>&1; then
                PackageInstalled="yes"
            fi
        fi
    fi

    [[ "${PackageInstalled}" == "yes" ]] && return 0 || return 1
}

# Check pacakge exist and is not installed
function checkPackageNeedInstall() {
    local PackageName=${1:-""}
    local PackageInfo=""
    local PackageExist="yes"

    [[ -n "${PackageName}" ]] || return 1
    [[ -x "$(command -v pacman)" ]] || return 1

    if PackageInfo=$(pacman -Si "${PackageName}" 2>&1); then
        [[ "${PackageInfo}" =~ "Error:" ]] && PackageExist="no"
    else
        PackageExist="no"
    fi

    if [[ "${PackageExist}" == "yes" ]]; then
        if ! checkPackageInstalled "${PackageName}"; then
            return 0
        fi
    fi

    return 1
}


# App installer
# Get os type & architecture that match running platform
function App_Installer_Get_OS_Info_Match_Cond() {
    OS_INFO_UNMATCH_COND=""

    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch
    [[ -z "${OS_INFO_FLOAT}" ]] && get_arch_float

    OS_INFO_MATCH_TYPE="${OS_INFO_TYPE}"
    case "${OS_INFO_TYPE}" in
        darwin)
            OS_INFO_MATCH_TYPE="${OS_INFO_MATCH_TYPE}|osx|os-x|mac|apple"
            ;;
        solaris)
            OS_INFO_MATCH_TYPE="${OS_INFO_MATCH_TYPE}|sunos"
            ;;
    esac

    OS_INFO_MATCH_ARCH="${OS_INFO_ARCH}"
    case "${OS_INFO_ARCH}" in
        amd64)
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|x86_64|64bit"
            ;;
        386)
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|486|586|686|x86|32bit"
            [[ -z "${OS_INFO_UNMATCH_COND}" ]] \
                && OS_INFO_UNMATCH_COND="x86_64" \
                || OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|x86_64"
            ;;
        arm64)
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|armv8|aarch64"
            ;;
        arm)
            # OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|armv7|arm32v7|armhf|armel"
            [[ -z "${OS_INFO_UNMATCH_COND}" ]] \
                && OS_INFO_UNMATCH_COND="arm64|armv8|aarch64" \
                || OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|arm64|armv8|aarch64"
            ;;
        ppc64le)
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|powerpc64le"
            ;;
        ppc64)
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|powerpc64"
            [[ -z "${OS_INFO_UNMATCH_COND}" ]] \
                && OS_INFO_UNMATCH_COND="ppc64le|powerpc64le" \
                || OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|ppc64le|powerpc64le"
            ;;
        mips)
            [[ -z "${OS_INFO_UNMATCH_COND}" ]] \
                && OS_INFO_UNMATCH_COND="mips64|mipsle" \
                || OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|mips64|mipsle"
            ;;
        riscv)
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|riscv32"
            [[ -z "${OS_INFO_UNMATCH_COND}" ]] \
                && OS_INFO_UNMATCH_COND="riscv64" \
                || OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|riscv64"
            ;;
    esac

    OS_INFO_MATCH_FLOAT="${OS_INFO_FLOAT}"
    case "${OS_INFO_FLOAT}" in
        hardfloat)
            OS_INFO_MATCH_FLOAT="${OS_INFO_MATCH_FLOAT}|armhf|gnueabihf|musleabihf"
            ;;
        softfloat)
            OS_INFO_MATCH_FLOAT="${OS_INFO_MATCH_FLOAT}|armel|gnueabi|musleabi"
            [[ -z "${OS_INFO_UNMATCH_COND}" ]] \
                && OS_INFO_UNMATCH_COND="gnueabihf|musleabihf" \
                || OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|gnueabihf|musleabihf"
            ;;
    esac
}

# Get release information from github repository using github API
function App_Installer_Get_Remote() {
    # REMOTE_VERSION: release version
    # REMOTE_DOWNLOAD_URL: download url that match running platform
    # The download filename should contain at least one of the platform type or architecture, like: `rclone-v1.56.2-linux-amd64.zip`
    # Usage:
    # App_Installer_Get_Remote "https://api.github.com/repos/rclone/rclone/releases/latest"
    # App_Installer_Get_Remote "https://api.github.com/repos/jarun/nnn/releases/latest" "nnn-nerd-.*\.tar\.gz"
    # App_Installer_Get_Remote "https://dev.yorhel.nl/ncdu" 'ncdu-[^<>:;,?"*|/]+\.tar\.gz' "ncdu-.*\.tar\.gz"
    local remote_url=$1
    local file_match_pattern=$2
    local version_match_pattern=$3
    local multi_match_filter=$4
    local remote_content match_urls match_result match_result_type match_result_arch match_result_float match_cnt

    [[ -z "${remote_url}" ]] && colorEcho "${FUCHSIA}REMOTE URL${RED} can't empty!" && return 1

    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    REMOTE_VERSION=""
    REMOTE_DOWNLOAD_URL=""

    [[ -z "${file_match_pattern}" ]] && file_match_pattern="\.zip|\.bz|\.gz|\.xz|\.tbz|\.tgz|\.txz|\.7z"
    [[ -z "${multi_match_filter}" ]] && multi_match_filter="musl|static"

    [[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

    remote_content=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)
    [[ -z "${remote_content}" ]] && colorEcho "${RED}  Error occurred while downloading from ${FUCHSIA}${remote_url}${RED}!" && return 1

    # Get app version
    REMOTE_VERSION=$(echo "${remote_content}" | grep 'tag_name' | cut -d\" -f4 | cut -d'v' -f2)
    [[ -z "${REMOTE_VERSION}" ]] && REMOTE_VERSION=$(echo "${remote_content}" | grep -E "${version_match_pattern}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    [[ -z "${REMOTE_VERSION}" ]] && REMOTE_VERSION=$(echo "${remote_content}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)

    # Get download urls
    match_urls=$(echo "${remote_content}" \
        | grep -E "${file_match_pattern}" \
        | grep -o -P "(((ht|f)tps?):\/\/)+[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?")

    if ! echo "${match_urls}" | grep -q -E "${file_match_pattern}"; then
        match_urls=""
    fi

    [[ -z "${match_urls}" ]] && match_urls=$(echo "${remote_content}" | grep -Eo "${file_match_pattern}")

    [[ -z "${OS_INFO_MATCH_TYPE}" ]] && App_Installer_Get_OS_Info_Match_Cond

    # Filter download urls by unmatching condition
    if [[ -n "${OS_INFO_UNMATCH_COND}" ]]; then
        match_urls=$(echo "${match_urls}" | grep -Evi "${OS_INFO_UNMATCH_COND}")
    fi

    match_result_type=""
    match_result_arch=""
    match_result_float=""

    if [[ -n "${OS_INFO_MATCH_TYPE}" ]]; then
        match_result_type=$(echo "${match_urls}" | grep -Ei "${OS_INFO_MATCH_TYPE}")
        [[ -n "${match_result_type}" ]] && match_urls="${match_result_type}"
    fi

    if [[ -n "${OS_INFO_MATCH_ARCH}" ]]; then
        match_result_arch=$(echo "${match_urls}" | grep -Ei "${OS_INFO_MATCH_ARCH}")
        [[ -n "${match_result_arch}" ]] && match_urls="${match_result_arch}"
    fi

    # Not match any of the platform type & architecture
    [[ -z "${match_result_type}" && -z "${match_result_arch}" ]] && match_urls=""

    if [[ -n "${OS_INFO_MATCH_FLOAT}" ]]; then
        match_result_float=$(echo "${match_urls}" | grep -Ei "${OS_INFO_MATCH_FLOAT}")
        [[ -n "${match_result_float}" ]] && match_urls="${match_result_float}"
    fi

    # Filter more than one file
    match_cnt=$(echo "${match_urls}" | wc -l)
    if [[ ${match_cnt} -gt 1 ]] && [[ -n "${multi_match_filter}" ]]; then
        match_result=$(echo "${match_urls}" | grep -Ei "${multi_match_filter}")
        [[ -n "${match_result}" ]] && match_urls="${match_result}"
    fi

    [[ -n "${match_urls}" ]] && REMOTE_DOWNLOAD_URL=$(echo "${match_urls}" | head -n1)

    [[ -n "${REMOTE_DOWNLOAD_URL}" ]] && return 0 || return 1
}

# Download & Extract
function App_Installer_Download_Extract() {
    local download_url=$1
    local download_filename=$2
    local workdir=$3
    local github_url="https://github.com"
    local remote_filename archive_ext_list archive_ext TargetExt
    local curl_rtn_code extract_rtn_code

    [[ -z "${download_url}" ]] && colorEcho "${FUCHSIA}Download URL${RED} can't empty!" && return 1

    remote_filename=$(echo "${download_url}" | awk -F"/" '{print $NF}')
    [[ -z "${download_filename}" ]] && download_filename="${remote_filename}"

    [[ -z "${workdir}" ]] && workdir="$(pwd)"

    # Download
    [[ -n "${GITHUB_DOWNLOAD_URL}" ]] && download_url="${download_url//${github_url}/${GITHUB_DOWNLOAD_URL}}"
    colorEcho "${BLUE}  From ${ORANGE}${download_url}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}"
    curl_rtn_code=$?

    if [[ ${curl_rtn_code} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        download_url="${download_url//${GITHUB_DOWNLOAD_URL}/${github_url}}"
        colorEcho "${BLUE}  From ${ORANGE}${download_url}"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}"
        curl_rtn_code=$?
    fi

    # Extract
    extract_rtn_code=0
    if [[ ${curl_rtn_code} -eq 0 ]]; then
        archive_ext=""
        archive_ext_list=(
            ".tar.bz2"
            ".tar.bz"
            ".tar.gz"
            ".tar.xz"
            ".tbz2"
            ".tbz"
            ".tgz"
            ".txz"
            ".bz2"
            ".bz"
            ".gz"
            ".xz"
            ".zip"
            ".7z"
        )
        for TargetExt in "${archive_ext_list[@]}"; do
            if echo "${remote_filename}" | grep -q "${TargetExt}$"; then
                archive_ext="${TargetExt}"
                break
            fi
        done

        case "${archive_ext}" in
            ".zip")
                unzip -qo "${download_filename}" -d "${workdir}" || extract_rtn_code=$?
                ;;
            ".tar.bz2" | ".tar.bz" | ".tbz2" | ".tbz")
                tar -xjf "${download_filename}" -C "${workdir}" || extract_rtn_code=$?
                ;;
            ".tar.gz" | ".tgz")
                tar -xzf "${download_filename}" -C "${workdir}" || extract_rtn_code=$?
                ;;
            ".tar.xz" | ".txz")
                tar -xJf "${download_filename}" -C "${workdir}" || extract_rtn_code=$?
                ;;
            ".bz2" | ".bz")
                cd "${workdir}" || return 1
                bzip2 -df "${download_filename}" || extract_rtn_code=$?
                ;;
            ".gz")
                cd "${workdir}" || return 1
                gzip -df "${download_filename}" || extract_rtn_code=$?
                ;;
            ".xz")
                cd "${workdir}" || return 1
                xz -df "${download_filename}" || extract_rtn_code=$?
                ;;
            ".7z")
                7z e "${download_filename}" -o"${workdir}" || extract_rtn_code=$?
                ;;
        esac
    fi

    if [[ ${curl_rtn_code} -eq 0 && ${extract_rtn_code} -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Reset app installer variables
function App_Installer_Reset() {
    APP_INSTALL_NAME=""
    GITHUB_REPO_NAME=""

    EXEC_INSTALL_PATH="/usr/local/bin"
    EXEC_INSTALL_NAME=""

    ARCHIVE_EXT=""
    ARCHIVE_EXEC_DIR=""
    ARCHIVE_EXEC_NAME=""

    MAN1_FILE="*.1"
    ZSH_COMPLETION_FILE=""

    IS_INSTALL="yes"
    IS_UPDATE="no"

    CURRENT_VERSION="0.0.0"
    REMOTE_VERSION=""
    VERSION_FILENAME=""

    REMOTE_DOWNLOAD_URL=""
}

# Install app from github releases or given url
function App_Installer_Install() {
    # Usage:
    # App_Installer "https://api.github.com/repos/rclone/rclone/releases/latest"
    #
    # The following variables need to be set before executing the function:
    # WORKDIR APP_INSTALL_NAME GITHUB_REPO_NAME
    # EXEC_INSTALL_PATH EXEC_INSTALL_NAME CURRENT_VERSION
    # ARCHIVE_EXT ARCHIVE_EXEC_DIR ARCHIVE_EXEC_NAME
    # MAN1_FILE ZSH_COMPLETION_FILE
    #
    # Check `installer/zoxide_installer.sh` or `installer/ncdu_installer.sh` or `installer/juicefs_installer.sh` or `installer/lazygit_installer.sh` as example
    local CHECK_URL=$1

    [[ "${IS_INSTALL}" != "yes" ]] && return 0

    [[ -z "${CHECK_URL}" ]] && CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"

    # get app remote version & download link that match running platform
    # colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."
    [[ -z "${REMOTE_DOWNLOAD_URL}" ]] && App_Installer_Get_Remote "${CHECK_URL}"

    [[ -z "${REMOTE_VERSION}" || -z "${REMOTE_DOWNLOAD_URL}" ]] && IS_INSTALL="no"

    version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}" && IS_INSTALL="no"

    [[ "${IS_INSTALL}" != "yes" ]] && return 0

    # set the app execute filename in archive
    [[ -z "${ARCHIVE_EXEC_NAME}" ]] && ARCHIVE_EXEC_NAME="${EXEC_INSTALL_NAME}"

    [[ -z "${WORKDIR}" ]] && WORKDIR="$(pwd)"
    DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"
    [[ -n "${ARCHIVE_EXT}" ]] && DOWNLOAD_FILENAME="${DOWNLOAD_FILENAME}.${ARCHIVE_EXT}"

    # download & extract file
    if App_Installer_Download_Extract "${REMOTE_DOWNLOAD_URL}" "${DOWNLOAD_FILENAME}" "${WORKDIR}"; then
        [[ -n "${ARCHIVE_EXEC_DIR}" ]] && ARCHIVE_EXEC_DIR=$(find "${WORKDIR}" -type d -name "${ARCHIVE_EXEC_DIR}")
        [[ -z "${ARCHIVE_EXEC_DIR}" || ! -d "${ARCHIVE_EXEC_DIR}" ]] && ARCHIVE_EXEC_DIR="${WORKDIR}"

        if echo "${ARCHIVE_EXEC_NAME}" | grep -q '\*'; then
            ARCHIVE_EXEC_NAME=$(find "${ARCHIVE_EXEC_DIR}" -type f -name "${ARCHIVE_EXEC_NAME}") && \
                ARCHIVE_EXEC_NAME=$(basename "${ARCHIVE_EXEC_NAME}")
        fi
        [[ -z "${ARCHIVE_EXEC_NAME}" || ! -s "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" ]] && ARCHIVE_EXEC_NAME="${EXEC_INSTALL_NAME}"

        # install app
        if [[ -s "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" ]]; then
            sudo cp -f "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                [[ -n "${VERSION_FILENAME}" ]] && echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true

            # man pages
            if [[ -n "${MAN1_FILE}" ]]; then
                CP_FILE_LIST=$(find "${ARCHIVE_EXEC_DIR}" -type f -name "${MAN1_FILE}")
                while read -r CP_FILE; do
                    [[ ! -s "${CP_FILE}" ]] && continue
                    sudo cp -f "${CP_FILE}" "/usr/share/man/man1"
                done <<<"${CP_FILE_LIST}"
            fi

            # zsh completions
            if [[ -n "${ZSH_COMPLETION_FILE}" ]]; then
                CP_FILE_LIST=$(find "${ARCHIVE_EXEC_DIR}" -type f -name "${ZSH_COMPLETION_FILE}")
                while read -r CP_FILE; do
                    [[ ! -s "${CP_FILE}" ]] && continue
                    CP_FILENAME=$(basename "${CP_FILE}")
                    sudo cp -f "${CP_FILE}" "/usr/local/share/zsh/site-functions" && \
                        sudo chmod 644 "/usr/local/share/zsh/site-functions/${CP_FILENAME}" && \
                        sudo chown "$(id -u)":"$(id -g)" "/usr/local/share/zsh/site-functions/${CP_FILENAME}"
                done <<<"${CP_FILE_LIST}"
            fi
        else
            colorEcho "${RED}  Can't find ${FUCHSIA}${ARCHIVE_EXEC_NAME}${RED} in downloaded files!"
            return 1
        fi
    else
        colorEcho "${RED}  Download failed from ${ORANGE}${REMOTE_DOWNLOAD_URL}${RED}!"
        return 1
    fi

    return 0
}


# pip package installer
function pip_Package_Install() {
    # Usage:
    # pip_Package_Install numpy
    local PackageName=$1
    local PackageVersion=${2:-""}
    local PYTHON_CMD

    if [[ -z "${PackageName}" ]]; then
        colorEcho "${FUCHSIA}pip package${RED} name can't empty!"
        return 1
    fi

    colorEcho "${BLUE}  Installing ${FUCHSIA}pip package ${ORANGE}${PackageName}${BLUE}..."
    if [[ -x "$(command -v python3)" ]]; then
        PYTHON_CMD="python3"
    elif [[ -x "$(command -v python)" ]]; then
        PYTHON_CMD="python"
    else
        colorEcho "${FUCHSIA}    python${RED} is not installed!"
        return 1
    fi

    if [[ ! -x "$(command -v pip)" || ! -x "$(command -v pip3)" ]]; then
        colorEcho "${FUCHSIA}    pip${RED} is not installed!"
        return 1
    fi

    if [[ -z "${PackageVersion}" ]]; then
        ${PYTHON_CMD} -m pip install --user -U "${PackageName}"
    else
        ${PYTHON_CMD} -m pip install --user -U "${PackageName}"=="${PackageVersion}"
    fi
}


# Start new screen session and logging to ~/screenlog.*
function newScreenSession() {
    local SCREEN_SESSION_NAME=${1:-"default"}
    local SCREEN_SESSION_LOGGING=${2:-"no"}

    if [[ -x "$(command -v screen)" ]]; then
        if [[ -z "$STY" && -z "$TMUX" ]]; then
            mkdir -p "$HOME/.screen" && chmod 700 "$HOME/.screen" && export SCREENDIR="$HOME/.screen"
            if ! grep -q "^term " "$HOME/.screenrc" 2>/dev/null; then
                echo "term ${TERM}" >> "$HOME/.screenrc"
            fi

            if ! grep -q "^caption always " "$HOME/.screenrc" 2>/dev/null; then
                tee -a "$HOME/.screenrc" >/dev/null <<-'EOF'
# https://gist.github.com/onsails/1328005/dacbc9903fcea5385bb8ee2fde4e1a367d32889c
# caption always "%?%F%{-b bc}%:%{-b bb}%?%C|%D|%M %d|%H%?%F%{+u wb}%? %L=%-Lw%45>%{+b by}%n%f* %t%{-}%+Lw%-0<"
caption always "%{=}%{+b kR}%H %{+b kY}%M %d %{+b kG}%2c %{+b kB}%?%-Lw%?%{+b kW}%n*%f %kt%?(%u)%?%{+bkB}%?%+Lw%? | %{kR} Load: %l %{kB}"
EOF
            fi

            # logging
            if [[ "${SCREEN_SESSION_LOGGING}" == "yes" ]]; then
                screen -L -Logfile "$HOME/.screen/screen_$(date '+%Y%m%d_%H%M%S').log" -xRR "${SCREEN_SESSION_NAME}"
            else
                screen -xRR "${SCREEN_SESSION_NAME}"
            fi
        fi
    else
        colorEcho "${FUCHSIA}screen${RED} is not installed!"
        return 1
    fi
}

# Start new tmux session
function newTmuxSession() {
    local TMUX_SESSION_NAME=${1:-"default"}

    ## Logging in tmux session
    # script -f "$HOME/.tmux_logs/tmux_$(date '+%Y%m%d_%H%M%S').log" >/dev/null && exit

    ## tmux-logging
    ## https://github.com/tmux-plugins/tmux-logging
    # if [[ -s "$HOME/.tmux.conf.local" ]]; then
    #     if ! grep -q "tmux-logging" "$HOME/.tmux.conf.local" 2>/dev/null; then
    #         echo "set -g @plugin 'tmux-plugins/tmux-logging'" \
    #             | tee -a "$HOME/.tmux.conf.local" >/dev/null
    #     fi
    # fi

    if [[ "$(command -v tmux)" ]]; then
        if [[ -z "$STY" && -z "$TMUX" ]]; then
            if ! tmux attach -t "${TMUX_SESSION_NAME}" 2>/dev/null; then
                tmux new -s "${TMUX_SESSION_NAME}"
            fi
        fi
    else
        colorEcho "${FUCHSIA}tmux${RED} is not installed!"
        return 1
    fi
}


# docker mirrors
function Set_Docker_Mirrors() {
    local REGISTRY_MIRRORS=$1

    if [[ ! -x "$(command -v jq)" ]]; then
        colorEcho "${FUCHSIA}jq${RED} is not installed!"
        return 1
    fi

    [[ -z "${REGISTRY_MIRRORS}" ]] && \
        REGISTRY_MIRRORS='"https://ustc-edu-cn.mirror.aliyuncs.com","https://docker.mirrors.sjtug.sjtu.edu.cn","https://mirror.baidubce.com","https://hub-mirror.c.163.com"'

    colorEcho "${BLUE}Setting docker registry-mirrors to:"
    colorEcho "${FUCHSIA}  ${REGISTRY_MIRRORS}"

    [[ ! -s "/etc/docker/daemon.json" ]] && echo '{}' | sudo tee "/etc/docker/daemon.json" >/dev/null

    cat "/etc/docker/daemon.json" \
        | jq -r ".\"registry-mirrors\"=[${REGISTRY_MIRRORS}]" \
        | sudo tee "/etc/docker/daemon.json" >/dev/null

    colorEcho "${BLUE}Restarting docker service:"
    sudo systemctl daemon-reload && sudo systemctl restart docker
}

# docker pull: Pull multiple images together
# https://github.com/moby/moby/issues/16106
function dockerPullImages() {
    # usage: 
    # dockerPullImages "node:lts-alpine golang:alpine"

    # https://www.linuxjournal.com/content/parallel-shells-xargs-utilize-all-your-cpu-cores-unix-and-windows
    # nproc: the number of installed processors
    # --ignore=N if possible, exclude N processing units
    echo "$@" | xargs -P "$(nproc --ignore=1)" -n1 docker pull

    # for dockerImage in "$@"; do docker pull $dockerImage; done
}

# Remove all dangling containers & images
function dockerRemoveDangling() {
    local list imageTag

    colorEcho "${BLUE}Removing all dangling containers & images..."
    # container build cache
    # list=$(sudo docker ps -a | grep -v 'CONTAINER' | awk '{print $1}')
    list=$(sudo docker ps -aq --filter "status=exited" --filter "status=created")
    if [[ -n "${list}" ]]; then
        sudo docker ps -aq --filter "status=exited" --filter "status=created" | xargs -n1 sudo docker rm
    fi

    sudo docker container prune --force
    sudo docker image prune --force

    # local images
    # The RepoDigest field in the image inspect will have a sha256 reference if you pulled the image from a registry
    # list=$(sudo docker images --format "{{.Repository}}" | grep '_')
    list=$(sudo docker images --filter "dangling=false" --format "{{.Repository}}:{{.Tag}}" \
        | xargs -n1 sudo docker image inspect \
            --format '{{if .RepoTags}}{{index .RepoTags 0}}{{end}} {{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' \
        | grep -v '@' | sed 's/\s//g')
    if [[ -n "${list}" ]]; then
        while read -r imageTag; do
            sudo docker rmi "${imageTag}"
        done <<<"${list}"
    fi
}


function Get_Read_Array_Options() {
    local runShell

    READ_ARRAY_OPTS=()
    runShell=$(ps -p $$ -o cmd='',comm='',fname='' 2>/dev/null | sed 's/^-//' | grep -oE '\w+' | head -n1)
    [[ "${runShell}" == "zsh" ]] && READ_ARRAY_OPTS=(-A) || READ_ARRAY_OPTS=(-a)
}


function Get_Installer_CURL_Options() {
    local opts

    [[ -z "${READ_ARRAY_OPTS[*]}" ]] && Get_Read_Array_Options

    CURL_CHECK_OPTS=()
    if [[ -n "${INSTALLER_CHECK_CURL_OPTION}" ]]; then
        if ! IFS=" " read -r "${READ_ARRAY_OPTS[@]}" CURL_CHECK_OPTS <<< "${INSTALLER_CHECK_CURL_OPTION}" 2>/dev/null; then
            while read -r opts; do
                CURL_CHECK_OPTS+=("${opts}")
            done < <(echo "${INSTALLER_CHECK_CURL_OPTION}" | tr ' ' '\n')
        fi
    fi
    [[ -z "${CURL_CHECK_OPTS[*]}" ]] && CURL_CHECK_OPTS=(-fsL)

    CURL_DOWNLOAD_OPTS=()
    if [[ -n "${INSTALLER_DOWNLOAD_CURL_OPTION}" ]]; then
        if ! IFS=" " read -r "${READ_ARRAY_OPTS[@]}" CURL_DOWNLOAD_OPTS <<< "${INSTALLER_DOWNLOAD_CURL_OPTION}" 2>/dev/null; then
            while read -r opts; do
                CURL_DOWNLOAD_OPTS+=("${opts}")
            done < <(echo "${INSTALLER_DOWNLOAD_CURL_OPTION}" | tr ' ' '\n')
        fi
    fi
    [[ -z "${CURL_DOWNLOAD_OPTS[*]}" ]] && CURL_DOWNLOAD_OPTS=(-fSL)

    return 0
}


function Get_Git_Clone_Options() {
    local opts

    [[ -z "${READ_ARRAY_OPTS[*]}" ]] && Get_Read_Array_Options

    [[ -z "${GIT_CLONE_DEFAULT_OPTION}" ]] && \
        GIT_CLONE_DEFAULT_OPTION="-c core.autocrlf=false -c core.filemode=false"

    GIT_CLONE_OPTS=()
    if ! IFS=" " read -r "${READ_ARRAY_OPTS[@]}" GIT_CLONE_OPTS <<< "${GIT_CLONE_DEFAULT_OPTION}" 2>/dev/null; then
        while read -r opts; do
            GIT_CLONE_OPTS+=("${opts}")
        done < <(echo "${GIT_CLONE_DEFAULT_OPTION}" | tr ' ' '\n')
    fi
}


# broot
# a better tree optimizing for the height of the screen
function br_tree() {
    br -c :pt "$@"
}

# br with git status
function br_git_status() {
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/broot.toml" ]]; then
        br --conf "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/broot.toml" --git-status
    else
        br --git-status
    fi
}


# Send desktop notifications and reminders from Linux terminal
# https://opensource.com/article/22/1/linux-desktop-notifications
function remind() {
    local COUNT="$#"
    local COMMAND="$1"
    local MESSAGE="$1"
    local OP="$2"

    shift 2
    local WHEN="$*"

    # Display help if no parameters or help command
    if [[ $COUNT -eq 0 || "$COMMAND" == "help" || "$COMMAND" == "--help" || "$COMMAND" == "-h" ]]; then
        echo "COMMAND"
        echo "    remind <message> <time>"
        echo "    remind <command>"
        echo
        echo "DESCRIPTION"
        echo "    Displays notification at specified time"
        echo
        echo "EXAMPLES"
        echo '    remind "Hi there" now'
        echo '    remind "Time to wake up" in 5 minutes'
        echo '    remind "Dinner" in 1 hour'
        echo '    remind "Take a break" at noon'
        echo '    remind "Are you ready?" at 13:00'
        echo '    remind list'
        echo '    remind clear'
        echo '    remind help'
        echo
        return
    fi

    # Install notify-send
    if checkPackageNeedInstall "notify-send"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}notify-send${BLUE}..."
        sudo pacman --noconfirm -S notify-send
    fi

    # Install AT
    if checkPackageNeedInstall "at"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}at${BLUE}..."
        sudo pacman --noconfirm -S at
    fi

    # Check presence of notify-send command
    if ! which notify-send >/dev/null; then
        echo "remind: notify-send is required but not installed on your system. Install it with your package manager of choice, for example 'sudo apt install notify-send'."
        return
    fi

    # Check presence of AT command
    if ! which at >/dev/null; then
        echo "remind: AT utility is required but not installed on your system. Install it with your package manager of choice, for example 'sudo apt install at'."
        return
    fi

    # Run commands: list, clear
    if [[ $COUNT -eq 1 ]]; then
        if [[ "$COMMAND" == "list" ]]; then
        at -l
        elif [[ "$COMMAND" == "clear" ]]; then
        at -r "$(atq | cut -f1)"
        else
        echo "remind: unknown command $COMMAND. Type 'remind' without any parameters to see syntax."
        fi
        return
    fi

    # Determine time of notification
    if [[ "$OP" == "in" ]]; then
        local TIME="now + $WHEN"
    elif [[ "$OP" == "at" ]]; then
        local TIME="$WHEN"
    elif [[ "$OP" == "now" ]]; then
        local TIME="now"
    else
        echo "remind: invalid time operator $OP"
        return
    fi

    # Schedule the notification
    echo "notify-send '$MESSAGE' 'Reminder' -u critical" | at $TIME 2>/dev/null
    echo "Notification scheduled at $TIME"
}


# https://github.com/chubin/wttr.in
function get_weather() {
    local wttr_city=${1:-""}
    local wttr_format=${2:-""}
    local wttr_lang=${3:-"zh-cn"}
    local wttr_url

    if [[ -z "${wttr_format}" ]]; then
        wttr_url="wttr.in/${wttr_city}"
    else
        wttr_url="wttr.in/${wttr_city}?format=${wttr_format}"
    fi

    curl -fsL --connect-timeout 3 --max-time 10 \
        --noproxy '*' -H "Accept-Language: ${wttr_lang}" --compressed \
        "${wttr_url}"
}

function get_weather_custom() {
    local wttr_city=${1:-""}
    local wttr_format=${2:-""}
    local wttr_lang=${3:-"zh-cn"}
    local wttr_url
    local wttr_weather

    if [[ -z "${wttr_format}" ]]; then
        wttr_format="%l:+%c%C,+%F0%9F%8C%A1%t,+%E2%9B%86%h,+%F0%9F%8E%8F%w,+%E2%98%94%p+%o,+%P"
    fi

    wttr_url="wttr.in/${wttr_city}?format=${wttr_format}"

    wttr_weather=$(curl -fsL --connect-timeout 3 --max-time 10 \
        --noproxy '*' -H "Accept-Language: ${wttr_lang}" --compressed \
        "${wttr_url}")
    [[ -n "${wttr_weather}" ]] && colorEcho "${YELLOW}${wttr_weather}"
}

# Bash Function To Rename Files Without Typing Full Name Twice
function mv_rename() {
    if [ "$#" -ne 1 ] || [ ! -e "$1" ]; then
        command mv "$@"
        return
    fi

    read -rei "$1" newfilename
    command mv -v -- "$1" "$newfilename"
}

## Dateutils
# http://www.fresse.org/dateutils/
# apt install -y dateutils
# dateutils.dadd 2018-05-22 +120d
# Usage: date_diff 20201208 20180522
function date_diff() {
    if [[ $# -eq 2 ]]; then
        echo $(( ($(date -d "$1" +%s) - $(date -d "$2" +%s) )/(60*60*24) ))
    fi
}

#  Usage: get_zone_time Asia/Shanghai America/Los_Angeles America/New_York
function get_zone_time() {
    local TZONES CURRENT_UTC_TIME DISPLAY_FORMAT UTC_TIME LOCAL_TIME ZONE_TIME tz

    TZONES=("$@")
    [[ -z "${TZONES[*]}" ]] && TZONES=("Asia/Shanghai")
    # /usr/share/zoneinfo
    # Asia/Shanghai America/Los_Angeles America/New_York
    CURRENT_UTC_TIME=$(date -u)

    DISPLAY_FORMAT="%F %T %Z %z"

    UTC_TIME=$(date -u -d "$CURRENT_UTC_TIME" +"$DISPLAY_FORMAT")
    colorEcho "${YELLOW}UTC Time: ${UTC_TIME}"

    LOCAL_TIME=$(date -d "$CURRENT_UTC_TIME" +"$DISPLAY_FORMAT")
    colorEcho "${FUCHSIA}Local Time: ${LOCAL_TIME}"

    for tz in "${TZONES[@]}"; do
        ZONE_TIME=$(TZ="$tz" date -d "$CURRENT_UTC_TIME" +"$DISPLAY_FORMAT")
        colorEcho "${BLUE}${tz}: ${ZONE_TIME}"
    done
}


## Sort an array
## https://gist.github.com/suewonjp/7150f3fe449a58b2ce6cbb456882bed6
## tmp=( c d a e b )
## sort_array tmp
## echo ${tmp[*]} ### a b c d e
# function sort_array() {
#     if [[ -n "$1" ]]; then
#         local IFS=$'\n'
#         eval "local arr=( \${$1[*]} )"
#         arr=( $( sort <<<"${arr[*]}" ) )
#         eval "$1=( \${arr[*]} )"
#     fi
# }

## https://askubuntu.com/questions/597924/wrong-behavior-of-sort-command
# function sort_array_lc() {
#     if [[ -n "$1" ]]; then
#         local IFS=$'\n'
#         eval "local arr=( \${$1[*]} )"
#         arr=( $( LC_ALL=C sort <<<"${arr[*]}" ) )
#         eval "$1=( \${arr[*]} )"
#     fi
# }


## load SSH keys with Passphrase Protected
## https://www.funtoo.org/Keychain
## http://unix.stackexchange.com/questions/90853/how-can-i-run-ssh-add-automatically-without-password-prompt
## https://www.cyberciti.biz/faq/ssh-passwordless-login-with-keychain-for-scripts/
function load_ssh_keys() {
    local IdentityFiles

    if checkPackageNeedInstall "keychain"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}keychain${BLUE}..."
        sudo pacman --noconfirm -S keychain
    fi

    if [[ ! -x "$(command -v keychain)" ]]; then
        colorEcho "${FUCHSIA}keychain${RED} is not installed!"
        return 1
    fi

    # /usr/bin/keychain --list
    # /usr/bin/keychain --clear

    if [[ -s "$HOME/.ssh/config" ]]; then
        IdentityFiles=$(grep 'IdentityFile' "$HOME/.ssh/config" \
            | sed -e 's/IdentityFile//' -e "s/^\s*//" -e "s/\s$//" -e "s|~|$HOME|" \
            | sort | uniq)
        for TargetFile in "${IdentityFiles[@]}"; do
            /usr/bin/keychain "${TargetFile}"
        done
    fi

    [[ -z "$HOSTNAME" ]] && HOSTNAME=$(uname -n)
    if [[ -s "$HOME/.keychain/$HOSTNAME-sh" ]]; then
        source "$HOME/.keychain/$HOSTNAME-sh"
        /usr/bin/keychain --list
    fi

    # Improve the security of keychain, need to re-enter any passphrases when log in
    if ! grep -q '/usr/bin/keychain --clear' ~/.zshrc >/dev/null 2>&1; then
        {
            echo ''
            echo '# Improve the security of keychain'
            echo '# User need to re-enter any passphrases when log in'
            echo '[[ -x "$(command -v keychain)" ]] && /usr/bin/keychain --clear >/dev/null 2>&1'
        } >> ~/.zshrc
    fi

    if ! grep -q '/usr/bin/keychain --clear' ~/.bash_profile >/dev/null 2>&1; then
        {
            echo ''
            echo '# Improve the security of keychain'
            echo '# User need to re-enter any passphrases when log in'
            echo '[[ -x "$(command -v keychain)" ]] && /usr/bin/keychain --clear >/dev/null 2>&1'
        } >> ~/.bash_profile
    fi
}


## ProgressBar
# bar=''
# for ((i=0;$i<=100;i++)); do
#     printf "Progress:[%-100s]%d%%\r" $bar $i
#     sleep 0.1
#     bar=#$bar
# done
# echo
function draw_progress_bar() {
    # https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
    # progress bar length in characters
    [[ -z "$PROGRESS_BAR_WIDTH" ]] && PROGRESS_BAR_WIDTH=50

    # Arguments: current value, max value, unit of measurement (optional)
    local __value=$1
    local __max=$2
    local __unit=${3:-""}  # if unit is not supplied, do not display it

    # Calculate percentage
    if (( __max < 1 )); then __max=1; fi  # anti zero division protection
    local __percentage=$(( 100 - (__max*100 - __value*100) / __max ))

    # Rescale the bar according to the progress bar width
    local __num_bar=$(( __percentage * PROGRESS_BAR_WIDTH / 100 ))

    # Draw progress bar
    printf "["
    for b in $(seq 1 $__num_bar); do printf "#"; done
    for s in $(seq 1 $(( PROGRESS_BAR_WIDTH - __num_bar ))); do printf " "; done
    if [[ -n "$__unit" ]]; then
        printf "] $__percentage%% ($__value / $__max $__unit)\r"
    else
        printf "] $__percentage%% ($__value / $__max)\r"
    fi
}
## Usage:
# PROGRESS_CNT=100
# PROGRESS_CUR=1
# while true; do
#     PROGRESS_CUR=$((PROGRESS_CUR+1))
#     # Draw a progress bar
#     draw_progress_bar $PROGRESS_CUR $PROGRESS_CNT "files"
#     # Check if we reached 100%
#     [[ $PROGRESS_CUR == $PROGRESS_CNT ]] && break
#     # sleep 0.1  # Wait before redrawing
# done
# # Go to the newline at the end of progress
# printf "\n"
