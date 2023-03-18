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

# gRPC
# https://grpc.io/docs/languages/go/quickstart/

# Protocol Buffers - Google's data interchange format
# https://github.com/protocolbuffers/protobuf
INSTALLER_APP_NAME="protobuf"
INSTALLER_GITHUB_REPO="protocolbuffers/protobuf"

INSTALLER_ARCHIVE_EXT="zip"
INSTALLER_ARCHIVE_EXEC_DIR="bin"
INSTALLER_ARCHIVE_EXEC_NAME="protoc"

GOPATH=$(go env GOPATH 2>/dev/null)
INSTALLER_INSTALL_PATH="${GOPATH:-"/usr/local"}/bin"
INSTALLER_INSTALL_NAME="protoc"

[[ -z "${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && INSTALLER_ARCHIVE_EXEC_NAME="${INSTALLER_INSTALL_NAME}"

INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_INSTALL_NAME}"
[[ -n "${INSTALLER_ARCHIVE_EXT}" ]] && INSTALLER_DOWNLOAD_FILE="${INSTALLER_DOWNLOAD_FILE}.${INSTALLER_ARCHIVE_EXT}"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

# Install the protocol compiler plugins for Go
if [[ ! -x "$(command -v protoc-gen-go)" && -x "$(command -v go)" ]]; then
    # go install "google.golang.org/grpc"
    go install "google.golang.org/protobuf/cmd/protoc-gen-go@latest"
    go install "google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest"
fi
