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
# [Wayland](https://wiki.archlinux.org/title/Wayland)
# XDG_SESSION_TYPE=wayland
InstallList=(
    "plasma-wayland-session"
    "xorg-xwayland"
)
InstallSystemPackages "" "${InstallList[@]}"

## [Plasma (Wayland) session stuck on a black screen](https://discuss.kde.org/t/solved-plasma-wayland-session-stuck-on-a-black-screen/6691)
# if ! grep -q "^KWIN_DRM_NO_AMS=" "/etc/environment"; then
#     echo "KWIN_DRM_NO_AMS=1" || sudo tee -a "/etc/environment" >/dev/null
# fi

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

## [Chromium](https://wiki.archlinux.org/title/chromium)
# %U --ozone-platform-hint=auto --enable-wayland-ime --gtk-version=4
if [[ -f "/usr/share/applications/google-chrome.desktop" ]]; then
    if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/google-chrome.desktop"; then
        sudo sed -i -e 's|/usr/bin/google-chrome-stable|/usr/bin/google-chrome-stable --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/google-chrome.desktop"
    fi
fi

if [[ -f "/usr/share/applications/google-chrome-beta.desktop" ]]; then
    if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/google-chrome-beta.desktop"; then
        sudo sed -i -e 's|/usr/bin/google-chrome-beta|/usr/bin/google-chrome-beta --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/google-chrome-beta.desktop"
    fi
fi

if [[ -f "/usr/share/applications/google-chrome-unstable.desktop" ]]; then
    if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/google-chrome-unstable.desktop"; then
        sudo sed -i -e 's|/usr/bin/google-chrome-unstable|/usr/bin/google-chrome-unstable --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/google-chrome-unstable.desktop"
    fi
fi

## vscode
# --ozone-platform-hint=auto --enable-wayland-ime
if [[ -f "/usr/share/applications/code.desktop" ]]; then
    if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/code.desktop"; then
        sudo sed -i -e 's|/usr/bin/code|/usr/bin/code --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/code.desktop"
    fi
fi

if [[ -f "/usr/share/applications/code-url-handler.desktop" ]]; then
    if ! grep -q "\--ozone-platform-hint=auto" "/usr/share/applications/code-url-handler.desktop"; then
        sudo sed -i -e 's|/usr/bin/code|/usr/bin/code --ozone-platform-hint=auto --enable-wayland-ime|g' "/usr/share/applications/code-url-handler.desktop"
    fi
fi

# WPS
if [[ -f "/usr/bin/wps" ]]; then
    if ! grep -q "export QT_IM_MODULE=" "/usr/bin/wps"; then
        sudo sed -i -e '2a export QT_IM_MODULE="fcitx"' -e '2a export XMODIFIERS="@im=fcitx"' "/usr/bin/wps"
    fi
fi

if [[ -f "/usr/bin/wpp" ]]; then
    if ! grep -q "export QT_IM_MODULE=" "/usr/bin/wpp"; then
        sudo sed -i -e '2a export QT_IM_MODULE="fcitx"' -e '2a export XMODIFIERS="@im=fcitx"' "/usr/bin/wpp"
    fi
fi

if [[ -f "/usr/bin/et" ]]; then
    if ! grep -q "export QT_IM_MODULE=" "/usr/bin/et"; then
        sudo sed -i -e '2a export QT_IM_MODULE="fcitx"' -e '2a export XMODIFIERS="@im=fcitx"' "/usr/bin/et"
    fi
fi

# [Waydroid](https://wiki.archlinux.org/title/Waydroid)
# [在 Archlinux KDE下使用 Waydroid](https://zhuanlan.zhihu.com/p/643889264)
