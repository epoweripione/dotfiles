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

App_Installer_Reset

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type

# jq
if [[ ! -x "$(command -v jq)" && -x "$(command -v pacman)" ]]; then
    if checkPackageNeedInstall "jq"; then
        colorEcho "${BLUE}Installing ${FUCHSIA}jq${BLUE}..."
        sudo pacman --noconfirm -S jq
    fi
fi

if [[ ! -x "$(command -v jq)" ]]; then
    colorEcho "${FUCHSIA}jq${RED} is not installed!"
    exit 1
fi


# https://flutter.dev/docs/get-started/install/linux
INSTALLER_APP_NAME="flutter"

INSTALLER_INSTALL_PATH="$HOME/flutter/bin"
INSTALLER_INSTALL_NAME="flutter"

# https://flutter.dev/community/china
FLUTTER_STORAGE_BASE_URL="https://storage.googleapis.com"
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    export PUB_HOSTED_URL=https://pub.flutter-io.cn
    export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

    # export PUB_HOSTED_URL=https://mirror.sjtu.edu.cn/dart-pub
    # export FLUTTER_STORAGE_BASE_URL=https://mirror.sjtu.edu.cn
fi

# git clone -b dev https://github.com/flutter/flutter.git
# export PATH="$PWD/flutter/bin:$PATH"
# cd ./flutter
# flutter doctor

if [[ -x "$(command -v flutter)" ]]; then
    # `flutter` is Windows executable file in WSL
    if check_wsl_windows_exe "$(which flutter)"; then
        INSTALLER_IS_INSTALL="no"
    else
        INSTALLER_IS_UPDATE="yes"
        INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    fi
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
    case "${OS_INFO_TYPE}" in
        darwin)
            INSTALLER_CHECK_URL="${FLUTTER_STORAGE_BASE_URL}/flutter_infra_release/releases/releases_macos.json"
            ;;
        *)
            INSTALLER_CHECK_URL="${FLUTTER_STORAGE_BASE_URL}/flutter_infra_release/releases/releases_${OS_INFO_TYPE}.json"
            ;;
    esac

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/flutter.json"
    [[ -n "${INSTALLER_CHECK_URL}" ]] && curl "${CURL_CHECK_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_CHECK_URL}"

    if [[ -s "${INSTALLER_DOWNLOAD_FILE}" ]]; then
        CURRENT_RELEASE_HASH=$(jq -r '.current_release.stable//empty' "${INSTALLER_DOWNLOAD_FILE}")
        [[ -n "${CURRENT_RELEASE_HASH}" ]] && \
            INSTALLER_VER_REMOTE=$(jq -r ".releases[] | select(.hash==\"${CURRENT_RELEASE_HASH}\")" "${INSTALLER_DOWNLOAD_FILE}" | jq -r '.version//empty') && \
            INSTALLER_FILE_PATH=$(jq -r ".releases[] | select(.hash==\"${CURRENT_RELEASE_HASH}\")" "${INSTALLER_DOWNLOAD_FILE}" | jq -r '.archive//empty')
    fi

    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" && -n "${INSTALLER_FILE_PATH}" ]]; then
    # macOS
    # https://flutter.dev/docs/get-started/install/macos
    if [[ "${INSTALLER_IS_UPDATE}" == "no" && "${OS_INFO_TYPE}" == "darwin" && ! -x "$(command -v xcodebuild)" ]]; then
        # sudo xcode-select --install
        sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
        # xcode-select --print-path
        # sudo xcode-select --reset

        # sudo xcodebuild -license
        sudo xcodebuild -runFirstLaunch
    fi

    # Android Studio
    # https://developer.android.com/studio/install
    # Install desired Java version
    [[ ! -x "$(command -v java)" && "$(command -v rtx)" ]] && rtx global java@zulu-17
    [[ ! -x "$(command -v java)" && "$(command -v asdf)" ]] && asdf_App_Install java zulu-17

    if [[ -x "$(command -v pacman)" ]]; then
        # Pre-requisite packages
        PackagesList=(
            libc6:i386
            libncurses5:i386
            libstdc++6:i386
            lib32z1
            libbz2-1.0:i386
            zlib.i686
            ncurses-libs.i686
            bzip2-libs.i686
            cmake
            ninja
        )
        colorEcho "${FUCHSIA}  Android Studio${BLUE}: Checking Pre-requisite packages..."
        for TargetPackage in "${PackagesList[@]}"; do
            if checkPackageNeedInstall "${TargetPackage}"; then
                colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
                sudo pacman --noconfirm -S "${TargetPackage}"
            fi
        done
    fi

    # Install Android Studio
    if check_os_arch; then
        if pacman -Si "archlinuxcn/android-studio" >/dev/null 2>&1; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}Android Studio${BLUE}..."
            sudo pacman --noconfirm --needed -S "archlinuxcn/android-studio"
        elif yay -Si "aur/android-studio" >/dev/null 2>&1; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}Android Studio${BLUE}..."
            yay --noconfirm --needed -S "aur/android-studio"
        fi
    fi

    if [[ ! -x "$(command -v android-studio)" ]]; then
        # Init snap
        if [[ ! -x "$(command -v snap)" || ! -d "/snap" ]]; then
            [[ -s "${MY_SHELL_SCRIPTS}/installer/snap_installer.sh" ]] && \
                source "${MY_SHELL_SCRIPTS}/installer/snap_installer.sh"
        fi

        if [[ -x "$(command -v snap)" && ! -x "$(command -v android-studio)" ]]; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}Android Studio${BLUE}..."
            sudo snap install android-studio --classic
        fi
    fi

    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    INSTALLER_DOWNLOAD_URL="${FLUTTER_STORAGE_BASE_URL}/flutter_infra_release/releases/${INSTALLER_FILE_PATH}"

    # INSTALLER_DOWNLOAD_FILE=$(echo ${INSTALLER_DOWNLOAD_URL} | awk -F"/" '{print $NF}')
    # INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_DOWNLOAD_FILE}"

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_DOWNLOAD_URL##*/}"
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -eq 0 ]]; then
        [[ -d "$HOME/flutter" ]] && rm -rf "$HOME/flutter"

        if echo "${INSTALLER_DOWNLOAD_FILE}" | grep -q '.tar.xz$'; then
            tar -xJf "${INSTALLER_DOWNLOAD_FILE}" -C "$HOME"
        elif echo "${INSTALLER_DOWNLOAD_FILE}" | grep -q '.zip$'; then
            unzip -qo "${INSTALLER_DOWNLOAD_FILE}" -d "$HOME"
        fi
    fi
