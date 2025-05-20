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

# [erdtree (erd): a modern, cross-platform, and multi-threaded filesystem and disk-usage analysis tool](https://github.com/solidiquis/erdtree)
INSTALLER_APP_NAME="erdtree"
INSTALLER_GITHUB_REPO="solidiquis/erdtree"

INSTALLER_INSTALL_NAME="erd"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    INSTALLER_EXEC_FULLNAME=$(readlink -f "$(which ${INSTALLER_INSTALL_NAME})")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if [[ -n "${INSTALLER_EXEC_FULLNAME}" ]] && [[ "${INSTALLER_EXEC_FULLNAME}" != *"${INSTALLER_INSTALL_PATH}"* ]]; then
        colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

        INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
        App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
        if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
            INSTALLER_IS_INSTALL="no"
        fi
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    INSTALLER_INSTALL_METHOD="custom"

    if [[ -n "${INSTALLER_EXEC_FULLNAME}" ]] && [[ "${INSTALLER_EXEC_FULLNAME}" != *"${INSTALLER_INSTALL_PATH}"* ]]; then
        [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]] && INSTALLER_INSTALL_METHOD="build"
    fi
fi

if [[ "${INSTALLER_INSTALL_METHOD}" == "build" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    # Install via Homebrew
    if [[ -x "$(command -v brew)" ]]; then
        if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
            brew upgrade "${INSTALLER_APP_NAME}"
        else
            brew install "${INSTALLER_APP_NAME}"
        fi
    fi

    # From source on crates.io
    [[ ! -x "$(command -v brew)" && -x "$(command -v cargo)" ]] && cargo install "${INSTALLER_APP_NAME}"
elif [[ "${INSTALLER_INSTALL_METHOD}" == "custom" ]]; then
    if ! App_Installer_Install; then
        colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
    fi
fi

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" && ! -s "$HOME/.erdtreerc" ]]; then
    tee "$HOME/.erdtreerc" >/dev/null <<-'EOF'
--level 2
--icons
--sort size-rev
EOF
fi

if grep -q "size-rev" "$HOME/.erdtreerc" 2>/dev/null; then
    sed -i 's/size-rev/rsize/g' "$HOME/.erdtreerc"
fi


cd "${CURRENT_DIR}" || exit