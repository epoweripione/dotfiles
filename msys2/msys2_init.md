# Installation
https://github.com/msys2/msys2/wiki/MSYS2-installation

# Reinstallation
https://github.com/msys2/msys2/wiki/MSYS2-reinstallation

# Updating packages
## 1. Run `pacman -Syuu`. Follow the instructions. 
## 2. Modify pacman config
### pacman colors
`sed -i "s/#Color/Color/g" /etc/pacman.conf`

### pacman mirrors in china(option)
```
sed -i "1iServer = http://mirrors.ustc.edu.cn/msys2/mingw/i686" /etc/pacman.d/mirrorlist.mingw32 && \
  sed -i "1iServer = http://mirrors.ustc.edu.cn/msys2/mingw/x86_64" /etc/pacman.d/mirrorlist.mingw64 && \
  sed -i "1iServer = http://mirrors.ustc.edu.cn/msys2/msys/\$arch" /etc/pacman.d/mirrorlist.msys
```

## 3. Repeat Run `pacman -Syuu` until it says there are no packages to update.
## 4. Finally you can do an update of the remaining packages by issuing: `pacman -Suu`

# ConEmu: How to call msys2 as tab?
https://superuser.com/questions/1024301/conemu-how-to-call-msys2-as-tab

# Install custom packages
`pacman -S ccache coreutils gcc gnu-netcat iperf3 lftp make man-db man-pages-posix nano openssh p7zip python python3-pip rsync screenfetch unrar unzip upx vim whois winpty zip`

# git
## ~~git for msys~~
~~`pacman -S git git-extra`~~

## git for windows proper
> https://github.com/valtron/llvm-stuff/wiki/Set-up-Windows-dev-environment-with-MSYS2  
> https://github.com/git-for-windows/git/wiki/Install-inside-MSYS2-proper

### Open an MSYS2 terminal.
> Edit /etc/pacman.conf and just before [mingw32], add the git-for-windows packages repository:  
> and optionally also the MINGW-only repository for the opposite architecture (i.e. MINGW32 for 64-bit SDK):
```
sed -i "/^\[mingw32\]/i\[git-for-windows]\nServer = https://wingit.blob.core.windows.net/x86-64\n" /etc/pacman.conf && \
  sed -i "/^\[mingw32\]/i\[git-for-windows-mingw32]\nServer = https://wingit.blob.core.windows.net/i686\n" /etc/pacman.conf
```

### Authorize signing key (this step may have to be repeated occasionally until https://github.com/msys2/msys2/issues/62 is fixed)
```
curl -fsSL https://raw.githubusercontent.com/git-for-windows/build-extra/master/git-for-windows-keyring/git-for-windows.gpg | pacman-key --add - && pacman-key --lsign-key 1A9F3986
```

### Then synchronize new repository
`pacboy update`

> This updates msys2-runtime and therefore will ask you to close the window (not just exit the pacman process). Don't panic, simply close all currently open MSYS2 shells and MSYS2 programs. Once all are closed, start a new terminal again.

### Then synchronize again (updating the non-core part of the packages):
`pacboy update`

### And finally install the Git/cURL packages:
`pacboy sync git:x git-doc-html:x git-doc-man:x git-extra: curl:x`

> Finally, check that everything went well by doing `git --version` in a MINGW64 shell and it should output something like git version 2.18.1.windows.1 (or newer).

# ZSH
## Modify msys2 profile to fix SHELL & soft link
```
sed -i "/^  profile_d zsh/a\  SHELL=\"\$(which zsh)\"" /etc/profile && \
  sed -i '$a\\nexport MSYS=\"winsymlinks:lnk\"' /etc/profile
```

## Install zsh
`pacman -S zsh`

## Install oh-my-zsh
`sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"`

## Run zsh as default shell
```
tee -a ~/.bashrc <<-'EOF'

# Launch Zsh 
if [[ "${ZSH_VERSION:-unset}" = "unset" ]]; then
  export SHELL=/bin/zsh
  exec zsh
fi
EOF
```

## Setting task in conemu/cmder
### MSYS2::MINGW64 as Admin
**Task parameters:** `/icon "%SystemDrive%\msys64\msys2.ico"`  
**Commands** `*set MSYSTEM=MINGW64 & set HOME=%SystemDrive%\msys64\home\%USERNAME% & cmd /c "%SystemDrive%\msys64\usr\bin\bash --login -i" -new_console:d:"%SystemDrive%\msys64\home\%USERNAME%":t:"MINGW64"`

### MSYS2::MINGW32 as Admin
**Task parameters:** `/icon "%SystemDrive%\msys64\msys2.ico"`  
**Commands** `*set MSYSTEM=MINGW32 & set HOME=%SystemDrive%\msys64\home\%USERNAME% & cmd /c "%SystemDrive%\msys64\usr\bin\zsh --login -i" -new_console:d:"%SystemDrive%\msys64\home\%USERNAME%":t:"MINGW32"`

### MSYS2::MSYS as Admin
**Task parameters:** `/icon "%SystemDrive%\msys64\msys2.ico"`  
**Commands** `*set MSYSTEM=MSYS & set HOME=%SystemDrive%\msys64\home\%USERNAME% & cmd /c "%SystemDrive%\msys64\usr\bin\bash --login -i" -new_console:d:"%SystemDrive%\msys64\home\%USERNAME%":t:"MSYS"`
