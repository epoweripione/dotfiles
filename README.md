# Dotfiles & Scripts
A set of bash, zsh, tmux, powershell, wsl, nodejs, msys2 configuration and script files.

**These scripts only tested on my pc, laptop & cloud host and may not cover all cases, and may contain errors, `use at your own RISK`!**

**Personal use only, make sure do a full test before using them in `Production Environment`!**

**`Best practice:` make a `system backup` or prepare a `live cd` before running these scripts!**

**Linux Distros what I daily use are `Manjaro KDE Plasma`, `Debian`, `Centos Stream`, `WSL2 on Windows 11`.**

# Features
## Linux
- **[Zsh](http://zsh.sourceforge.net)** as default shell
- **[Oh My Zsh](https://ohmyz.sh/)** to managing Zsh configuration
- **ys** theme for Zsh without Graphical Environment
- **[Oh My Posh](https://ohmyposh.dev/)** theme for Zsh with Desktop Environment(KDE, GNOME, XFCE, WSL...)
- [ZSH theme change script](/zsh/zsh_change_theme.sh)
  * ys
  * [agnosterzak](https://github.com/zakaziko99/agnosterzak-ohmyzsh-theme)
  * [agkozak](https://github.com/agkozak/agkozak-zsh-prompt)
  * [alien](https://github.com/eendroroy/alien)
  * [powerlevel10k](https://github.com/romkatv/powerlevel10k)
  * [spaceship](https://github.com/denysdovhan/spaceship-prompt)
- [Zsh plugins](/zsh/zsh_update.sh)
  * [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
  * [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  * [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
  * [fzf-tab](https://github.com/Aloxaf/fzf-tab)
  * [fzf-tab-completion](https://github.com/lincheney/fzf-tab-completion)
  * [forgit](https://github.com/wfxr/forgit)
  * [fuzzy-sys](https://github.com/NullSense/fuzzy-sys)
  * [powerlevel10k](https://github.com/romkatv/powerlevel10k)
  * ...
- Terminal Multiplexers: autostart **Zellij/Tmux/Screen** session on remote system when logging in via `SSH`
  * [Zellij](https://github.com/zellij-org/zellij)
  * [Oh My Tmux](https://github.com/gpakosz/.tmux)
- `Package managers` with `pacman-style` command syntax
  * [pacaptr](https://github.com/rami3l/pacaptr)
  * [pacapt](https://github.com/icy/pacapt)
- [Unix commands](/zsh/zsh_upgrade_all_packages.sh)
  * [fastfetch](https://github.com/fastfetch-cli/fastfetch)
  * [jq](https://jqlang.github.io/jq/)
  * [fzf](https://github.com/junegunn/fzf)
  * [Modern Unix](https://github.com/ibraheemdev/modern-unix)
  * ...
- Helper functions
  * [public](/functions/public.sh): color echo, version compare...
  * [system](/functions/system.sh): cron jobs, systemd services, snapper snapshots...
  * [osinfo](/functions/osinfo.sh): OS type, architecture, release, package manager, icon, virtualized...
  * [network](/functions/network.sh): ipv4, ipv6, url, web service...
  * [proxy](/functions/proxy.sh): get & set proxy
  * [git](/functions/git.sh): clone, update git repos
    + **Git_Clone_Update** clone or update a git repo:
      ```bash
      Git_Clone_Update "username/repository" "$HOME/repository" # default host `https://github.com/`
      Git_Clone_Update "https://gitlab.com/username/repository" "$HOME/repository" # full repo url
      Git_Clone_Update "git@github.com:username/repository.git" "$HOME/repository"
      ```
    + **Git_Clone_Update_Branch** clone or update a git repo only specified branch:
      ```bash
      Git_Clone_Update_Branch "https://github.com/username/repository" "$HOME/repository" # auto get default branch
      Git_Clone_Update_Branch "username/repository" "$HOME/repository" "https://github.com" "dev" # dev branch
      ```
    + **Git_Update_Repo_in_SubDir** update all git repos in subdirectories
      ```bash
      Git_Update_Repo_in_SubDir "$ZSH/custom" # update all ZSH plugins & themes
      ```
  * [docker](/functions/docker.sh): docker mirrors, pull multiple images...
  * [installer](/functions/installer.sh): functions to install apps
  * [versions](/functions/versions.sh): version manager functions for goup, mise, asdf...
  * [web](/functions/web.sh)
  * [misc](/functions/misc.sh)
- [Scripts](/installer/) & [functions](/functions/installer.sh) to install apps
  * Auto resolve download URL that match running platform, especially for apps release on `Github`
  * Speed up downloads with `axel`, if fails use `curl` instead
  * Automatically extract `executable`, `man`, `Zsh completions` files from compressed files and install to corresponding directories(`/usr/local/bin`, `/usr/share/man`, `/usr/local/share/zsh/site-functions`)
  ```bash
  installPrebuiltBinary rclone "rclone/rclone" # github releases
  installPrebuiltBinary nnn "jarun/nnn" "nnn-nerd-.*\.tar\.gz" # github releases
  installPrebuiltBinary earthly "earthly/earthly" "earthly-*" # github releases
  installPrebuiltBinary "https://dev.yorhel.nl/ncdu" "/download/ncdu-[^<>:;,?\"*|/]+\.tar\.gz" "ncdu-.*\.tar\.gz" # full URL
  ```
  * Install app using brew, cargo, go...
  ```bash
  installBuildBinary sd sd cargo
  installBuildBinary fvm fvm brew
  installBuildBinary protoc-gen-go protoc-gen-go go "google.golang.org/protobuf/cmd/protoc-gen-go@latest"
  ```
  * Install apps using installer will set mirrors if the world blocked, you can override them in `~/.dotfiles.env.local`
    + [Homebrew](/installer/homebrew_installer.sh)
      - [https://mirrors.ustc.edu.cn/homebrew-bottles](https://mirrors.ustc.edu.cn/homebrew-bottles)
      - [https://mirrors.ustc.edu.cn/homebrew-core.git](https://mirrors.ustc.edu.cn/homebrew-core.git)
      - [https://mirrors.ustc.edu.cn/homebrew-cask.git](https://mirrors.ustc.edu.cn/homebrew-cask.git)
    + [Docker Registry](/installer/docker_installer.sh)
      - DOCKER_MIRROR_LIST=(...)
    + [Nodejs](/nodejs/nvm_node_installer.sh)
      - [https://npmmirror.com/](https://npmmirror.com/)
    + [Go](/installer/goup_go_installer.sh)
      - [https://goproxy.cn](https://goproxy.cn)
    + [Rust](/installer/cargo_rust_installer.sh)
      - [https://rsproxy.cn](https://rsproxy.cn)
      - [https://rsproxy.cn/rustup](https://rsproxy.cn/rustup)
    + [Python/pip](/installer/python_pip_config.sh)
      - [https://mirrors.aliyun.com/pypi/simple/](https://mirrors.aliyun.com/pypi/simple/)
    + [Anaconda](/installer/conda_python_installer.sh)
      - [https://mirror.sjtu.edu.cn/anaconda/](https://mirror.sjtu.edu.cn/anaconda/)
    + [Flutter](/installer/flutter_installer.sh)
      - [https://pub.flutter-io.cn](https://pub.flutter-io.cn)
      - [https://storage.flutter-io.cn](https://storage.flutter-io.cn)
- [Git configs](/git/git_global_config.sh)
- [Update apps that installed by app store or version managers](/zsh/zsh_upgrade_all_packages.sh)
  * pacman, apt-get, dnf, yum...
  * [Homebrew](https://brew.sh/)
  * [flatpak](https://flatpak.org/)
  * [snap](https://snapcraft.io/)
  * [sdkman](https://sdkman.io/)
  * [conda](https://docs.conda.io/en/latest/)
  * [goup](https://github.com/owenthereal/goup)
  * [rustup](https://rustup.rs/)
  * [nvm](https://github.com/nvm-sh/nvm)
  * [nvs](https://github.com/jasongin/nvs)
  * [asdf](https://asdf-vm.com/)
  * [mise](https://mise.jdx.dev/)
  * [jabba](https://github.com/shyiko/jabba)
  * [version-fox](https://github.com/version-fox/vfox)
  * [version-manager(vmr)](https://github.com/gvcgo/version-manager)
  * ...
- alias for docker: `alias | grep '^docker'`
- [Auto setting environment variables for apps](/functions/env.sh)
  * Snap
  * Homebrew
  * PHP
  * Java
  * Go
  * Flutter
  * Rust
  * Python/pip
  * nvm
  * nvs
  * Ruby
  * krew
  * Oracle Instant Client
  * ...
- `Debian` distro upgrade
  * [10 to 11](/linux/debian_upgrade_10_to_11.sh)
  * [11 to 12](/linux/debian_upgrade_11_to_12.sh)
- `CentOS Stream` distro upgrade
  * [8 to 9](/linux/centos_stream_upgrade_8_to_9.sh)
- Custom environment variables in `~/.dotfiles.env.local`
  * Auto setting proxy if exists, use `127.0.0.1:7890` by default
    ```bash
    GLOBAL_PROXY_IP="127.0.0.1"
    GLOBAL_PROXY_SOCKS_PROTOCOL="socks5"
    GLOBAL_PROXY_SOCKS_PORT="7890"
    GLOBAL_PROXY_MIXED_PORT="7890"
    NO_PROXY_LIST=(
        "127.0.0.1"
        "::1"
        "localhost"
        ".corp"
        ".internal"
        ".local"
        ".localdomain"
    )
    ```
  * git clone options
    ```bash
    GIT_CLONE_DEFAULT_OPTION="-c core.autocrlf=false -c core.filemode=false"
    ```
  * installer options
    ```bash
    INSTALLER_CHECK_CURL_OPTION="-fsL --connect-timeout 5"
    INSTALLER_DOWNLOAD_CURL_OPTION="-fSL --connect-timeout 5"
    INSTALLER_DOWNLOAD_AXEL_OPTION="--num-connections=5 --timeout=30 --alternate"
    ```
  * Github clone & download mirror
    ```bash
    GITHUB_HUB_URL="https://github.com"
    GITHUB_DOWNLOAD_URL="https://github.com"
    GITHUB_RAW_URL="https://raw.githubusercontent.com"
    GITHUB_API_TOKEN=""
    ```
  * mirrors
    ```bash
    USE_MIRROR_WHEN_BLOCKED="true"

    # Debian
    MIRROR_PACKAGE_MANAGER_APT="mirror.sjtu.edu.cn"
    
    # Archlinux
    MIRROR_ARCHLINUX_CN="https://mirrors.sustech.edu.cn"

    # CentOS Stream
    MIRROR_CENTOS_STREAM="https://mirrors.aliyun.com/centos-stream"

    # Rockylinux
    MIRROR_ROCKYLINUX="https://mirrors.aliyun.com/rockylinux"
    MIRROR_EPEL_RELEASE="https://mirrors.aliyun.com"

    # homebrew
    HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
    HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
    HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
    HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

    # flatpak
    MIRROR_FLATPAK_URL="https://mirrors.ustc.edu.cn/flathub"

    # go
    GOUP_GO_HOST="golang.google.cn"
    MIRROR_GO_PROXY="https://goproxy.cn,direct"
    # MIRROR_GO_PROXY="https://goproxy.io,direct"
    # MIRROR_GO_PROXY="https://mirrors.aliyun.com/goproxy/,direct"
    # MIRROR_GO_PROXY="https://proxy.golang.org,direct"
    MIRROR_GO_SUMDB="sum.golang.google.cn"
    # MIRROR_GO_SUMDB="gosum.io+ce6e7565+AY5qEHUk/qmHc5btzW45JVoENfazw8LielDsaI+lEbq6"
    # MIRROR_GO_PRIVATE="*.corp.example.com"

    # flutter
    PUB_HOSTED_URL="https://pub.flutter-io.cn"
    FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
    # PUB_HOSTED_URL="https://mirror.sjtu.edu.cn/dart-pub"
    # FLUTTER_STORAGE_BASE_URL="https://mirror.sjtu.edu.cn"

    # rust
    RUSTUP_DIST_SERVER="https://rsproxy.cn"
    RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
    MIRROR_RUST_CARGO="rsproxy-sparse"
    # RUSTUP_DIST_SERVER="https://mirror.sjtu.edu.cn/rust-static"
    # RUSTUP_UPDATE_ROOT="https://mirror.sjtu.edu.cn/rust-static/rustup"
    # MIRROR_RUST_CARGO="sjtu"

    # nodejs
    MIRROR_NODEJS_REGISTRY="https://registry.npmmirror.com"

    # nvm
    NVM_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node"
    NVM_LOAD_NVMRC_IN_CURRENT_DIRECTORY=false

    # nvs
    NVS_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node"

    # python/pip
    PYTHON_PIP_CONFIG="$HOME/.pip/pip.conf"
    MIRROR_PYTHON_PIP_URL="https://mirrors.sustech.edu.cn/pypi/web/simple"
    MIRROR_PYTHON_PIP_EXTRA=""

    # anaconda
    MIRROR_PYTHON_CONDA="mirrors.sustech.edu.cn"
    # MIRROR_PYTHON_CONDA="https://mirror.sjtu.edu.cn"
    # MIRROR_PYTHON_CONDA="https://mirrors.tuna.tsinghua.edu.cn"

    # ruby
    RUBY_BUILD_MIRROR_URL="https://cache.ruby-china.com"
    RUBY_GEM_SOURCE_MIRROR="https://gems.ruby-china.com/"

    # lyx
    MIRROR_LYX_BASE="https://mirrors.tuna.tsinghua.edu.cn/lyx/"
    ```
  * [Install and/or update Apps](/zsh/zsh_upgrade_all_packages.sh)
    ```bash
    # Apps always install and update
    AppAlwaysInstallList=("asdf" "mise" "as-tree" "bat" "broot" "croc" "dasel" "duf" "dust" "erdtree" "eza" "fd" "git-delta" "lazygit" "lnav" "magic-wormhole" "navi" "nnn" "tealdeer" "yq" "zoxide")
    # Apps only install and update on WSL or Desktop environment
    AppWSLDesktopList=("bottom" "btop" "choose" "curlie" "distrobox" "dog" "fq" "fx" "git-lfs" "gotty" "httpie" "httpie-go" "httpstat" "hyperfine" "lsd" "nali" "ncdu" "nu" "onefetch" "ohmyposh" "poetry" "procs" "pup" "rclone" "re-txt" "restic" "sd" "tig" "usql" "viu" "wrk" "xh")
    # Apps only update when installed
    AppUpdateOnlyList=("frp" "goproxy" "he3" "safe-rm" "mihomo" "mieru" "mita" "subconverter" "sing-box" "flutter")
    ```

### Manjaro
- `BTRFS` filesystem
  * [Install using Calamares on Manjaro Live CD](/manjaro/btrfs_01_before_install.sh)
  * [After install, but before starting the installed system](/manjaro/btrfs_02_after_install_before_restart.sh)
  * [After the first start](/manjaro/btrfs_03_after_install_after_restart.sh)
- Encrypt `BTRFS` with `LUKS2`
  * [Enable LUKS2 and Argon2 support](/manjaro/btrfs_convert_LUKS1_to_LUKS2.sh)
- Enable Snap
- Enable Flatpak
- Enable AUR
- `bootsplash` theme
- `Snapper` to take snapshots on `BTRFS`
- `GRUB` with `Snapper` snapshots
- [Daily use apps](/manjaro/manjaro_setup.sh)
  * Define variable `AppManjaroInstallList=(...)` in `~/.dotfiles.env.local` for apps to install
- `Samba`
- `SmartDNS`
- `CJK` fonts
- `Fcitx5` input methods
- `Rime` 中州韻輸入法引擎
  * [白霜拼音](https://github.com/gaboolic/rime-frost)
  * [雾凇拼音](https://github.com/iDvel/rime-ice)
  * [朙月拼音](https://github.com/rime/rime-luna-pinyin)
  * [粵語拼音](https://github.com/rime/rime-cantonese)
  * [五筆字型 86 版](https://github.com/rime/rime-wubi)
  * [注音](https://github.com/rime/rime-bopomofo)
  * [倉頡](https://github.com/rime/rime-cangjie)
  * [墨奇音形](https://github.com/gaboolic/rime-shuangpin-fuzhuma)
  * 全拼
  * 双拼（小鹤双拼、小鹤九宫双拼、墨奇音形+小鹤双拼、墨奇音形+自然码双拼、墨奇音形+微软双拼、墨奇音形+搜狗双拼、墨奇音形大字集）
  * 五笔（QQ 86五笔、五笔·拼音、五筆·簡入繁出、极点五笔86、极点五笔拼音混输）
  * 粵語拼音
  * Emoji
  * 其他（五筆畫、中古三拼、中古全拼、X-SAMPA、雲龍國際音標、徐码、郑码）
  * ...
- `Emoji` keyboard
- `CUPS`: Printers, Scanner
- `KVM` & `QEMU` Emulator
- `Conky` themes
  * [Hybrid](https://bitbucket.org/dirn-typo/hybrid) on `top-right` of desktop
  * Use [wttr.in](https://wttr.in/) to update [Weather](/snippets/weather_wttr.sh) on `bottom-left` of desktop(`Nodejs` needs installed)
- Run Windows Applications with [cassowary](https://github.com/casualsnek/cassowary)
- Run Windows Applications with [winapps](https://github.com/Osmium-Linux/winapps)
- [Arch Linux Chinese Community Repository](https://github.com/archlinuxcn/mirrorlist-repo) if GEO in `China`
- [Auto setting proxy if exists, use `127.0.0.1:7890` by default](/manjaro/desktop_proxy.sh)
- Accelerate the speed of `AUR PKGBUILD` if the world blocked
  * use `axel` to download, if fails use `curl` instead
  * if download from `github.com`, use env variable `GITHUB_DOWNLOAD_URL` `GITHUB_RAW_URL` if exists

## macOS (Same as `Linux`, but not fully tested)

## Windows
- [Windows Terminal](https://github.com/microsoft/terminal)
- [Powershell](/powershell/)
  * Modules
    + Find-String
    + Posh-git
    + Terminal-Icons
    + PSEverything
    + PSFzf
    + Get-ChildItemColor
    + PoshFunctions
  * [Oh My Posh](https://ohmyposh.dev/) theme
  * [unix-style key bindings](/powershell/Microsoft.PowerShell_profile.ps1)
  * [Tab Expansion with PSFzf](https://github.com/kelleyma49/PSFzf)
  * [Scoop](https://scoop.sh/) to install apps
    + [Scoop & Apps](/powershell/scoop_install_apps.ps1)
  * Custom environment variables in `~/.powershell.env.ps1`
    + Auto setting proxy if exists, use `127.0.0.1:7890` by default
        ```powershell
        $GLOBAL_PROXY_IP="127.0.0.1"
        $GLOBAL_PROXY_MIXED_PORT="7890"
        $GLOBAL_PROXY_HTTP_PORT="7890"
        ```
    + Github clone & download mirror
        ```powershell
        $GITHUB_HUB_URL="https://github.com"
        $GITHUB_DOWNLOAD_URL="https://github.com"
        $GITHUB_RAW_URL="https://raw.githubusercontent.com"
        ```
    + [Helper functions](/powershell/ps_custom_function.ps1)
    + ...
- [WSL](/wsl/wsl2_init.sh)
  * Base on `Debian` distro
  * All the features above for `Linux`
  * [map host ip to wsl](/wsl/wsl2-map-win-localhost.sh)
- [MSYS2](/msys2/)

## Android
- [Termux](/termux_init.sh)

## [Nodejs](/nodejs/)
- Use `npmmirror.com` for `npm` packages if the world blocked
- [pnpm](https://pnpm.io/) to install `npm` packages
- [nvm](https://github.com/nvm-sh/nvm) to manager `node` versions
- [nvs](https://github.com/jasongin/nvs) to manager `node` versions
- `npm-check-updates` to update `npm` packages
- [A simple file server](/nodejs/simpleserver/)

## [NAS](/nas/)
- scripts for `openwrt` (test purpose)

## [K8S](/k8s/)
- Script for `k8s` (test purpose)

## [CJK Text Optimization for Tampermonkey](/cjk/) (unstable)
- Set `font-family` by `html.lang`
  * `Noto` fonts for `SC/TC/HK/JP/KR` locale
  * `emoji` for Emoji
- Add spaces between CJK characters and Latin letters
- Remove hidden obfuscated characters
- Code block pretty
- Element inspector to Screenshot
- Element inspector to Markdown


# Install on Linux
## 1. Use the installed distro package manager to install `curl` and `git`
```bash
sudo pacman -S curl git
sudo apt-get install curl git
sudo dnf install curl git
...
```

## 2. Clone to `$HOME/.dotfiles`
`source <(curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue)`

or

`curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue | bash "$HOME/.dotfiles"`

## 3. Install `Zsh` & `Oh My Zsh`
`${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_installer.sh`

## 4. Set `Zsh` as your login shell
`chsh -s $(which zsh)`

## 5. Install/update packages & init `Zsh` shell
`${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_upgrade_all_packages.sh && ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_init.sh`

# Update
`source <(curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue) && ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_upgrade_all_packages.sh`

## Upgrading npm dependencies
1. Use `npm outdated` to discover dependencies that are out of date.
2. Use `npm update` to perform safe dependency upgrades.
3. Use `npm install <packagename>@latest` to upgrade to the latest major version of a package.

### npm-check
1. Use `npm install -g npm-check` to install the `npm-check` package globally.
2. Use `npm-check -u -y` to upgrade all dependencies to their latest major versions.


# Install on Windows Powershell
## Install [Windows Terminal](https://github.com/microsoft/terminal/releases) if running `Windows 10`
**`Windows 11` has built-in `Windows Terminal`**

## Install [Powershell](https://github.com/kelleyma49/PSFzf/releases)

## Open `Powershell` as Administrator

## Download powershell scripts to `~\Documents\PowerShell\Scripts` via `pwsh_script_download.ps1`
```powershell
curl -fsSL -o "~\pwsh_script_download.ps1" "https://git.io/JPS2j" && ~\pwsh_script_download.ps1
```

## Init `Powershell`
```powershell
~\Documents\PowerShell\Scripts\Powershell_init.ps1
```

## Use `scoop` to batch install apps & fonts
Edit file `~\Documents\PowerShell\Scripts\scoop_install_apps.ps1` to define the apps & fonts you want to install:
- `$Apps` - List of apps to install
- `$sudoApps` - List of apps to install with administrative privileges
- `$sudoFonts` - List of fonts to install with administrative privileges

```powershell
~\Documents\PowerShell\Scripts\scoop_install_apps.ps1
```


# Install on WSL(Windows Subsystem for Linux)
- Install `WSL` distro
```powershell
wsl --list --online
wsl --install -d Debian # or distro which your favor
wsl --update
```
- Open `WSL` distro
- Follow the guide in `Install on Linux`


# commitizen
`${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/commitizen-relax_installer.sh`


# License
MIT
