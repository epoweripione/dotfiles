#!/usr/bin/env bash

# color echo with datetime
# export COLOR_ECHO_DATETIME_FORMAT="%F %T.%6N %:z" # [2000-01-01 12:00:00.123456 +00:00]
# export COLOR_ECHO_DATETIME_FORMAT="%FT%T%:z" # [2000-01-01T12:00:00+00:00]
[[ -n "${COLOR_ECHO_DATETIME_FORMAT}" ]] && export COLOR_ECHO_DATETIME_FORMAT

# no proxy ip & domain
get_no_proxy

# git clone default options
if [[ -z "${GIT_CLONE_DEFAULT_OPTION}" ]]; then
    GIT_CLONE_DEFAULT_OPTION="-c core.autocrlf=false -c core.filemode=false"
    GIT_CLONE_DEFAULT_OPTION="${GIT_CLONE_DEFAULT_OPTION} -c fsck.zeroPaddedFilemode=ignore"
    GIT_CLONE_DEFAULT_OPTION="${GIT_CLONE_DEFAULT_OPTION} -c fetch.fsck.zeroPaddedFilemode=ignore"
    GIT_CLONE_DEFAULT_OPTION="${GIT_CLONE_DEFAULT_OPTION} -c receive.fsck.zeroPaddedFilemode=ignore"
fi
export GIT_CLONE_DEFAULT_OPTION

[[ -z "${GIT_CLONE_OPTS[*]}" ]] && Get_Git_Clone_Options

# curl & axel default options
export INSTALLER_CHECK_CURL_OPTION=${INSTALLER_CHECK_CURL_OPTION:-"-fsL --connect-timeout 5"}
export INSTALLER_DOWNLOAD_CURL_OPTION=${INSTALLER_DOWNLOAD_CURL_OPTION:-"-fSL --connect-timeout 5"}
export INSTALLER_DOWNLOAD_AXEL_OPTION=${INSTALLER_DOWNLOAD_AXEL_OPTION:-"--num-connections=5 --timeout=30 --alternate"}

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# Accelerate the speed of accessing GitHub
export GITHUB_HUB_URL=${GITHUB_HUB_URL:-"https://github.com"}
export GITHUB_DOWNLOAD_URL=${GITHUB_DOWNLOAD_URL:-"https://github.com"}
export GITHUB_RAW_URL=${GITHUB_RAW_URL:-"https://raw.githubusercontent.com"}

# https://docs.github.com/cn/rest/overview/resources-in-the-rest-api#rate-limiting
[[ -n "${GITHUB_API_TOKEN}" ]] && export GITHUB_API_TOKEN

# sbin
[[ -d "/sbin" && ":$PATH:" != *":/sbin:"* ]] && export PATH=/sbin:$PATH
[[ -d "/usr/sbin" && ":$PATH:" != *":/usr/sbin:"* ]] && export PATH=/usr/sbin:$PATH
[[ -d "/usr/local/sbin" && ":$PATH:" != *":/usr/local/sbin:"* ]] && export PATH=/usr/local/sbin:$PATH

# snap
if [[ -x "$(command -v snap)" ]]; then
    [[ ":$PATH:" != *":/snap/bin:"* ]] && export PATH=$PATH:/var/lib/snapd/snap/bin:/snap/bin
fi

# Krew
if [[ -d "${KREW_ROOT:-$HOME/.krew}/bin" ]]; then
    [[ ":$PATH:" != *":${KREW_ROOT:-$HOME/.krew}/bin:"* ]] && export PATH=$PATH:${KREW_ROOT:-$HOME/.krew}/bin
fi

# calico
if [[ ! -x "$(command -v calicoctl)" && -x "$(command -v kubectl)" ]]; then
    [[ -z "${CALICO_DATASTORE_TYPE}" ]] && export CALICO_DATASTORE_TYPE=kubernetes
    [[ -z "${CALICO_KUBECONFIG}" ]] && export CALICO_KUBECONFIG="$HOME/.kube/config"
fi

# Oracle Instant Client
if [[ -z "${ORACLE_HOME}" ]]; then
    if [[ -d "/opt/oracle/instantclient_21_1" ]]; then
        export ORACLE_HOME="/opt/oracle/instantclient_21_1"
    elif [[ -d "/opt/oracle/instantclient_19_10" ]]; then
        export ORACLE_HOME="/opt/oracle/instantclient_19_10"
    elif [[ -d "/opt/oracle/instantclient_18_5" ]]; then
        export ORACLE_HOME="/opt/oracle/instantclient_18_5"
    elif [[ -d "/opt/oracle/instantclient_18_3" ]]; then
        export ORACLE_HOME="/opt/oracle/instantclient_18_3"
    elif [[ -d "/opt/oracle/instantclient_12_2" ]]; then
        export ORACLE_HOME="/opt/oracle/instantclient_12_2"
    fi