fi

# new install
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && "${INSTALLER_IS_UPDATE}" == "no" ]]; then
    export PATH=$PATH:${INSTALLER_INSTALL_PATH}

    if [[ ! -x "$(command -v google-chrome)" ]]; then
        [[ -x "/opt/google/chrome/google-chrome" ]] && \
            export CHROME_EXECUTABLE="/opt/google/chrome/google-chrome" 
    fi

    # proxy_http_cmd flutter precache
    # proxy_http_cmd flutter doctor
fi


# Launch the Android Studio to install the Android SDK components
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && "${INSTALLER_IS_UPDATE}" == "no" && -x "$(command -v android-studio)" ]]; then
    android-studio
fi

[[ -d "$HOME/Android/Sdk/cmdline-tools/latest/bin" ]] && export PATH=$PATH:$HOME/Android/Sdk/cmdline-tools/latest/bin
[[ -d "$HOME/Android/Sdk/platform-tools" ]] && export PATH=$PATH:$HOME/Android/Sdk/platform-tools

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    flutter doctor --android-licenses
    flutter doctor
fi

## [Unable to find bundled Java version on Flutter](https://stackoverflow.com/questions/51281702/unable-to-find-bundled-java-version-on-flutter)
## On Linux/MacOS
# [[ -x "$(command -v android-studio)" ]] && cd "$(dirname $(readlink -f $(which android-studio)))" && ln -s jbr jre
## On Windows (check installation folder)
# cd "%USERPROFILE%\scoop\apps\android-studio\current\" && rmdir /s /q .\jre && mklink /D "jre" "jbr"
## or
# Remove-Item -Path "$HOME\scoop\apps\android-studio\current\jre" -Recurse -Force -Confirm:$false
# New-Item -ItemType SymbolicLink -Path "$HOME\scoop\apps\android-studio\current\jre" -Target "$HOME\scoop\apps\android-studio\current\jbr"

## sdkmanager
## https://developer.android.com/studio/command-line/sdkmanager

## Getting Android sdkmanager to run with Java 11
## https://stackoverflow.com/questions/53076422/getting-android-sdkmanager-to-run-with-java-11
## The sdkmanager included in the new Command-Line Tools package supports JDK 11 
## and it can be downloaded from the Android Studio download page, 
## in the Command line tools only section(https://developer.android.com/studio#command-tools). 
## There's no need to download any other files or to hack with the sdkmanager script, 
## however you will need to update your PATH setting, 
## e.g. on Linux: $ANDROID_HOME/cmdline-tools/latest/bin instead of $ANDROID_HOME/tools/bin
## on Windows use scoop: %USERPROFILE%\scoop\apps\android-sdk\current\cmdline-tools\latest\bin

## use proxy
## sdkmanager --proxy={http | socks} --proxy_host={IP_address | DNS_address} --proxy_port=port_number
# sdkmanager --proxy=socks --proxy_host=127.0.0.1 --proxy_port=7890 --list

## List installed and available packages
## sdkmanager --list [options] \
##     [--channel=channel_id] // Channels: 0 (stable), 1 (beta), 2 (dev), or 3 (canary)
# sdkmanager --list

## Install packages
## sdkmanager packages [options]
## sdkmanager --package_file=package_file [options]
# sdkmanager "platform-tools" "platforms;android-29"

## Install NDK & CMake 
## sdkmanager --install \
##     ["ndk;major.minor.build[suffix]" | "cmake;major.minor.micro.build"] \
##     [--channel=channel_id] // NDK channels: 0 (stable), 1 (beta), or 3 (canary)
# sdkmanager --install "ndk;22.1.7171670"
# sdkmanager --install "cmake;3.18.1"

## Uninstall packages
## sdkmanager --uninstall packages [options]
## sdkmanager --uninstall --package_file=package_file [options]

## Update all installed packages
## sdkmanager --update [options]
# sdkmanager --update


cd "${CURRENT_DIR}" || exit
