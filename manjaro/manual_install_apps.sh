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

MANUAL_INSTALL_APP_STORE="${1:-$HOME}"
MANUAL_INSTALL_DIR="${2:-/opt}"

DESKTOP_DIR=$(xdg-user-dir DESKTOP)

[[ ! -d "${MANUAL_INSTALL_DIR}" ]] && mkdir -p "${MANUAL_INSTALL_DIR}"

# [GoldenDict++OCR](https://autoptr.top/gdocr/GoldenDict-OCR-Deployment/)
INSTALLER_ARCHIVE_FILENAME="$(find "${MANUAL_INSTALL_APP_STORE}" -maxdepth 1 -type f -iname "goldendict*debian.tar.gz" | sort -r | head -n1)"
if [[ -f "${INSTALLER_ARCHIVE_FILENAME}" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}GoldenDict++OCR${BLUE}..."
    [[ -d "${MANUAL_INSTALL_DIR}/GoldenDict++OCR" ]] && sudo rm -rf "${MANUAL_INSTALL_DIR}/GoldenDict++OCR" || true

    sudo tar -xzf "${INSTALLER_ARCHIVE_FILENAME}" -C "${MANUAL_INSTALL_DIR}" && \
        sudo find "${MANUAL_INSTALL_DIR}/GoldenDict" -type d -print0 | xargs -0 sudo chmod 755
fi

if ! sudo test -d "${MANUAL_INSTALL_DIR}/GoldenDict/tessdata"; then
    if [[ -f "${MANUAL_INSTALL_APP_STORE}/GoldenDict++OCR-Model-Files-onnx+ncnn+tess.tar.gz" ]]; then
        colorEcho "${BLUE}Installing ${FUCHSIA}GoldenDict++OCR Model Files${BLUE}..."
        sudo tar -xzf "${MANUAL_INSTALL_APP_STORE}/GoldenDict++OCR-Model-Files-onnx+ncnn+tess.tar.gz" -C "${MANUAL_INSTALL_DIR}"
    fi
fi

if ! sudo test -d "${MANUAL_INSTALL_DIR}/GoldenDict/nsocr"; then
    if [[ -f "${MANUAL_INSTALL_APP_STORE}/GoldenDict++OCR-Model-Files-Linux_only.tar.gz" ]]; then
        sudo tar -xzf "${MANUAL_INSTALL_APP_STORE}/GoldenDict++OCR-Model-Files-Linux_only.tar.gz" -C "${MANUAL_INSTALL_DIR}"
    fi
fi

if sudo test -d "${MANUAL_INSTALL_DIR}/GoldenDict"; then
    sudo chown -R "$(id -u)":"$(id -g)" "${MANUAL_INSTALL_DIR}/GoldenDict" && \
        sudo find "${MANUAL_INSTALL_DIR}/GoldenDict" -type d -print0 | xargs -0 sudo chmod 755 && \
        sudo chmod +x "${MANUAL_INSTALL_DIR}/GoldenDict/goldendict.sh" && \
        sudo chmod +x "${MANUAL_INSTALL_DIR}/GoldenDict/GoldenDict"
fi

if [[ -f "${MANUAL_INSTALL_DIR}/GoldenDict/splash.png" && ! -f "/usr/share/pixmaps/GoldenDict++OCR.png" ]]; then
    sudo cp "${MANUAL_INSTALL_DIR}/GoldenDict/splash.png" "/usr/share/pixmaps/GoldenDict++OCR.png"
fi

if [[ -f "${MANUAL_INSTALL_DIR}/GoldenDict/goldendict.sh" && ! -f "${DESKTOP_DIR}/GoldenDict++OCR.desktop" ]]; then
    tee "${DESKTOP_DIR}/GoldenDict++OCR.desktop" >/dev/null <<-EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=GoldenDict++OCR
Comment=GoldenDict++OCR
Exec=${MANUAL_INSTALL_DIR}/GoldenDict/goldendict.sh
Icon=GoldenDict++OCR
Path=${MANUAL_INSTALL_DIR}/GoldenDict
Terminal=false
StartupNotify=true
GenericName=GoldenDict++OCR
EOF
fi

## Run `GoldenDict++OCR`
# if [[ -f "${MANUAL_INSTALL_DIR}/GoldenDict/goldendict.sh" ]]; then
#     cd "${MANUAL_INSTALL_DIR}/GoldenDict++OCR" && ./goldendict.sh
# fi


# [xDroid](https://www.linzhuotech.com/Product/download)
INSTALLER_ARCHIVE_FILENAME="$(find "${MANUAL_INSTALL_APP_STORE}" -maxdepth 1 -type f -iname 'xdroid*.tar.xz' | sort -r | head -n1)"
INSTALLER_FILENAME=""
if [[ -f "${INSTALLER_ARCHIVE_FILENAME}" ]]; then
    sudo tar -xJf "${INSTALLER_ARCHIVE_FILENAME}" -C "${MANUAL_INSTALL_DIR}"
fi

INSTALLER_FILENAME="$(find "${MANUAL_INSTALL_DIR}" -maxdepth 1 -type f -iname 'xdroid*.run' | sort -r | head -n1)"
if [[ -n "${INSTALLER_FILENAME}" && -f "${INSTALLER_FILENAME}" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}Linux Headers${BLUE}..."
    LinuxKernel=$(pacman -Qsq "^linux" | grep "^linux[0-9]*[-rt]*$")
    sudo pacman --noconfirm --needed -S "${LinuxKernel}" "${LinuxKernel}-headers"

    colorEcho "${BLUE}Installing ${FUCHSIA}xDroid${BLUE}..."
    "${INSTALLER_FILENAME}"
fi
