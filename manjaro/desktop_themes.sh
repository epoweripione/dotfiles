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

[[ -z "${OS_INFO_DESKTOP}" ]] && get_os_desktop

THEMES_DIR="$HOME/themes"
mkdir -p "${THEMES_DIR}"

# [A Guide To Using Plank Dock On Linux](https://www.linuxuprising.com/2019/12/a-guide-to-using-plank-dock-on-linux.html)
colorEcho "${BLUE}Installing ${FUCHSIA}plank${BLUE}..."
sudo pacman --noconfirm --needed -S plank

# plank settings: on any icon on Plank Dock, just do `CTRL+RightClick`
# plank --preferences

# add to autostart
if [[ -x "$(command -v emote)" ]]; then
    tee "$HOME/.config/autostart/plank.desktop" >/dev/null <<-'EOF'
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=plank
Icon=plank
Comment=Plank Dock
Exec=plank
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=5
StartupNotify=false
Terminal=false
Hidden=false
EOF
fi

if [[ "${OS_INFO_DESKTOP}" == "XFCE" ]]; then
    # [Vala Panel Application Menu](https://github.com/rilian-la-te/vala-panel-appmenu)
    colorEcho "${BLUE}Installing ${FUCHSIA}Vala Panel Application Menu${BLUE}..."
    yay --noconfirm --needed -S appmenu-gtk-module vala-panel-appmenu-common vala-panel-appmenu-registrar vala-panel-appmenu-xfce

    xfconf-query -c xsettings -p /Gtk/ShellShowsMenubar -n -t bool -s true
    xfconf-query -c xsettings -p /Gtk/ShellShowsAppmenu -n -t bool -s true
fi

if [[ "${OS_INFO_DESKTOP}" == "KDE" ]]; then
    # [Kvantum](https://github.com/tsujan/Kvantum)
    colorEcho "${BLUE}Installing ${FUCHSIA}Kvantum${BLUE}..."
    sudo pacman --noconfirm --needed -S community/kvantum community/kvantum-manjaro \
        community/kvantum-theme-materia community/kvantum-theme-matcha community/nx-kvantum-theme \
        archlinuxcn/kvantum-theme-nordic-git

    # [Latte-Dock](https://github.com/KDE/latte-dock)
    colorEcho "${BLUE}Installing ${FUCHSIA}Latte-Dock${BLUE}..."
    sudo pacman --noconfirm --needed -S latte-dock

    # [WhiteSur KDE Theme](https://github.com/vinceliuice/WhiteSur-kde)
    colorEcho "${BLUE}Installing ${FUCHSIA}WhiteSur KDE Theme${BLUE}..."
    Git_Clone_Update_Branch "vinceliuice/WhiteSur-kde" "${THEMES_DIR}/WhiteSur-kde" && \
        cd "${THEMES_DIR}/WhiteSur-kde" && \
        ./install.sh
else
    # [WhiteSur GTK Theme](https://github.com/vinceliuice/WhiteSur-gtk-theme)
    colorEcho "${BLUE}Installing ${FUCHSIA}WhiteSur GTK Theme${BLUE}..."
    Git_Clone_Update_Branch "vinceliuice/WhiteSur-gtk-theme" "${THEMES_DIR}/WhiteSur-gtk-theme" && \
        cd "${THEMES_DIR}/WhiteSur-gtk-theme" && \
        ./install.sh -c Dark -c Light
fi

# [WhiteSur Icon Theme](https://github.com/vinceliuice/WhiteSur-icon-theme)
colorEcho "${BLUE}Installing ${FUCHSIA}WhiteSur Icon Theme${BLUE}..."
Git_Clone_Update_Branch "vinceliuice/WhiteSur-icon-theme" "${THEMES_DIR}/WhiteSur-icon-theme" && \
    cd "${THEMES_DIR}/WhiteSur-icon-theme" && \
    ./install.sh

# [Whitesur cursors](https://github.com/vinceliuice/WhiteSur-cursors)
colorEcho "${BLUE}Installing ${FUCHSIA}Whitesur cursors${BLUE}..."
Git_Clone_Update_Branch "vinceliuice/WhiteSur-cursors" "${THEMES_DIR}/WhiteSur-cursors" && \
    cd "${THEMES_DIR}/WhiteSur-cursors" && \
    ./install.sh

# if [[ "${OS_INFO_DESKTOP}" == "GNOME" ]]; then
#     # https://extensions.gnome.org/extension/19/user-themes/
#     # https://github.com/ewlsh/dash-to-dock/tree/ewlsh/gnome-40
#     # https://extensions.gnome.org/extension/3193/blur-my-shell
# fi


# Kvantum Manager
# Select Kvantum from `System Settings → Appearance → Global Theme → Application Style → Widget Style` and apply it.
# Select Kvantum from `System Settings → Appearance → Global Theme → Color → Scheme` and click Apply.
# You could change the color scheme later if you choose another Kvantum theme with Kvantum Manager.
# Logging out and in would be good for Plasma to see the new theme.
if [[ -x "$(command -v kvantummanager)" ]]; then
    kvantummanager
fi


cd "${CURRENT_DIR}" || exit
