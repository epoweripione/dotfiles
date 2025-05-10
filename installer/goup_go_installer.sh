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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

## goup (pronounced Go Up) is an elegant Go version manager
## https://github.com/owenthereal/goup
# curl -sSf https://raw.githubusercontent.com/owenthereal/goup/master/install.sh | sh -s -- '--skip-prompt'
INSTALLER_APP_NAME="goup"
INSTALLER_GITHUB_REPO="owenthereal/goup"

INSTALLER_INSTALL_PATH="/usr/local/bin"
INSTALLER_INSTALL_NAME="goup"

INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_INSTALL_NAME}"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    INSTALLER_FILE_NAME="${OS_INFO_TYPE}-${OS_INFO_ARCH}"

    [[ -z "${INSTALLER_FILE_NAME}" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    # Download file
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        INSTALLER_DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        # Install
        if [[ -s "${INSTALLER_DOWNLOAD_FILE}" ]]; then
            sudo cp -f "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
                sudo chmod +x "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}"
        fi
    fi
fi

# How it works
# install.sh: downloads the latest Goup release for your platform and appends Goup's bin directory ($HOME/.go/bin) & 
#   Go's bin directory ($HOME/.go/current/bin) to your PATH environment variable.
# goup: switches to selected Go version.
# goup install: downloads specified version of Go to$HOME/.go/VERSION and symlinks it to $HOME/.go/current.
# goup show: shows the activated Go version located at $HOME/.go/current.
# goup remove: removes the specified Go version.
# goup ls-ver: lists all available Go versions from https://golang.org/dl.
# goup upgrade: upgrades goup.

[[ ":$PATH:" != *":$HOME/.go/bin:"* ]] && export PATH=$PATH:$HOME/.go/bin:$HOME/.go/current/bin

# install latest version
goupInstallLatest

# remove unuse installed go version but keep the latest minor version
goupRemoveUnuse

# go mirrors
[[ "${THE_WORLD_BLOCKED}" == "true" ]] && setMirrorGo

# godoc -http :8000
if [[ ! -x "$(command -v godoc)" && -x "$(command -v go)" ]]; then
    go install "golang.org/x/tools/cmd/godoc@latest"
fi

## Cross-compiling with Golang
# go tool dist list

## Handling all architectures
# SUPPORT_PLATFORM=$(go tool dist list)
# APP_NAME=""
# APP_VERSION="1.0.0"
# while read -r PLATFORM; do
#     [[ -z "${PLATFORM}" ]] && continue
#     PLATFORM_OS=$(echo "${PLATFORM}" | cut -d'/' -f1)
#     PLATFORM_ARCH=$(echo "${PLATFORM}" | cut -d'/' -f2)
#     # Cross compilation does not support CGO, so disable it
#     CGO_ENABLED=0 GOOS=${PLATFORM_OS} GOARCH=${PLATFORM_ARCH} \
#         go build -o ${APP_NAME}_${PLATFORM_OS}_${PLATFORM_ARCH}_${APP_VERSION}
# done <<<"${SUPPORT_PLATFORM}"

## Cross-compiling with cgo
## https://imwnk.cn/archives/cgo-compile/
## https://zhuanlan.zhihu.com/p/338891206
## https://zhuanlan.zhihu.com/p/349197066
## https://johng.cn/cgo-enabled-affect-go-static-compile/
## https://musl.cc/
## https://github.com/FiloSottile/homebrew-musl-cross
# CGO_ENABLED=1 GOOS=linux GOARCH=amd64 CC="x86_64-linux-musl-gcc" CXX="x86_64-linux-musl-g++" CGO_LDFLAGS="-static" go build -a -v

## golang 1.17+
## https://dev.to/kristoff/zig-makes-go-cross-compilation-just-work-29ho
# CGO_ENABLED=1 GOOS=linux GOARCH=amd64 CC="zig cc -target x86_64-linux" CXX="zig c++ -target x86_64-linux" go build