fi

if [[ -n "${ORACLE_HOME}" ]]; then
    if [[ ":${LD_LIBRARY_PATH}:" != *":${ORACLE_HOME}:"* ]]; then
        if [[ -z "${LD_LIBRARY_PATH}" ]]; then
            export LD_LIBRARY_PATH=${ORACLE_HOME}
        else
            export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}
        fi
    fi

    [[ ":$PATH:" != *":${ORACLE_HOME}:"* ]] && export PATH=$PATH:${ORACLE_HOME}
fi

# starship
if [[ -x "$(command -v starship)" ]]; then
    if [[ -z "${ICON_OS_SSH_SCREEN_TMUX}" ]]; then
        get_os_icon

        ICON_OS_SSH_SCREEN_TMUX="${OS_INFO_ICON}"
        [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]] && ICON_OS_SSH_SCREEN_TMUX="${ICON_OS_SSH_SCREEN_TMUX} "
        [[ -n "$STY" ]] && ICON_OS_SSH_SCREEN_TMUX="${ICON_OS_SSH_SCREEN_TMUX} 🖵"
        [[ -n "$TMUX" ]] && ICON_OS_SSH_SCREEN_TMUX="${ICON_OS_SSH_SCREEN_TMUX}離"
    fi
    export ICON_OS_SSH_SCREEN_TMUX

    if [[ ! -s "$HOME/.config/starship.toml" ]]; then
        cp -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/themes/starship.toml" "$HOME/.config"
    fi
fi

# PHP
if [[ -x "$(command -v php)" ]]; then
    PHP_INI_DIR=$(php --ini | grep "Scan for additional .ini files in" | cut -d':' -f2 | cut -d' ' -f2)
    export PHP_INI_DIR
fi

if [[ -x "$(command -v php-config)" ]]; then
    PHP_EXT_DIR=$(php-config --extension-dir)
    export PHP_EXT_DIR
fi

# composer
if [[ -x "$(command -v composer)" ]]; then
    export COMPOSER_ALLOW_SUPERUSER=1
    export COMPOSER_HOME=/usr/local/share/composer
    [[ ":$PATH:" != *":${COMPOSER_HOME}:"* ]] && export PATH=$PATH:${COMPOSER_HOME}/vendor/bin
fi

