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

if [[ -x "$(command -v plank)" ]]; then
    # add to autostart
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

    # [plank themes](https://github.com/erikdubois/plankthemes)
    Git_Clone_Update_Branch "erikdubois/plankthemes" "${THEMES_DIR}/plankthemes" && \
        mkdir -p "$HOME/.local/share/plank/themes" && \
        cp -Rf "${THEMES_DIR}/plankthemes/"* "$HOME/.local/share/plank/themes"
fi

if [[ "${OS_INFO_DESKTOP}" == "XFCE" ]]; then
    # [Vala Panel Application Menu](https://github.com/rilian-la-te/vala-panel-appmenu)
    colorEcho "${BLUE}Installing ${FUCHSIA}Vala Panel Application Menu${BLUE}..."
    AppInstallList=(
        "extra/appmenu-gtk-module"
        "aur/vala-panel-appmenu-common-git"
        "aur/vala-panel-appmenu-registrar"
        "aur/vala-panel-appmenu-xfce"
        "aur/vala-panel-appmenu-locale"
        "aur/thunderbird-globalmenu"
        "aur/firefox-esr-globalmenu"
        "aur/rclone-appmenu"
        "aur/syncthing-appmenu"
        ""
    )
    InstallSystemPackages "" "${AppInstallList[@]}"

    xfconf-query -c xsettings -p /Gtk/ShellShowsMenubar -n -t bool -s true
    xfconf-query -c xsettings -p /Gtk/ShellShowsAppmenu -n -t bool -s true
fi

if [[ "${OS_INFO_DESKTOP}" == "KDE" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}Kvantum, Lightly, ${BLUE}..."
    AppInstallList=(
        # [Kvantum](https://github.com/tsujan/Kvantum)
        # [Materia KDE](https://github.com/PapirusDevelopmentTeam/materia-kde)
        "extra/kvantum"
        "extra/kvantum-manjaro"
        "extra/materia-kde"
        "extra/kvantum-theme-materia"
        "extra/kvantum-theme-matcha"
        "aur/kvantum-theme-catppuccin-git"
        "aur/kvantum-theme-whitesur-git"
        # [Lightly: A modern style for qt applications](https://github.com/Bali10050/lightly)
        # "aur/lightly-qt6"
        # [Latte-Dock](https://github.com/KDE/latte-dock)
        "aur/latte-dock"
    )
    InstallSystemPackages "" "${AppInstallList[@]}"
else
    # [WhiteSur GTK Theme](https://github.com/vinceliuice/WhiteSur-gtk-theme)
    AppInstallList=(
        "aur/whitesur-gtk-theme"
    )
    InstallSystemPackages "" "${AppInstallList[@]}"
fi

AppInstallList=(
    "archlinuxcn/tela-icon-theme-git"
    "aur/whitesur-icon-theme"
    "aur/whitesur-cursor-theme-git"
    # "aur/plasma6-applets-panel-colorizer"
)
InstallSystemPackages "" "${AppInstallList[@]}"


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
