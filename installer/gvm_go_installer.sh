#!/usr/bin/env bash

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

App_Installer_Reset

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

## Install gvm
## https://github.com/moovweb/gvm
## Please turn on proxy in china (replace the IP and Port to fit your proxy server)
## Mac OS X Requirements
## Install Mercurial from https://www.mercurial-scm.org/downloads
## Install Xcode Command Line Tools from the App Store.
# sudo xcode-select --install
# brew update
# brew install mercurial
## Linux Requirements
## Debian/Ubuntu
# sudo apt-get install curl git mercurial make binutils bison gcc build-essential
## Redhat/Centos
# sudo yum install curl git make bison gcc glibc-devel
## Install Mercurial from http://pkgs.repoforge.org/mercurial/
## FreeBSD Requirements
# sudo pkg_add -r bash git mercurial
INSTALLER_APP_NAME="gvm & go"

INSTALLER_VER_CURRENT="go0.0.0"

if [[ -d "$HOME/.gvm" ]]; then
    INSTALLER_IS_UPDATE="yes"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
fi

# new install
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && "${INSTALLER_IS_UPDATE}" == "no" ]]; then
    if [[ -x "$(command -v pacman)" ]]; then
        PackagesList=(
            bash
            curl
            git
            mercurial
            make
            binutils
            bison
            gcc
            build-essential
            glibc-devel
        )
        for TargetPackage in "${PackagesList[@]}"; do
            if checkPackageNeedInstall "${TargetPackage}"; then
                colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
                sudo pacman --noconfirm -S "${TargetPackage}"
            fi
        done
    fi

    if [[ "${OS_INFO_TYPE}" == "darwin" && -x "$(command -v brew)" ]]; then
        sudo xcode-select --install
        brew update
        brew install mercurial
    fi

    bash < <(curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
fi


# if [[ "${INSTALLER_IS_INSTALL}" == "yes" && "${THE_WORLD_BLOCKED}" == "true" ]]; then
#     if [[ ! -x "$(command -v proxychains4)" ]]; then
#         [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/proxychains_installer.sh" ]] && \
#             source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/proxychains_installer.sh"
#     fi
# fi


if [[ "${INSTALLER_IS_INSTALL}" == "yes" && -d "$HOME/.gvm" ]]; then
    if type 'gvm' 2>/dev/null | grep -q 'function'; then
        :
    else
        [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
    fi

    case "${OS_INFO_TYPE}" in
        windows)
            GVM_DOWNLOAD_EXT="zip"
            ;;
        *)
            GVM_DOWNLOAD_EXT="tar.gz"
            ;;
    esac

    ## In order to compile Go 1.5+, make sure Go 1.4 is installed first.
    if ! gvm list 2>/dev/null | grep -q 'go1.4'; then
        # if [[ "${THE_WORLD_BLOCKED}" == "true" && -x "$(command -v proxychains4)" ]]; then
        #     proxychains4 gvm install go1.4 -B
        # else
        #     gvm install go1.4 -B
        # fi
        GVM_DOWNLOAD_VERSION="go1.4"
        GVM_DOWNLOAD_NAME="${GVM_DOWNLOAD_VERSION}.${OS_INFO_TYPE}-${OS_INFO_ARCH}.${GVM_DOWNLOAD_EXT}"
        GVM_DOWNLOAD_SOURCE="https://dl.google.com/go/${GVM_DOWNLOAD_NAME}"

        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "$HOME/.gvm/archive/${GVM_DOWNLOAD_NAME}" -C- "${GVM_DOWNLOAD_SOURCE}" && \
            gvm install go1.4 -B
    fi

    INSTALLER_VER_CURRENT=$(gvm list 2>/dev/null | grep '=>' | cut -d' ' -f2)
    if gvm list 2>/dev/null | grep -q 'go1.4'; then
        ## Set GOROOT_BOOTSTRAP to compile Go 1.5+
        # gvm use go1.4
        # GOROOT_BOOTSTRAP=$GOROOT

        # Install latest go version
        INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" "https://go.dev/VERSION?m=text" | grep -Eo -m1 'go([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
        # INSTALLER_VER_REMOTE=${INSTALLER_VER_REMOTE%.}

        if [[ -n "${INSTALLER_VER_REMOTE}" ]] && ! gvm list 2>/dev/null | grep -q "${INSTALLER_VER_REMOTE}"; then
            # if [[ "${THE_WORLD_BLOCKED}" == "true" && -x "$(command -v proxychains4)" ]]; then
            #     proxychains4 gvm install ${INSTALLER_VER_REMOTE}
            # else
            #     gvm install ${INSTALLER_VER_REMOTE}
            # fi
            GVM_DOWNLOAD_VERSION="${INSTALLER_VER_REMOTE}"
            GVM_DOWNLOAD_NAME="${GVM_DOWNLOAD_VERSION}.${OS_INFO_TYPE}-${OS_INFO_ARCH}.${GVM_DOWNLOAD_EXT}"
            GVM_DOWNLOAD_SOURCE="https://dl.google.com/go/${GVM_DOWNLOAD_NAME}"

            curl "${CURL_DOWNLOAD_OPTS[@]}" -o "$HOME/.gvm/archive/${GVM_DOWNLOAD_NAME}" -C- "${GVM_DOWNLOAD_SOURCE}" && \
                gvm install "${INSTALLER_VER_REMOTE}" -B
        fi

        # Set default go version
        if [[ -n "${INSTALLER_VER_REMOTE}" ]]; then
            if gvm list 2>/dev/null | grep -q "${INSTALLER_VER_REMOTE}"; then
                gvm use "${INSTALLER_VER_REMOTE}" --default
            fi
        elif [[ -n "${INSTALLER_VER_CURRENT}" ]]; then
            gvm use "${INSTALLER_VER_CURRENT}" --default
        fi
    fi
