# Boot
```bash
journalctl --boot=-1 --priority=3
journalctl -xb -p 1..3
journalctl -xb | grep -i -E 'error|failed'
```

## Failed to find module 'xxx'
Find the entry in the module lists and remove it:

/lib/modules-load.d
/usr/lib/modules-load.d
/usr/local/lib/modules-load.d
/etc/modules-load.d
/run/modules-load.d


## [Failed to start pkgfile database update](https://forum.manjaro.org/t/failed-failed-to-start-pkgfile-database-update/31731/46)
`sudo sed -i '/^\[Timer\]/a\OnBootSec=10min' "/usr/lib/systemd/system/pkgfile-update.timer"`


## SamInfo3_for_guest: Unable to locate guest account
`id guest 2>/dev/null || sudo useradd guest -s /bin/nologin`


## [Unit dbus-org.freedesktop.home1.service not found](https://forum.manjaro.org/t/systemd-homed-annoyance-when-disabled-the-journal-log-is-literally-spammed/32498)
`sudo sed -i "/pam_systemd_home.so/ s/^\(.*\)$/#\1/" /etc/pam.d/system-auth`

or
```bash
sudo "/usr/lib/security/pam_systemd_home.so" "/usr/lib/security/pam_systemd_home.so.bak"
for i in homed.service userdbd.service userdbd.socket; do
    sudo systemctl disable --now systemd-${i}
    sudo systemctl mask systemd-${i}
done
```

## [Bluetooth errors](https://www.reddit.com/r/archlinux/comments/yu9az9/bluetooth_errors_since_2_days_ago/)
```bash
# bluetoothd: profiles/audio/vcp.c:vcp_init() D-Bus experimental not enabled
# bluetoothd: src/plugin.c:plugin_init() Failed to init vcp plugin
# bluetoothd: profiles/audio/mcp.c:mcp_init() D-Bus experimental not enabled
# bluetoothd: src/plugin.c:plugin_init() Failed to init mcp plugin
# bluetoothd: profiles/audio/bap.c:bap_init() D-Bus experimental not enabled
# bluetoothd: src/plugin.c:plugin_init() Failed to init bap plugin
sudo pacman --noconfirm --needed -S bluez-utils
sudo systemctl status bluetooth
sudo sed -i -e 's/^#Experimental.*/Experimental = true/' -e 's/^#KernelExperimental.*/KernelExperimental = true/' /etc/bluetooth/main.conf
```

## Fix `konsole: kf.xmlgui: Shortcut for action  "" set with QAction::setShortcut()! Use KActionCollection::setDefaultShortcut(s) instead.`
`rm $HOME/.config/QtProject.conf`

## [Fix Windows and Linux Showing Different Time When Dual Booting](https://windowsloop.com/fix-windows-and-linux-showing-different-time-when-dual-booting/)
- Windows Settings (Win+I)→Time & language→Date and Time→Turn off "Set time automatically"
- Start menu→Search and open "Registry Editor"→HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation→Add new "DWORD" value "RealTimeIsUniversal" and set "Value Data" to "1"
`reg add HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation /v RealTimeIsUniversal /t reg_dword /d 00000001 /f`
- Reboot the computer


## [Baloo still crashing](https://forum.manjaro.org/t/baloo-still-crashing/130024)
```bash
balooctl disable && balooctl purge && balooctl enable
balooctl status
```