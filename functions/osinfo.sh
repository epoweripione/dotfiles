#!/usr/bin/env bash

## Get OS type, architecture etc.
## https://en.wikipedia.org/wiki/Uname
# Windows Subsystem for Linux
function check_os_wsl() {
    local os_wsl

    os_wsl=$(uname -r 2>/dev/null)
    [[ "${os_wsl}" =~ "WSL" || "${os_wsl}" =~ "microsoft" || "${os_wsl}" =~ "Microsoft" ]] && return 0 || return 1
}

function check_os_wsl1() {
    local os_wsl

    os_wsl=$(uname -r 2>/dev/null)
    [[ "${os_wsl}" =~ "Microsoft" ]] && return 0 || return 1
}

function check_os_wsl2() {
    local os_wsl

    os_wsl=$(uname -r 2>/dev/null)
    [[ "${os_wsl}" =~ "WSL2" || "${os_wsl}" =~ "microsoft" ]] && return 0 || return 1
}

# Arch-based Linux
function check_os_arch() {
    local os_id os_id_like

    os_id="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release 2>/dev/null | cut -d '=' -f2)"
    os_id_like="$(grep -E '^ID_LIKE=([a-zA-Z]*)' /etc/os-release 2>/dev/null | cut -d '=' -f2)"

    [[ "${os_id}" == "arch" || "${os_id}" == "manjaro" || "${os_id_like}" == "arch" ]] && return 0 || return 1
}

# get os type: darwin, windows, linux, freebsd, openbsd, solaris
function get_os_type() {
    local osname ostype

    osname=$(uname 2>/dev/null)
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

# get os release: macos, windows, debian, ubuntu, centos, fedora, freebsd, openbsd, dragonfly, solaris, android
function get_os_release() {
    local osname os_release

    osname=$(uname 2>/dev/null)
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
    local osname

    osname=$(uname 2>/dev/null)
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

    if check_os_wsl; then
        osname='Windows'
    fi

    OS_INFO_RELEASE_TYPE=$osname
}

# Get OS release info: ID, VERSION_ID, VERSION_CODENAME
function get_os_release_info() {

    if [[ "$(command -v lsb_release)" ]]; then
        # debian, ubuntu...
        OS_RELEASE_ID=$(lsb_release --id --short 2>/dev/null | tr '[:upper:]' '[:lower:]')

        # buster, bookworm, trixie...
        OS_RELEASE_CODENAME=$(lsb_release --codename --short 2>/dev/null)

        # 11, 12, 13...
        OS_RELEASE_VER=$(lsb_release --release --short 2>/dev/null)
    else
        # rhel, fedora, centos, rocky, almalinux...
        OS_RELEASE_ID=$(awk -F= '/^ID=/ {print $2}' /etc/os-release | tr '[:upper:]' '[:lower:]' | tr -d '"')

        # Ootpa, Sage Margay, Blue Onyx...
        OS_RELEASE_CODENAME=$(awk -F= '/^VERSION_CODENAME=/ {print $2}' /etc/os-release | tr -d '"')
        [[ -z "${OS_RELEASE_CODENAME}" ]] && \
            OS_RELEASE_CODENAME=$(awk -F= '/^VERSION=/ {print $2}' /etc/os-release | tr -d '"' | cut -d'(' -f2 | cut -d')' -f1)

        # 8, 9, 10...
        OS_RELEASE_VER=$(awk -F= '/^VERSION_ID=/ {print $2}' /etc/os-release | tr -d '"' | cut -d'.' -f1)
    fi
}

# Determine which desktop environment is installed from the shell: KDE,XFCE,GNOME...
function get_os_desktop() {
    local osdesktop

    [[ -x "$(command -v wmctrl)" ]] && osdesktop=$(wmctrl -m 2>/dev/null)

    [[ -z "${osdesktop}" ]] && osdesktop=${XDG_CURRENT_DESKTOP}

    # to lowercase
    # OS_INFO_DESKTOP="${osdesktop,,}"
    # OS_INFO_DESKTOP=$(tr '[:upper:]' '[:lower:]' <<<"${osdesktop}")

    # to uppercase
    # OS_INFO_DESKTOP="${osdesktop^^}"
    OS_INFO_DESKTOP=$(tr '[:lower:]' '[:upper:]' <<<"${osdesktop}")
}

# https://github.com/systemd/systemd/blob/main/src/basic/architecture.c
function get_arch() {
	local architecture spruce_type

    architecture=$(uname -m 2>/dev/null)
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

    # CPU architecture
    OS_INFO_CPU_ARCH=$(lscpu 2>/dev/null | awk '/Architecture:/{print $2}')
    if [[ -z "${OS_INFO_CPU_ARCH}" ]]; then
        case "${OS_INFO_ARCH}" in
            amd64)
                OS_INFO_CPU_ARCH="x86_64"
                ;;
            386)
                OS_INFO_CPU_ARCH="x86"
                ;;
            arm64)
                OS_INFO_CPU_ARCH="aarch64"
                ;;
            *)
                OS_INFO_CPU_ARCH="${OS_INFO_ARCH}"
                ;;
        esac
    fi
}