fi


# go env
if [[ -d "$HOME/.gvm" ]]; then
    ENV_PATH_OLD=$PATH

    if type 'gvm' 2>/dev/null | grep -q 'function'; then
        :
    else
        [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
    fi

    if gvm list 2>/dev/null | grep -q 'go1.4'; then
        INSTALLER_VER_CURRENT=$(gvm list 2>/dev/null | grep '=>' | cut -d' ' -f2)

        # Set GOROOT_BOOTSTRAP to compile Go 1.5+
        gvm use go1.4 >/dev/null 2>&1
        export GOROOT_BOOTSTRAP=$GOROOT

        # Set default go version
        [[ -n "${INSTALLER_VER_CURRENT}" ]] && gvm use "${INSTALLER_VER_CURRENT}" --default >/dev/null 2>&1
    fi

    # fix (maybe) break PATH
    ENV_PATH_GO=$PATH
    export PATH=${ENV_PATH_OLD}
    if [[ ":$ENV_PATH_GO:" != *":$ENV_PATH_OLD:"* ]]; then
        ENV_PATH_GO=$(echo "$ENV_PATH_GO" | sed 's/:$//')
        [[ -n "${ENV_PATH_GO}" ]] && export PATH=${ENV_PATH_GO}:${ENV_PATH_OLD}
    fi

    unset ENV_PATH_GO
    unset ENV_PATH_OLD
fi


# go mirrors
setMirrorGo


## fix ERROR: Unrecognized Go version
# cd "$HOME/.gvm/archive/go" && git pull


## go env: 1.13+
# go env -w GOBIN=$HOME/bin
# export GOPROXY=https://proxy.golang.org,direct
# export GONOPROXY=


## fix `gvm uninstall 1.14.2` -> ERROR: Couldn't remove pkgsets
# gvm use 1.14.2 && go clean -modcache && gvm use 1.14.3 && gvm uninstall 1.14.2
