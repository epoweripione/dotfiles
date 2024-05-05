#!/usr/bin/env bash

# pip package installer
function pip_Package_Install() {
    # Usage:
    # pip_Package_Install numpy
    local PackageName=$1
    local PackageVersion=${2:-""}
    local PythonCMD PipCMD

    if [[ -z "${PackageName}" ]]; then
        colorEcho "${FUCHSIA}Package name${RED} can't empty!"
        return 1
    fi

    PythonCMD=""
    if [[ -x "$(command -v python3)" ]]; then
        PythonCMD="python3"
    elif [[ -x "$(command -v python)" ]]; then
        PythonCMD="python"
    fi

    if [[ -z "${PythonCMD}" ]]; then
        colorEcho "${FUCHSIA}    python${RED} is not installed!"
        return 1
    fi

    # fix: error: externally-managed-environment
    PipCMD="$HOME/.local/bin/pip"
    [[ ! -f "{PipCMD}" ]] && ${PythonCMD} -m venv "$HOME/.local"

    if [[ ! -x "${PipCMD}" ]]; then
        colorEcho "${FUCHSIA}    pip${RED} is not installed!"
        return 1
    fi

    colorEcho "${BLUE}  Installing ${FUCHSIA}pip package ${ORANGE}${PackageName}${BLUE}..."
    if [[ -z "${PackageVersion}" ]]; then
        ${PipCMD} install -U "${PackageName}"
    else
        ${PipCMD} install -U "${PackageName}"=="${PackageVersion}"
    fi
}

# pip install packages globally
function gpip() {
    PIP_REQUIRE_VIRTUALENV=false pip "$@"
}

# [How do I allow pip inside anaconda3 venv when pip set to require virtualenv?](https://stackoverflow.com/questions/54263894/how-do-i-allow-pip-inside-anaconda3-venv-when-pip-set-to-require-virtualenv)
function allow_pip_in_conda_environment() {
    # abort if we're not in a conda env (or in the base environment)
    if [[ -z "${CONDA_DEFAULT_ENV}" || "${CONDA_DEFAULT_ENV}" == "base" ]]; then
        echo "Should be run from within a conda environment (not base)"
        return
    fi

    ACTIVATE="$CONDA_PREFIX/etc/conda/activate.d/dont-require-venv-for-pip.sh"
    DEACTIVATE="$CONDA_PREFIX/etc/conda/deactivate.d/require-venv-for-pip.sh"

    # abort if either the activate or the deactivate hook already exists in this env
    if [[ -f "$ACTIVATE" || -f "$DEACTIVATE" ]]; then
        echo "This hook is already installed in this conda environment"
        return
    fi

    # write the hooks (create dirs if they don't exist)
    mkdir -p "$(dirname "$ACTIVATE")"
    mkdir -p "$(dirname "$DEACTIVATE")"
    echo "export PIP_REQUIRE_VIRTUALENV=false" > "$ACTIVATE"
    echo "export PIP_REQUIRE_VIRTUALENV=true" > "$DEACTIVATE"

    # switch off PIP_REQUIRE_VIRTUALENV in the current session as well
    export PIP_REQUIRE_VIRTUALENV=false
}

# Check package exists
function checkPackageExists() {
    local PackageName=${1:-""}
    local PackageInfo=""

    [[ -n "${PackageName}" ]] || return 1

    if [[ -x "$(command -v apt-cache)" ]]; then
        PackageInfo=$(apt-cache search --names-only "^${PackageName}$")
        [[ -n "${PackageInfo}" ]] && return 0 || return 1
    fi

    if [[ -x "$(command -v dnf)" ]]; then
        dnf info "${PackageName}" >/dev/null 2>&1 && return 0 || return 1
    fi

    if [[ "$(command -v yay)" ]]; then
        yay -Si "${PackageName}" >/dev/null 2>&1 && return 0 || return 1
    fi

    if [[ -x "$(command -v pacman)" ]]; then
        # pacman -Si "${PackageName}" >/dev/null 2>&1 && return 0 || return 1
        if PackageInfo=$(pacman -Si "${PackageName}" 2>&1); then
            [[ "${PackageInfo}" =~ "Error:" || "${PackageInfo}" =~ "error:" ]] && return 1 || return 0
        fi
    fi

    return 1
}

# Check package is installed
function checkPackageInstalled() {
    local PackageName=${1:-""}
    local PackageLocalFiles=""
    local PackageInstalled="no"

    [[ -n "${PackageName}" ]] || return 1
    [[ -x "$(command -v pacman)" ]] || return 1

    if PackageLocalFiles=$(pacman -Ql "${PackageName##*/}" 2>&1); then
        PackageInstalled="yes"
    else
        if [[ "${PackageLocalFiles}" == *"unimplemented"* ]]; then
            if pacman -Qi "${PackageName##*/}" >/dev/null 2>&1; then
                PackageInstalled="yes"
            fi
        fi
    fi

    [[ "${PackageInstalled}" == "yes" ]] && return 0 || return 1
}

# Check package exist and is not installed
function checkPackageNeedInstall() {
    local PackageName=${1:-""}
    local PackageExist="yes"

    [[ -n "${PackageName}" ]] || return 1
    [[ -x "$(command -v pacman)" ]] || return 1

    if ! checkPackageExists "${PackageName}"; then
        PackageExist="no"
    fi

    if [[ "${PackageExist}" == "yes" ]]; then
        if ! checkPackageInstalled "${PackageName}"; then
            return 0
        fi
    fi

    return 1
}

