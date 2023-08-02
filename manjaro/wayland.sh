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

# [KWin/Wayland](https://community.kde.org/KWin/Wayland)
colorEcho "${BLUE}Installing ${FUCHSIA}plasma-wayland-session${BLUE}..."
sudo pacman --noconfirm --needed -S plasma-wayland-session

## Switch to Wayland
## Log out, click user-name and use the bottom drop-down box to select `Plasma (Wayland)` desktop session
## And, finally type user password to log in
# echo $XDG_SESSION_TYPE

## Run app via Wayland protocol
## Start app executable file via `startplasma-wayland` at the beginning
## For example, to run `Dolphin` file manager via Wayland, use command in terminal (`konsole`):
# startplasma-wayland dolphin
## Edit the app shortcut file under ‘/usr/share/applications‘ (or copy to .local/share/applications), and add the variable to ‘Exec‘.
## So you can start the app via Wayland protocol even from start menu.


# [Waydroid](https://wiki.archlinux.org/title/Waydroid)
# [在 Archlinux KDE下使用 Waydroid](https://zhuanlan.zhihu.com/p/643889264)
