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

App_Installer_Reset

# if [[ ! -x "$(command -v rustup)" && ! -x "$(command -v cargo)" ]]; then
#     colorEcho "${FUCHSIA}rustup & cargo${RED} is not installed!"
#     exit 1
# fi

# fix: /lib64/libc.so.6: version `GLIBC_2.32' not found (required by viu)
# ldd $(which viu)
# https://github.com/japaric/rust-cross#how-do-i-compile-a-fully-statically-linked-rust-binaries


# viu: Simple terminal image viewer written in Rust
# https://github.com/atanunq/viu
INSTALLER_APP_NAME="viu"
INSTALLER_GITHUB_REPO="atanunq/viu"

INSTALLER_INSTALL_PATH="/usr/local/bin"
INSTALLER_INSTALL_NAME="viu"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

[[ ! -x "$(command -v cargo)" ]] && INSTALLER_IS_INSTALL="no"

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    Git_Clone_Update_Branch "${INSTALLER_GITHUB_REPO}" "${WORKDIR}/${INSTALLER_APP_NAME}"
    if [[ -d "${WORKDIR}/${INSTALLER_APP_NAME}" ]]; then
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
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        [[ -n "${TARGET_PLATFORM}" ]] && cd "${WORKDIR}/${INSTALLER_APP_NAME}" && \
            rustup target add "${TARGET_PLATFORM}" && \
            cargo install --path . --target "${TARGET_PLATFORM}"
    fi
fi


cd "${CURRENT_DIR}" || exit