# gvm
if [[ -d "$HOME/.gvm" && -z "${GOROOT_BOOTSTRAP}" ]]; then
    ENV_PATH_OLD=$PATH

    if type 'gvm' 2>/dev/null | grep -q 'function'; then
        :
    else
        [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
    fi

    if gvm list 2>/dev/null | grep -q 'go1.4'; then
        GVM_GO_VERSION=$(gvm list | grep '=>' | cut -d' ' -f2)

        # Set GOROOT_BOOTSTRAP to compile Go 1.5+
        gvm use go1.4 >/dev/null 2>&1
        export GOROOT_BOOTSTRAP=$GOROOT

        # Set default go version
        [[ -n "${GVM_GO_VERSION}" ]] && gvm use "${GVM_GO_VERSION}" --default >/dev/null 2>&1
    fi

    # fix (maybe) break PATH
    ENV_PATH_GO=$PATH
    export PATH=${ENV_PATH_OLD}
    if [[ ":$ENV_PATH_GO:" != *":$ENV_PATH_OLD:"* ]]; then
        ENV_PATH_GO=$(echo "$ENV_PATH_GO" | sed 's/:$//')
        [[ -n "${ENV_PATH_GO}" ]] && export PATH=${ENV_PATH_GO}:${ENV_PATH_OLD}
    fi

    # GOBIN
    [[ -z "$GOBIN" && -n "$GOROOT" ]] && export GOBIN=$GOROOT/bin

    unset ENV_PATH_GO
    unset ENV_PATH_OLD
    unset GVM_GO_VERSION
fi

# goup
if [[ -d "$HOME/.go" ]]; then
    [[ ":$PATH:" != *":$HOME/.go/bin:"* ]] && export PATH=$PATH:$HOME/.go/bin:$HOME/.go/current/bin
fi

# go
if [[ -x "$(command -v go)" ]]; then
    [[ -n "${GOPATH}" ]] && GO_ENV_GOPATH="${GOPATH}" || GO_ENV_GOPATH=$(go env GOPATH 2>/dev/null)
    [[ -n "${GO_ENV_GOPATH}" && ":$PATH:" != *":${GO_ENV_GOPATH}/bin:"* ]] && export PATH=$PATH:${GO_ENV_GOPATH}/bin
    unset GO_ENV_GOPATH

    ## go module
    # GO_VERSION=$(go version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    # if version_ge "${GO_VERSION}" '1.13'; then
    #     go env -w GO111MODULE=auto
    # else
    #     export GO111MODULE=auto
    # fi
    # unset GO_VERSION
fi

# flutter
if [[ -d "$HOME/flutter/bin" ]]; then
    [[ ":$PATH:" != *":$HOME/flutter/bin:"* ]] && export PATH=$PATH:$HOME/flutter/bin

    if [[ -z "${CHROME_EXECUTABLE}" ]]; then
        if [[ -x "$(command -v google-chrome)" ]]; then
            CHROME_EXECUTABLE=$(readlink -f "$(which google-chrome)")
        else
            [[ -x "/opt/google/chrome/google-chrome" ]] && CHROME_EXECUTABLE="/opt/google/chrome/google-chrome" 
        fi
    fi
    [[ -n "${CHROME_EXECUTABLE}" ]] && export CHROME_EXECUTABLE
fi

# Android Studio Tools
if [[ -d "$HOME/Android/Sdk" && ":$PATH:" != *":$HOME/Android/Sdk:"* ]]; then
    [[ -d "$HOME/Android/Sdk/cmdline-tools/latest/bin" ]] && \
        export PATH=$PATH:$HOME/Android/Sdk/cmdline-tools/latest/bin

    [[ -d "$HOME/Android/Sdk/platform-tools" ]] && \
        export PATH=$PATH:$HOME/Android/Sdk/platform-tools
fi

# vcpkg
if [[ -z "${VCPKG_ROOT}" ]]; then
    if [[ -x "$(command -v vcpkg)" ]]; then
        [[ -z "${VCPKG_ROOT}" ]] && VCPKG_ROOT=$(dirname "$(readlink -f "$(command -v vcpkg)")")
        [[ -z "${VCPKG_DOWNLOADS}" && -d "/var/cache/vcpkg" ]] && VCPKG_DOWNLOADS="/var/cache/vcpkg"
        export VCPKG_ROOT
        export VCPKG_DOWNLOADS
    elif [[ -d "$HOME/vcpkg" ]]; then
        export VCPKG_ROOT="$HOME/vcpkg"
    fi
fi

# jabba
if [[ -d "$HOME/.jabba" ]]; then
    if type 'jabba' 2>/dev/null | grep -q 'function'; then
        :
    else
        [[ -s "$HOME/.jabba/jabba.sh" ]] && source "$HOME/.jabba/jabba.sh"
    fi
fi

# java
if [[ -x "$(command -v java)" && -z "${JAVA_HOME}" ]]; then
    JAVA_HOME=$(readlink -f "$(which java)" | sed "s:/jre/bin/java::" | sed "s:/bin/java::")

    if [[ ! -d "${JAVA_HOME}" && "${JAVA_HOME}" == *".asdf"* ]]; then
        JAVA_HOME="$(asdf which java)"
        [[ -n "${JAVA_HOME}" ]] && JAVA_HOME="$(dirname "$(dirname "${JAVA_HOME:A}")")"
    fi

    [[ -d "${JAVA_HOME}" ]] && export JAVA_HOME
    [[ ":$PATH:" != *":${JAVA_HOME}/bin:"* ]] && export PATH=$PATH:${JAVA_HOME}/bin

    [[ -z "${JRE_HOME}" && -d "${JAVA_HOME}/jre" ]] && export JRE_HOME="${JAVA_HOME}/jre"
    [[ -z "${CLASSPATH}" && -d "${JAVA_HOME}/lib" ]] && export CLASSPATH="${JAVA_HOME}/lib"
fi

# poetry
if [[ -x "$(command -v poetry)" && -d "$HOME/.poetry/bin" ]]; then
    [[ ":$PATH:" != *":$HOME/.poetry/bin:"* ]] && export PATH=$HOME/.poetry/bin:$PATH
fi

# pip local install
if [[ -d "$HOME/.local/bin" ]]; then
    [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH=$HOME/.local/bin:$PATH
fi

if [[ -z "${PIP_CMD_USER}" ]]; then
    [[ -f "$HOME/.local/bin/pip" ]] && PIP_CMD_USER="$HOME/.local/bin/pip" || PIP_CMD_USER="$(which pip)"
    [[ -n "${PIP_CMD_USER}" ]] && export PIP_CMD_USER
fi

# nvs
if [[ -d "$HOME/.nvs" ]]; then
    if type 'nvs' 2>/dev/null | grep -q 'function'; then
        :
    else
        export NVS_HOME="$HOME/.nvs" && source "$NVS_HOME/nvs.sh"
    fi
fi

# nvm
if [[ -d "$HOME/.nvm" ]]; then
    if type 'nvm' 2>/dev/null | grep -q 'function'; then
        :
    else
        export NVM_DIR="$HOME/.nvm"
        [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

        [[ -z "${NVM_LOAD_NVMRC_IN_CURRENT_DIRECTORY}" ]] && NVM_LOAD_NVMRC_IN_CURRENT_DIRECTORY=false
        export NVM_LOAD_NVMRC_IN_CURRENT_DIRECTORY
    fi
fi

# npm global
if [[ -d "$HOME/.npm-global" ]]; then
    [[ ":$PATH:" != *":$HOME/.npm-global/bin:"* ]] && export PATH=$HOME/.npm-global/bin:$PATH
fi

# sdkman
if [[ -d "$HOME/.sdkman" ]]; then
    if type 'sdk' 2>/dev/null | grep -q 'function'; then
        :
    else
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
fi

## rbenv
# if [[ -d "$HOME/.rbenv" && ! -x "$(command -v rbenv)" ]]; then
#     [[ ":$PATH:" != *":$HOME/.rbenv/bin:"* ]] && export PATH=$PATH:$HOME/.rbenv/bin
# fi

# WSL1
if check_os_wsl1; then
    # Docker
    if [[ -d "/c/Program Files/Docker Toolbox" ]]; then
        # export PATH="$PATH:/c/Program\ Files/Docker\ Toolbox"
        export DOCKER_TOOLBOX_INSTALL_PATH="/c/Program Files/Docker Toolbox"

        WINDOWS_USER=$(/c/Windows/System32/cmd.exe /c 'echo %USERNAME%' | sed -e 's/\r//g')
        export WINDOWS_USER
        # export WINDOWS_USER=$(/c/Windows/System32/cmd.exe /c "whoami" | sed -E s/'^.+\\([^\\]*)$'/'\1'/)
        export DOCKER_TLS_VERIFY=1
        export DOCKER_HOST=tcp://192.168.99.100:2376
        export DOCKER_CERT_PATH=/c/Users/$WINDOWS_USER/.docker/machine/certs

        alias docker-machine='${DOCKER_TOOLBOX_INSTALL_PATH}/docker-machine.exe'
    elif [[ -d "/c/Program Files/Docker/Docker" ]]; then
        # export PATH="$PATH:/mnt/c/Program\ Files/Docker/Docker/resources/bin"
        export DOCKER_INSTALL_PATH="/c/Program Files/Docker/Docker"

        export DOCKER_HOST=tcp://127.0.0.1:2375

        alias docker-machine='$DOCKER_INSTALL_PATH/resources/bin/docker-machine.exe'
    fi
fi

# WSL
if check_os_wsl; then
    # https://gist.github.com/wmeng223/60b51b30eb758bd7a2a648436da1e562
    export COLORTERM="truecolor"

    ## start services upon WSL launch: libnss-winbind
    # if (( $(ps -ef | grep -v grep | grep winbind | wc -l) == 0 )); then
    #     systemctl is-enabled winbind >/dev/null 2>&1 && \
    #         sudo service winbind start
    #     # if systemctl list-unit-files --type=service | grep "winbind.service" | grep "enabled" >/dev/null 2>&1; then
    #     #     service winbind start
    #     # fi
    # fi

    ## fast-syntax-highlighting: fix Segmentation fault (core dumped) when input char -
    ## https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/108
    # FAST_HIGHLIGHT[chroma-git]="chroma/-ogit.ch"

    # get local weather
#     get_weather_custom
# else
#     get_os_desktop && [[ -n "${OS_INFO_DESKTOP}" ]] && get_weather_custom
fi
