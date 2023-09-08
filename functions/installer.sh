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

# Check pacakge exists
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

    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch
    [[ -z "${OS_INFO_FLOAT}" ]] && get_arch_float
    [[ -z "${CPU_ARCH_LEVEL}" ]] && get_cpu_arch_level

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
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|x86_64|x64|64bit"
            ;;
        386)
            OS_INFO_MATCH_ARCH="${OS_INFO_MATCH_ARCH}|486|586|686|x86|32bit|ia32"
            [[ -z "${OS_INFO_UNMATCH_COND}" ]] \
                && OS_INFO_UNMATCH_COND="x86_64|x64|64bit" \
                || OS_INFO_UNMATCH_COND="${OS_INFO_UNMATCH_COND}|x86_64|x64|64bit"
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

    [[ -z "${remote_url}" && -n "${INSTALLER_CHECK_URL}" ]] && remote_url="${INSTALLER_CHECK_URL}"
    [[ -z "${remote_url}" && -n "${INSTALLER_GITHUB_REPO}" ]] && remote_url="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"

    [[ -z "${remote_url}" ]] && colorEcho "${FUCHSIA}REMOTE URL${RED} can't empty!" && return 1

    INSTALLER_VER_REMOTE=""
    INSTALLER_REMOTE_CONTENT=""

    [[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

    # Get app version
    INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)
    if [[ -z "${INSTALLER_REMOTE_CONTENT}" && "${remote_url}" == "https://api.github.com/repos/"* ]]; then
        if [[ -n "${GITHUB_API_TOKEN}" ]]; then
            # Use Github API token to fix rate limit exceeded
            INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" -H "Authorization: token ${GITHUB_API_TOKEN}" "${remote_url}" 2>/dev/null)
        fi

        # Extract from github release page
        if [[ -z "${INSTALLER_REMOTE_CONTENT}" ]]; then
            remote_url="${remote_url//api.github.com\/repos/github.com}"
            INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)
        fi

        if [[ -n "${INSTALLER_REMOTE_CONTENT}" ]]; then
            INSTALLER_VER_REMOTE=$(grep '<title>' <<<"${INSTALLER_REMOTE_CONTENT}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
            [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(grep 'Release' <<<"${INSTALLER_REMOTE_CONTENT}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
            [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' <<<"${INSTALLER_REMOTE_CONTENT}" | head -n1)
        fi
    fi

    [[ -z "${INSTALLER_REMOTE_CONTENT}" ]] && colorEcho "${RED}  Can't get latest version from ${FUCHSIA}${remote_url}${RED}!" && return 1

    [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(jq -r '.tag_name//empty' 2>/dev/null <<<"${INSTALLER_REMOTE_CONTENT}" | cut -d'v' -f2)

    [[ -z "${INSTALLER_VER_REMOTE}" && -n "${version_match_pattern}" ]] && \
        INSTALLER_VER_REMOTE=$(grep -E "${version_match_pattern}" <<<"${INSTALLER_REMOTE_CONTENT}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)

    [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' <<<"${INSTALLER_REMOTE_CONTENT}" | head -n1)

    [[ -n "${INSTALLER_VER_REMOTE}" ]] && return 0 || return 1
}

# Get remote file download address from given url that match running platform
function App_Installer_Get_Remote() {
    # INSTALLER_VER_REMOTE: release version
    # INSTALLER_DOWNLOAD_URL: download address that match running platform
    # The download filename should contain at least one of the platform type or architecture, like: `rclone-v1.56.2-linux-amd64.zip`
    # Usage:
    # App_Installer_Get_Remote "https://api.github.com/repos/rclone/rclone/releases/latest"
    # App_Installer_Get_Remote "https://api.github.com/repos/jarun/nnn/releases/latest" "nnn-nerd-.*\.tar\.gz"
    # App_Installer_Get_Remote "https://dev.yorhel.nl/ncdu" 'ncdu-[^<>:;,?"*|/]+\.tar\.gz' "ncdu-.*\.tar\.gz"
    local remote_url=$1
    local file_match_pattern=$2
    local version_match_pattern=$3
    local multi_match_filter=$4
    local match_urls match_result match_cnt
    local match_result_type match_result_arch match_result_float match_result_cpu_level

    [[ -z "${remote_url}" ]] && colorEcho "${FUCHSIA}REMOTE URL${RED} can't empty!" && return 1

    # INSTALLER_VER_REMOTE=""
    INSTALLER_DOWNLOAD_URL=""

    [[ -z "${file_match_pattern}" ]] && file_match_pattern="\.zip|\.bz|\.gz|\.xz|\.tbz|\.tgz|\.txz|\.7z"
    [[ -z "${multi_match_filter}" ]] && multi_match_filter="musl|static"

    [[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
    [[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

    # Get app version
    if [[ -z "${INSTALLER_REMOTE_CONTENT}" ]]; then
        [[ -n "${INSTALLER_APP_NAME}" ]] && colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
        INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)
    fi

    if [[ -z "${INSTALLER_REMOTE_CONTENT}" && "${remote_url}" == "https://api.github.com/repos/"* ]]; then
        if [[ -n "${GITHUB_API_TOKEN}" ]]; then
            # Use Github API token to fix rate limit exceeded
            INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" -H "Authorization: token ${GITHUB_API_TOKEN}" "${remote_url}" 2>/dev/null)
        fi

        # Extract from github release page
        if [[ -z "${INSTALLER_REMOTE_CONTENT}" ]]; then
            remote_url="${remote_url//api.github.com\/repos/github.com}"
            INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)
        fi

        if [[ -n "${INSTALLER_REMOTE_CONTENT}" ]]; then
            INSTALLER_VER_REMOTE=$(grep '<title>' <<<"${INSTALLER_REMOTE_CONTENT}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
            [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(grep 'Release' <<<"${INSTALLER_REMOTE_CONTENT}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
            [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' <<<"${INSTALLER_REMOTE_CONTENT}" | head -n1)

            # Extract download urls from expanded_assets
            remote_url=$(grep '/expanded_assets/' <<<"${INSTALLER_REMOTE_CONTENT}" \
                | grep -o -P "(((ht|f)tps?):\/\/)+[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?" \
                | head -n1)
            [[ -n "${remote_url}" ]] && INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)

            [[ -n "${INSTALLER_REMOTE_CONTENT}" ]] && \
                INSTALLER_REMOTE_CONTENT=$(sed 's|<a href="/|<a href="https://github.com/|g' <<<"${INSTALLER_REMOTE_CONTENT}" | grep '/releases/download/')
        fi
    fi

    [[ -z "${INSTALLER_REMOTE_CONTENT}" ]] && colorEcho "${RED}  Can't get latest version from ${FUCHSIA}${remote_url}${RED}!" && return 1

    [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(jq -r '.tag_name//empty' 2>/dev/null <<<"${INSTALLER_REMOTE_CONTENT}" | cut -d'v' -f2)

    [[ -z "${INSTALLER_VER_REMOTE}" && -n "${version_match_pattern}" ]] && \
        INSTALLER_VER_REMOTE=$(grep -E "${version_match_pattern}" <<<"${INSTALLER_REMOTE_CONTENT}" | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)

    [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE=$(grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' <<<"${INSTALLER_REMOTE_CONTENT}" | head -n1)

    # Get download urls
    match_urls=$(jq -r '.assets[].browser_download_url' 2>/dev/null <<<"${INSTALLER_REMOTE_CONTENT}")
    if [[ -z "${match_urls}" ]]; then
        match_urls=$(grep -E "${file_match_pattern}" <<<"${INSTALLER_REMOTE_CONTENT}" \
            | grep -o -P "(((ht|f)tps?):\/\/)+[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?")
    else
        match_urls=$(grep -E "${file_match_pattern}" <<<"${match_urls}")
    fi

    [[ -z "${match_urls}" ]] && match_urls=$(grep -Eo "${file_match_pattern}" <<<"${INSTALLER_REMOTE_CONTENT}")

    [[ -z "${OS_INFO_MATCH_TYPE}" ]] && App_Installer_Get_OS_Info_Match_Cond

    # Filter download urls by unmatching condition
    if [[ -n "${OS_INFO_UNMATCH_COND}" ]]; then
        match_urls=$(grep -Evi "${OS_INFO_UNMATCH_COND}" <<<"${match_urls}")
    fi

    match_result_type=""
    match_result_arch=""
    match_result_float=""
    match_result_cpu_level=""

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

    INSTALLER_INSTALL_PATH="/usr/local/bin"
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

    [[ "${INSTALLER_IS_INSTALL}" != "yes" ]] && return 0

    [[ -z "${remote_url}" ]] && remote_url="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"

    # get app remote version & download link that match running platform
    if [[ -z "${INSTALLER_DOWNLOAD_URL}" ]]; then
        if [[ -z "${INSTALLER_ARCHIVE_EXT}" && -n "${INSTALLER_ARCHIVE_EXEC_NAME}" ]]; then
            App_Installer_Get_Remote "${remote_url}" "${INSTALLER_ARCHIVE_EXEC_NAME}"
        else
            App_Installer_Get_Remote "${remote_url}"
        fi
    fi

    if [[ -z "${INSTALLER_VER_REMOTE}" || -z "${INSTALLER_DOWNLOAD_URL}" ]]; then
        INSTALLER_IS_INSTALL="nomatch"
    else
        version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}" && INSTALLER_IS_INSTALL="no"
    fi

    [[ "${INSTALLER_IS_INSTALL}" != "yes" ]] && return 0

    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    # set the app execute filename in archive
    [[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"

    [[ -z "${WORKDIR}" ]] && WORKDIR="$(pwd)"
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_INSTALL_NAME}"
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
                        -not -name "*.${INSTALLER_ARCHIVE_EXT}" -not -name "*.[[:digit:]]" -not -name "${INSTALLER_ZSH_COMP_FILE}")
                else
                    INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}" \
                        -not -name "*.${INSTALLER_ARCHIVE_EXT}" -not -name "*.[[:digit:]]")
                fi
            else
                if [[ -n "${INSTALLER_ZSH_COMP_FILE}" ]]; then
                    INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}" \
                        -not -name "*.[[:digit:]]" -not -name "${INSTALLER_ZSH_COMP_FILE}")
                else
                    INSTALLER_ARCHIVE_EXEC_NAME=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${INSTALLER_ARCHIVE_EXEC_NAME}" \
                        -not -name "*.[[:digit:]]")
                fi
            fi

            if [[ -n "${INSTALLER_ARCHIVE_EXEC_NAME}" ]]; then
                INSTALLER_ARCHIVE_EXEC_DIR=$(dirname "${INSTALLER_ARCHIVE_EXEC_NAME}")
                INSTALLER_ARCHIVE_EXEC_NAME=$(basename "${INSTALLER_ARCHIVE_EXEC_NAME}")
            else
                INSTALLER_ARCHIVE_EXEC_DIR="${WORKDIR}"
                INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"
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
            [[ ! -s "${INSTALLER_ARCHIVE_EXEC_DIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"
        fi
        [[ -z "${exec_list[*]}" ]] && exec_list=("${INSTALLER_ARCHIVE_EXEC_NAME}")

        # install app
        app_installed="no"
        for exec_name in "${exec_list[@]}"; do
            [[ -z "${exec_name}" ]] && continue

            if [[ ! -s "${INSTALLER_ARCHIVE_EXEC_DIR}/${exec_name}" ]]; then
                exec_name=$(find "${INSTALLER_ARCHIVE_EXEC_DIR}" -type f -name "${exec_name}")
                INSTALLER_ARCHIVE_EXEC_DIR=$(dirname "${exec_name}") && exec_name=$(basename "${exec_name}")
            fi
            [[ -z "${exec_name}" ]] && continue

            if [[ -s "${INSTALLER_ARCHIVE_EXEC_DIR}/${exec_name}" ]]; then
                [[ -n "${INSTALLER_INSTALL_NAME}" ]] && install_filename="${INSTALLER_INSTALL_NAME}" || install_filename="${exec_name}"

                sudo cp -f "${INSTALLER_ARCHIVE_EXEC_DIR}/${exec_name}" "${INSTALLER_INSTALL_PATH}/${install_filename}" && \
                    sudo chmod +x "${INSTALLER_INSTALL_PATH}/${install_filename}" && \
                    app_installed="yes"
            fi
        done

        # man pages, zsh completions
        if [[ "${app_installed}" == "yes" ]]; then
            # write version to file
            [[ -n "${INSTALLER_VER_FILE}" ]] && echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_VER_FILE}" >/dev/null || true

            # man pages (man1..man8)
            for ((i=1; i <= 8; ++i)); do
                [[ ! -d "/usr/share/man/man${i}" ]] && sudo mkdir -p "/usr/share/man/man${i}"
                install_files=$(find "${INSTALLER_ARCHIVE_ROOT}" -type f -name "*.${i}")
                while read -r finded_file; do
                    [[ ! -s "${finded_file}" ]] && continue
                    sudo cp -f "${finded_file}" "/usr/share/man/man${i}"
                done <<<"${install_files}"
            done

            # zsh completions
            if [[ -n "${INSTALLER_ZSH_COMP_FILE}" ]]; then
                [[ ! -d "/usr/local/share/zsh/site-functions" ]] && sudo mkdir -p "/usr/local/share/zsh/site-functions"
                install_files=$(find "${INSTALLER_ARCHIVE_ROOT}" -type f -name "${INSTALLER_ZSH_COMP_FILE}")
                while read -r finded_file; do
                    [[ ! -s "${finded_file}" ]] && continue
                    [[ -n "${INSTALLER_ZSH_COMP_INSTALL}" ]] && install_filename="${INSTALLER_ZSH_COMP_INSTALL}" || install_filename=$(basename "${finded_file}")
                    sudo cp -f "${finded_file}" "/usr/local/share/zsh/site-functions/${install_filename}" && \
                        sudo chmod 644 "/usr/local/share/zsh/site-functions/${install_filename}" && \
                        sudo chown "$(id -u)":"$(id -g)" "/usr/local/share/zsh/site-functions/${install_filename}"
                done <<<"${install_files}"
            fi
        else
            colorEcho "${RED}  Can't find ${FUCHSIA}${INSTALLER_ARCHIVE_EXEC_NAME}${RED} in downloaded file ${YELLOW}${INSTALLER_DOWNLOAD_FILE}!"
            return 1
        fi
    else
        colorEcho "${RED}  Download failed from ${ORANGE}${INSTALLER_DOWNLOAD_URL}${RED}!"
        return 1
    fi

    return 0
}
