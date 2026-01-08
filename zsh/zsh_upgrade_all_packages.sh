#!/usr/bin/env zsh

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

# OS Type: darwin, windows, linux, freebsd, openbsd, solaris
# Arch(spruce_type): amd64, 386, arm, arm64, mips64le, mips64, mipsle, mips, s390x, ppc64le, ppc64, riscv64
# VDIS: 64, 32, arm, arm64, mips64le, mips64, mipsle, mips, s390x, ppc64le, ppc64, riscv64
[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch
[[ -z "${OS_INFO_VDIS}" ]] && get_sysArch
[[ -z "${OS_INFO_DESKTOP}" ]] && get_os_desktop

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

## Setting by pass gfw proxy
[[ -s "${MY_SHELL_SCRIPTS}/cross/cross_gfw_config.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/cross_gfw_config.sh"

## WSL2: map host ip to localhost
# if check_os_wsl2; then
#     [[ -s "$HOME/.dotfiles/wsl/wsl2-map-win-localhost.sh" ]] && \
#         source "$HOME/.dotfiles/wsl/wsl2-map-win-localhost.sh"
# fi


# Package managers with pacman-style command syntax
[[ -s "${MY_SHELL_SCRIPTS}/installer/pacman_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/pacman_installer.sh"


colorEcho "${BLUE}Updating ${FUCHSIA}system packages${BLUE}..."
if [[ -x "$(command -v pacman)" ]]; then
    if [[ $UID -ne 0 && "$(command -v yay)" ]]; then
        yay --noconfirm -Syu
    else
        sudo pacman --noconfirm -Syu
    fi
else
    if check_release_package_manager packageManager yum; then
        sudo yum update -y
    elif check_release_package_manager packageManager apt; then
        sudo apt update && sudo apt upgrade -y
    elif check_release_package_manager packageManager pacman; then
        if [[ $UID -ne 0 && "$(command -v yay)" ]]; then
            yay --noconfirm -Syu
        else
            sudo pacman --noconfirm -Syu
        fi
    fi
fi

# Snapper pre snapshots
if [[ -x "$(command -v snapper)" ]]; then
    if snapper list-configs 2>/dev/null | grep -q "root"; then
        SNAPPER_NUM_ROOT=$(sudo snapper -c root create -t pre -p --description "pre ${MY_SHELL_SCRIPTS}/zsh/zsh_upgrade_all_packages.sh")
    fi

    if snapper list-configs 2>/dev/null | grep -q "home"; then
        SNAPPER_NUM_HOME=$(sudo snapper -c home create -t pre -p --description "pre ${MY_SHELL_SCRIPTS}/zsh/zsh_upgrade_all_packages.sh")
    fi
fi

[[ ! -d "/usr/local/bin" ]] && sudo mkdir -p "/usr/local/bin"
[[ ! -d "/usr/local/share/zsh/site-functions" ]] && sudo mkdir -p "/usr/local/share/zsh/site-functions"

if [[ -x "$(command -v docker)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS}/installer/docker_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/docker_installer.sh"
fi


if [[ -x "$(command -v php)" && -x "$(command -v composer)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}composer & composer global packages${BLUE}..."
    composer selfupdate && composer g update
fi


# https://github.com/zyedidia/micro
if [[ -x "$(command -v micro)" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}Micro editor${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/zyedidia/micro/releases/latest"

    INSTALLER_VER_CURRENT=$(micro -version | grep Version | cut -d',' -f2)
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}micro ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        curl https://getmic.ro | bash && sudo mv micro "/usr/local/bin"
    fi
fi


if [[ -d "$HOME/.jabba" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}jabba${BLUE}..."
    if type 'jabba' 2>/dev/null | grep -q 'function'; then
        :
    else
        [[ -s "$HOME/.jabba/jabba.sh" ]] && source "$HOME/.jabba/jabba.sh"
    fi

    INSTALLER_CHECK_URL="https://api.github.com/repos/shyiko/jabba/releases/latest"

    INSTALLER_VER_CURRENT=$(jabba --version | cut -d' ' -f2)
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}jabba ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        curl -fsSL https://github.com/shyiko/jabba/raw/master/install.sh | bash && \
            source "$HOME/.jabba/jabba.sh" && \
            sed -i "/jabba.sh/d" ~/.zshrc
    fi
fi


if [[ -d "$HOME/.sdkman" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}sdk ${BLUE}using sdkman..."
    if type 'sdk' 2>/dev/null | grep -q 'function'; then
        :
    else
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi

    sdk selfupdate && sdk update && printf "Y\n" | sdk upgrade
fi


if [[ -x "$(command -v goup)" ]]; then
    goupUpgrade
    goupRemoveUnuse
fi

if [[ -x "$(command -v rustup)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}Rust toolchains and rustup${BLUE}..."
    rustup upgrade
fi

if [[ -x "$(command -v cargo-binstall)" ]]; then
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/cargo-binstall_installer.sh"
    [[ -f "${AppInstaller}" ]] && source "${AppInstaller}"
fi

if [[ -x "$(command -v cargo-binstall)" ]]; then
    colorEcho "${BLUE}Updating installed binary by ${FUCHSIA}Rust Cargo${BLUE}..."
    cargo binstall --no-confirm $(cargo install --list | egrep '^([a-z0-9_-]+)\s+(v[0-9.]+).*:$' | cut -f1 -d' ')
else
    if [[ -x "$(command -v cargo-install-update)" ]]; then
        colorEcho "${BLUE}Updating installed binary by ${FUCHSIA}Rust Cargo${BLUE}..."
        cargo install-update --all
    fi
fi

# Always install & update apps
# Maybe load app list from `$HOME/.dotfiles.env.local` in `zsh_custom_conf.sh`
if [[ -z "${AppAlwaysInstallList[*]}" ]]; then
    AppAlwaysInstallList=(
        "chsrc"
        # "asdf"
        "mise"
        "as-tree"
        "bat"
        "broot"
        # "busybox"
        "croc"
        "dasel"
        "duf"
        "dust"
        "edit#microsoft/edit#tar.zst#edit*"
        "erdtree"
        # "exa"
        "eza"
        "fd"
        "git-delta"
        "lazygit"
        "lnav"
        "magic-wormhole"
        # "nano"
        "fastfetch#fastfetch-cli/fastfetch#tar.gz#fastfetch*"
        "nnn"
        # "skim"
        "superfile"
        "sttr#abhimanyu003/sttr#tar.gz#sttr*"
        "tailspin"
        "witr#pranshuparmar/witr##witr[^.]+[a-zA-Z0-9\-]+$"
        "yq"
        "zoxide"
        # "clash"
        "mihomo"
        "mieru"
        # "naive#klzgrad/naiveproxy#tar.xz#naive*"
        "sing-box"
        "clash2singbox"
    )
fi
for Target in "${AppAlwaysInstallList[@]}"; do
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    [[ ! -f "${AppInstaller}" ]] && AppInstaller="${MY_SHELL_SCRIPTS}/cross/${Target}_installer.sh"
    if [[ -f "${AppInstaller}" ]]; then
        source "${AppInstaller}"
    else
        if grep -q -E "#" <<<"${Target}"; then
            installPrebuiltBinary "${Target}"
        fi
    fi
done

# zellij
AppInstaller="${MY_SHELL_SCRIPTS}/installer/zellij_installer.sh"
# [[ -z "${ZELLIJ}" && -z "${ZELLIJ_SESSION_NAME}" && -s "${AppInstaller}" ]] && source "${AppInstaller}"
[[ -s "${AppInstaller}" ]] && source "${AppInstaller}"

# tmux
if [[ ! -x "$(command -v zellij)" ]]; then
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/tmux_installer.sh"
    [[ -z "${TMUX}" && -s "${AppInstaller}" ]] && source "${AppInstaller}"
fi

# Always install & update apps in WSL & Desktop environment, otherwise update only for manual install apps
if check_os_wsl; then
    IS_UPDATE_ONLY="no"
else
    [[ -n "${OS_INFO_DESKTOP}" ]] && IS_UPDATE_ONLY="no" || IS_UPDATE_ONLY="yes"
fi

if [[ -z "${AppWSLDesktopList[*]}" ]]; then
    AppWSLDesktopList=(
        "bottom"
        "btop"
        "bandwhich#imsnif/bandwhich#tar.gz#bandwhich*"
        "choose"
        "cpufetch#Dr-Noob/cpufetch##cpufetch_*"
        "curlie"
        "distrobox"
        # "dog"
        "doggo"
        "dysk"
        # [F2 - Command-Line Batch Renaming](https://github.com/ayoisaiah/f2)
        "f2#ayoisaiah/f2#tar.gz#f2*"
        "fish#fish-shell/fish-shell#tar.xz#fish*"
        "fq"
        "fx"
        "gdu#dundee/gdu#tgz#gdu*"
        "git-lfs"
        "gotty"
        "httpie"
        "httpie-go"
        "httpstat"
        "hyperfine"
        # [ImageKit - a powerful and fast command-line tool for batch processing images](https://github.com/hzbd/imagekit)
        "imagekit#hzbd/imagekit##imagekit*"
        # "noxdir#crumbyte/noxdir#tar.gz#noxdir*"
        # [Logdy - terminal logs in web browser](https://github.com/logdyhq/logdy-core)
        "logdy#logdyhq/logdy-core##logdy*"
        "lsd"
        "nali"
        "ncdu"
        "nu"
        "onefetch"
        "ohmyposh"
        "pgenv"
        # "pistol"
        "poetry"
        "procs"
        "pup"
        "rclone"
        "re-txt"
        "restic"
        "sd"
        "somo"
        # "starship"
        "tig"
        # [tldx - Domain Availability Research Tool](https://github.com/brandonyoungdev/tldx)
        "tldx#brandonyoungdev/tldx#tar.gz#tldx*"
        # [Trippy - A network diagnostic tool](https://github.com/fujiapple852/trippy)
        "trip#fujiapple852/trippy#tar.gz#trippy*"
        "usql"
        "uv"
        "vfox"
        "viu"
        "wrk"
        "xh"
        "navi"
        "tealdeer"
    )
fi
for Target in "${AppWSLDesktopList[@]}"; do
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    [[ ! -f "${AppInstaller}" ]] && AppInstaller="${MY_SHELL_SCRIPTS}/cross/${Target}_installer.sh"
    if [[ -f "${AppInstaller}" ]]; then
        source "${AppInstaller}"
    else
        if grep -q -E "#" <<<"${Target}"; then
            installPrebuiltBinary "${Target}"
        fi
    fi
done

# Update only for manual install apps
IS_UPDATE_ONLY="yes"
if [[ -z "${AppUpdateOnlyList[*]}" ]]; then
    AppUpdateOnlyList=(
        # "cgit"
        "frp"
        "goproxy"
        # "gvm_go"
        "he3"
        "lx-music-desktop"
        # "inlets"
        # "proxychains"
        "safe-rm"
        "mita"
        "subconverter"
        "trojan"
        "v2ray"
        "xray"
        "flutter"
        # "tabby"
        "unhide"
    )
fi
for Target in "${AppUpdateOnlyList[@]}"; do
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    [[ ! -f "${AppInstaller}" ]] && AppInstaller="${MY_SHELL_SCRIPTS}/cross/${Target}_installer.sh"
    if [[ -f "${AppInstaller}" ]]; then
        source "${AppInstaller}"
    else
        if grep -q -E "#" <<<"${Target}"; then
            installPrebuiltBinary "${Target}"
        fi
    fi
done

# duckdb
AppInstaller="${MY_SHELL_SCRIPTS}/db/duckdb_installer.sh"
[[ -f "${AppInstaller}" ]] && source "${AppInstaller}"

# Update fonts
IS_UPDATE_ONLY="yes"
if [[ -z "${FontUpdateList[*]}" ]]; then
    FontUpdateList=(
        "AlibabaHealthDesign"
        "DreamHanCJK"
        "MengshenPinyin"
        "ToneOZPinyinKai"
        "ToneOZPinyinWenkai"
        "ToneOZRadicalZ"
        "ToneOZTsuipita"
        "LXGWBright"
        "LXGWBrightCode"
        "LXGWKose"
        "LxgwMarkerGothic"
        "LXGWNeoFusion"
        "LXGWNeoScreen"
        "LXGWNeoXiHeiCode"
        "LxgwXiHei"
        "LXGWYozai"
        "LxgwZhenKai"
        "LxgwZhiSong"
        # "MapleMono_hinted" # for low resolution screen(e.g. screen resolution is lower or equal than 1080P)
        "MapleMono_unhinted" # high resolution screen (e.g. 2K, 4K, Retina for MacBook)
    )
fi
for Target in "${FontUpdateList[@]}"; do
    FontInstaller="${MY_SHELL_SCRIPTS}/fonts/${Target}_installer.sh"
    [[ ! -f "${FontInstaller}" ]] && FontInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    [[ -f "${FontInstaller}" ]] && source "${FontInstaller}"
done

# AI
IS_UPDATE_ONLY="yes"
if [[ -z "${AIUpdateList[*]}" ]]; then
    AIUpdateList=(
        "ollama"
    )
fi
for Target in "${AIUpdateList[@]}"; do
    AIInstaller="${MY_SHELL_SCRIPTS}/AI/${Target}_installer.sh"
    [[ ! -f "${AIInstaller}" ]] && AIInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    [[ -f "${AIInstaller}" ]] && source "${AIInstaller}"
done

unset IS_UPDATE_ONLY

if [[ "$(command -v micromamba)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}all installed miniforge packages${BLUE}..."
    micromamba self-update
    micromamba update -y --all
elif [[ "$(command -v mamba)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}all installed miniforge packages${BLUE}..."
    mamba update -y --all
elif [[ -x "$(command -v conda)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}all installed conda packages${BLUE}..."
    conda update -y --all
fi

if [[ "$(command -v pixi)" ]]; then
    pixi self-update
fi

if [[ -x "$(command -v fnm)" && -s "${MY_SHELL_SCRIPTS}/nodejs/fnm_node_updater.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/nodejs/fnm_node_updater.sh"
fi

if [[ -d "$HOME/.nvm" && -s "${MY_SHELL_SCRIPTS}/nodejs/nvm_node_updater.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/nodejs/nvm_node_updater.sh"
fi

if [[ -d "$HOME/.nvs" && -s "${MY_SHELL_SCRIPTS}/nodejs/nvs_node_updater.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/nodejs/nvs_node_updater.sh"
fi

if [[ -d "$HOME/.bun" && -s "${MY_SHELL_SCRIPTS}/nodejs/bun_installer.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/nodejs/bun_installer.sh"
fi

if [[ -d "$HOME/.asdf" && ! "$(command -v mise)" ]]; then
    [[ ! "$(command -v asdf)" ]] && source "$HOME/.asdf/asdf.sh"
    [[ "$(command -v asdf)" ]] && asdf_App_Update
fi

if [[ "$(command -v mise)" ]]; then
    mise_App_Update
fi

if [[ "$(command -v vfox)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}all version-fox packages${BLUE}..."
    vfox update --all
fi

# if [[ "$(command -v vmr-update)" ]]; then
#     colorEcho "${BLUE}Updating ${FUCHSIA}version-manager(vmr)${BLUE}..."
#     vmr-update
# fi

if [[ -x "$(command -v navi)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}navi featured cheatsheets${BLUE}..."
    Git_Update_Repo_in_SubDir "$(navi info cheats-path)"
fi

if [[ -x "$(command -v tldr)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}tldr cheatsheets${BLUE}..."
    # tldr --update
    case "${OS_INFO_TYPE}" in
        darwin)
            TLDR_PAGES="$HOME/Library/Application Support/tldr"
            ;;
        windows)
            # TLDR_PAGES="$HOME/AppData/Roaming/tldr"
            TLDR_PAGES=""
            ;;
        *)
            TLDR_PAGES="$HOME/.local/share/tldr"
            ;;
    esac
    [[ -n "${TLDR_PAGES}" ]] && Git_Clone_Update_Branch "tldr-pages/tldr" "${TLDR_PAGES}"

    # tealdeer Pages cache
    if tldr -v | grep -q 'tealdeer'; then
        # tldr --show-paths
        if [[ ! -L "$HOME/.cache/tealdeer/tldr-pages" && -d "${TLDR_PAGES}" ]]; then
            [[ -d "$HOME/.cache/tealdeer/tldr-pages" ]] && rm -rf "$HOME/.cache/tealdeer/tldr-pages"
            mkdir -p "$HOME/.cache/tealdeer" && \
                ln -s "${TLDR_PAGES}" "$HOME/.cache/tealdeer/tldr-pages" || true
        fi
    fi
fi

if [[ -x "$(command -v flatpak)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}all Flatpak packages${BLUE}..."
    flatpak upgrade -y
fi

if [[ -x "$(command -v snap)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}all Snap packages${BLUE}..."
    sudo snap refresh
fi

if [[ -x "$(command -v brew)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}all homebrew packages${BLUE}..."
    # brew cleanup
    brew update
    brew upgrade
fi

if [[ -x "$(command -v mc)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}mc${BLUE}..."
    mc update
fi

# oh-my-fish
if [[ -x "$(command -v fish)" && ! -d "$HOME/.local/share/omf" ]]; then
    curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
    # omf search autojump
    # omf install z

    # fish_config
fi

# if [[ -x "$(command -v pip)" ]]; then
#     colorEcho "${BLUE}Updating ${FUCHSIA}pip installed user packages${BLUE}..."
#     # https://stackoverflow.com/questions/68673221/warning-running-pip-as-the-root-user
#     # pip list -o | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 \
#     #     | xargs --no-run-if-empty -n1 pip install --root-user-action=ignore --user -U
#     pip list -o | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 \
#         | xargs --no-run-if-empty -n1 pip install --user -U
# fi

# fastfetch -c "$HOME/fastfetch_all.jsonc"
if [[ ! -f "$HOME/fastfetch_all.jsonc" ]]; then
    curl -fsSL -o "$HOME/fastfetch_all.jsonc" \
        "https://raw.githubusercontent.com/fastfetch-cli/fastfetch/dev/presets/all.jsonc"
fi

# Wayland IME Support
if [[ "${XDG_SESSION_TYPE}" == "wayland" ]]; then
    # setWaylandIMEChrome
    # setWaylandIMEVSCode
    setWaylandIMEWPSOffice
fi

if [[ -n "$ZSH" ]]; then
    if [[ -s "${MY_SHELL_SCRIPTS}/zsh/zsh_update.sh" ]]; then
        colorEcho "${BLUE}Updating ${FUCHSIA}oh-my-zsh & custom stuff${BLUE}..."
        source "${MY_SHELL_SCRIPTS}/zsh/zsh_update.sh"
        # -i : Force shell to be interactive
        # Then, if the shell is interactive, 
        # commands are read from /etc/zshrc 
        # and then $ZDOTDIR/.zshrc (this is usually your $HOME/.zshrc)
        # -c : Run a command in this shell
        # zsh -i -c "${MY_SHELL_SCRIPTS}/zsh/zsh_update.sh"
    fi
fi

# Snapper post snapshots
if [[ -x "$(command -v snapper)" ]]; then
    if [[ -n "${SNAPPER_NUM_ROOT}" ]]; then
        sudo snapper -c root create -t post --pre-number "${SNAPPER_NUM_ROOT}" --description "post ${MY_SHELL_SCRIPTS}/zsh/zsh_upgrade_all_packages.sh"
    fi

    if [[ -n "${SNAPPER_NUM_HOME}" ]]; then
        sudo snapper -c home create -t post --pre-number "${SNAPPER_NUM_HOME}" --description "post ${MY_SHELL_SCRIPTS}/zsh/zsh_upgrade_all_packages.sh"
    fi

    if [[ -n "${SNAPPER_NUM_ROOT}" || -n "${SNAPPER_NUM_HOME}" ]]; then
        if check_os_arch; then
            # GRUB tweaks & Regenrate GRUB2 configuration
            [[ -s "${MY_SHELL_SCRIPTS}/manjaro/grub-tweaks.sh" ]] && source "${MY_SHELL_SCRIPTS}/manjaro/grub-tweaks.sh"
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit
colorEcho "${GREEN}Upgarde all packages done!"
