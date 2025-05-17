#!/usr/bin/env bash

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

# Package managers with pacman-style command syntax
if [[ ! -x "$(command -v pacman)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS}/installer/pacman_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/pacman_installer.sh"
fi

if [[ ! -x "$(command -v pacman)" ]]; then
    colorEcho "${FUCHSIA}pacapt or pacaptr${RED} is not installed!"
    exit 1
fi

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# Install ZSH Shell
if [[ -x "$(command -v pacman)" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}installed packages${BLUE}..."
    sudo pacman --noconfirm -Syu

    colorEcho "${BLUE}Installing ${FUCHSIA}pre-requisite packages${BLUE}..."
    ## Install Latest Git ( Git 2.x ) on CentOS 7
    ## https://computingforgeeks.com/how-to-install-latest-version-of-git-git-2-x-on-centos-7/
    # sudo dnf -y remove git
    # sudo dnf -y install https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.7-1.x86_64.rpm
    # sudo dnf -y install git

    # GeoIP binary and database
    # http://kbeezie.com/geoiplookup-command-line/
    # autojump
    # https://github.com/wting/autojump
    # jq
    # https://stedolan.github.io/jq/

    # epel
    [[ -z "${OS_PACKAGE_MANAGER}" ]] && get_os_package_manager
    if [[ "${OS_PACKAGE_MANAGER}" == "dnf" ]]; then
        if checkPackageNeedInstall "epel-release"; then
            sudo dnf -y install epel-release && sudo dnf -y upgrade
        fi
    fi

    # Pre-requisite packages
    PackagesList=(
        aria2
        axel
        curl
        wget
        git
        zip
        unzip
        # autojump
        # autojump-zsh
        bind-utils
        bind9-utils
        binutils
        build-essential
        connect-proxy
        coreutils
        dnsutils
        autoconf
        g++
        gcc
        geoip
        geoip-bin
        geoip-data
        geoip-database
        GeoIP
        GeoIP-data
        glibc-langpack-en
        glibc-locale-source
        bc
        dstat
        htop
        inxi
        jq
        lsof
        make
        man
        man-pages-zh-CN
        man-pages-zh_cn
        manpages-zh
        mtr
        multitail
        netcat-openbsd
        openbsd-netcat
        nmap
        python3
        recode
        rlwrap
        rsync
        screen
        strace
        telnet
        # tmux
        xsel
        xmlstarlet
    )
    InstallSystemPackages "" "${PackagesList[@]}"
fi

## https://github.com/man-pages-zh/manpages-zh
sudo localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8
# alias man="LC_MESSAGES=zh_CN.UTF-8 man"
# alias man="man -Lzh_CN"

## keep SSH env when using `sudo -i`
## https://mwl.io/archives/1000
## sudo visudo -f /etc/sudoers.d/keep_env_via_ssh
# echo 'Defaults env_keep += "SSH_CLIENT SSH_CONNECTION SSH_TTY SSH_AUTH_SOCK"' \
#     | sudo tee "/etc/sudoers.d/keep_env_via_ssh" >/dev/null

colorEcho "${BLUE}Installing ${FUCHSIA}ZSH ${BLUE}Shell..."
# http://zsh.sourceforge.net/
if [[ ! -x "$(command -v zsh)" ]]; then
    RHEL_VERSION=$(cat /etc/os-release | grep "^VERSION=" | cut -d'"' -f2)
    if [[ "${RHEL_VERSION}" == "7" ]]; then
        ## install latest zsh for readhat 7 & centos 7
        ## sudo dnf -y remove zsh
        # if checkPackageInstalled "zsh"; then
        #     INSTALLER_VER_CURRENT=$(zsh --version | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
        #     colorEcho "${BLUE}  Removing ${FUCHSIA}zsh ${YELLOW}${INSTALLER_VER_CURRENT}${BLUE}..."
        #     sudo pacman --noconfirm -R zsh
        # fi

        # sudo dnf -y update && sudo dnf -y install ncurses-devel gcc make
        PackagesList=(
            ncurses-devel
            gcc
            make
        )
        InstallSystemPackages "" "${PackagesList[@]}"

        # ZSH_REPO_VERSION=$(dnf info zsh | grep -E "[Vv]ersion" | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}')

        INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" http://zsh.sourceforge.net/News/ \
                            | grep -Eo -m1 'Release ([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
        INSTALLER_VER_REMOTE=$(grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' <<<"${INSTALLER_VER_REMOTE}")

        if [[ -n "${INSTALLER_VER_REMOTE}" ]]; then
            INSTALLER_DOWNLOAD_URL="https://nchc.dl.sourceforge.net/project/zsh/zsh/${INSTALLER_VER_REMOTE}/zsh-${INSTALLER_VER_REMOTE}.tar.xz"
            colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
            curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/zsh.tar.xz" "${INSTALLER_DOWNLOAD_URL}" && \
                tar -xJf "${WORKDIR}/zsh.tar.xz" -C "${WORKDIR}" && \
                mv "${WORKDIR}"/zsh-* "${WORKDIR}/zsh" && \
                cd "${WORKDIR}/zsh" && \
                sudo ./configure >/dev/null && \
                sudo make >/dev/null && \
                sudo make install >/dev/null
        fi

        if [[ ! -x "$(command -v zsh)" ]] && [[ -s "/usr/local/bin/zsh" ]]; then
            sudo ln -sv /usr/local/bin/zsh /bin/zsh
        fi

        if [[ -x "$(command -v zsh)" ]]; then
            if [[ ! -f "/bin/zsh" ]]; then
                sudo ln -sv "$(command -v zsh)" /bin/zsh
            fi

            command -v zsh | sudo tee -a /etc/shells
        fi
    else
        if checkPackageNeedInstall "zsh"; then
            sudo pacman --noconfirm -S zsh
        fi
    fi
fi


if [[ ! -x "$(command -v zsh)" ]]; then
    colorEcho "${FUCHSIA}ZSH${RED} is not installed! Please manual install ${FUCHSIA}ZSH${RED}!"
    exit
fi


if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/git/git_global_config.sh" ]]; then
    source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/git/git_global_config.sh"
fi


# change default shell to zsh
# chsh -s $(which zsh)

sudo mkdir -p "/usr/local/share/zsh/site-functions"

# WSL
if check_os_wsl; then
    if ! grep -q "exec zsh" "$HOME/.bashrc" 2>/dev/null; then
        tee -a ~/.bashrc >/dev/null <<-'EOF'

# Launch ZSH
if [[ "${ZSH_VERSION:-unset}" = "unset" ]]; then
    export SHELL=$(which zsh)
    exec zsh
fi
EOF
    fi
fi

# axel
if [[ ! -x "$(command -v axel)" ]]; then
    if [[ ! -x "$(command -v snap)" ]]; then
        [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/snap_installer.sh" ]] && \
            source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/snap_installer.sh"
    fi

    [[ -x "$(command -v snap)" ]] && sudo snap install axel
fi

## Install oh-my-zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}oh-my-zsh${BLUE}..."
    cd "$HOME/.oh-my-zsh" && git pull
else
    colorEcho "${BLUE}Installing ${FUCHSIA}oh-my-zsh${BLUE}..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

cd "${CURRENT_DIR}" || exit