function get_sysArch() {
	local architecture VDIS

    architecture=$(uname -m 2>/dev/null)
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

# https://en.wikipedia.org/wiki/X86-64#Microarchitecture_levels
# https://unix.stackexchange.com/questions/631217/how-do-i-check-if-my-cpu-supports-x86-64-v2
# https://utcc.utoronto.ca/~cks/space/blog/programming/GoAmd64ArchitectureLevels
function get_cpu_arch_level() {
    local flags level verbose

    verbose=$1

    # awk 'BEGIN {
    #     while (!/flags/) if (getline < "/proc/cpuinfo" != 1) return 1
    #     if (/lm/&&/cmov/&&/cx8/&&/fpu/&&/fxsr/&&/mmx/&&/syscall/&&/sse2/) level = 1
    #     if (level == 1 && /cx16/&&/lahf_lm/&&/popcnt/&&/sse4_1/&&/sse4_2/&&/ssse3/) level = 2
    #     if (level == 2 && /avx/&&/avx2/&&/bmi1/&&/bmi2/&&/f16c/&&/fma/&&/abm/&&/movbe/&&/xsave/) level = 3
    #     if (level == 3 && /avx512f/&&/avx512bw/&&/avx512cd/&&/avx512dq/&&/avx512vl/) level = 4
    #     # if (level > 0) { print "CPU supports x86-64-v" level }
    # }'

    flags=$(grep '^flags\b' </proc/cpuinfo | head -n1)
    flags=" ${flags#*:} "

    has_flags() {
        # https://unix.stackexchange.com/questions/417292/bash-for-loop-without-a-in-foo-bar-part
        # If `in WORDS ...;' is not present, then `in "$@"' is assumed.
        for flag; do
            case "$flags" in
                *" $flag "*)
                    :
                    ;;
                *)
                    [[ -n "$verbose" ]] && echo >&2 "Missing $flag for the next level"
                    return 1
                    ;;
            esac
        done
    }

    determine_level() {
        level=0
        has_flags lm cmov cx8 fpu fxsr mmx syscall sse2 || return 0
        level=1
        has_flags cx16 lahf_lm popcnt sse4_1 sse4_2 ssse3 || return 0
        level=2
        has_flags avx avx2 bmi1 bmi2 f16c fma abm movbe xsave || return 0
        level=3
        has_flags avx512f avx512bw avx512cd avx512dq avx512vl || return 0
        level=4
    }

    determine_level
    # echo "CPU supports x86-64-v$level"

    CPU_ARCH_LEVEL=$level
}

function get_os_icon() {
    local osname OS_ICON OS_RELEASE_ID

    osname=$(uname 2>/dev/null)
    case "$osname" in
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

    if check_os_wsl; then
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

    command -v xbps-install >/dev/null && OS_PACKAGE_MANAGER="xbps" && return
    command -v brew >/dev/null && OS_PACKAGE_MANAGER="homebrew" && return
}

function check_release_package_manager() {
    local checkType=$1
    local value=$2
    local release='' systemPackage='' osname

    osname=$(uname 2>/dev/null)
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

# https://www.freedesktop.org/software/systemd/man/systemd-detect-virt.html
# https://www.howtogeek.com/803839/how-to-let-linux-scripts-detect-theyre-running-in-virtual-machines/
function get_os_virtualized() {
    local virtualEnv

    # systemd-detect-virt --list
    if [[ -x "$(command -v systemd-detect-virt)" ]]; then
        virtualEnv=$(systemd-detect-virt 2>/dev/null)
    elif [[ -x "$(command -v hostnamectl)" ]]; then
        virtualEnv=$(hostnamectl 2>/dev/null | grep -i 'virtualization' | cut -d':' -f2 | sed 's/\s//g')
    fi

    [[ -z "${virtualEnv}" ]] && virtualEnv="none"

    OS_INFO_VIRTUALIZED="${virtualEnv}"
}

function check_os_virtualized() {
    local virtualEnv

    # systemd-detect-virt --list
    if [[ -x "$(command -v systemd-detect-virt)" ]]; then
        virtualEnv=$(systemd-detect-virt 2>/dev/null)
    elif [[ -x "$(command -v hostnamectl)" ]]; then
        virtualEnv=$(hostnamectl 2>/dev/null | grep -i 'virtualization' | cut -d':' -f2 | sed 's/\s//g')
    fi

    [[ -z "${virtualEnv}" ]] && virtualEnv="none"

    [[ "${virtualEnv}" != "none" ]] && return 0 || return 1
}

# Check if app is Microsoft Windows executable file (EXE file) in WSL
# Usage: if check_wsl_windows_exe "/c/Users/user01/scoop/shims/flutter"; then echo 'The app is Windows executable file!'; fi
function check_wsl_windows_exe() {
    local appPath=$1
    local wslPath

    os_wsl=$(uname -r 2>/dev/null)
    if check_os_wsl; then
        wslPath=$(wslpath -w "${appPath}" 2>/dev/null)
        # C:\Users\user01\scoop\shims\flutter
        if [[ "${wslPath}" =~ ':\\' ]]; then
            return 0
        else
            return 1
        fi
    fi

    return 1
}
