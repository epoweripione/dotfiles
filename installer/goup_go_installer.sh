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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

## goup (pronounced Go Up) is an elegant Go version manager
## https://github.com/owenthereal/goup
# curl -sSf https://raw.githubusercontent.com/owenthereal/goup/master/install.sh | sh -s -- '--skip-prompt'
APP_INSTALL_NAME="goup"
GITHUB_REPO_NAME="owenthereal/goup"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="goup"

DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"

REMOTE_SUFFIX=""
REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"
VERSION_FILENAME=""

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    REMOTE_FILENAME="${OS_INFO_TYPE}-${OS_INFO_ARCH}"

    [[ -z "${REMOTE_FILENAME}" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    # Download file
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
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
        # Install
        if [[ -s "${DOWNLOAD_FILENAME}" ]]; then
            sudo cp -f "${DOWNLOAD_FILENAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                [[ -n "${VERSION_FILENAME}" ]] && echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true
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
[[ "${THE_WORLD_BLOCKED}" == "true" ]] && export GOUP_GO_HOST=golang.google.cn

colorEcho "${BLUE}  Installing latest ${FUCHSIA}go${BLUE}..."
# fix: proxyconnect tcp: dial tcp: lookup socks5h: no such host
if echo "${all_proxy}" | grep -q 'socks5h'; then
    proxy_socks5h_to_socks5 goup install
else
    goup install
fi

# Go module
if [[ -x "$(command -v go)" ]]; then
    GO_VERSION=$(go version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_ge "${GO_VERSION}" '1.13'; then
        go env -w GO111MODULE=auto
        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            go env -w GOPROXY="https://goproxy.cn,direct"
            # go env -w GOPROXY="https://goproxy.io,direct"
            # go env -w GOPROXY="https://mirrors.aliyun.com/goproxy/,direct"
            # go env -w GOPROXY="https://proxy.golang.org,direct"

            go env -w GOSUMDB="sum.golang.google.cn"
            # go env -w GOSUMDB="gosum.io+ce6e7565+AY5qEHUk/qmHc5btzW45JVoENfazw8LielDsaI+lEbq6"

            ## https://goproxy.io/zh/docs/goproxyio-private.html
            # go env -w GOPRIVATE="*.corp.example.com"
        fi
    else
        export GO111MODULE=auto
        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            export GOPROXY="https://goproxy.cn"
            export GOSUMDB="sum.golang.google.cn"
        fi
    fi
    unset GO_VERSION
fi

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
