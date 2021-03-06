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

OS_INFO_WSL=$(uname -r)

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

## Setting by pass gfw proxy
[[ -s "${MY_SHELL_SCRIPTS}/cross/cross_gfw_config.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/cross_gfw_config.sh"

# WSL2: map host ip to localhost
if [[ "${OS_INFO_WSL}" =~ "microsoft" ]]; then
    [[ -s "$HOME/.dotfiles/wsl/wsl2-map-win-localhost.sh" ]] && \
        source "$HOME/.dotfiles/wsl/wsl2-map-win-localhost.sh"
fi


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


if [[ -x "$(command -v docker)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS}/installer/docker_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/docker_installer.sh"
fi


if [[ -x "$(command -v php)" && -x "$(command -v composer)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}composer & composer global packages${BLUE}..."
    composer selfupdate && composer g update
fi


# https://github.com/zyedidia/micro
if [[ -x "$(command -v micro)" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}Micro editor${BLUE}..."

    CHECK_URL="https://api.github.com/repos/zyedidia/micro/releases/latest"

    CURRENT_VERSION=$(micro -version | grep Version | cut -d',' -f2)
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_gt "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}micro ${YELLOW}${REMOTE_VERSION}${BLUE}..."
        curl https://getmic.ro | bash && sudo mv micro "/usr/local/bin"
    fi
fi


if [[ -d "$HOME/.jabba" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}jabba${BLUE}..."
    if type 'jabba' 2>/dev/null | grep -q 'function'; then
        :
    else
        [[ -s "$HOME/.jabba/jabba.sh" ]] && source "$HOME/.jabba/jabba.sh"
    fi

    CHECK_URL="https://api.github.com/repos/shyiko/jabba/releases/latest"

    CURRENT_VERSION=$(jabba --version | cut -d' ' -f2)
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_gt "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}jabba ${YELLOW}${REMOTE_VERSION}${BLUE}..."
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


[[ -x "$(command -v goup)" ]] && goup_Upgrade


if [[ -x "$(command -v rustup)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA} Rust toolchains and rustup${BLUE}..."
    rustup upgrade
fi


# Always install & update apps
AppList=(
    "as-tree"
    "asdf"
    "bat"
    "broot"
    "busybox"
    "croc"
    "dasel"
    "duf"
    "dust"
    "exa"
    "fd"
    "git-delta"
    "lazygit"
    "lnav"
    "magic-wormhole"
    # "nano"
    "navi"
    "nnn"
    "tealdeer"
    "yq"
    "zoxide"
)
for Target in "${AppList[@]}"; do
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    [[ -s "${AppInstaller}" ]] && source "${AppInstaller}"
done

# tmux
AppInstaller="${MY_SHELL_SCRIPTS}/installer/tmux_installer.sh"
[[ -z "$TMUX" && -s "${AppInstaller}" ]] && source "${AppInstaller}"

# Always install & update apps in WSL & Desktop environment, otherwise update only for manual install apps
[[ "${OS_INFO_WSL}" =~ "Microsoft" || "${OS_INFO_WSL}" =~ "microsoft" || -n "${OS_INFO_DESKTOP}" ]] && IS_UPDATE_ONLY="no" || IS_UPDATE_ONLY="yes"
AppList=(
    "bottom"
    "btop"
    "choose"
    "curlie"
    "distrobox"
    "dog"
    "fq"
    "fx"
    "git-lfs"
    "gotty"
    "httpie"
    "httpie-go"
    "httpstat"
    "hyperfine"
    "lsd"
    "nali"
    "ncdu"
    "nu"
    "onefetch"
    "ohmyposh"
    # "pistol"
    "poetry"
    "procs"
    "pup"
    "rclone"
    "re-txt"
    "restic"
    "sd"
    "starship"
    "tig"
    "usql"
    "viu"
)
for Target in "${AppList[@]}"; do
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    [[ -s "${AppInstaller}" ]] && source "${AppInstaller}"
done

# Update only for manual install apps
IS_UPDATE_ONLY="yes"
AppList=(
    # "cgit"
    "frp"
    "goproxy"
    # "gvm_go"
    # "inlets"
    # "proxychains"
    "safe-rm"
    "clash"
    "subconverter"
    "trojan"
    "v2ray"
    "xray"
    "flutter"
)
for Target in "${AppList[@]}"; do
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    [[ ! -s "${AppInstaller}" ]] && AppInstaller="${MY_SHELL_SCRIPTS}/cross/${Target}_installer.sh"
    [[ -s "${AppInstaller}" ]] && source "${AppInstaller}"
done

unset AppList
unset Target
unset AppInstaller
unset OS_INFO_WSL
unset IS_UPDATE_ONLY


if [[ -x "$(command -v conda)" ]]; then
    # colorEcho "${BLUE}Updating ${FUCHSIA}conda${BLUE}..."
    # conda update -y conda

    colorEcho "${BLUE}Updating ${FUCHSIA}all installed conda packages${BLUE}..."
    conda update -y --all
fi

if [[ -d "$HOME/.nvm" && -s "${MY_SHELL_SCRIPTS}/nodejs/nvm_node_updater.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/nodejs/nvm_node_updater.sh"
fi

if [[ -d "$HOME/.nvs" && -s "${MY_SHELL_SCRIPTS}/nodejs/nvs_node_updater.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/nodejs/nvs_node_updater.sh"
fi

if [[ -d "$HOME/.asdf" ]]; then
    [[ ! "$(command -v asdf)" ]] && source "$HOME/.asdf/asdf.sh"
    [[ "$(command -v asdf)" ]] && asdf_App_Update
fi

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

if [[ -x "$(command -v pip)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}pip installed user packages${BLUE}..."
    # https://stackoverflow.com/questions/68673221/warning-running-pip-as-the-root-user
    noproxy_cmd pip list -o | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 \
        | xargs --no-run-if-empty -n1 pip install --root-user-action=ignore --user -U
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


cd "${CURRENT_DIR}" || exit
colorEcho "${GREEN}Upgarde all packages done!"
