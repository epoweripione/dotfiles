# Boot
`journalctl -xb | grep -i -E 'error|failed'`

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
