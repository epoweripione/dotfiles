[Waydroid](https://waydro.id/)
[Waydroid](https://wiki.archlinux.org/title/Waydroid)
```bash
# Waydroid only works in a Wayland session manager, 
# so make sure you are in a Wayland session.

# install
yay --noconfirm --needed -S archlinuxcn/waydroid

# init
sudo waydroid init -s GAPPS
sudo systemctl enable --now waydroid-container.service

# Start
# /var/lib/waydroid/images
waydroid session start

## run inside X11 session
# yay --noconfirm --needed -S xorg-xwayland cage
# cage waydroid session start

# Launch GUI
waydroid show-full-ui

# Launch shell
waydroid shell

# Install an application
waydroid app install $path_to_apk

# Run an application
waydroid app list
waydroid app launch $package_name

# update
waydroid upgrade
```

[Genymotion](https://www.genymotion.com/)
```bash
# install
yay --noconfirm --needed -S archlinuxcn/genymotion
```
