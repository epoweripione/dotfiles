#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

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
APP_INSTALL_NAME="exa"

colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

CHECK_URL="https://api.github.com/repos/ogham/exa/releases/latest"
REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)

REMOTE_FILENAME=""
case "${OS_INFO_TYPE}" in
    linux)
        case "${OS_INFO_VDIS}" in
            64)
                REMOTE_FILENAME=exa-linux-x86_64-musl-v${REMOTE_VERSION}.zip
                ;;
            arm)
                REMOTE_FILENAME=exa-linux-armv7-v${REMOTE_VERSION}.zip
                ;;
        esac
        ;;
    darwin)
        REMOTE_FILENAME=exa-macos-x86_64-v${REMOTE_VERSION}.zip
        ;;
esac


if [[ -x "$(command -v exa)" ]]; then
    CURRENT_VERSION=$(exa -v | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        REMOTE_FILENAME=""
    fi
fi


if [[ -n "$REMOTE_VERSION" && -n "$REMOTE_FILENAME" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    DOWNLOAD_FILENAME="${WORKDIR}/exa.zip"
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/ogham/exa/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        unzip -qo "${DOWNLOAD_FILENAME}" -d "${WORKDIR}" && \
            sudo cp -f "${WORKDIR}/bin/exa" "/usr/local/bin/exa" && \
            sudo cp -f "${WORKDIR}"/man/exa* "/usr/share/man/man1" && \
            sudo cp -f "${WORKDIR}/completions/exa.zsh" "/usr/local/share/zsh/site-functions" && \
            sudo chmod 644 "/usr/local/share/zsh/site-functions/exa.zsh" && \
            sudo chown "$(id -u)":"$(id -g)" "/usr/local/share/zsh/site-functions/exa.zsh"
    fi
fi

cd "${CURRENT_DIR}" || exit