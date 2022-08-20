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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# if [[ ! -x "$(command -v rustup)" && ! -x "$(command -v cargo)" ]]; then
#     colorEcho "${FUCHSIA}rustup & cargo${RED} is not installed!"
#     exit 1
# fi

# fix: /lib64/libc.so.6: version `GLIBC_2.32' not found (required by viu)
# ldd $(which viu)
# https://github.com/japaric/rust-cross#how-do-i-compile-a-fully-statically-linked-rust-binaries


# viu: Simple terminal image viewer written in Rust
# https://github.com/atanunq/viu
APP_INSTALL_NAME="viu"
GITHUB_REPO_NAME="atanunq/viu"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="viu"

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

[[ ! -x "$(command -v cargo)" ]] && IS_INSTALL="no"

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    Git_Clone_Update_Branch "${GITHUB_REPO_NAME}" "${WORKDIR}/${APP_INSTALL_NAME}"
    if [[ -d "${WORKDIR}/${APP_INSTALL_NAME}" ]]; then
        [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
        [[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

        # Build for architecture
        # <arch><sub>-<vendor>-<sys>-<abi>
        # rustc --print target-list
        case "${OS_INFO_TYPE}" in
            linux)
                case "${OS_INFO_VDIS}" in
                    32)
                        TARGET_PLATFORM=i686-unknown-linux-musl
                        ;;
                    64)
                        TARGET_PLATFORM=x86_64-unknown-linux-musl
                        ;;
                    arm)
                        TARGET_PLATFORM=arm-unknown-linux-musleabihf
                        ;;
                    arm64)
                        TARGET_PLATFORM=aarch64-unknown-linux-musl
                        ;;
                esac
                ;;
            darwin)
                case "${OS_INFO_VDIS}" in
                    64)
                        TARGET_PLATFORM=x86_64-apple-darwin
                        ;;
                    arm64)
                        TARGET_PLATFORM=aarch64-apple-darwin
                        ;;
                esac
                ;;
            windows)
                case "${OS_INFO_VDIS}" in
                    32)
                        TARGET_PLATFORM=i686-pc-windows-msvc
                        ;;
                    64)
                        TARGET_PLATFORM=x86_64-pc-windows-msvc
                        ;;
                    arm64)
                        TARGET_PLATFORM=aarch64-pc-windows-msvc
                        ;;
                esac
                ;;
        esac

        # Pre-requisite packages
        if [[ -x "$(command -v pacman)" ]]; then
            PackagesList=(
                musl
                musl-dev
                musl-tools
                FiloSottile/musl-cross/musl-cross
            )
            for TargetPackage in "${PackagesList[@]}"; do
                if checkPackageNeedInstall "${TargetPackage}"; then
                    colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
                    sudo pacman --noconfirm -S "${TargetPackage}"
                fi
            done
        fi

        ## Compile
        # cargo build --release --target ${TARGET_PLATFORM} 

        # Install: $HOME/.cargo/bin
        # View the list of installed packages: cargo install --list
        colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
        [[ -n "${TARGET_PLATFORM}" ]] && cd "${WORKDIR}/${APP_INSTALL_NAME}" && \
            rustup target add ${TARGET_PLATFORM} && \
            cargo install --path . --target ${TARGET_PLATFORM}
    fi
fi


cd "${CURRENT_DIR}" || exit