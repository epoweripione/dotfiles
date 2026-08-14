# Dotfiles & System Configuration Scripts

A comprehensive collection of dotfiles, shell scripts, environment configurations, and automation tools for **Linux** (Manjaro, Debian, CentOS Stream, Ubuntu), **macOS**, **Windows** (PowerShell, WSL2, MSYS2), and **Android** (Termux).

> [!WARNING]
> **Use at your own risk!** These scripts are tested primarily on my personal workstations, laptops, and cloud servers. They may not cover every edge case.
> Make sure to conduct thorough testing before running these scripts in a production environment.
> **Best Practice:** Create a full system backup or prepare a live boot disk prior to execution.

---

## Operating Systems & Workstations
* **Primary Workstation OS:** Manjaro Linux (KDE Plasma)
* **Server Distributions:** Debian, CentOS Stream
* **Windows Environment:** Windows 11 with WSL2 (Debian) & PowerShell 7

---

## Features & Modules

### Linux & Shell Environment
* **Shell:** [Zsh](http://zsh.sourceforge.net/) managed via [Oh My Zsh](https://ohmyz.sh/).
* **Prompt Themes:**
  * `ys` theme for headless / server environments.
  * [Oh My Posh](https://ohmyposh.dev/) for desktop environments (KDE, GNOME, XFCE, WSL).
  * Theme switcher script ([/zsh/zsh_change_theme.sh](./zsh/zsh_change_theme.sh)) supporting `ys`, [agnosterzak](https://github.com/zakaziko99/agnosterzak-ohmyzsh-theme), [agkozak](https://github.com/agkozak/agkozak-zsh-prompt), [alien](https://github.com/eendroroy/alien), [powerlevel10k](https://github.com/romkatv/powerlevel10k), and [spaceship](https://github.com/denysdovhan/spaceship-prompt).
* **Zsh Plugins:** Automatic updates ([/zsh/zsh_update.sh](./zsh/zsh_update.sh)) for `zsh-syntax-highlighting`, `zsh-autosuggestions`, `fast-syntax-highlighting`, `fzf-tab`, `fzf-tab-completion`, `forgit`, `fuzzy-sys`, `powerlevel10k`, etc.
* **Terminal Multiplexers:** Auto-start SSH session multiplexing with [Zellij](https://github.com/zellij-org/zellij), [Oh My Tmux](https://github.com/gpakosz/.tmux), or `Screen`.
* **Universal Package Management:** Pacman-style syntax wrapper via [pacaptr](https://github.com/rami3l/pacaptr) and [pacapt](https://github.com/icy/pacapt).
* **Modern CLI Tools Integration:** Integrated installation and setup for [fastfetch](https://github.com/fastfetch-cli/fastfetch), [jq](https://jqlang.github.io/jq/), [fzf](https://github.com/junegunn/fzf), and other [Modern Unix](https://github.com/ibraheemdev/modern-unix) utilities.

### Modular Shell Helper Functions (`/functions/`)
* [public.sh](./functions/public.sh): Colored echo outputs, version comparison functions.
* [system.sh](./functions/system.sh): Cron job management, systemd service setup, Snapper backup snapshot controls.
* [osinfo.sh](./functions/osinfo.sh): OS detection, architecture info, release versioning, package manager detection, desktop icons, virtualization detection.
* [network.sh](./functions/network.sh): IPv4/IPv6 utility functions, URL handling, web service health checks.
* [proxy.sh](./functions/proxy.sh): Environment-wide proxy getters and setters.
* [git.sh](./functions/git.sh): Git repository cloning and updating utilities:
  ```bash
  # Clone or update a repository (default host: https://github.com/)
  Git_Clone_Update "username/repository" "$HOME/repository"
  Git_Clone_Update "https://gitlab.com/username/repository" "$HOME/repository"
  Git_Clone_Update "git@github.com:username/repository.git" "$HOME/repository"

  # Clone or update a specific branch
  Git_Clone_Update_Branch "https://github.com/username/repository" "$HOME/repository"
  Git_Clone_Update_Branch "username/repository" "$HOME/repository" "https://github.com" "dev"

  # Update all subdirectories containing Git repositories
  Git_Update_Repo_in_SubDir "$ZSH/custom"
  ```
* [docker.sh](./functions/docker.sh): Registry mirror configurations and multi-image pull helpers.
* [installer.sh](./functions/installer.sh): Application installation utilities with automatic release resolution.
* [versions.sh](./functions/versions.sh): Multi-version manager integrations (goup, mise, asdf, etc.).
* [env.sh](./functions/env.sh): Environment variable auto-loader for Snap, Homebrew, PHP, Java, Go, Flutter, Rust, Python, Node version managers, Ruby, Krew, Oracle Instant Client, etc.
* Additional modules: [web.sh](./functions/web.sh), [misc.sh](./functions/misc.sh).

### Automated Installer Framework (`/installer/`)
* **Smart URL Resolution:** Automatically fetches release binaries matching system architecture (x86_64, arm64, etc.) directly from GitHub releases or custom URLs.
* **Accelerated Downloads:** Uses `axel` for multi-threaded downloads with automatic failover to `curl`.
* **Automated Installation:** Extracts executable binaries, man pages, and Zsh completion files directly into system paths (`/usr/local/bin`, `/usr/share/man`, `/usr/local/share/zsh/site-functions`).
  ```bash
  # Prebuilt Binary Installation
  installPrebuiltBinary rclone "rclone/rclone"
  installPrebuiltBinary nnn "jarun/nnn" "nnn-nerd-.*\.tar\.gz"
  installPrebuiltBinary earthly "earthly/earthly" "earthly-*"
  installPrebuiltBinary "https://dev.yorhel.nl/ncdu" "/download/ncdu-[^<>:;,?\"*|/]+\.tar\.gz" "ncdu-.*\.tar\.gz"

  # Build from Source Installation
  installBuildBinary sd sd cargo
  installBuildBinary fvm fvm brew
  installBuildBinary protoc-gen-go protoc-gen-go go "google.golang.org/protobuf/cmd/protoc-gen-go@latest"
  ```
* **Preconfigured Regional Mirrors:** Speeds up downloads in restricted network environments (overrideable via `~/.dotfiles.env.local`):
  * **[Homebrew](./installer/homebrew_installer.sh):** USTC mirrors (`homebrew-bottles`, `homebrew-core`, `homebrew-cask`).
  * **[Docker Registry](./installer/docker_installer.sh):** Custom registry mirrors list.
  * **Node.js:** [fnm](./nodejs/fnm_node_installer.sh), [nvm](./nodejs/nvm_node_installer.sh), and [nvs](./nodejs/nvs_node_installer.sh) using `npmmirror.com`.
  * **[Go](./installer/goup_go_installer.sh):** `goproxy.cn`.
  * **[Rust](./installer/cargo_rust_installer.sh):** `rsproxy.cn`.
  * **[Python/pip](./installer/python_pip_config.sh):** Aliyun & SUSTech PyPI mirrors.
  * **[Anaconda](./installer/conda_python_installer.sh):** SJTU Anaconda mirror.
  * **[Flutter](./installer/flutter_installer.sh):** `pub.flutter-io.cn` and `storage.flutter-io.cn`.

### Package Maintenance & Version Managers
The system update script ([/zsh/zsh_upgrade_all_packages.sh](./zsh/zsh_upgrade_all_packages.sh)) standardizes updates across OS package managers and runtime version managers:
* Native package managers (`pacman`, `apt`, `dnf`, `yum`)
* [Homebrew](https://brew.sh/), [Flatpak](https://flatpak.org/), [Snap](https://snapcraft.io/)
* Version managers: `sdkman`, `conda`, `goup`, `rustup`, `nvm`, `nvs`, `asdf`, `mise`, `jabba`, `version-fox` (vfox), `version-manager` (vmr).

### Local Customizations (`~/.dotfiles.env.local`)
Create `~/.dotfiles.env.local` to customize environment variables, proxy settings, git defaults, download options, mirrors, and package lists:

```bash
# Global Network Proxy Setup (Default: 127.0.0.1:7890)
GLOBAL_PROXY_IP="127.0.0.1"
GLOBAL_PROXY_SOCKS_PROTOCOL="socks5"
GLOBAL_PROXY_SOCKS_PORT="7890"
GLOBAL_PROXY_MIXED_PORT="7890"
NO_PROXY_LIST=("127.0.0.1" "::1" "localhost" ".corp" ".internal" ".local" ".localdomain")

# Git Default Options
GIT_CLONE_DEFAULT_OPTION="-c core.autocrlf=false -c core.filemode=false"

# Installer Download Options
INSTALLER_CHECK_CURL_OPTION="-fsL --connect-timeout 5"
INSTALLER_DOWNLOAD_CURL_OPTION="-fSL --connect-timeout 5"
INSTALLER_DOWNLOAD_AXEL_OPTION="--num-connections=5 --timeout=30 --alternate"

# GitHub Mirror URLs & API Token
GITHUB_HUB_URL="https://github.com"
GITHUB_DOWNLOAD_URL="https://github.com"
GITHUB_RAW_URL="https://raw.githubusercontent.com"
GITHUB_API_TOKEN=""

# Package Mirrors Configuration
USE_MIRROR_WHEN_BLOCKED="true"
MIRROR_PACKAGE_MANAGER_APT="mirrors.sustech.edu.cn"
MIRROR_ARCHLINUX_CN="https://mirrors.sustech.edu.cn"
MIRROR_CENTOS_STREAM="https://mirrors.aliyun.com/centos-stream"
MIRROR_ROCKYLINUX="https://mirrors.aliyun.com/rockylinux"
MIRROR_EPEL_RELEASE="https://mirrors.aliyun.com"
HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
MIRROR_FLATPAK_URL="https://mirrors.ustc.edu.cn/flathub"
GOUP_GO_HOST="golang.google.cn"
MIRROR_GO_PROXY="https://goproxy.cn,direct"
MIRROR_GO_SUMDB="sum.golang.google.cn"
PUB_HOSTED_URL="https://pub.flutter-io.cn"
FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
RUSTUP_DIST_SERVER="https://rsproxy.cn"
RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
MIRROR_RUST_CARGO="rsproxy-sparse"
MIRROR_NODEJS_REGISTRY="https://registry.npmmirror.com"
NVM_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node"
NVS_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node"
PYTHON_PIP_CONFIG="$HOME/.pip/pip.conf"
MIRROR_PYTHON_PIP_URL="https://mirrors.sustech.edu.cn/pypi/web/simple"
MIRROR_PYTHON_CONDA="mirrors.sustech.edu.cn"
RUBY_BUILD_MIRROR_URL="https://cache.ruby-china.com"
RUBY_GEM_SOURCE_MIRROR="https://gems.ruby-china.com/"

# Application Installation Playlists
AppAlwaysInstallList=("asdf" "mise" "as-tree" "bat" "broot" "croc" "dasel" "duf" "dust" "erdtree" "eza" "fd" "git-delta" "lazygit" "lnav" "magic-wormhole" "navi" "nnn" "tealdeer" "yq" "zoxide")
AppWSLDesktopList=("bottom" "btop" "choose" "curlie" "distrobox" "dog" "fq" "fx" "git-lfs" "gotty" "httpie" "httpie-go" "httpstat" "hyperfine" "lsd" "nali" "ncdu" "nu" "onefetch" "ohmyposh" "poetry" "procs" "pup" "rclone" "re-txt" "restic" "sd" "tig" "usql" "viu" "wrk" "xh")
AppUpdateOnlyList=("frp" "goproxy" "he3" "safe-rm" "mihomo" "mieru" "mita" "subconverter" "sing-box" "flutter")
```

### Manjaro Linux & Desktop Setup (`/manjaro/`)
* **BTRFS Filesystem Workflow:**
  * [Pre-install script for Calamares on Live CD](./manjaro/btrfs_01_before_install.sh)
  * [Post-installation script before restart](./manjaro/btrfs_02_after_install_before_restart.sh)
  * [Post-first-boot configuration](./manjaro/btrfs_03_after_install_after_restart.sh)
  * [LUKS2 & Argon2 encryption conversion](./manjaro/btrfs_convert_LUKS1_to_LUKS2.sh)
* **Package Backends:** Snap, Flatpak, AUR enabled out-of-the-box.
* **Backup & Recovery:** `Snapper` snapshot integration paired with GRUB boot items.
* **Desktop Workstation Setup:**
  * Automated installation via [manjaro_setup.sh](./manjaro/manjaro_setup.sh).
  * Samba file sharing, SmartDNS server configuration.
  * CJK fonts & Fcitx5 input engine integration.
  * Comprehensive **Rime Input Method** schemas:
    * [Frost Pinyin (白霜拼音)](https://github.com/gaboolic/rime-frost)
    * [Ice Pinyin (雾凇拼音)](https://github.com/iDvel/rime-ice)
    * [Luna Pinyin (朙月拼音)](https://github.com/rime/rime-luna-pinyin)
    * [Cantonese Jyutping (粵語拼音)](https://github.com/rime/rime-cantonese)
    * [Wubi 86 (五筆字型 86 版)](https://github.com/rime/rime-wubi)
    * [Bopomofo / Zhuyin (注音)](https://github.com/rime/rime-bopomofo)
    * [Cangjie (倉頡)](https://github.com/rime/rime-cangjie)
    * [Moqi Phonetic-Shape (墨奇音形)](https://github.com/gaboolic/rime-shuangpin-fuzhuma)
    * Quanpin, Shuangpin variants (Flypy, Xiaohe 9-Key, Zirancode, MS, Sogou), Wubi variants (QQ 86, Wubi-Pinyin, Jidian), Emoji, Middle Chinese, IPA, Xuma, Zhengma, etc.
  * Emoji keyboard integration & CUPS printer/scanner services.
  * KVM & QEMU virtualization environment.
  * **Conky Themes:** Top-right `Hybrid` desktop widget, bottom-left weather info powered by [wttr.in](https://wttr.in/) ([weather_wttr.sh](./snippets/weather_wttr.sh)).
  * Seamless Windows application execution via [Cassowary](https://github.com/casualsnek/cassowary) and [WinApps](https://github.com/Osmium-Linux/winapps).
  * Arch Linux Chinese Community Repository (archlinuxcn) mirror setup and AUR PKGBUILD acceleration.

### Linux Distribution Upgrades (`/linux/`)
* **Debian Major Version Upgrades:**
  * [Debian 10 to 11](./linux/debian_upgrade_10_to_11.sh)
  * [Debian 11 to 12](./linux/debian_upgrade_11_to_12.sh)
  * [Debian 12 to 13](./linux/debian_upgrade_12_to_13.sh)
* **CentOS Stream Upgrades:**
  * [CentOS Stream 8 to 9](./linux/centos_stream_upgrade_8_to_9.sh)

### Windows & PowerShell Environment (`/powershell/`)
* **Windows Terminal & PowerShell 7** support.
* **PowerShell Profile & Custom Modules:** `Find-String`, `Posh-git`, `Terminal-Icons`, `PSEverything`, `PSFzf`, `Get-ChildItemColor`, `PoshFunctions`.
* **Prompt Theme:** [Oh My Posh](https://ohmyposh.dev/) with Unix-style key bindings ([Microsoft.PowerShell_profile.ps1](./powershell/Microsoft.PowerShell_profile.ps1)).
* **Fuzzy Tab Completion:** Powered by `PSFzf`.
* **Package Management:** [Scoop](https://scoop.sh/) automation script ([scoop_install_apps.ps1](./powershell/scoop_install_apps.ps1)) supporting standard apps, elevated apps (`$sudoApps`), and elevated fonts (`$sudoFonts`).
* **Environment Configuration (`~/.powershell.env.ps1`):** Network proxy setup, GitHub mirror options, and custom helper functions ([ps_custom_function.ps1](./powershell/ps_custom_function.ps1)).
* **WSL2 Integration (`/wsl/`):**
  * Automated initialization based on Debian ([wsl2_init.sh](./wsl/wsl2_init.sh)).
  * Host IP mapping helper script ([wsl2-map-win-localhost.sh](./wsl/wsl2-map-win-localhost.sh)).
* **MSYS2 Environment (`/msys2/`):** Scripts and configuration setups for MSYS2.

### Additional Target Platforms & Tools
* **Android / Termux (`/termux_init.sh`):** Termux initialization script with shell tools and package environment.
* **Node.js Development Environment (`/nodejs/`):** `pnpm`, `npm-check-updates`, version management via `fnm`/`nvm`/`nvs`, and a lightweight file server ([simpleserver](./nodejs/simpleserver/)).
* **NAS & OpenWrt (`/nas/`):** OpenWrt network and storage utility scripts.
* **Kubernetes (`/k8s/`):** Helper scripts for local and remote Kubernetes cluster management.
* **CJK Text Optimization Tampermonkey Script (`/cjk/`):** Web user script for auto-selecting locale fonts (SC, TC, HK, JP, KR, Emoji), adding spaces between CJK and Latin text, removing hidden obfuscated characters, prettifying code blocks, and exporting inspected elements to screenshots or Markdown.

---

## Installation Guide

### Installation on Linux / macOS / WSL

#### 1. Install prerequisites using your system package manager
```bash
# Arch Linux / Manjaro
sudo pacman -S curl git

# Debian / Ubuntu
sudo apt-get update && sudo apt-get install -y curl git

# RHEL / Fedora / CentOS Stream
sudo dnf install -y curl git
```

#### 2. Clone the repository to `$HOME/.dotfiles`
```bash
source <(curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue)
```
*Alternatively:*
```bash
curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue | bash "$HOME/.dotfiles"
```

#### 3. Install Zsh & Oh My Zsh
```bash
"${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_installer.sh"
```

#### 4. Set Zsh as your default login shell
```bash
chsh -s "$(which zsh)"
```

#### 5. Install/update packages and initialize Zsh
```bash
"${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_upgrade_all_packages.sh" && "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_init.sh"
```

---

### Installation on Windows (PowerShell)

1. **Install Windows Terminal & PowerShell 7** (Built-in on Windows 11; installable via Microsoft Store / GitHub on Windows 10).
2. **Open PowerShell as Administrator**.
3. **Download scripts to `~\Documents\PowerShell\Scripts`:**
   ```powershell
   curl -fsSL -o "~\pwsh_script_download.ps1" "https://git.io/JPS2j" && ~\pwsh_script_download.ps1
   ```
4. **Initialize PowerShell profile:**
   ```powershell
   ~\Documents\PowerShell\Scripts\Powershell_init.ps1
   ```
5. **Batch install applications and fonts via Scoop:**
   Edit `~\Documents\PowerShell\Scripts\scoop_install_apps.ps1` to configure `$Apps`, `$sudoApps`, and `$sudoFonts`, then execute:
   ```powershell
   ~\Documents\PowerShell\Scripts\scoop_install_apps.ps1
   ```

---

### Installation on WSL (Windows Subsystem for Linux)

1. **Install a WSL distribution (e.g. Debian):**
   ```powershell
   wsl --list --online
   wsl --install -d Debian
   wsl --update
   ```
2. **Launch the WSL distribution** and follow the **[Installation on Linux](#installation-on-linux--macos--wsl)** section above.

---

## Maintenance & Updates

### Updating Dotfiles & Managed Packages
To update the dotfiles repository and all managed system packages:
```bash
source <(curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue) && "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_upgrade_all_packages.sh"
```

### Upgrading Node.js / npm Dependencies
```bash
# Check outdated dependencies
npm outdated

# Upgrade dependencies within semver constraints
npm update

# Upgrade to latest major version
npm install <packagename>@latest

# Upgrade all dependencies globally via npm-check
npm install -g npm-check
npm-check -u -y
```

### Commitizen Setup
To install Commitizen helper rules:
```bash
"${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/commitizen-relax_installer.sh"
```

---

## License
Distributed under the [MIT License](./LICENSE).
