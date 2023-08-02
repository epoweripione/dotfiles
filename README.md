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
  * [neofetch](https://github.com/dylanaraps/neofetch)
  * [jq](https://jqlang.github.io/jq/)
  * [fzf](https://github.com/junegunn/fzf)
  * [Modern Unix](https://github.com/ibraheemdev/modern-unix)
- Helper functions
  * [public](/functions/public.sh): color echo, version compare...
  * [system](/functions/system.sh): cron jobs, systemd services, snapper snapshots...
  * [osinfo](/functions/osinfo.sh): OS type, architecture, release, package manager, icon, virtualized...
  * [network](/functions/network.sh): ipv4, ipv6, url, web service...
  * [proxy](/functions/proxy.sh): get & set proxy
  * [git](/functions/git.sh): clone, update git repos
  * [docker](/functions/docker.sh): docker mirrors, pull multiple images...
  * [installer](/functions/installer.sh): functions to install apps
  * [versions](/functions/versions.sh): version manager functions for goup, rtx, asdf...
  * [web](/functions/web.sh)
  * [misc](/functions/misc.sh)
- [Scripts](/installer/) & [functions](/functions/installer.sh) to install apps
  * Auto resolve download URL that match running platform, especially for apps release on `Github`
  * Speed up downloads with `axel`, if fails use `curl` instead
  * Automatically extract `executable`, `man`, `Zsh completions` files from compressed files and install to corresponding directories(`/usr/local/bin`, `/usr/share/man`, `/usr/local/share/zsh/site-functions`)
- [Git configs](/git/git_global_config.sh)
- [Update apps that installed by app store or version managers]((/zsh/zsh_upgrade_all_packages.sh))
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
  * [rtx](https://github.com/jdxcode/rtx)
  * [jabba](https://github.com/shyiko/jabba)
  * ...
- alias for docker: `alias | grep '^docker'`
- [Auto setting environment variables for apps](/zsh/zsh_custom_env.sh)
  * Snap
  * Homebrew
  * PHP
  * Java
  * Golang
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
  * Github clone & download mirror
    ```bash
    GITHUB_HUB_URL="https://github.com"
    GITHUB_DOWNLOAD_URL="https://github.com"
    GITHUB_RAW_URL="https://raw.githubusercontent.com"
    ```
  * [Install and/or update Apps](/zsh/zsh_upgrade_all_packages.sh)
    ```bash
    # Apps always install and update
    AppAlwaysInstallList=("asdf" "rtx" "as-tree" "bat" "broot" "croc" "dasel" "duf" "dust" "erdtree" "exa" "fd" "git-delta" "lazygit" "lnav" "magic-wormhole" "navi" "nnn" "skim" "tealdeer" "yq" "zoxide")
    # Apps only install and update on WSL or Desktop environment
    AppWSLDesktopList=("bottom" "btop" "choose" "curlie" "distrobox" "dog" "fq" "fx" "git-lfs" "gotty" "httpie" "httpie-go" "httpstat" "hyperfine" "lsd" "nali" "ncdu" "nu" "onefetch" "ohmyposh" "poetry" "procs" "pup" "rclone" "re-txt" "restic" "sd" "tig" "usql" "viu" "wrk" "xh")
    # Apps only update when installed
    AppUpdateOnlyList=("frp" "goproxy" "he3" "safe-rm" "clash" "mieru" "mita" "subconverter" "sing-box" "trojan" "v2ray" "xray" "flutter")
    ```

### Manjaro
- `BTRFS` filesystem
  * [Install using Calamares on Manjaro Live CD](/manjaro/btrfs_01_before_install.sh)
  * [After install, but before starting the installed system](/manjaro/btrfs_02_after_install_before_restart.sh)
  * [After the first start](/manjaro/btrfs_03_after_install_after_restart.sh)
- Encrypt `BTRFS` with `LUKS2`
  * [Enable LUKS2 and Argon2 support](/manjaro/btrfs_convert_LUKS1_to_LUKS2.sh)
- `bootsplash` theme
- `Snapper` to take snapshots on `BTRFS`
- `GRUB` with `Snapper` snapshots
- [Daily use apps](/manjaro/manjaro_setup.sh)
- `Samba`
- `SmartDNS`
- `CJK` fonts
- `Fcitx5` input methods
- `Emoji` keyboard
- `CUPS`: Printers, Scanner
- `KVM` & `QEMU` Emulator
- `Conky` themes
- Run Windows Applications with [cassowary](https://github.com/casualsnek/cassowary)
- Run Windows Applications with [winapps](https://github.com/Osmium-Linux/winapps)

## Windows
- [ Windows Terminal](https://github.com/microsoft/terminal)
- [Powershell](/powershell/)
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
        $GITHUB_RAW_URL = "https://raw.githubusercontent.com"
        ```
    + Helper functions
- [WSL](/wsl/wsl2_init.sh)
  * Base on `Debian` distro
  * All the features above for `Linux`
  * [map host ip to wsl](/wsl/wsl2-map-win-localhost.sh)
- [MSYS2](/msys2/)

## Android
- [Termux](https://termux.com/)

## [Nodejs](/nodejs/)
- Use `npmmirror.com` for `npm` packages if the world blocked
- [pnpm](https://pnpm.io/) to install `npm` packages
- [nvm](https://github.com/nvm-sh/nvm) to manager `node` versions
- [nvs](https://github.com/jasongin/nvs) to manager `node` versions
- `npm-check-updates` to update `npm` packages

## [NAS](/nas/)
- scripts for `openwrt` (test purpose)

## [K8S](/k8s/)
- Script for `k8s` (test purpose)


# Install
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

### npm-check-updates
1. Use `npm install -g npm-check-updates` to install the `npm-check-updates` package globally.
2. Use `npm-check-updates -u` or `ncu -u` to check newer versions.
3. Use `npm-check-updates -u` or `ncu -u` to upgrade all dependencies to their latest major versions.

### npm-check
1. Use `npm install -g npm-check` to install the `npm-check` package globally.
2. Use `npm-check -u -y` to upgrade all dependencies to their latest major versions.

# commitizen
`${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/commitizen-relax_installer.sh`


# License
MIT
