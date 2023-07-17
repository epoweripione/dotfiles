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

# Notepadqq: https://github.com/notepadqq/notepadqq
INSTALLER_APP_NAME="notepadqq"
INSTALLER_INSTALL_NAME="notepadqq"

# yay --noconfirm --needed -S extra/notepadqq
# yay --noconfirm --needed -S aur/notepadqq-git

# Pre-requisite packages
PackagesList=(
    desktop-file-utils
    hicolor-icon-theme
    qt5
    uchardet
)
for TargetPackage in "${PackagesList[@]}"; do
    if checkPackageNeedInstall "${TargetPackage}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
        sudo pacman --noconfirm -S "${TargetPackage}"
    fi
done

colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE} from source..."
[[ -z "${GIT_CLONE_OPTS[*]}" ]] && Get_Git_Clone_Options
git clone "${GIT_CLONE_OPTS[@]}" --depth=1 --recursive "https://github.com/notepadqq/notepadqq" "${WORKDIR}/${INSTALLER_APP_NAME}" && \
    cd "${WORKDIR}/${INSTALLER_APP_NAME}" && \
    ./configure --prefix /usr >/dev/null && \
    make >/dev/null && \
    sudo make install >/dev/null


cd "${CURRENT_DIR}" || exit
