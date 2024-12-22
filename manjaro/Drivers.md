# Drivers
## List USB device
```bash
lsusb
lsusb -v -s 003:006 # Select Specific Device

iwconfig
ip a
lspci -knn | grep -i net -A2
inxi -Nazy

sudo rfkill list all
sudo rfkill unblock wifi # soft block
```

## USB WiFi chipset
- [USB WiFi chipset information for Linux](https://github.com/morrownr/USB-WiFi/blob/main/home/USB_WiFi_Chipsets.md)
- [USB WiFi adapters that are supported with Linux `in-kernel` drivers](https://github.com/morrownr/USB-WiFi/blob/main/home/USB_WiFi_Adapters_that_are_supported_with_Linux_in-kernel_drivers.md)
- [Existing Linux Wireless drivers](https://wireless.docs.kernel.org/en/latest/en/users/drivers.html)
```bash
# List `in-kernel` drivers
modprobe -nv mt76
modprobe -nv rtl
find "/lib/modules/$(uname -r)/kernel/drivers/net/wireless" -type f -name "mt*.zst"
find "/lib/modules/$(uname -r)/kernel/drivers/net/wireless" -type f -name "rtl*.zst"
```

## WiFi6 AIC8800 wireless adaptor
### [USB tethering](https://wiki.archlinux.org/title/Android_tethering#USB_tethering)
- Connect the phone via USB
- Enable the tethering option from your phone
  * 设置 > 连接与共享 > USB 网络共享
  * Settings > Tethering & portable hotspot > USB tethering
  * Settings > Wireless & networks > Internet tethering
  * Settings > More... > Tethering & mobile hotspot > USB tethering
- `ip a`

### [Switching Kernels](https://forum.manjaro.org/t/switching-kernels/70658)
```bash
# List installed kernels
sudo mhwd-kernel --listinstalled
# List available kernels
sudo mhwd-kernel --list
# Install desired kernel version
sudo mhwd-kernel --install linux61
# reboot
# →Grub boot loader screen
# →Advanced…
# →Select the newly installed kernel
```

### aic8800-dkms
```bash
yay --noconfirm --needed -S dkms usb_modeswitch

yay --mflags "--skipchecksums --skippgpcheck" --noconfirm -S aic8800-dkms
cd "$HOME/.cache/yay/aic8800-dkms"
sed -i 's|1.0.5|1.0.6|g' PKGBUILD
makepkg -si --skipchecksums --skippgpcheck aic8800-dkms

sudo dkms install --no-depmod aic8800/1.0.6 -k "$(uname -r)"
dkms status
# dkms remove aic8800/1.0.6 --all
```

### Linux Headers
```bash
sudo pacman -S $(pacman -Qsq "^linux" | grep "^linux[0-9]*[-rt]*$" | awk '{print $1"-headers"}' ORS=' ')
```

### [UGREEN CM762-35264](https://www.lulian.cn/download/135.html)
- download driver
```bash
curl -fSL -o $HOME/DevWorkSpaces/CM762-35264_USB.zip "https://download.lulian.cn/2024%E9%A9%B1%E5%8A%A8/CM762-35264_USB%E6%97%A0%E7%BA%BF%E7%BD%91%E5%8D%A1%E9%A9%B1%E5%8A%A8_V1.2.zip"
unzip $HOME/DevWorkSpaces/CM762-35264_USB.zip -d $HOME/DevWorkSpaces/CM762-35264_USB
cd $HOME/DevWorkSpaces/CM762-35264_USB/Linux/aic8800_linux_drvier
sh install_setup.sh
cd drivers/aic8800
```

- edit `$HOME/DevWorkSpaces/CM762-35264_USB/Linux/aic8800_linux_drvier/drivers/aic8800/aic8800_fdrv/rwnx_main.c`
  * add following code after line `4549`
```c
                                    #if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 12, 0))
                                        , int link_id
                                    #endif
```

- edit `$HOME/DevWorkSpaces/CM762-35264_USB/Linux/aic8800_linux_drvier/drivers/aic8800/aic8800_fdrv/rwnx_radar.c`
  * add following code after line `1402 & 1506`
```c
                    #if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 12, 0))
                        , 0
                    #endif
```

- compile
```bash
make
```

- check results: 
```bash
ls aic_load_fw/aic_load_fw.ko && ls aic8800_fdrv/aic8800_fdrv.ko
```

- install driver: 
```bash
sudo make install
```

- ~~dkms~~
```bash
sudo mkdir "/usr/src/aic8800-1.0.5/"
sudo cp -rf "$HOME/DevWorkSpaces/CM762-35264_USB/Linux/aic8800_linux_drvier/drivers/aic8800/"* "/usr/src/aic8800-1.0.5/"
sudo cp -rf "$HOME/DevWorkSpaces/CM762-35264_USB/Linux/aic8800_linux_drvier/fw/" "/usr/src/aic8800-1.0.5/"
sudo cp -rf "$HOME/DevWorkSpaces/CM762-35264_USB/Linux/aic8800_linux_drvier/fw/"* "/usr/lib/firmware/"
sudo dkms install aic8800/1.0.5
```

- uninstall driver: 
```bash
sudo make uninstall
cd $HOME/DevWorkSpaces/CM762-35264_USB/Linux/aic8800_linux_drvier
sh uninstall_setup.sh
```

### Enable & check installed driver
```bash
# Enable
sudo modprobe aic_load_fw
sudo modprobe aic8800_fdrv

# Check & debug
lsmod | grep aic
sudo modinfo aic8800_fdrv | grep alias

lspci -knn | grep -i net -A2
sudo journalctl -u systemd-networkd -f
sudo journalctl -u NetworkManager -f
sudo journalctl --dmesg -f
sudo dmesg | grep -E '(cfg80211|iwl3945|aic)'
```

### [TP-LINK TL-XDN7000](https://github.com/MXWXZ/aic8800d80fdrvpackage)
```bash
Git_Clone_Update_Branch "MXWXZ/aic8800d80fdrvpackage" "$HOME/aic8800d80fdrvpackage"
# Git_Clone_Update_Branch "radxa-pkg/aic8800" "$HOME/aic8800d80fdrvpackage"

## fix `error: too many arguments to function ‘cfg80211_ch_switch_notify’`
## [The Linux Kernel documentation](https://www.kernel.org/doc/html/)
# grep -A10 -B 10 'cfg80211_ch_switch_notify' "/lib/modules/$(uname -r)/build/include/net/"*.h
# grep -A10 -B 10 'cfg80211_ch_switch_started_notify' "/lib/modules/$(uname -r)/build/include/net/"*.h
# grep -A10 -B 10 'start_radar_detection' "/lib/modules/$(uname -r)/build/include/net/"*.h

dpkg -b aic8800d80fdrvpackage/ .
sudo dpkg -r aic8800d80fdrvpackage
sudo dpkg -i aic8800d80fdrvpackage_0.0.3_all.deb
```

### [Mercury AX900/UX9](https://service.mercurycom.com.cn/download-2462.html)
```bash
curl -fSL -o $HOME/DevWorkSpaces/UX9.zip "https://service.mercurycom.com.cn/download/202402/UX9(%E5%85%8D%E9%A9%B1%E7%89%88)%20V1.1%20Linux%E7%B3%BB%E7%BB%9F%E9%A9%B1%E5%8A%A8%E7%A8%8B%E5%BA%8F20240202.zip"
unzip $HOME/DevWorkSpaces/UX9.zip -d $HOME/DevWorkSpaces
mv $HOME/DevWorkSpaces/UX9*Linux* $HOME/DevWorkSpaces/UX9-Linux
sudo dpkg -i $HOME/DevWorkSpaces/UX9-Linux/aic8800d80fdrvpackage.deb
```

### [Easily unpack DEB, edit postinst, and repack DEB](https://unix.stackexchange.com/questions/138188/easily-unpack-deb-edit-postinst-and-repack-deb)
```bash
# mkdir -p $HOME/DevWorkSpaces/UX9-Linux/aic8800d80fdrvpackage
# ar -vx $HOME/DevWorkSpaces/UX9-Linux/aic8800d80fdrvpackage.deb --output=$HOME/DevWorkSpaces/aic8800d80fdrvpackage
# cd $HOME/DevWorkSpaces/aic8800d80fdrvpackage && tar -xzf data.tar.gz && tar -xzf control.tar.gz ./DEBIAN
dpkg-deb -R $HOME/DevWorkSpaces/UX9-Linux/aic8800d80fdrvpackage.deb $HOME/DevWorkSpaces/UX9-Linux
# edit DEBIAN/postinst
dpkg-deb -b tmp $HOME/DevWorkSpaces/UX9-Linux/aic8800d80fdrvpackage_fixed.deb

```
