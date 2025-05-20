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

[[ -z "${OS_INFO_DESKTOP}" ]] && get_os_desktop

# [Lite XL - A lightweight text editor written in Lua](https://github.com/lite-xl/lite-xl)
INSTALLER_APP_NAME="lite-xl"
INSTALLER_GITHUB_REPO="lite-xl/lite-xl"

INSTALLER_INSTALL_NAME="lite-xl"
INSTALLER_VER_FILE="/opt/lite-xl/${INSTALLER_INSTALL_NAME}.version"

if [[ -x "/opt/lite-xl/lite-xl" ]]; then
    INSTALLER_IS_UPDATE="yes"
    [[ -s "${INSTALLER_VER_FILE}" ]] && INSTALLER_VER_CURRENT=$(head -n1 "${INSTALLER_VER_FILE}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" || -z "${OS_INFO_DESKTOP}" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}" && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if App_Installer_Get_Remote_URL "https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest" "lite-xl-[^-]+-addons-.*\.tar\.gz"; then
        if App_Installer_Download "${INSTALLER_DOWNLOAD_URL}" "$(xdg-user-dir DOWNLOAD)/lite-xl.tar.gz"; then
            if Archive_File_Extract "$(xdg-user-dir DOWNLOAD)/lite-xl.tar.gz" "${WORKDIR}"; then
                sudo cp -f -R "${WORKDIR}/lite-xl" "/opt/"
                [[ -n "${INSTALLER_VER_FILE}" ]] && echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_VER_FILE}" >/dev/null || true
            fi
        else
            colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
        fi
    fi

    # Application icon
    if [[ ! -s "/opt/lite-xl/lite-xl.svg" ]]; then
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/lite-xl.svg" "https://raw.githubusercontent.com/lite-xl/lite-xl/master/resources/icons/lite-xl.svg"
        if [[ -s "${WORKDIR}/lite-xl.svg" ]]; then
            sudo cp "${WORKDIR}/lite-xl.svg" "/opt/lite-xl/lite-xl.svg"
            sudo mkdir -p "/usr/local/share/icons/hicolor/scalable/apps"
            sudo cp "${WORKDIR}/lite-xl.svg" "/usr/local/share/icons/hicolor/scalable/apps/lite-xl.svg"
        fi
    fi

    # Desktop entry
    if [[ -x "/opt/lite-xl/lite-xl" && ! -s "/usr/share/applications/com.lite_xl.LiteXL.desktop" ]]; then
        sudo tee "/usr/share/applications/com.lite_xl.LiteXL.desktop" >/dev/null <<-'EOF'
[Desktop Entry]
Type=Application
Name=Lite XL
Comment=A lightweight text editor written in Lua
Exec=/opt/lite-xl/lite-xl %F
Icon=lite-xl
Terminal=false
StartupWMClass=lite-xl
Categories=Development;IDE;
MimeType=text/plain;inode/directory;
EOF

        xdg-desktop-menu forceupdate
    fi
fi
