#!/usr/bin/env bash

[[ -z "${OS_TYPE}" ]] && OS_TYPE=$(uname)

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

# systemctl
alias service-enabled='systemctl list-unit-files --type=service --state=enabled'
alias service-running='systemctl --type=service --state=running'
alias service-failed='systemctl --type=service --state=failed'

# fcitx5
alias rime-reconfig='qdbus org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1.SetConfig "fcitx://config/addon/rime/deploy" ""'
alias rime-sync='qdbus org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1.SetConfig "fcitx://config/addon/rime/sync" ""'

# proxy for ssh, git
if [[ -x "$(command -v nc)" && -n "${GLOBAL_PROXY_IP}" ]]; then
    if [[ -n "${GLOBAL_PROXY_MIXED_PORT}" ]]; then
        alias sshproxy='ssh -o '"'"'ProxyCommand nc -X connect -x ${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT} %h %p'"'"''
        alias gitproxy='git -c core.sshCommand="ssh -o '"'"'ProxyCommand nc -X connect -x ${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT} %h %p'"'"'"'
    elif [[ -n "${GLOBAL_PROXY_SOCKS_PORT}" ]]; then
        alias sshproxy='ssh -o '"'"'ProxyCommand nc -X 5 -x ${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_SOCKS_PORT} %h %p'"'"''
        alias gitproxy='git -c core.sshCommand="ssh -o '"'"'ProxyCommand nc -X 5 -x ${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_SOCKS_PORT} %h %p'"'"'"'
    fi
fi

# most used history commands
alias histop='fc -l -n 1 | grep -v "^\./" | sort | uniq -c | sort -rn | sed "s/^[ ]*[0-9]\+[ ]*//"'
alias hisrate='fc -l -n 1 | grep -v "^\./" | sort | uniq -c | sort -rn | sed "s/^[ ]*//" \
        | awk '"'"'BEGIN{i=0;total=0} \
            {CMD[i]=$0;RATE[i]=$1;i++;total=total+$1} \
            END{for (i=0; i in RATE; i++)print RATE[i]/total*100 "% " CMD[i];}'"'"''

# alias histop="awk -F';' '{print $2}' ${HISTFILE} | sort | uniq -c | sort -rn"

# skim
if [[ -x "$(command -v sk)" ]]; then
    alias sk-grep='sk --ansi -i -c '"'"'grep -rI --color=always --line-number "{}" .'"'"''
    alias sk-ack='sk --ansi -i -c '"'"'ack --color "{}"'"'"''
    alias sk-ag='sk --ansi -i -c '"'"'ag --color "{}"'"'"''
    alias sk-rg='sk --ansi -i -c '"'"'rg --color=always --line-number "{}"'"'"''
fi

# go
# if [[ -x "$(command -v go)" ]]; then
#     [[ -n "${all_proxy}" ]] && alias go='noproxy_cmd go'
# fi

# docker
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
    # https://nix.dev/
    alias docker-nix='docker run --rm -it --name nix -v $PWD:/opt ghcr.io/nixos/nix'
fi


if [[ -x "$(command -v eza)" ]]; then
    alias ezan="eza -ghl --icons --git --time-style=long-iso"
    alias ezal="eza -aghl --icons --git --time-style=long-iso"
    alias ezaa="eza -abghHliS --icons --git --time-style=long-iso"
    alias ezat="eza --tree --icons"
    alias ezat1="eza --tree --icons --level=1"
    alias ezat2="eza --tree --icons --level=2"
    alias ezat3="eza --tree --icons --level=3"
    # replace exa with eza
    alias exan="eza -ghl --icons --git --time-style=long-iso"
    alias exal="eza -aghl --icons --git --time-style=long-iso"
    alias exaa="eza -abghHliS --icons --git --time-style=long-iso"
    alias exat="eza --tree --icons"
    alias exat1="eza --tree --icons --level=1"
    alias exat2="eza --tree --icons --level=2"
    alias exat3="eza --tree --icons --level=3"
fi

# pip
if [[ -x "$(command -v pip)" ]]; then
    alias pipupdateall='$HOME/.local/bin/pip list -o 2>/dev/null | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 | xargs -r -n1 $HOME/.local/bin/pip install -U'
    # alias pipupdateall='noproxy_cmd pip list -o | grep -Ev '"'"'^-|^package|^warning|^error'"'"' | cut -d '"'"' '"'"' -f1 | xargs -n1 pip install -U'
elif [[ -x "$(command -v pip3)" ]]; then
    alias pipupdateall='$HOME/.local/bin/pip3 list -o 2>/dev/null | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 | xargs -r -n1 $HOME/.local/bin/pip3 install -U'
fi

# broot
if [[ "$(command -v br)" && -s "${MY_SHELL_SCRIPTS}/conf/broot.toml" ]]; then
    alias br='br --conf "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/broot.toml"'
fi

[[ -x "$(command -v microk8s)" ]] && alias mkctl="microk8s kubectl"

if [[ ! -x "$(command -v calicoctl)" && -x "$(command -v kubectl)" ]]; then
    alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"
fi

[[ -x "$(command -v lazygit)" ]] && alias lg='lazygit'

# rlwarp alias
[[ -x "$(command -v telnet)" && -x "$(command -v rlwrap)" ]] && alias telnet="rlwrap telnet"

if [[ -n "$ORACLE_HOME" && -x "$(command -v rlwrap)" ]]; then
    alias sqlplus="rlwrap sqlplus"
    alias rman="rlwrap rman"
    alias asmcmd="rlwrap asmcmd"
    alias ggsci="rlwrap ggsci"
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
    # [[ -x "$(command -v xxd)" ]] && alias encodeURIComponent="tr -d '\n' | xxd -plain | sed 's/\(..\)/%\1/g'"
    # [[ -x "$(command -v od)" ]] && alias encodeURIComponent="tr -d '\n' | od -An -tx1 | tr ' ' %"

    # printf %s "<url>" | jq -sRr @uri
    [[ -x "$(command -v jq)" ]] && alias encodeURIComponent="xargs printf %s | jq -sRr @uri"

    [[ -x "$(command -v perl)" ]] && alias decodeURIComponent='perl -pe '\''s/\+/ /g;'\'' -e '\''s/%(..)/chr(hex($1))/eg;'\'''
fi

# macOS
if [[ "${OS_TYPE}" == "Darwin" ]]; then
    [[ -x "$(command -v greadlink)" ]] && alias readlink=greadlink
fi

# Extend variable in MSYS2 to use node,npm,php,composer... with winpty
if [[ "${OS_TYPE}" =~ "MSYS_NT" || "${OS_TYPE}" =~ "MINGW" || "${OS_TYPE}" =~ "CYGWIN_NT" ]]; then
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
