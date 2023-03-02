#!/usr/bin/env zsh

# Custom ZSH configuration
export MY_SHELL_SCRIPTS="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}"

OS_TYPE=$(uname)

# custom PS2
# export PS2="> "

# fix duplicate environment variables "SHELL=/usr/bin/zsh"
if (( $(env | grep SHELL | wc -l) > 1 )); then
    unset SHELL
    SHELL=$(which zsh)
    export SHELL
fi

# compinit
# source "${MY_SHELL_SCRIPTS}/zsh/zsh_compinit.sh"

### Fix slowness of pastes with zsh-syntax-highlighting.zsh
### https://github.com/zsh-users/zsh-autosuggestions/issues/238#issuecomment-389324292
pasteinit() {
    OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
    zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
    zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish
### Fix slowness of pastes

# disable hosts auto completion
zstyle ':completion:*' hosts off

# custom bindkey
bindkey \^U backward-kill-line

# bind the Control-P/N keys for zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

# not confirm a rm *
setopt localoptions rmstarsilent

## Colors
# autoload -U colors && colors
# export CLICOLOR=1
# export LSCOLORS='gxfxcxdxbxegedabagacad'
# export LS_COLORS="di=36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"


# complete hard drives in MSYS2
if [[ "$OS_TYPE" =~ "MSYS_NT" || "$OS_TYPE" =~ "MINGW" || "$OS_TYPE" =~ "CYGWIN_NT" ]]; then
    drives=$(mount | sed -rn 's#^[A-Z]: on /([a-z]).*#\1#p' | tr '\n' ' ')
    zstyle ':completion:*' fake-files /: "/:$drives"
    unset drives
fi


# Load custom functions
if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/custom_functions.sh"

    # Use proxy or mirror when some sites were blocked or low speed
    [[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

    # Check & set global proxy
    [[ "${THE_WORLD_BLOCKED}" == "true" ]] && check_set_global_proxy 7891 7890
fi

# Environment variables
[[ -s "$HOME/.dotfiles.env.local" ]] && source "$HOME/.dotfiles.env.local"

# aliases
if [[ -x "$(command -v nano)" ]]; then
    export EDITOR="nano"
    export VISUAL="nano"

    alias zshconfig="nano ~/.zshrc"
    alias ohmyzsh="nano ~/.oh-my-zsh"

    # Auto files
    # alias -s html='nano'
    # alias -s php='nano'
    # alias -s rb='nano'
    # alias -s py='nano'
    # alias -s js='nano'
    # alias -s c='nano'
    # alias -s java='nano'
    # alias -s txt='nano'
    # alias -s gz='tar -xzvf'
    # alias -s tgz='tar -xzvf'
    # alias -s zip='unzip'
    # alias -s bz2='tar -xjvf'
fi

alias cls='clear'
alias grep="grep --color=auto"

alias service-enabled='systemctl list-unit-files --type=service --state=enabled'
alias service-running='systemctl --type=service --state=running'
alias service-failed='systemctl --type=service --state=failed'

[[ -x "$(command -v nc)" && -n "${GLOBAL_PROXY_IP}" && -n "${GLOBAL_PROXY_MIXED_PORT}" ]] && 
    alias sshproxy='ssh -o ProxyCommand='"'"'nc -X connect -x ${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT} %h %p'"'"''

[[ -x "$(command -v nc)" && -n "${GLOBAL_PROXY_IP}" && -n "${GLOBAL_PROXY_SOCKS_PORT}" ]] && 
    alias sshproxy='ssh -o ProxyCommand='"'"'nc -X 5 -x ${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_SOCKS_PORT} %h %p'"'"''

# most used history commands
alias histop='fc -l -n 1 | grep -v "^\./" | sort | uniq -c | sort -rn | sed "s/^[ ]*[0-9]\+[ ]*//"'
alias hisrate='fc -l -n 1 | grep -v "^\./" | sort | uniq -c | sort -rn | sed "s/^[ ]*//" \
        | awk '"'"'BEGIN{i=0;total=0} \
            {CMD[i]=$0;RATE[i]=$1;i++;total=total+$1} \
            END{for (i=0; i in RATE; i++)print RATE[i]/total*100 "% " CMD[i];}'"'"''

# alias histop="awk -F';' '{print $2}' ${HISTFILE} | sort | uniq -c | sort -rn"

# skim aliases
if [[ -x "$(command -v sk)" ]]; then
    alias sk-grep='sk --ansi -i -c '"'"'grep -rI --color=always --line-number "{}" .'"'"''
    alias sk-ack='sk --ansi -i -c '"'"'ack --color "{}"'"'"''
    alias sk-ag='sk --ansi -i -c '"'"'ag --color "{}"'"'"''
    alias sk-rg='sk --ansi -i -c '"'"'rg --color=always --line-number "{}"'"'"''
fi

# docker aliases
if [[ -x "$(command -v docker)" ]]; then
    alias dockerpullall='docker images | grep -Ev "REPOSITORY|<none>" | awk '"'"'{print $1,$2}'"'"' OFS='"'"':'"'"' | xargs -L1 docker pull'
    alias dockerps='docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"'
    alias dockerpsall='docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}\t{{.Ports}}\t{{.Networks}}\t{{.Command}}\t{{.Size}}"'
    alias dockerclean='docker ps -a | awk '"'"'/Exited/ {print $1}'"'"' | xargs docker rm'

    # https://github.com/jesseduffield/lazydocker
    alias docker-lazy='docker run --rm -it --name lazy -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.config/lazydocker:/.config/jesseduffield/lazydocker lazyteam/lazydocker'
    # https://github.com/nicolargo/glances
    alias docker-glances='docker run --rm -it --name glances --pid host --network host -v /var/run/docker.sock:/var/run/docker.sock:ro nicolargo/glances:latest-full'
    # https://hub.docker.com/r/aksakalli/gtop
    alias docker-gtop='docker run --rm -it --name gtop --pid host --network host aksakalli/gtop'
    # https://github.com/Ciphey/Ciphey
    alias docker-ciphey='docker run --rm -it --name ciphey remnux/ciphey'
    # https://github.com/wagoodman/dive
    alias docker-dive='docker run --rm -it --name dive -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive'
    # https://github.com/lavie/runlike
    alias docker-runlike='docker run --rm --name runlike -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike'
    # https://github.com/P3GLEG/Whaler
    alias docker-whaler='docker run --rm -t --name whaler -v /var/run/docker.sock:/var/run/docker.sock:ro pegleg/whaler'
    # https://www.nushell.sh
    alias docker-nushell='docker run --rm -it --name nushell quay.io/nushell/nu'
    # https://xon.sh/
    alias docker-xonsh='docker run --rm -it --name xonsh xonsh/xonsh:slim'
    # https://www.portainer.io/
    alias docker-portainer='docker run -d --name portainer -p 8000:8000 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/portainer_data:/data portainer/portainer-ce'
    alias docker-portainer-agent='docker run -d --name portainer_agent -p 9001:9001 -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent'
    # https://github.com/SelfhostedPro/Yacht
    alias docker-yacht='docker run -d --name yacht -p 8000:8000 -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/yacht:/config selfhostedpro/yacht'
    # https://github.com/AlDanial/cloc
    alias docker-cloc='docker run --rm -v $PWD:/tmp aldanial/cloc'
    # https://filebrowser.org
    alias docker-filebrowser='docker run -d --name filebrowser --user $(id -u):$(id -g) -p 80:80 -v $PWD:/srv filebrowser/filebrowser'
    # https://testssl.sh/
    alias docker-testssl='docker run --rm -it --name testssl drwetter/testssl.sh'
    # https://github.com/chromedp/docker-headless-shell
    alias docker-headless-shell='docker run -d --name headless-shell -p 9222:9222 chromedp/headless-shell'
    # https://docs.browserless.io/docs/docker.html
    alias docker-browserless='docker run -d --name browserless -p 3000:3000 browserless/chrome'
    # https://github.com/soulteary/apt-proxy
    # command: --ubuntu=cn:tsinghua --debian=cn:tsinghua  --alpine=cn:tsinghua --centos=cn:tsinghua
    # usage: docker-apt-proxy "--ubuntu=cn:tsinghua --debian=cn:tsinghua  --alpine=cn:tsinghua --centos=cn:tsinghua"
    alias docker-apt-proxy='docker run -d --name apt-proxy -p 3142:3142 soulteary/apt-proxy'
    # https://github.com/soulteary/certs-maker
    # usage: docker-certs-maker "--CERT_DNS=lab.com,*.lab.com,*.data.lab.com"
    alias docker-certs-maker='docker run --rm -it --name certs-maker -v $PWD:/ssl soulteary/certs-maker'
fi

[[ -x "$(command -v microk8s)" ]] && alias mkctl="microk8s kubectl"

if [[ ! -x "$(command -v calicoctl)" && -x "$(command -v kubectl)" ]]; then
    export CALICO_DATASTORE_TYPE=kubernetes
    export CALICO_KUBECONFIG="$HOME/.kube/config"
    alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"
fi

[[ -x "$(command -v lazygit)" ]] && alias lg='lazygit'

# zsh-command-time
# If command execution time above min. time, plugins will not output time.
ZSH_COMMAND_TIME_MIN_SECONDS=3

# Message to display (set to "" for disable).
# → Execution time: ←
if [[ "$DISABLE_ZSH_COMMAND_TIME_MSG" == true ]]; then
    ZSH_COMMAND_TIME_MSG=""
else
    ZSH_COMMAND_TIME_MSG=" \u2192 Execution time: %s \u2190"

    # Message color.
    if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        ZSH_COMMAND_TIME_COLOR="magenta"
    else
        if [[ $UID -eq 0 ]]; then
            ZSH_COMMAND_TIME_COLOR="red"
        else
            ZSH_COMMAND_TIME_COLOR="yellow"
        fi
    fi
fi


# rlwarp alias
[[ -x "$(command -v telnet)" && -x "$(command -v rlwrap)" ]] && alias telnet="rlwrap telnet"

# macOS
[[ "$OS_TYPE" == "Darwin" && -x "$(command -v greadlink)" ]] && alias readlink=greadlink

# Extend variable in MSYS2 to use node,npm,php,composer... with winpty
if [[ "$OS_TYPE" =~ "MSYS_NT" || "$OS_TYPE" =~ "MINGW" || "$OS_TYPE" =~ "CYGWIN_NT" ]]; then
    export PATH=$PATH:/c/nodejs:/c/Users/$USERNAME/AppData/Roaming/npm:/c/php/php7:/c/php/composer/vendor/bin

    # dotnet
    if [[ "$(command -v dotnet.exe)" ]]; then
        alias dotnet="winpty dotnet.exe"
    fi

    #java
    if [[ "$(command -v java.exe)" ]]; then
        alias java="winpty java.exe"
        alias java="winpty javac.exe"
    fi

    # node,npm
    if [[ "$(command -v node.exe)" ]]; then
        alias node="winpty node.exe"
        alias npm="winpty npm.cmd"
        alias electron="winpty electron.cmd"
        alias es-checker="winpty es-checker.cmd"
        alias eslint="winpty eslint.cmd"
        alias ionic="winpty ionic.cmd"
        alias jshint="winpty jshint.cmd"
        alias ng="winpty ng.cmd"
        alias npm-check="winpty npm-check.cmd"
        alias npx="winpty npx.cmd"
        alias nrm="winpty nrm.cmd"
        alias parcel="winpty parcel.cmd"
        alias schematics="winpty schematics.cmd"
        alias standard="winpty standard.cmd"
        alias tsc="winpty tsc.cmd"
        alias tslint="winpty tslint.cmd"
        alias tsserver="winpty tsserver.cmd"
    fi

    # php,composer
    if [[ "$(command -v php.exe)" ]]; then
        alias php="winpty php.exe"
        alias composer="winpty composer.bat"
        alias pear="winpty pear.bat"
        alias pear2="winpty pear2.bat"
        alias pecl="winpty pecl.bat"
        alias php-cs-fixer="winpty php-cs-fixer.bat"
        alias php-parse="winpty php-parse.bat"
        alias phpunit="winpty phpunit.bat"
        alias psysh="winpty psysh.bat"
        alias var-dump-server="winpty var-dump-server.bat"
    fi

    # Docker
    if [[ -n "$DOCKER_TOOLBOX_INSTALL_PATH" ]]; then
        alias dockertoolbox='exec "$DOCKER_TOOLBOX_INSTALL_PATH/start.sh"'
    fi

    if [[ "$(command -v docker.exe)" ]]; then
        alias docker="winpty docker.exe"
        alias docker-compose="winpty docker-compose.exe"
    fi

    if [[ "$(command -v docker-machine.exe)" ]]; then
        alias docker-machine="winpty docker-machine.exe"
    fi

    # other
    alias wmic="winpty wmic"
fi

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
    export PATH=$PATH:${KREW_ROOT:-$HOME/.krew}/bin
fi

# Oracle Instant Client
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

if [[ -n "$ORACLE_HOME" ]]; then
    if [[ -z "$LD_LIBRARY_PATH" ]]; then
        export LD_LIBRARY_PATH=$ORACLE_HOME
    else
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME
    fi

    export PATH=$PATH:$ORACLE_HOME

    if [[ -x "$(command -v rlwrap)" ]]; then
        alias sqlplus="rlwrap sqlplus"
        alias rman="rlwrap rman"
        alias asmcmd="rlwrap asmcmd"
        alias ggsci="rlwrap ggsci"
    fi
fi

# starship
if [[ -x "$(command -v starship)" ]]; then
    get_os_icon

    ICON_OS_SSH_SCREEN_TMUX="${OS_INFO_ICON}"
    [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]] && ICON_OS_SSH_SCREEN_TMUX="${ICON_OS_SSH_SCREEN_TMUX} "
    [[ -n "$STY" ]] && ICON_OS_SSH_SCREEN_TMUX="${ICON_OS_SSH_SCREEN_TMUX} 🖵"
    [[ -n "$TMUX" ]] && ICON_OS_SSH_SCREEN_TMUX="${ICON_OS_SSH_SCREEN_TMUX}離"

    export ICON_OS_SSH_SCREEN_TMUX="${ICON_OS_SSH_SCREEN_TMUX}"

    if [[ ! -s "$HOME/.config/starship.toml" ]]; then
        cp -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/themes/starship.toml" "$HOME/.config"
    fi
fi

# funky
[[ -s "$HOME/.local/share/funky/funky.sh" ]] && source "$HOME/.local/share/funky/funky.sh"

# homebrew
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
        export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
        export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
        export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
        export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
    fi
fi

# exa
if [[ -x "$(command -v exa)" ]]; then
    alias exal="exa -aghl --icons --git --time-style=long-iso"
    alias exaa="exa -abghHliS --icons --git --time-style=long-iso"
    alias exat="exa --tree --icons"
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
    export PATH=$PATH:/usr/local/share/composer/vendor/bin
fi

# gvm
if [[ -d "$HOME/.gvm" ]]; then
    ENV_PATH_OLD=$PATH

    if type 'gvm' 2>/dev/null | grep -q 'function'; then
        :
    else
        [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
    fi

    if gvm list 2>/dev/null | grep -q 'go1.4'; then
        CURRENT_VERSION=$(gvm list | grep '=>' | cut -d' ' -f2)

        # Set GOROOT_BOOTSTRAP to compile Go 1.5+
        gvm use go1.4 >/dev/null 2>&1
        export GOROOT_BOOTSTRAP=$GOROOT

        # Set default go version
        [[ -n "$CURRENT_VERSION" ]] && gvm use "$CURRENT_VERSION" --default >/dev/null 2>&1
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
fi

# goup
if [[ -d "$HOME/.go" ]]; then
    [[ ":$PATH:" != *":$HOME/.go/bin:"* ]] && export PATH=$PATH:$HOME/.go/bin:$HOME/.go/current/bin
    [[ "${THE_WORLD_BLOCKED}" == "true" ]] && export GOUP_GO_HOST=golang.google.cn
fi

# go
if [[ -x "$(command -v go)" ]]; then
    [[ -n "${GOPATH}" ]] && GO_ENV_GOPATH="${GOPATH}" || GO_ENV_GOPATH=$(go env GOPATH 2>/dev/null)
    [[ -n "${GO_ENV_GOPATH}" && ":$PATH:" != *":${GO_ENV_GOPATH}/bin:"* ]] && export PATH=$PATH:${GO_ENV_GOPATH}/bin

    # go module
    GO_VERSION=$(go version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_ge "${GO_VERSION}" '1.13'; then
        go env -w GO111MODULE=auto
        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            go env -w GOPROXY="https://goproxy.cn,direct"
            # go env -w GOPROXY="https://goproxy.io,direct"
            # go env -w GOPROXY="https://mirrors.aliyun.com/goproxy/,direct"
            # go env -w GOPROXY="https://proxy.golang.org,direct"

            go env -w GOSUMDB="sum.golang.google.cn"
            # go env -w GOSUMDB="gosum.io+ce6e7565+AY5qEHUk/qmHc5btzW45JVoENfazw8LielDsaI+lEbq6"

            ## https://goproxy.io/zh/docs/goproxyio-private.html
            # go env -w GOPRIVATE="*.corp.example.com"
        fi
    else
        export GO111MODULE=auto
        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            export GOPROXY="https://goproxy.cn"
            export GOSUMDB="sum.golang.google.cn"
        fi
    fi

    if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
        [[ -n "${all_proxy}" ]] && alias go='noproxy_cmd go'
    fi

    unset GO_VERSION
    unset GO_ENV_GOPATH
fi

# flutter
if [[ -d "$HOME/flutter/bin" ]]; then
    export PATH=$PATH:$HOME/flutter/bin

    if [[ ! -x "$(command -v google-chrome)" ]]; then
        [[ -x "/opt/google/chrome/google-chrome" ]] && \
            export CHROME_EXECUTABLE="/opt/google/chrome/google-chrome" 
    fi

    if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
        export PUB_HOSTED_URL=https://pub.flutter-io.cn
        export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

        # export PUB_HOSTED_URL=https://mirror.sjtu.edu.cn/dart-pub
        # export FLUTTER_STORAGE_BASE_URL=https://mirror.sjtu.edu.cn
    fi

    # Android Studio Tools
    [[ -d "$HOME/Android/Sdk/cmdline-tools/latest/bin" ]] && \
        export PATH=$PATH:$HOME/Android/Sdk/cmdline-tools/latest/bin

    # [[ -d "$HOME/Android/Sdk/platform-tools" ]] && \
    #     export PATH=$PATH:$HOME/Android/Sdk/platform-tools
fi

# rustup & cargo
if [[ "${THE_WORLD_BLOCKED}" == "true" && -x "$(command -v rustup)" ]]; then
    # rustup mirror
    export RUSTUP_DIST_SERVER="https://rsproxy.cn"
    export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"

    # export RUSTUP_DIST_SERVER=https://mirror.sjtu.edu.cn/rust-static
    # export RUSTUP_UPDATE_ROOT=https://mirror.sjtu.edu.cn/rust-static/rustup

    # export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
    # export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static

    # cargo mirror
    if [[ ! -s "$HOME/.cargo/config" ]]; then
        mkdir -p "$HOME/.cargo"
        tee "$HOME/.cargo/config" >/dev/null <<-'EOF'
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'rsproxy'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

[source.sjtu]
registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index/"

[source.rustcc]
registry = "git://crates.rustcc.cn/crates.io-index"

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
EOF
    fi
fi

# ruby
if [[ -x "$(command -v rbenv)" ]]; then
    export RUBY_BUILD_MIRROR_URL="https://cache.ruby-china.com"
fi

# vcpkg
if [[ -z "${VCPKG_ROOT}" && -x "$(command -v vcpkg)" ]]; then
    [[ -z "${VCPKG_ROOT}" ]] && VCPKG_ROOT=$(dirname "$(readlink -f "$(command -v vcpkg)")")
    [[ -z "${VCPKG_DOWNLOADS}" && -d "/var/cache/vcpkg" ]] && VCPKG_DOWNLOADS="/var/cache/vcpkg"
    export VCPKG_ROOT
    export VCPKG_DOWNLOADS
elif [[ -z "${VCPKG_ROOT}" && -d "$HOME/vcpkg" ]]; then
    export VCPKG_ROOT="$HOME/vcpkg"
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
if [[ -x "$(command -v java)" ]]; then
    if [[ -z "${JAVA_HOME}" ]]; then
        JAVA_HOME=$(readlink -f "$(which java)" | sed "s:/jre/bin/java::" | sed "s:/bin/java::")

        if [[ ! -d "${JAVA_HOME}" && "${JAVA_HOME}" =~ ".asdf" ]]; then
            JAVA_HOME="$(asdf which java)"
            [[ -n "${JAVA_HOME}" ]] && JAVA_HOME="$(dirname "$(dirname "${JAVA_HOME:A}")")"
        fi

        [[ -d "${JAVA_HOME}" ]] && export JAVA_HOME && export PATH=$PATH:${JAVA_HOME}/bin
    fi

    [[ -z "${JRE_HOME}" && -d "${JAVA_HOME}/jre" ]] && export JRE_HOME="${JAVA_HOME}/jre"
    [[ -z "${CLASSPATH}" && -d "${JAVA_HOME}/lib" ]] && export CLASSPATH="${JAVA_HOME}/lib"
fi

# # anaconda3
# if [[ -d "$HOME/anaconda3/bin" ]]; then
#     export PATH=$PATH:$HOME/anaconda3/condabin
# fi

# # miniconda3
# if [[ -d "$HOME/miniconda3/bin" ]]; then
#     export PATH=$PATH:$HOME/miniconda3/condabin
#     # source "$HOME/miniconda3/bin/activate"
# fi

# poetry
if [[ -x "$(command -v poetry)" && -d "$HOME/.poetry/bin" ]]; then
    export PATH=$PATH:$HOME/.poetry/bin
fi

# pip local install
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH=$PATH:$HOME/.local/bin
fi

# pip aliases
if [[ -x "$(command -v pip)" ]]; then
    alias pipupdateall='noproxy_cmd pip list -o | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 | xargs -r -n1 pip install --user -U'
    # alias pipupdateall='noproxy_cmd pip list -o | grep -Ev '"'"'^-|^package|^warning|^error'"'"' | cut -d '"'"' '"'"' -f1 | xargs -n1 pip install -U'
elif [[ -x "$(command -v pip3)" ]]; then
    alias pipupdateall='noproxy_cmd pip3 list -o | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 | xargs -r -n1 pip3 install --user -U'
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
    fi

    if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
        export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
    fi

    if [[ "${NVM_LOAD_NVMRC_IN_CURRENT_DIRECTORY}" == true ]]; then
        # use specified node version for the current directory with .nvmrc
        # echo "lts/*" > .nvmrc # to default to the latest LTS version
        # echo "node" > .nvmrc # to default to the latest version
        autoload -U add-zsh-hook
        load-nvmrc() {
            local node_version nvmrc_path nvmrc_node_version

            node_version="$(nvm version)"
            nvmrc_path="$(nvm_find_nvmrc)"
            if [[ -n "$nvmrc_path" ]]; then
                    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
                    if [[ "$nvmrc_node_version" == "N/A" ]]; then
                            nvm install
                    elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
                            nvm use
                    fi
            elif [[ "$node_version" != "$(nvm version default)" ]]; then
                    # echo "Reverting to nvm default version"
                    nvm use default
            fi
        }
        add-zsh-hook chpwd load-nvmrc
        load-nvmrc
    fi
fi

# npm global
if [[ -d "$HOME/.npm-global" ]]; then
    export PATH=$HOME/.npm-global/bin:$PATH
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

# URL encode/decode
# https://love2dev.com/blog/whats-the-difference-between-encodeuri-and-encodeuricomponent/
# usage
# echo -n "https://www.google.com/search?q=网址转中文" | encodeURI
# echo -n "https://www.google.com/search?q=%E7%BD%91%E5%9D%80%E8%BD%AC%E4%B8%AD%E6%96%87" | decodeURI
# echo -n "网址转中文" | encodeURIComponent
# echo -n "https://www.google.com/search?q=%E7%BD%91%E5%9D%80%E8%BD%AC%E4%B8%AD%E6%96%87" | decodeURIComponent
if [[ -x "$(command -v node)" ]]; then
    alias encodeURI="node -e \"process.stdin.on('data', data => process.stdout.write(encodeURI(data.toString())))\""
    alias decodeURI="node -e \"process.stdin.on('data', data => process.stdout.write(decodeURI(data.toString())))\""
    # echo '文档' | tr -d '\n' | encodeURIComponent
    alias encodeURIComponent="node -e \"process.stdin.on('data', data => process.stdout.write(encodeURIComponent(data.toString())))\""
    alias decodeURIComponent="node -e \"process.stdin.on('data', data => process.stdout.write(decodeURIComponent(data.toString())))\""
else
    [[ -x "$(command -v xxd)" ]] && alias encodeURIComponent="tr -d '\n' | xxd -plain | sed 's/\(..\)/%\1/g'"
    [[ -x "$(command -v od)" ]] && alias encodeURIComponent="tr -d '\n' | od -An -tx1 | tr ' ' %"
    alias decodeURIComponent="sed 's/%/\\\\x/g' | xargs -0 printf '%b'"
fi

# broot
if [[ ! "$(command -v br)" && -x "$(command -v broot)" ]]; then
    [[ -s "$HOME/.config/broot/launcher/bash/br" ]] && source "$HOME/.config/broot/launcher/bash/br"

    if [[ "$(command -v br)" && -s "${MY_SHELL_SCRIPTS}/conf/broot.toml" ]]; then
        alias br='br --conf "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/broot.toml"'
    fi
fi

# nnn
if [[ -x "$(command -v nnn)" ]]; then
    NNN_PLUG_INLINE='g:!go run $nnn*'
    NNN_PLUG_DEFAULT="1:bookmarks;a:autojump;b:oldbigfile;d:diffs;e:suedit;f:finder;i:ipinfo;k:pskill;m:nmount"
    NNN_PLUG_DEFAULT="${NNN_PLUG_DEFAULT};o:fzz;p:preview-tui;u:getplugs;v:imgview;w:pdfread;x:togglex"
    NNN_PLUG="${NNN_PLUG_DEFAULT};${NNN_PLUG_INLINE}"

    export NNN_PLUG
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_FIFO="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/nnn.fifo"
    [[ -x "$(command -v pistol)" ]] && export USE_PISTOL=1
fi

# fzf
if [[ -x "$(command -v fzf)" && -s "${MY_SHELL_SCRIPTS}/fzf_config.sh" ]]; then
    source "${MY_SHELL_SCRIPTS}/fzf_config.sh"
fi

# git clone default options
GIT_CLONE_DEFAULT_OPTION="-c core.autocrlf=false -c core.filemode=false"\
" -c fsck.zeroPaddedFilemode=ignore"\
" -c fetch.fsck.zeroPaddedFilemode=ignore"\
" -c receive.fsck.zeroPaddedFilemode=ignore"

export GIT_CLONE_DEFAULT_OPTION

[[ -z "${GIT_CLONE_OPTS[*]}" ]] && Get_Git_Clone_Options

# curl & axel default options
export INSTALLER_CHECK_CURL_OPTION=${INSTALLER_CHECK_CURL_OPTION:-"-fsL --connect-timeout 5"}
export INSTALLER_DOWNLOAD_CURL_OPTION=${INSTALLER_DOWNLOAD_CURL_OPTION:-"-fSL --connect-timeout 5"}
export INSTALLER_DOWNLOAD_AXEL_OPTION=${INSTALLER_DOWNLOAD_AXEL_OPTION:-"--num-connections=5 --timeout=30 --alternate"}

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# Accelerate the speed of accessing GitHub
# https://fastgit.org/
# https://www.gitclone.com/
# https://raw.hellogithub.com/hosts
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    # GITHUB_HUB_URL="https://gitclone.com/github.com"
    # GITHUB_HUB_URL="https://hub.fgit.ml/"
    export GITHUB_MIRROR_USE_FASTGIT=${GITHUB_MIRROR_USE_FASTGIT:-"false"}
    if [[ "${GITHUB_MIRROR_USE_FASTGIT}" == "true" ]]; then
        # GITHUB_HUB_URL="https://hub.fastgit.xyz"
        GITHUB_DOWNLOAD_URL=${GITHUB_DOWNLOAD_URL:-"https://download.fastgit.org"}
        GITHUB_RAW_URL=${GITHUB_RAW_URL:-"https://raw.fastgit.org"}
    fi

    # https://github.com/hunshcn/gh-proxy
    # https://ghps.cc/ https://ghproxy.net/ https://proxy.zyun.vip/
    export GITHUB_MIRROR_USE_GHPROXY=${GITHUB_MIRROR_USE_GHPROXY:-"true"}
    if [[ "${GITHUB_MIRROR_USE_GHPROXY}" == "true" ]]; then
        GITHUB_MIRROR_GHPROXY_URL=${GITHUB_MIRROR_GHPROXY_URL:-"https://ghproxy.com/"}
        # GITHUB_HUB_URL="${GITHUB_MIRROR_GHPROXY_URL}https://github.com"
        GITHUB_DOWNLOAD_URL=${GITHUB_DOWNLOAD_URL:-"${GITHUB_MIRROR_GHPROXY_URL}https://github.com"}
        GITHUB_RAW_URL=${GITHUB_RAW_URL:-"${GITHUB_MIRROR_GHPROXY_URL}https://raw.githubusercontent.com"}
    fi
fi

export GITHUB_HUB_URL=${GITHUB_HUB_URL:-"https://github.com"}
export GITHUB_DOWNLOAD_URL=${GITHUB_DOWNLOAD_URL:-"https://github.com"}
export GITHUB_RAW_URL=${GITHUB_RAW_URL:-"https://raw.githubusercontent.com"}

# https://docs.github.com/cn/rest/overview/resources-in-the-rest-api#rate-limiting
export GITHUB_API_TOKEN=${GITHUB_API_TOKEN:-""}

# WSL1
if check_os_wsl1; then
    # Docker
    if [[ -d "/c/Program Files/Docker Toolbox" ]]; then
        # export PATH="$PATH:/c/Program\ Files/Docker\ Toolbox"
        export DOCKER_TOOLBOX_INSTALL_PATH='/c/Program\ Files/Docker\ Toolbox'

        export WINDOWS_USER=$(/c/Windows/System32/cmd.exe /c 'echo %USERNAME%' | sed -e 's/\r//g')
        # export WINDOWS_USER=$(/c/Windows/System32/cmd.exe /c "whoami" | sed -E s/'^.+\\([^\\]*)$'/'\1'/)
        export DOCKER_TLS_VERIFY=1
        export DOCKER_HOST=tcp://192.168.99.100:2376
        export DOCKER_CERT_PATH=/c/Users/$WINDOWS_USER/.docker/machine/certs

        alias docker-machine='$DOCKER_TOOLBOX_INSTALL_PATH/docker-machine.exe'
    elif [[ -d "/c/Program Files/Docker/Docker" ]]; then
        # export PATH="$PATH:/mnt/c/Program\ Files/Docker/Docker/resources/bin"
        export DOCKER_INSTALL_PATH='/c/Program\ Files/Docker/Docker'

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

# Autostart Tmux/screen Session On Remote System When Logging In Via SSH
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    if [[ "$(command -v zellij)" ]]; then
        newZellijSession
    elif [[ "$(command -v tmux)" ]]; then
        newTmuxSession
    elif [[ -x "$(command -v screen)" ]]; then
        newScreenSession
    fi
fi