# Install system built-in repo packages
# PackagesList=(cmake make) && InstallSystemPackages "${BLUE}Checking Pre-requisite packages..." "${PackagesList[@]}"
function InstallSystemPackages() {
    local PreInstallMsg="$1"
    shift
    local InstallList=("$@")
    local PackagesToInstall=()
    local TargetPackage

    [[ -n "${PreInstallMsg}" ]] && colorEcho "${PreInstallMsg}"
    for TargetPackage in "${InstallList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            PackagesToInstall+=("${TargetPackage}")
        fi
    done

    if [[ -n "${PackagesToInstall[*]}" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${PackagesToInstall[*]}${BLUE}..."
        sudo pacman --noconfirm -S "${PackagesToInstall[@]}"
    fi
}

# App installer
function Get_Installer_CURL_Options() {
    local opts

    [[ -z "${READ_ARRAY_OPTS[*]}" ]] && Get_Read_Array_Options

    CURL_CHECK_OPTS=()
    if [[ -n "${INSTALLER_CHECK_CURL_OPTION}" ]]; then
        if ! IFS=" " read -r "${READ_ARRAY_OPTS[@]}" CURL_CHECK_OPTS <<<"${INSTALLER_CHECK_CURL_OPTION}" 2>/dev/null; then
            while read -r opts; do
                CURL_CHECK_OPTS+=("${opts}")
            done < <(tr ' ' '\n'<<<"${INSTALLER_CHECK_CURL_OPTION}")
        fi
    fi
    [[ -z "${CURL_CHECK_OPTS[*]}" ]] && CURL_CHECK_OPTS=(-fsL)

    CURL_DOWNLOAD_OPTS=()
    if [[ -n "${INSTALLER_DOWNLOAD_CURL_OPTION}" ]]; then
        if ! IFS=" " read -r "${READ_ARRAY_OPTS[@]}" CURL_DOWNLOAD_OPTS <<<"${INSTALLER_DOWNLOAD_CURL_OPTION}" 2>/dev/null; then
            while read -r opts; do
                CURL_DOWNLOAD_OPTS+=("${opts}")
            done < <(tr ' ' '\n'<<<"${INSTALLER_DOWNLOAD_CURL_OPTION}")
        fi
    fi
    [[ -z "${CURL_DOWNLOAD_OPTS[*]}" ]] && CURL_DOWNLOAD_OPTS=(-fSL)

    return 0
}

function Get_Installer_AXEL_Options() {
    local opts

    [[ -z "${READ_ARRAY_OPTS[*]}" ]] && Get_Read_Array_Options

    AXEL_DOWNLOAD_OPTS=()
    if [[ -n "${INSTALLER_DOWNLOAD_AXEL_OPTION}" ]]; then
        if ! IFS=" " read -r "${READ_ARRAY_OPTS[@]}" AXEL_DOWNLOAD_OPTS <<<"${INSTALLER_DOWNLOAD_AXEL_OPTION}" 2>/dev/null; then
            while read -r opts; do
                AXEL_DOWNLOAD_OPTS+=("${opts}")
            done < <(echo "${INSTALLER_DOWNLOAD_AXEL_OPTION}" | tr ' ' '\n')
        fi
    fi
    [[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && AXEL_DOWNLOAD_OPTS=(--num-connections=5 --timeout=30 --alternate)

    return 0
}

# Get os type & architecture that match running platform
function App_Installer_Get_OS_Info_Match_Cond() {
    OS_INFO_UNMATCH_COND=""

    [[ -z "${OS_INFO_RELEASE}" ]] && get_os_release
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch
    [[ -z "${OS_INFO_FLOAT}" ]] && get_arch_float
    [[ -z "${CPU_ARCH_LEVEL}" ]] && get_cpu_arch_level

    OS_INFO_MATCH_RELEASE="${OS_INFO_RELEASE}"
    OS_INFO_MATCH_OPENWRT_BOARD=""
    OS_INFO_MATCH_OPENWRT_ARCH=""
    case "${OS_INFO_RELEASE}" in
        android)
            OS_INFO_MATCH_RELEASE="${OS_INFO_MATCH_RELEASE}|Android|ANDROID"
            ;;
        openwrt)
            OS_INFO_MATCH_RELEASE="${OS_INFO_MATCH_RELEASE}|OpenWrt|OpenWRT|OPENWRT"
            # Filename like: *-openwrt-aarch64_cortex-a53*
            # OPENWRT_BOARD="mediatek/mt7622"
            [[ -r "/etc/os-release" ]] && OS_INFO_MATCH_OPENWRT_BOARD="$(. /etc/os-release && echo "$OPENWRT_BOARD")"
            # OPENWRT_ARCH="aarch64_cortex-a53"
            [[ -r "/etc/os-release" ]] && OS_INFO_MATCH_OPENWRT_ARCH="$(. /etc/os-release && echo "$OPENWRT_ARCH")"
            ;;
    esac

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
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|x86_64|x86-64|x64|64bit"
            [[ -n "${OS_INFO_TYPE}" ]] && OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|${OS_INFO_TYPE}64" # linux64
            ;;
        386)
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|486|586|686|x86|32bit|ia32"
            [[ -n "${OS_INFO_TYPE}" ]] && OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|${OS_INFO_TYPE}32" # linux32

            [[ -z "${OS_INFO_UNMATCH_COND}" ]] \
                && OS_INFO_UNMATCH_COND="x86_64|x86-64|x64|64bit" \
                || OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|x86_64|x86-64|x64|64bit"

            [[ -n "${OS_INFO_TYPE}" ]] && OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|${OS_INFO_TYPE}64" # linux64
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
            OS_INFO_MATCH_FLOAT="${OS_INFO_MATCH_FLOAT}|armeabi|armel|gnueabi|musleabi"
            [[ -z "${OS_INFO_UNMATCH_COND}" ]] \
                && OS_INFO_UNMATCH_COND="gnueabihf|musleabihf" \
                || OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|gnueabihf|musleabihf"
            ;;
    esac

    # [sing-box](https://github.com/SagerNet/sing-box/blob/main/.goreleaser.yaml)
    # [Clash.Meta](https://github.com/MetaCubeX/Clash.Meta/blob/Meta/Makefile)
    OS_INFO_MATCH_CPU_LEVEL=""
    [[ CPU_ARCH_LEVEL -le 2 ]] && OS_INFO_MATCH_CPU_LEVEL="amd64-compatible|amd64v1|amd64v2"
    [[ CPU_ARCH_LEVEL -ge 3 ]] && OS_INFO_MATCH_CPU_LEVEL="amd64v3|amd64-v3"
}

# Get release version from github repository using github API or extract from github release page
function App_Installer_Get_Remote_Version() {
    local remote_url=$1
    local version_match_pattern=$2
    local jq_match_pattern

    [[ -z "${remote_url}" && -n "${INSTALLER_CHECK_URL}" ]] && remote_url="${INSTALLER_CHECK_URL}"
    [[ -z "${remote_url}" && -n "${INSTALLER_GITHUB_REPO}" ]] && remote_url="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"

    [[ -z "${remote_url}" ]] && colorEcho "${FUCHSIA}REMOTE URL${RED} can't empty!" && return 1

    INSTALLER_VER_REMOTE=""
    INSTALLER_REMOTE_CONTENT=""

    [[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

    # Get app version
    INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)

    # Github repos
    [[ "${remote_url}" == "https://api.github.com/repos/"* ]] && jq_match_pattern=".tag_name"

    if [[ -z "${INSTALLER_REMOTE_CONTENT}" && "${remote_url}" == "https://api.github.com/repos/"* ]]; then
        jq_match_pattern=""
        if [[ -n "${GITHUB_API_TOKEN}" ]]; then
            # Use Github API token to fix rate limit exceeded
            INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" -H "Authorization: token ${GITHUB_API_TOKEN}" "${remote_url}" 2>/dev/null)
        fi

        # Extract from github release page
        if [[ -z "${INSTALLER_REMOTE_CONTENT}" ]]; then
            remote_url="${remote_url//api.github.com\/repos/github.com}"
            INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)

            if [[ -n "${INSTALLER_REMOTE_CONTENT}" ]]; then
                INSTALLER_FROM_GITHUB_RELEASE="yes"
                INSTALLER_VER_REMOTE=$(grep '<title>' <<<"${INSTALLER_REMOTE_CONTENT}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
                [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(grep 'Release' <<<"${INSTALLER_REMOTE_CONTENT}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
                [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' <<<"${INSTALLER_REMOTE_CONTENT}" | head -n1)
            fi
        fi
    fi

    [[ -z "${INSTALLER_REMOTE_CONTENT}" ]] && colorEcho "${RED}  Can't get latest version from ${FUCHSIA}${remote_url}${RED}!" && return 1

    # use `jq` if start with `jq=`
    # `jq=.tag_name` `jq=.channels.Stable.version`
    if grep -q -E "^jq=" <<<"${version_match_pattern}"; then
        version_match_pattern="${version_match_pattern/jq=/}"
        if grep -q -E "@" <<<"${version_match_pattern}"; then
            jq_match_pattern=$(awk -F@ '{print $1}' <<<"${version_match_pattern}")
            version_match_pattern=$(awk -F@ '{print $2}' <<<"${version_match_pattern}")
        else
            jq_match_pattern="${version_match_pattern}"
            version_match_pattern=""
        fi
    fi

    if [[ -z "${INSTALLER_VER_REMOTE}" && -n "${jq_match_pattern}" ]]; then
        INSTALLER_VER_REMOTE=$(jq -r "${jq_match_pattern}//empty" 2>/dev/null <<<"${INSTALLER_REMOTE_CONTENT}" | cut -d'v' -f2)
        [[ -n "${version_match_pattern}" ]] && INSTALLER_VER_REMOTE=$(grep -E "${version_match_pattern}" <<<"${INSTALLER_VER_REMOTE}")
    fi

    [[ -z "${INSTALLER_VER_REMOTE}" && -n "${version_match_pattern}" ]] && \
        INSTALLER_VER_REMOTE=$(grep -E "${version_match_pattern}" <<<"${INSTALLER_REMOTE_CONTENT}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)

    [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' <<<"${INSTALLER_REMOTE_CONTENT}" | head -n1)

    [[ -n "${INSTALLER_VER_REMOTE}" ]] && return 0 || return 1
}

# Get remote file download address from given url that match running platform
function App_Installer_Get_Remote_URL() {
    # INSTALLER_VER_REMOTE: release version
    # INSTALLER_DOWNLOAD_URL: download address that match running platform
    # The download filename should contain at least one of the platform type or architecture, like: `rclone-v1.56.2-linux-amd64.zip`
    # Usage:
    # App_Installer_Get_Remote_URL "https://api.github.com/repos/rclone/rclone/releases/latest"
    # App_Installer_Get_Remote_URL "https://api.github.com/repos/jarun/nnn/releases/latest" "nnn-nerd-.*\.tar\.gz"
    # App_Installer_Get_Remote_URL "https://dev.yorhel.nl/ncdu" 'ncdu-[^<>:;,?"*|/]+\.tar\.gz' "ncdu-.*\.tar\.gz"
    local remote_url=$1
    local file_match_pattern=$2
    local version_match_pattern=$3
    local multi_match_filter=$4
    local match_urls match_result match_cnt jq_match_pattern
    local match_result_release match_result_type match_result_arch match_result_float match_result_cpu_level

    [[ -z "${remote_url}" ]] && colorEcho "${FUCHSIA}REMOTE URL${RED} can't empty!" && return 1

    INSTALLER_DOWNLOAD_URL=""

    [[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
    [[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

    # Get app version
    if [[ -z "${INSTALLER_REMOTE_CONTENT}" ]]; then
        [[ -n "${INSTALLER_APP_NAME}" ]] && colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
        App_Installer_Get_Remote_Version "${remote_url}" "${version_match_pattern}"
    fi

    [[ -z "${INSTALLER_REMOTE_CONTENT}" ]] && return 1

    if [[ "${remote_url}" == "https://api.github.com/repos/"* ]]; then
        # Extract download urls from github release expanded_assets
        if [[ "${INSTALLER_FROM_GITHUB_RELEASE}" == "yes" ]]; then
            jq_match_pattern=""
            remote_url=$(grep '/expanded_assets/' <<<"${INSTALLER_REMOTE_CONTENT}" \
                | grep -o -P "(((ht|f)tps?):\/\/)+[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?" \
                | head -n1)
            [[ -n "${remote_url}" ]] && INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)

            if [[ -n "${INSTALLER_REMOTE_CONTENT}" ]]; then
                INSTALLER_REMOTE_CONTENT=$(sed 's|<a href="/|<a href="https://github.com/|g' <<<"${INSTALLER_REMOTE_CONTENT}" | grep '/releases/download/')
            fi
        else
            jq_match_pattern=".assets[].browser_download_url"
        fi

        [[ -z "${INSTALLER_REMOTE_CONTENT}" ]] && return 1
    fi

    # use `jq` if start with `jq=`
    # `jq=.assets[].browser_download_url#\.tar\.gz` `jq=.channels.Stable.downloads.chrome[].url`
    if grep -q -E "^jq=" <<<"${file_match_pattern}"; then
        file_match_pattern="${file_match_pattern/jq=/}"
        if grep -q -E "#" <<<"${file_match_pattern}"; then
            jq_match_pattern=$(awk -F# '{print $1}' <<<"${file_match_pattern}")
            file_match_pattern=$(awk -F# '{print $2}' <<<"${file_match_pattern}")
        else
            jq_match_pattern="${file_match_pattern}"
            file_match_pattern=""
        fi
    fi

    # Default match pattern & filter
    [[ -z "${file_match_pattern}" ]] && file_match_pattern="\.zip|\.bz|\.gz|\.xz|\.tbz|\.tgz|\.txz|\.7z"
    [[ -z "${multi_match_filter}" ]] && multi_match_filter="musl|static"

    # Get download urls
    if [[ -n "${jq_match_pattern}" ]]; then
        match_urls=$(jq -r "${jq_match_pattern}//empty" 2>/dev/null <<<"${INSTALLER_REMOTE_CONTENT}")
    fi

    if [[ -n "${file_match_pattern}" ]]; then
        if [[ -z "${match_urls}" ]]; then
            match_urls=$(grep -E "${file_match_pattern}" <<<"${INSTALLER_REMOTE_CONTENT}" \
                | grep -o -P "(((ht|f)tps?):\/\/)+[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?")
        else
            match_urls=$(grep -E "${file_match_pattern}" <<<"${match_urls}")
        fi
    fi

    [[ -z "${match_urls}" ]] && match_urls=$(grep -Eo "${file_match_pattern}" <<<"${INSTALLER_REMOTE_CONTENT}")

    # Get urls which match running platform
    [[ -z "${OS_INFO_MATCH_TYPE}" ]] && App_Installer_Get_OS_Info_Match_Cond

    # Filter download urls by unmatching condition
    if [[ -n "${OS_INFO_UNMATCH_COND}" ]]; then
        match_urls=$(grep -Evi "${OS_INFO_UNMATCH_COND}" <<<"${match_urls}")
    fi

    match_result_release=""
    match_result_type=""
    match_result_arch=""
    match_result_float=""
    match_result_cpu_level=""

    if [[ -n "${OS_INFO_MATCH_RELEASE}" ]]; then
        match_result_release=$(grep -Ei "${OS_INFO_MATCH_RELEASE}" <<<"${match_urls}")
        [[ -n "${match_result_release}" ]] && match_urls="${match_result_release}"
        # openwrt arch
        if [[ -n "${OS_INFO_MATCH_OPENWRT_ARCH}" ]]; then
            match_result_release=$(grep -Ei "${OS_INFO_MATCH_OPENWRT_ARCH}" <<<"${match_urls}")
            [[ -n "${match_result_release}" ]] && match_urls="${match_result_release}"
        fi
    fi

    if [[ -n "${OS_INFO_MATCH_TYPE}" ]]; then
        match_result_type=$(grep -Ei "${OS_INFO_MATCH_TYPE}" <<<"${match_urls}")
        [[ -n "${match_result_type}" ]] && match_urls="${match_result_type}"
    fi

    if [[ -n "${OS_INFO_MATCH_ARCH}" ]]; then
        match_result_arch=$(grep -Ei "${OS_INFO_MATCH_ARCH}" <<<"${match_urls}")
        [[ -n "${match_result_arch}" ]] && match_urls="${match_result_arch}"
    fi

    # Not match any of the platform type & architecture
    # [[ -z "${match_result_type}" && -z "${match_result_arch}" ]] && match_urls=""

    if [[ -n "${OS_INFO_MATCH_FLOAT}" ]]; then
        match_result_float=$(grep -Ei "${OS_INFO_MATCH_FLOAT}" <<<"${match_urls}")
        [[ -n "${match_result_float}" ]] && match_urls="${match_result_float}"
    fi

    if [[ -n "${OS_INFO_MATCH_CPU_LEVEL}" ]]; then
        match_result_cpu_level=$(grep -Ei "${OS_INFO_MATCH_CPU_LEVEL}" <<<"${match_urls}")
        [[ -n "${match_result_cpu_level}" ]] && match_urls="${match_result_cpu_level}"
    fi

    # Filter more than one file
    match_cnt=$(wc -l <<<"${match_urls}")
    if [[ ${match_cnt} -gt 1 ]] && [[ -n "${multi_match_filter}" ]]; then
        match_result=$(grep -Ei "${multi_match_filter}" <<<"${match_urls}")
        [[ -n "${match_result}" ]] && match_urls="${match_result}"
    fi

    [[ -n "${match_urls}" ]] && INSTALLER_DOWNLOAD_URL=$(head -n1 <<<"${match_urls}")

    [[ -n "${INSTALLER_DOWNLOAD_URL}" ]] && return 0 || return 1
}

# Download
function App_Installer_Download() {
    local download_url=$1
    local download_filename=$2
    local github_url="https://github.com"
    local remote_filename

    [[ -z "${download_url}" ]] && colorEcho "${FUCHSIA}Download URL${RED} can't empty!" && return 1

    remote_filename=$(echo "${download_url}" | awk -F"/" '{print $NF}')
    [[ -z "${download_filename}" ]] && download_filename="${remote_filename}"

    # Download
    [[ -n "${GITHUB_DOWNLOAD_URL}" ]] && download_url="${download_url//${github_url}/${GITHUB_DOWNLOAD_URL}}"
    colorEcho "${BLUE}  From ${ORANGE}${download_url}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}"
    curl_rtn_code=$?

    if [[ ${curl_rtn_code} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        download_url="${download_url//${GITHUB_DOWNLOAD_URL}/${github_url}}"
        colorEcho "${BLUE}  From ${ORANGE}${download_url}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}"
        curl_rtn_code=$?
    fi

    [[ ${curl_rtn_code} -eq 0 ]] && return 0 || return 1
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
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}"
    curl_rtn_code=$?

    if [[ ${curl_rtn_code} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        download_url="${download_url//${GITHUB_DOWNLOAD_URL}/${github_url}}"
        colorEcho "${BLUE}  From ${ORANGE}${download_url}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}"
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
            ".tar"
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
            ".tar")
                tar -xf "${download_filename}" -C "${workdir}" || extract_rtn_code=$?
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

# Get archive file extension
function App_Installer_Get_Archive_File_Extension() {
    local filename=$1
    local archive_ext_list archive_ext TargetExt

    [[ -z "${filename}" ]] && colorEcho "${FUCHSIA}Filename${RED} can't empty!" && return 1

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
        ".tar"
        ".bz2"
        ".bz"
        ".gz"
        ".xz"
        ".zip"
        ".7z"
    )
    for TargetExt in "${archive_ext_list[@]}"; do
        if echo "${filename}" | grep -q "${TargetExt}$"; then
            archive_ext="${TargetExt}"
            break
        fi
    done

    INSTALLER_ARCHIVE_EXT="${archive_ext}"

    [[ -n "${INSTALLER_ARCHIVE_EXT}" ]] && return 0 || return 1
}

# Extract archive file
function Archive_File_Extract() {
    local filename=$1
    local workdir=$2
    local archive_ext_list archive_ext TargetExt
    local extract_rtn_code

    [[ -z "${filename}" ]] && colorEcho "${FUCHSIA}Filename${RED} can't empty!" && return 1

    [[ -z "${workdir}" ]] && workdir="$(pwd)"

    extract_rtn_code=0
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
        ".tar"
        ".bz2"
        ".bz"
        ".gz"
        ".xz"
        ".zip"
        ".7z"
    )
    for TargetExt in "${archive_ext_list[@]}"; do
        if echo "${filename}" | grep -q "${TargetExt}$"; then
            archive_ext="${TargetExt}"
            break
        fi
    done

    [[ -z "${archive_ext}" ]] && return 1

    case "${archive_ext}" in
        ".zip")
            unzip -qo "${filename}" -d "${workdir}" || extract_rtn_code=$?
            ;;
        ".tar.bz2" | ".tar.bz" | ".tbz2" | ".tbz")
            tar -xjf "${filename}" -C "${workdir}" || extract_rtn_code=$?
            ;;
        ".tar.gz" | ".tgz")
            tar -xzf "${filename}" -C "${workdir}" || extract_rtn_code=$?
            ;;
        ".tar.xz" | ".txz")
            tar -xJf "${filename}" -C "${workdir}" || extract_rtn_code=$?
            ;;
        ".tar")
            tar -xf "${filename}" -C "${workdir}" || extract_rtn_code=$?
            ;;
        ".bz2" | ".bz")
            cd "${workdir}" || return 1
            bzip2 -df "${filename}" || extract_rtn_code=$?
            ;;
        ".gz")
            cd "${workdir}" || return 1
            gzip -df "${filename}" || extract_rtn_code=$?
            ;;
        ".xz")
            cd "${workdir}" || return 1
            xz -df "${filename}" || extract_rtn_code=$?
            ;;
        ".7z")
            7z e "${filename}" -o"${workdir}" || extract_rtn_code=$?
            ;;
    esac

    if [[ ${extract_rtn_code} -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Reset app installer variables
function App_Installer_Reset() {
    INSTALLER_APP_NAME=""
    INSTALLER_GITHUB_REPO=""

    INSTALLER_IS_INSTALL="yes"
    INSTALLER_IS_UPDATE="no"

    if [[ -n "$PREFIX" ]]; then
        # Termux for Android
        INSTALLER_INSTALL_PATH="$PREFIX/bin"
        INSTALLER_MANPAGE_PATH="$PREFIX/share/man"
        INSTALLER_ZSH_FUNCTION_PATH="$PREFIX/share/zsh/site-functions"
    else
        INSTALLER_INSTALL_PATH="/usr/local/bin"
        INSTALLER_MANPAGE_PATH="/usr/share/man"
        INSTALLER_ZSH_FUNCTION_PATH="/usr/local/share/zsh/site-functions"
    fi

    INSTALLER_INSTALL_METHOD=""
    INSTALLER_INSTALL_NAME=""
    INSTALLER_EXEC_FULLNAME=""

    INSTALLER_CHECK_URL=""
    INSTALLER_REMOTE_CONTENT=""
    INSTALLER_DOWNLOAD_URL=""
    INSTALLER_DOWNLOAD_FILE=""

    INSTALLER_VER_CURRENT="0.0.0"
    INSTALLER_VER_REMOTE=""
    INSTALLER_VER_FILE=""

    INSTALLER_ARCHIVE_EXT=""
    INSTALLER_ARCHIVE_ROOT=""
    INSTALLER_ARCHIVE_EXEC_DIR=""
    INSTALLER_ARCHIVE_EXEC_NAME=""

    INSTALLER_FILE_PATH=""
    INSTALLER_FILE_NAME=""
    INSTALLER_FILE_SUFFIX=""

    INSTALLER_ZSH_COMP_FILE=""
    INSTALLER_ZSH_COMP_INSTALL=""

    INSTALLER_CHOICE="N"
    INSTALLER_FROM_GITHUB_RELEASE="no"

    # additional downloads: Filename#URL#Install_File_Full_Path
    # e.g.: `cross/mihomo_installer.sh`
    INSTALLER_ADDON_FILES=()

    INSTALLER_INSTALL_LOGFILE="$HOME/.dotfiles.installer.log"

    [[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
    [[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options
}

# Install app from github releases or given url
function App_Installer_Install() {
    # Usage:
    # App_Installer "https://api.github.com/repos/rclone/rclone/releases/latest"
    #
    # The following variables need to be set before executing the function:
    # WORKDIR INSTALLER_APP_NAME INSTALLER_GITHUB_REPO INSTALLER_INSTALL_NAME
    # INSTALLER_ARCHIVE_EXT INSTALLER_ARCHIVE_EXEC_DIR INSTALLER_ARCHIVE_EXEC_NAME
    #
    # Check `installer/zoxide_installer.sh` or `installer/ncdu_installer.sh` or `installer/earthly_installer.sh` or `installer/lazygit_installer.sh` as example
    local remote_url=$1
    local exec_list exec_name app_installed finded_file install_files install_filename
    local addon_download addon_name addon_url addon_file addon_dir addon_installed

    [[ "${INSTALLER_IS_INSTALL}" != "yes" ]] && return 0

    [[ -z "${remote_url}" ]] && remote_url="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"

    # get app remote version & download link that match running platform
    if [[ -z "${INSTALLER_DOWNLOAD_URL}" ]]; then
        if [[ -z "${INSTALLER_ARCHIVE_EXT}" && -n "${INSTALLER_ARCHIVE_EXEC_NAME}" ]]; then
            App_Installer_Get_Remote_URL "${remote_url}" "${INSTALLER_ARCHIVE_EXEC_NAME}"
        else
            App_Installer_Get_Remote_URL "${remote_url}"
        fi
    fi

    if [[ -z "${INSTALLER_VER_REMOTE}" || -z "${INSTALLER_DOWNLOAD_URL}" ]]; then
        INSTALLER_IS_INSTALL="nomatch"
    else
        version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}" && INSTALLER_IS_INSTALL="no"
    fi

    [[ "${INSTALLER_IS_INSTALL}" != "yes" ]] && return 0

    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    [[ -z "${WORKDIR}" ]] && WORKDIR="$(pwd)"

    # download filename & execute filename in archive
    if [[ -n "${INSTALLER_INSTALL_NAME}" ]]; then
        INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_INSTALL_NAME}"
        [[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"
    else
        INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_APP_NAME}"
        [[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_APP_NAME}"
    fi

    [[ -z "${INSTALLER_ARCHIVE_EXT}" ]] && App_Installer_Get_Archive_File_Extension "${INSTALLER_DOWNLOAD_URL}"
    [[ -n "${INSTALLER_ARCHIVE_EXT}" ]] && INSTALLER_DOWNLOAD_FILE="${INSTALLER_DOWNLOAD_FILE}.${INSTALLER_ARCHIVE_EXT}"

    # download & extract file
    if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}" "${INSTALLER_DOWNLOAD_FILE}" "${WORKDIR}"; then
        [[ -n "${INSTALLER_ARCHIVE_EXEC_DIR}" ]] && INSTALLER_ARCHIVE_EXEC_DIR=$(find "${WORKDIR}" -type d -name "${INSTALLER_ARCHIVE_EXEC_DIR}")
        [[ -z "${INSTALLER_ARCHIVE_EXEC_DIR}" || ! -d "${INSTALLER_ARCHIVE_EXEC_DIR}" ]] && INSTALLER_ARCHIVE_EXEC_DIR="${WORKDIR}"

        [[ -z "${INSTALLER_ARCHIVE_ROOT}" || ! -d "${INSTALLER_ARCHIVE_ROOT}" ]] && INSTALLER_ARCHIVE_ROOT="${INSTALLER_ARCHIVE_EXEC_DIR}"

        # wildchar match
        if grep -q '\*' <<<"${INSTALLER_ARCHIVE_EXEC_NAME}"; then
            if [[ -n "${INSTALLER_ARCHIVE_EXT}" ]]; then
                if [[ -n "${INSTALLER_ZSH_COMP_FILE}" ]]; then
                    INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}" \
                        -not \( -name "*.${INSTALLER_ARCHIVE_EXT}" -or -name "${INSTALLER_ZSH_COMP_FILE}" \
                                -or -name "*.[[:digit:]]" -or -name "*completion*" -or -path "*completion*" \) )
                else
                    INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}" \
                        -not \( -name "*.${INSTALLER_ARCHIVE_EXT}" -or -name "*.[[:digit:]]" -or -name "*completion*" -or -path "*completion*" \) )
                fi
            else
                if [[ -n "${INSTALLER_ZSH_COMP_FILE}" ]]; then
                    INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}" \
                        -not \( -name "${INSTALLER_ZSH_COMP_FILE}" -or -name "*.[[:digit:]]" -or -name "*completion*" -or -path "*completion*" \) )
                else
                    INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}" \
                        -not \( -name "*.[[:digit:]]" -or -name "*completion*" -or -path "*completion*" \) )
                fi
            fi

            if [[ -f "${INSTALLER_ARCHIVE_EXEC_NAME}" ]]; then
                INSTALLER_ARCHIVE_EXEC_DIR=$(dirname "${INSTALLER_ARCHIVE_EXEC_NAME}")
                INSTALLER_ARCHIVE_EXEC_NAME=$(basename "${INSTALLER_ARCHIVE_EXEC_NAME}")
            else
                INSTALLER_ARCHIVE_EXEC_DIR="${WORKDIR}"
                if [[ -n "${INSTALLER_INSTALL_NAME}" ]]; then
                    INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"
                else
                    INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_APP_NAME}"
                fi
            fi
        fi

        # maybe more than one execute file
        # INSTALLER_ARCHIVE_EXEC_NAME="trzsz trz tsz"
        exec_list=()
        if grep -q ' ' <<<"${INSTALLER_ARCHIVE_EXEC_NAME}"; then
            [[ -z "${READ_ARRAY_OPTS[*]}" ]] && Get_Read_Array_Options

            if ! IFS=" " read -r "${READ_ARRAY_OPTS[@]}" exec_list <<<"${INSTALLER_ARCHIVE_EXEC_NAME}" 2>/dev/null; then
                while read -r exec_name; do
                    exec_list+=("${exec_name}")
                done < <(tr ' ' '\n' <<<"${INSTALLER_ARCHIVE_EXEC_NAME}")
            fi
        else
            if [[ ! -f "${INSTALLER_ARCHIVE_EXEC_DIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]]; then
                if [[ -n "${INSTALLER_INSTALL_NAME}" ]]; then
                    INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"
                else
                    INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_APP_NAME}"
                fi
            fi
        fi
        [[ -z "${exec_list[*]}" ]] && exec_list=("${INSTALLER_ARCHIVE_EXEC_NAME}")

        # install app
        app_installed="no"
        echo "[$(date +%FT%T%:z)] ${INSTALLER_APP_NAME} ${INSTALLER_VER_REMOTE} ${INSTALLER_DOWNLOAD_URL}" >> "${INSTALLER_INSTALL_LOGFILE}"
        for exec_name in "${exec_list[@]}"; do
            [[ -z "${exec_name}" ]] && continue

            if [[ ! -f "${INSTALLER_ARCHIVE_EXEC_DIR}/${exec_name}" ]]; then
                exec_name=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${exec_name}")
                INSTALLER_ARCHIVE_EXEC_DIR=$(dirname "${exec_name}") && exec_name=$(basename "${exec_name}")
            fi
            [[ -z "${exec_name}" ]] && continue

            finded_file="${INSTALLER_ARCHIVE_EXEC_DIR}/${exec_name}"
            [[ ! -f "${finded_file}" ]] && continue

            [[ -n "${INSTALLER_INSTALL_NAME}" ]] && install_filename="${INSTALLER_INSTALL_NAME}" || install_filename="${exec_name}"

            sudo cp -f "${finded_file}" "${INSTALLER_INSTALL_PATH}/${install_filename}" && \
                sudo chmod +x "${INSTALLER_INSTALL_PATH}/${install_filename}" && \
                app_installed="yes" && \
                colorEcho "${GREEN}  Installed: ${YELLOW}${INSTALLER_INSTALL_PATH}/${install_filename}" && \
                echo "[$(date +%FT%T%:z)] ${INSTALLER_APP_NAME} ${INSTALLER_INSTALL_PATH}/${install_filename}" >> "${INSTALLER_INSTALL_LOGFILE}"

            rm -f "${finded_file}"
        done

        # man pages, zsh completions
        if [[ "${app_installed}" == "yes" ]]; then
            # write version to file
            [[ -n "${INSTALLER_VER_FILE}" ]] && echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_VER_FILE}" >/dev/null || true

            # man pages (man1..man8)
            for ((i=1; i <= 8; ++i)); do
                [[ ! -d "${INSTALLER_MANPAGE_PATH}/man${i}" ]] && sudo mkdir -p "${INSTALLER_MANPAGE_PATH}/man${i}"
                [[ ! -d "${INSTALLER_MANPAGE_PATH}/man${i}" ]] && continue
                install_files=$(find "${INSTALLER_ARCHIVE_ROOT}" -type f -name "*.${i}")
                while read -r finded_file; do
                    [[ ! -f "${finded_file}" ]] && continue
                    install_filename=$(basename "${finded_file}")
                    sudo cp -f "${finded_file}" "${INSTALLER_MANPAGE_PATH}/man${i}/${install_filename}" && \
                        colorEcho "${GREEN}  Installed: ${YELLOW}${INSTALLER_MANPAGE_PATH}/man${i}/${install_filename}" && \
                        echo "[$(date +%FT%T%:z)] ${INSTALLER_APP_NAME} ${INSTALLER_MANPAGE_PATH}/man${i}/${install_filename}" >> "${INSTALLER_INSTALL_LOGFILE}"

                    rm -f "${finded_file}"
                done <<<"${install_files}"
            done

            # zsh completions
            if [[ -n "${INSTALLER_ZSH_COMP_FILE}" ]]; then
                [[ ! -d "${INSTALLER_ZSH_FUNCTION_PATH}" ]] && sudo mkdir -p "${INSTALLER_ZSH_FUNCTION_PATH}"
                install_files=$(find "${INSTALLER_ARCHIVE_ROOT}" -type f -name "${INSTALLER_ZSH_COMP_FILE}")
                while read -r finded_file; do
                    [[ ! -f "${finded_file}" ]] && continue
                    [[ ! -d "${INSTALLER_ZSH_FUNCTION_PATH}" ]] && continue
                    [[ -n "${INSTALLER_ZSH_COMP_INSTALL}" ]] && install_filename="${INSTALLER_ZSH_COMP_INSTALL}" || install_filename=$(basename "${finded_file}")
                    sudo cp -f "${finded_file}" "${INSTALLER_ZSH_FUNCTION_PATH}/${install_filename}" && \
                        sudo chmod 644 "${INSTALLER_ZSH_FUNCTION_PATH}/${install_filename}" && \
                        sudo chown "$(id -u)":"$(id -g)" "${INSTALLER_ZSH_FUNCTION_PATH}/${install_filename}" && \
                        colorEcho "${GREEN}  Installed: ${YELLOW}${INSTALLER_ZSH_FUNCTION_PATH}/${install_filename}" && \
                        echo "[$(date +%FT%T%:z)] ${INSTALLER_APP_NAME} ${INSTALLER_ZSH_FUNCTION_PATH}/${install_filename}" >> "${INSTALLER_INSTALL_LOGFILE}"

                    rm -f "${finded_file}"
                done <<<"${install_files}"
            fi

            # additional downloads
            for addon_download in "${INSTALLER_ADDON_FILES[@]}"; do
                [[ -z "${addon_download}" ]] && continue

                addon_name=$(awk -F# '{print $1}' <<<"${addon_download}")
                addon_url=$(awk -F# '{print $2}' <<<"${addon_download}")
                addon_file=$(awk -F# '{print $3}' <<<"${addon_download}")

                addon_dir=$(dirname "${addon_file}")
                if [[ ! -d "${addon_dir}" ]]; then
                    if ! mkdir -p "${addon_dir}" 2>/dev/null; then
                        if ! sudo mkdir -p "${addon_dir}" 2>/dev/null; then
                            colorEcho "${RED}  Failed to create directory ${YELLOW}${addon_dir}${RED} for ${FUCHSIA}${addon_name}${RED}!"
                            echo "[$(date +%FT%T%:z)] Failed to create directory ${addon_dir} for ${addon_name}" >> "${INSTALLER_INSTALL_LOGFILE}"
                            continue
                        fi
                    fi
                fi

                colorEcho "${BLUE}  Installing ${FUCHSIA}${addon_name}${BLUE}..."
                if App_Installer_Download "${addon_url}" "${WORKDIR}/${addon_name}"; then
                    addon_installed="no"
                    if cp -f "${WORKDIR}/${addon_name}" "${addon_file}" 2>/dev/null; then
                        addon_installed="yes"
                    else
                        if sudo cp -f "${WORKDIR}/${addon_name}" "${addon_file}" 2>/dev/null; then
                            addon_installed="yes"
                        fi
                    fi

                    if [[ "${addon_installed}" == "yes" ]]; then
                        colorEcho "${GREEN}  Installed: ${YELLOW}${addon_file}" && \
                        echo "[$(date +%FT%T%:z)] ${INSTALLER_APP_NAME} ${addon_file}" >> "${INSTALLER_INSTALL_LOGFILE}"
                    else
                        colorEcho "${RED}  Failed to copy ${YELLOW}${addon_name}${RED} to ${FUCHSIA}${addon_file}${RED}!"
                        echo "[$(date +%FT%T%:z)] Failed to copy ${addon_name} to ${addon_file}" >> "${INSTALLER_INSTALL_LOGFILE}"
                    fi
                fi
            done
        else
            colorEcho "${RED}  Can't find ${FUCHSIA}${INSTALLER_ARCHIVE_EXEC_NAME}${RED} in ${YELLOW}${INSTALLER_DOWNLOAD_FILE}!"
            echo "[$(date +%FT%T%:z)] ${INSTALLER_APP_NAME} Can't find ${INSTALLER_ARCHIVE_EXEC_NAME} in ${INSTALLER_DOWNLOAD_FILE}" >> "${INSTALLER_INSTALL_LOGFILE}"
            echo "" >> "${INSTALLER_INSTALL_LOGFILE}"
            return 1
        fi
        echo "" >> "${INSTALLER_INSTALL_LOGFILE}"
    else
        colorEcho "${RED}  Download failed from ${ORANGE}${INSTALLER_DOWNLOAD_URL}${RED}!"
        return 1
    fi

    return 0
}

# Get installed app version
function App_Installer_Get_Installed_Version() {
    local appBinary=$1
    local binaryFile versionFile

    [[ -z "${appBinary}" ]] && colorEcho "${FUCHSIA}App binary name${RED} can't empty!" && return 1

    binaryFile=$(which "${appBinary}" 2>/dev/null)
    [[ -z "${binaryFile}" ]] && INSTALLER_VER_CURRENT="0.0.0" && return 1

    INSTALLER_VER_CURRENT=$(${appBinary} --version 2>/dev/null | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    [[ -z "${INSTALLER_VER_CURRENT}" ]] && INSTALLER_VER_CURRENT=$(${appBinary} -v 2>/dev/null | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    [[ -z "${INSTALLER_VER_CURRENT}" ]] && INSTALLER_VER_CURRENT=$(${appBinary} -V 2>/dev/null | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)

    if [[ -z "${INSTALLER_VER_CURRENT}" ]]; then
        versionFile="${binaryFile}.version"
        [[ -s "${versionFile}" ]] && INSTALLER_VER_CURRENT=$(head -n1 "${versionFile}")
    fi

    [[ -z "${INSTALLER_VER_CURRENT}" ]] && INSTALLER_VER_CURRENT="0.0.0" && return 1

    return 0
}

# Auto extract download address, decompress and install prebuilt binary from given URL
function installPrebuiltBinary() {
    # Usage:
    # installPrebuiltBinary rclone "rclone/rclone" # github releases
    # installPrebuiltBinary nnn "jarun/nnn" "nnn-nerd-.*\.tar\.gz" # github releases
    # installPrebuiltBinary earthly "earthly/earthly" "earthly-*" # github releases
    # installPrebuiltBinary "https://dev.yorhel.nl/ncdu" "/download/ncdu-[^<>:;,?\"*|/]+\.tar\.gz" "ncdu-.*\.tar\.gz" # full URL

    # Or separated by #: binary_name#remote_url#archive_file_extension#file_match_pattern#version_match_pattern#multi_match_filter
    # installPrebuiltBinary 'tspin#bensadeh/tailspin#tar.gz#tspin*' # github releases
    # installPrebuiltBinary 'ncdu#https://dev.yorhel.nl/ncdu#tar.gz#ncdu-[^<>:;,?"*|/]+\.tar\.gz#ncdu-.*\.tar\.gz' # full URL

    # Or use in script, for example: `cross/mihomo_installer.sh`, `installer/ffsend_installer.sh`, `installer/tailsping_installer.sh`
    local binary_name=$1
    local remote_url=$2
    local file_match_pattern=$3
    local version_match_pattern=$4
    local multi_match_filter=$5
    local workdir_self_created="no"
    local binary_installed="no"
    local binary_url_pattern

    [[ -z "${binary_name}" ]] && colorEcho "${FUCHSIA}Binary name${RED} can't empty!" && return 1

    # Reset ENV vars if there is an application installed before
    [[ -n "${INSTALLER_APP_NAME}" || "${INSTALLER_IS_INSTALL}" != "yes" ]] && App_Installer_Reset

    if [[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]]; then
        WORKDIR="$(mktemp -d)"
        [[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)
        workdir_self_created="yes"
    fi

    # maybe: binary_name#remote_url#archive_file_extension#file_match_pattern#version_match_pattern#multi_match_filter
    # tspin#bensadeh/tailspin#tar.gz#tspin*
    # ncdu#https://dev.yorhel.nl/ncdu#tar.gz#ncdu-[^<>:;,?"*|/]+\.tar\.gz#ncdu-.*\.tar\.gz
    if [[ -z "${remote_url}" ]]; then
        binary_url_pattern="${binary_name}"

        binary_name=$(awk -F'#' '{print $1}' <<<"${binary_url_pattern}")
        remote_url=$(awk -F'#' '{print $2}' <<<"${binary_url_pattern}")

        [[ -z "${remote_url}" ]] && colorEcho "${FUCHSIA}URL${RED} can't empty!" && return 1

        INSTALLER_ARCHIVE_EXT=$(awk -F'#' '{print $3}' <<<"${binary_url_pattern}")
        file_match_pattern=$(awk -F'#' '{print $4}' <<<"${binary_url_pattern}")
        version_match_pattern=$(awk -F'#' '{print $5}' <<<"${binary_url_pattern}")
        multi_match_filter=$(awk -F'#' '{print $6}' <<<"${binary_url_pattern}")
    fi

    INSTALLER_APP_NAME="${binary_name}"
    [[ -z "${file_match_pattern}" ]] && INSTALLER_INSTALL_NAME="${binary_name}"

    # github releases: https://api.github.com/repos/${remote_url}/releases/latest
    [[ "${remote_url}" =~ ^(https?://|ftp://) ]] || INSTALLER_GITHUB_REPO="${remote_url}"

    # remote version
    if [[ -z "${INSTALLER_VER_REMOTE}" ]]; then
        colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
        App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    fi

    # installed version
    if [[ -n "${INSTALLER_VER_REMOTE}" && "${INSTALLER_VER_CURRENT}" == "0.0.0" ]]; then
        App_Installer_Get_Installed_Version "${INSTALLER_APP_NAME}"
        if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
            # colorEcho "${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE} already installed!"
            return 0
        fi
    fi

    [[ -n "${file_match_pattern}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${file_match_pattern}"

    if [[ "${remote_url}" =~ ^(https?://|ftp://) ]]; then
        if App_Installer_Get_Remote_URL "${remote_url}" "${file_match_pattern}" "${version_match_pattern}" "${multi_match_filter}"; then
            [[ "${INSTALLER_DOWNLOAD_URL}" =~ ^(https?://|ftp://) ]] || INSTALLER_DOWNLOAD_URL="${remote_url}${INSTALLER_DOWNLOAD_URL}"
            if App_Installer_Install "${remote_url}"; then
                binary_installed="yes"
            fi
        fi
    else
        if App_Installer_Install; then
            binary_installed="yes"
        fi
    fi

    if [[ "${workdir_self_created}" == "yes" ]]; then
        cd "${CURRENT_DIR}" || return 1
        rm -rf "${WORKDIR}"
    fi

    if [[ "${binary_installed}" == "yes" ]]; then
        return 0
    else
        colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
        return 1
    fi
}

## Download and decrypt file that encrypt with OpenSSL
## Using the AES-256-CBC algorithm with key file
## Create a key-file
# openssl rand 256 > keyfile.key
# openssl rand -hex 256 > keyfile.key
# openssl rand -base64 256 > keyfile.key
## Encryption
# openssl enc -e -aes256 -pbkdf2 -in file.txt -out file.enc -kfile keyfile.key
## Decryption
# openssl enc -d -aes256 -pbkdf2 -in file.enc -out file.txt -kfile keyfile.key
function downloadDecryptFile() {
    # Usage: downloadDecryptFile "https://transfer.sh/xxxx/file.enc" "file.enc" "$HOME/keyfile.key" "file.txt"
    local download_url=$1
    local download_filename=$2
    local encrypt_keyfile=$3
    local decrypt_filename=$4
    local remote_filename SaltedStartLine

    [[ -z "${download_url}" ]] && colorEcho "${FUCHSIA}Download URL${RED} can't empty!" && return 1

    remote_filename=$(echo "${download_url}" | awk -F"/" '{print $NF}')
    [[ -z "${download_filename}" ]] && download_filename="${remote_filename}"

    # Download
    colorEcho "${BLUE}Downloading ${FUCHSIA}${download_url}${BLUE} to ${ORANGE}${download_filename}${BLUE}..."
    curl "${CURL_DOWNLOAD_OPTS[@]}" --noproxy "*" -o "${download_filename}" "${download_url}"
    curl_rtn_code=$?

    if [[ ${curl_rtn_code} -eq 0 ]]; then
        if [[ -n "${encrypt_keyfile}" && -n "${decrypt_filename}" ]]; then
            colorEcho "${BLUE}Decrypting ${FUCHSIA}${download_url}${BLUE} to ${ORANGE}${decrypt_filename}${BLUE} using ${CYAN}${encrypt_keyfile}${BLUE}..."
            if ! openssl enc -d -aes256 -pbkdf2 -in "${download_filename}" -out "${decrypt_filename}" -kfile "${encrypt_keyfile}"; then
                return 1
            fi
        fi
    else
        return 1
    fi

    return 0
}
