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

# https://www.nano-editor.org/dist/latest/faq.html
INSTALLER_APP_NAME="nano"
INSTALLER_INSTALL_NAME="nano"

colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" -N https://www.nano-editor.org/download.php \
    | grep -Eo -m1 'nano-([0-9]{1,}\.)+[0-9]{1,}' | head -n1 | cut -d'-' -f2)
DIST_VERSION=$(echo "${INSTALLER_VER_REMOTE}" | cut -d'.' -f1)

INSTALLER_VER_CURRENT="0.0"

# http://mybookworld.wikidot.com/compile-nano-from-source
if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
fi

if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE} from source..."
    if [[ -x "$(command -v pacman)" ]]; then
        # Remove installed old version
        if checkPackageInstalled "${INSTALLER_APP_NAME}"; then
            INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
            if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
                colorEcho "${BLUE}  Removing ${FUCHSIA}${INSTALLER_APP_NAME}${YELLOW} ${INSTALLER_VER_CURRENT}${BLUE}..."
                if checkPackageInstalled "nano-syntax-highlighting"; then
                    sudo pacman --noconfirm -R "nano-syntax-highlighting"
                fi

                sudo pacman --noconfirm -R "${INSTALLER_APP_NAME}"
                sudo pacman --noconfirm -Rn "${INSTALLER_APP_NAME}" || true
            fi
        fi

        # Pre-requisite packages
        PackagesList=(
            ncurses
            libncurses-dev
            libncursesw-dev
            libncurses5-dev
            libncursesw5-dev
            ncurses-devel
            # http://support.moonpoint.com/os/unix/linux/ubuntu/groff_invalid_device.php
            groff
        )
        InstallSystemPackages "" "${PackagesList[@]}"
    fi

    INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}-${INSTALLER_VER_REMOTE}.tar.gz"
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_APP_NAME}.tar.gz"

    INSTALLER_DOWNLOAD_URL="https://www.nano-editor.org/dist/v${DIST_VERSION}/${INSTALLER_FILE_NAME}"

    wget -O "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" && \
        tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}" && \
        mv "${WORKDIR}"/${INSTALLER_APP_NAME}-* "${WORKDIR}/${INSTALLER_APP_NAME}"

    if [[ -d "${WORKDIR}/${INSTALLER_APP_NAME}" ]]; then
        colorEcho "${BLUE}  Compiling ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
        cd "${WORKDIR}/${INSTALLER_APP_NAME}" && \
            ./configure --prefix=/usr --enable-utf8 >/dev/null && \
            make >/dev/null && \
            sudo make install >/dev/null
    fi
fi

# Change default editor to nano
if [[ "${INSTALLER_IS_UPDATE}" == "no" && -x "$(command -v nano)" ]]; then
    if [[ -x "$(command -v update-alternatives)" ]]; then
        sudo update-alternatives --install /usr/bin/editor editor "$(which nano)" 100
        sudo update-alternatives --config editor
    fi

    # select default sensible-editor from all installed editors
    if [[ -x "$(command -v select-editor)" ]]; then
        select-editor
    esle
        # What About Distros That Don’t Provide select-editor?
        export VISUAL="nano" && export EDITOR="nano"
        if ! grep -q "^export VISUAL=" "$HOME/.bashrc" 2>/dev/null; then
            echo 'export VISUAL="nano" && export EDITOR="nano"' >> "$HOME/.bashrc"
        fi

        if ! grep -q "^export VISUAL=" "$HOME/.zshrc" 2>/dev/null; then
            echo 'export VISUAL="nano" && export EDITOR="nano"' >> "$HOME/.zshrc"
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit