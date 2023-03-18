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

## fix: /lib64/libc.so.6: version `GLIBC_2.18' not found (required by exa)
## ldd $(which exa)
## https://github.com/japaric/rust-cross#how-do-i-compile-a-fully-statically-linked-rust-binaries
# FILE_LIBC=$(find /usr /lib -name "libc.so.6" | head -n1)
# if [[ -n "${FILE_LIBC}" ]]; then
#     if strings "${FILE_LIBC}" | grep GLIBC_2.18 >/dev/null; then
#         :
#     else
#         colorEcho "${BLUE}  Installing ${FUCHSIA}GLIBC 2.18 ${BLUE}(required by exa)..."
#         curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/glibc.tar.gz" "http://ftp.gnu.org/gnu/glibc/glibc-2.18.tar.gz" && \
#             tar -xzf "${WORKDIR}/glibc.tar.gz" -C "${WORKDIR}" && \
#                 mv "${WORKDIR}"/glibc-* "${WORKDIR}/glibc" && \
#                 mkdir -p "${WORKDIR}/glibc/build" && \
#                 cd "${WORKDIR}/glibc/build" && \
#                 ../configure --prefix=/usr >/dev/null && \
#                 make -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) >/dev/null && \
#                 sudo make install >/dev/null
#     fi
# fi

# exa
# https://github.com/ogham/exa
INSTALLER_APP_NAME="exa"
INSTALLER_GITHUB_REPO="ogham/exa"

INSTALLER_ARCHIVE_EXT="zip"

INSTALLER_INSTALL_NAME="exa"

INSTALLER_ZSH_COMP_FILE="exa.zsh"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

cd "${CURRENT_DIR}" || exit