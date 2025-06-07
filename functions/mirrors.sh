#!/usr/bin/env bash

# docker
function setMirrorDocker() {
    local mirror

    # DOCKER_MIRROR_LIST=(
    #     "https://dockerpull.com"
    #     "https://dockerproxy.cn"
    # )
    [[ -z "${DOCKER_MIRROR_LIST[*]}" ]] && return 0

    if [[ -x "$(command -v docker)" && -z "${MIRROR_DOCKER_REGISTRY}" ]]; then
        for mirror in "${DOCKER_MIRROR_LIST[@]}"; do
            if [[ -z "${MIRROR_DOCKER_REGISTRY}" ]]; then
                MIRROR_DOCKER_REGISTRY="\"${mirror}\""
            else
                MIRROR_DOCKER_REGISTRY="${MIRROR_DOCKER_REGISTRY},\"${mirror}\""
            fi
        done
    fi
}

# homebrew
function setMirrorHomebrew() {
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        export HOMEBREW_BREW_GIT_REMOTE=${HOMEBREW_BREW_GIT_REMOTE:-"https://mirrors.ustc.edu.cn/brew.git"}
        export HOMEBREW_CORE_GIT_REMOTE=${HOMEBREW_CORE_GIT_REMOTE:-"https://mirrors.ustc.edu.cn/homebrew-core.git"}
        export HOMEBREW_BOTTLE_DOMAIN=${HOMEBREW_BOTTLE_DOMAIN:-"https://mirrors.ustc.edu.cn/homebrew-bottles"}
        export HOMEBREW_API_DOMAIN=${HOMEBREW_API_DOMAIN:-"https://mirrors.ustc.edu.cn/homebrew-bottles/api"}

        ## Brew installation fails due to Ruby versioning?
        ## https://unix.stackexchange.com/questions/694020/brew-installation-fails-due-to-ruby-versioning
        # export RUBY_BUILD_MIRROR_URL=${RUBY_BUILD_MIRROR_URL:-"https://cache.ruby-china.com"}
        # export RUBY_GEM_SOURCE_MIRROR=${RUBY_GEM_SOURCE_MIRROR:-"https://gems.ruby-china.com/"}
    fi
}

# go: installer/goup_go_installer.sh, installer/gvm_go_installer.sh
function setMirrorGo() {
    local GO_VERSION

    # goup
    if [[ -x "$(command -v goup)" ]]; then
        export GOUP_GO_HOST=${GOUP_GO_HOST:-"golang.google.cn"}
    fi

    # go
    if [[ -x "$(command -v go)" ]]; then
        GO_VERSION=$(go version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
        if version_ge "${GO_VERSION}" '1.13'; then
            go env -w GOPROXY="${MIRROR_GO_PROXY:-"https://goproxy.cn,direct"}"
            # go env -w GOSUMDB="${MIRROR_GO_SUMDB:-"sum.golang.google.cn"}"
            # GONOSUMDB=*.corp.example.com,rsc.io/private
            [[ -n "${MIRROR_GO_NOSUMDB}" ]] && go env -w GONOSUMDB="${MIRROR_GO_NOSUMDB}"
            # https://goproxy.io/zh/docs/goproxyio-private.html
            [[ -n "${MIRROR_GO_PRIVATE}" ]] && go env -w GOPRIVATE="${MIRROR_GO_PRIVATE}"
        else
            export GOPROXY=${MIRROR_GO_PROXY:-"https://goproxy.cn,direct"}
            # export GOSUMDB=${MIRROR_GO_SUMDB:-"sum.golang.google.cn"}
            [[ -n "${MIRROR_GO_NOSUMDB}" ]] && export GONOSUMDB="${MIRROR_GO_NOSUMDB}"
            [[ -n "${MIRROR_GO_PRIVATE}" ]] && export GOPRIVATE="${MIRROR_GO_PRIVATE}"
        fi
    fi
}

# flutter
function setMirrorFlutter() {
    if [[ -x "$(command -v flutter)" ]]; then
        export PUB_HOSTED_URL=${PUB_HOSTED_URL:-"https://pub.flutter-io.cn"}
        export FLUTTER_STORAGE_BASE_URL=${FLUTTER_STORAGE_BASE_URL:-"https://storage.flutter-io.cn"}
    fi
}

# rustup & cargo
function setMirrorRust() {
    export RUSTUP_DIST_SERVER=${RUSTUP_DIST_SERVER:-"https://rsproxy.cn"}
    export RUSTUP_UPDATE_ROOT=${RUSTUP_UPDATE_ROOT:-"https://rsproxy.cn/rustup"}

    # cargo
    MIRROR_RUST_CARGO=${MIRROR_RUST_CARGO:-"rsproxy-sparse"}
    if [[ ! -s "$HOME/.cargo/config.toml" ]]; then
        mkdir -p "$HOME/.cargo"
        cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/cargo.toml" "$HOME/.cargo/config.toml"
        sed -i -e "s|'crates-io-sparse'|'${MIRROR_RUST_CARGO}'|g" -e "s|# replace-with|replace-with|g" "$HOME/.cargo/config.toml"
    fi
}

# nodejs & nvm & nvs
function setMirrorNodejs() {
    # nodejs
    if [[ "$(command -v node)" ]]; then
        export MIRROR_NODEJS_REGISTRY=${MIRROR_NODEJS_REGISTRY:-"https://registry.npmmirror.com"}
    fi

    # corepack
    if [[ "$(command -v corepack)" ]]; then
        [[ -n "${MIRROR_NODEJS_REGISTRY}" ]] && export COREPACK_NPM_REGISTRY="${MIRROR_NODEJS_REGISTRY}"
    fi

    # nvm
    if [[ "$(command -v nvm)" ]]; then
        export NVM_NODEJS_ORG_MIRROR=${NVM_NODEJS_ORG_MIRROR:-"https://npmmirror.com/mirrors/node"}
    fi

    # nvs
    if [[ "$(command -v nvs)" ]]; then
        export NVS_NODEJS_ORG_MIRROR=${NVS_NODEJS_ORG_MIRROR:-"https://npmmirror.com/mirrors/node"}
        nvs remote node "${NVS_NODEJS_ORG_MIRROR}"
    fi

    # [NPM Binary mirror](https://github.com/cnpm/binary-mirror-config/blob/master/package.json)
    if [[ -z "${MIRROR_NODEJS_REGISTRY}" ]]; then
        unset CHROMEDRIVER_CDNURL
        unset COREPACK_NPM_REGISTRY
        unset CYPRESS_DOWNLOAD_PATH_TEMPLATE
        unset EDGEDRIVER_CDNURL
        unset ELECTRON_BUILDER_BINARIES_MIRROR
        unset ELECTRON_MIRROR
        unset NODEJS_ORG_MIRROR
        unset NVM_NODEJS_ORG_MIRROR
        unset NWJS_URLBASE
        unset OPERADRIVER_CDNURL
        unset PHANTOMJS_CDNURL
        unset PLAYWRIGHT_DOWNLOAD_HOST
        unset PRISMA_ENGINES_MIRROR
        unset PUPPETEER_CHROME_DOWNLOAD_BASE_URL
        unset PUPPETEER_CHROME_HEADLESS_SHELL_DOWNLOAD_BASE_URL
        unset PUPPETEER_DOWNLOAD_BASE_URL
        unset PUPPETEER_DOWNLOAD_HOST
        unset RE2_DOWNLOAD_MIRROR
        unset RE2_DOWNLOAD_SKIP_PATH
        unset SASS_BINARY_SITE
        unset SAUCECTL_INSTALL_BINARY_MIRROR
        unset SENTRYCLI_CDNURL
        unset SWC_BINARY_SITE
        # binary_host
        unset better_sqlite3_binary_host
        unset gl_binary_host
        unset keytar_binary_host
        unset robotjs_binary_host
        unset sharp_binary_host
        unset sharp_libvips_binary_host
    fi

    if [[ "${MIRROR_NODEJS_REGISTRY}" == "https://registry.npmmirror.com" ]]; then
        export CHROMEDRIVER_CDNURL='https://cdn.npmmirror.com/binaries/chromedriver'
        export COREPACK_NPM_REGISTRY='https://registry.npmmirror.com'
        export CYPRESS_DOWNLOAD_PATH_TEMPLATE='https://cdn.npmmirror.com/binaries/cypress/${version}/${platform}-${arch}/cypress.zip'
        export EDGEDRIVER_CDNURL='https://npmmirror.com/mirrors/edgedriver'
        export ELECTRON_BUILDER_BINARIES_MIRROR='https://cdn.npmmirror.com/binaries/electron-builder-binaries/'
        export ELECTRON_MIRROR='https://cdn.npmmirror.com/binaries/electron/'
        export NODEJS_ORG_MIRROR='https://cdn.npmmirror.com/binaries/node'
        export NVM_NODEJS_ORG_MIRROR='https://cdn.npmmirror.com/binaries/node'
        export NWJS_URLBASE='https://cdn.npmmirror.com/binaries/nwjs/v'
        export OPERADRIVER_CDNURL='https://cdn.npmmirror.com/binaries/operadriver'
        export PHANTOMJS_CDNURL='https://cdn.npmmirror.com/binaries/phantomjs'
        export PLAYWRIGHT_DOWNLOAD_HOST='https://cdn.npmmirror.com/binaries/playwright'
        export PRISMA_ENGINES_MIRROR='https://cdn.npmmirror.com/binaries/prisma'
        export PUPPETEER_CHROME_DOWNLOAD_BASE_URL='https://cdn.npmmirror.com/binaries/chrome-for-testing'
        export PUPPETEER_CHROME_HEADLESS_SHELL_DOWNLOAD_BASE_URL='https://cdn.npmmirror.com/binaries/chrome-for-testing'
        export PUPPETEER_DOWNLOAD_BASE_URL='https://cdn.npmmirror.com/binaries/chrome-for-testing'
        export PUPPETEER_DOWNLOAD_HOST='https://cdn.npmmirror.com/binaries/chrome-for-testing'
        export RE2_DOWNLOAD_MIRROR='https://cdn.npmmirror.com/binaries/node-re2'
        export RE2_DOWNLOAD_SKIP_PATH='true'
        export SASS_BINARY_SITE='https://cdn.npmmirror.com/binaries/node-sass'
        export SAUCECTL_INSTALL_BINARY_MIRROR='https://cdn.npmmirror.com/binaries/saucectl'
        export SENTRYCLI_CDNURL='https://cdn.npmmirror.com/binaries/sentry-cli'
        export SWC_BINARY_SITE='https://cdn.npmmirror.com/binaries/node-swc'
        # binary_host
        export better_sqlite3_binary_host='https://cdn.npmmirror.com/binaries/better-sqlite3'
        export gl_binary_host='https://cdn.npmmirror.com/binaries/gl'
        export keytar_binary_host='https://cdn.npmmirror.com/binaries/keytar'
        export robotjs_binary_host='https://cdn.npmmirror.com/binaries/robotjs'
        export sharp_binary_host='https://cdn.npmmirror.com/binaries/sharp'
        export sharp_libvips_binary_host='https://cdn.npmmirror.com/binaries/sharp-libvips'
    fi
}

# nodejs: nodejs/nvm_node_installer.sh, nodejs/nvs_node_installer.sh
function setMirrorNpm() {
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]]; then
        "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" AUTO
    fi
}

# pip
function setMirrorPip() {
    if [[ -x "$(command -v pip)" ]]; then
        export PYTHON_PIP_CONFIG=${PYTHON_PIP_CONFIG:-"$HOME/.pip/pip.conf"}
        export MIRROR_PYTHON_PIP_URL=${MIRROR_PYTHON_PIP_URL:-"https://mirrors.sustech.edu.cn/pypi/web/simple"}
        export MIRROR_PYTHON_PIP_EXTRA=${MIRROR_PYTHON_PIP_EXTRA}

        MIRROR_PYTHON_PIP_HOST=$(cut -d/ -f3 <<<"${MIRROR_PYTHON_PIP_URL}")
        export MIRROR_PYTHON_PIP_HOST
    fi
}

function setMirrorPipGlobal() {
    [[ ! -x "$(command -v pip)" ]] && return 0

    setMirrorPip

    [[ -f "${PYTHON_PIP_CONFIG}" ]] && rm "${PYTHON_PIP_CONFIG}"

    if [[ -z "${MIRROR_PYTHON_PIP_URL}" ]]; then
        sudo pip config --global unset global.index-url >/dev/null 2>&1
    else
        sudo pip config --global set global.index-url "${MIRROR_PYTHON_PIP_URL}" >/dev/null 2>&1
    fi

    if [[ -z "${MIRROR_PYTHON_PIP_EXTRA}" ]]; then
        sudo pip config --global unset global.extra-index-url  >/dev/null 2>&1
    else
        sudo pip config --global set global.extra-index-url "${MIRROR_PYTHON_PIP_EXTRA}" >/dev/null 2>&1
    fi

    # poetry source add --priority=primary mirrors "${MIRROR_PYTHON_PIP_URL}"
    # poetry source add --priority=supplemental mirrors "${MIRROR_PYTHON_PIP_EXTRA}"
    # pdm config pypi.url "${MIRROR_PYTHON_PIP_URL}"

    pip config --global list
}

# conda
function setMirrorConda() {
    if [[ "$(command -v conda)" || "$(command -v mamba)" ||"$(command -v micromamba)" ]]; then
        export MIRROR_PYTHON_CONDA=${MIRROR_PYTHON_CONDA:-"https://mirrors.sustech.edu.cn"}

        if [[ ! -s "$HOME/.condarc" ]]; then
            cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/condarc" "$HOME/.condarc"
        fi

        if [[ "${MIRROR_PYTHON_CONDA}" != "https://mirrors.sustech.edu.cn" ]]; then
            sed -i -e "s|https://mirrors.sustech.edu.cn|${MIRROR_PYTHON_CONDA}|g" "$HOME/.condarc"
        fi
    fi
}

# rbenv
function setMirrorRbenv() {
    if [[ -x "$(command -v rbenv)" ]]; then
        export RUBY_BUILD_MIRROR_URL=${RUBY_BUILD_MIRROR_URL:-"https://cache.ruby-china.com"}
    fi
}

# gem mirror
function setMirrorGem() {
    if [[ -x "$(command -v gem)" || -x "$(command -v bundle)" ]]; then
        export RUBY_GEM_SOURCE_MIRROR=${RUBY_GEM_SOURCE_MIRROR:-"https://gems.ruby-china.com/"}

        if [[ -x "$(command -v gem)" ]]; then
            gem sources --add "${RUBY_GEM_SOURCE_MIRROR}" --remove "https://rubygems.org/"
            gem sources -l
        fi

        if [[ -x "$(command -v bundle)" ]]; then
            bundle config mirror.https://rubygems.org "${RUBY_GEM_SOURCE_MIRROR}"
            bundle config list
        fi
    fi
}

# [Nix channels](https://mirrors.tuna.tsinghua.edu.cn/help/nix-channels/)
function setMirrorNix() {
    if [[ -x "$(command -v nix)" ]]; then
        export MIRROR_NIX_STORE=${MIRROR_NIX_STORE:-"https://mirrors.tuna.tsinghua.edu.cn"}
        mkdir -p "$HOME/.config/nix"
        if ! grep -q "^substituters =" "$HOME/.config/nix/nix.conf"; then
            echo "substituters = ${MIRROR_NIX_STORE}/nix-channels/store https://cache.nixos.org" >> "$HOME/.config/nix/nix.conf"
        fi

        if ! nix-channel --list | grep "${MIRROR_NIX_STORE}" >/dev/null 2>&1; then
            nix-channel --add "${MIRROR_NIX_STORE}/nix-channels/nixpkgs-unstable" nixpkgs
            nix-channel --update
        fi
    fi
}

# [Arch Linux Chinese Community Repository](https://github.com/archlinuxcn/mirrorlist-repo)
function setMirrorArchLinuxCN() {
    export MIRROR_ARCHLINUX_CN=${MIRROR_ARCHLINUX_CN:-"https://mirrors.sjtug.sjtu.edu.cn"}
}

# [Rockylinux mirror](https://rockylinux.cn/download)
function setMirrorRockyLinux() {
    local resetMirror=$1

    export MIRROR_ROCKYLINUX=${MIRROR_ROCKYLINUX:-"https://mirrors.aliyun.com/rockylinux"}
    export MIRROR_EPEL_RELEASE=${MIRROR_EPEL_RELEASE:-"https://mirrors.aliyun.com"}

    if [[ "${resetMirror}" == "reset" ]]; then
        # for i in /etc/yum.repos.d/Rocky*.bak; do sudo mv "$i" "${i%.bak}"; done
        sudo sed -e 's|^#mirrorlist=|mirrorlist=|g' \
            -e "s|^baseurl=${MIRROR_ROCKYLINUX}|#baseurl=http://dl.rockylinux.org/\$contentdir|g" \
        -i.bak \
        /etc/yum.repos.d/Rocky*.repo

        # epel
        # for i in /etc/yum.repos.d/epel*.bak; do sudo mv "$i" "${i%.bak}"; done
        sudo sed -e 's|^#metalink=|metalink=|' \
            -e "s|^baseurl=${MIRROR_EPEL_RELEASE}|#baseurl=https://download.example/pub|" \
        -i.bak \
        /etc/yum.repos.d/epel*.repo
    else
        sudo sed -e 's|^mirrorlist=|#mirrorlist=|g' \
            -e "s|^#baseurl=http://dl.rockylinux.org/\$contentdir|baseurl=${MIRROR_ROCKYLINUX}|g" \
        -i.bak \
        /etc/yum.repos.d/Rocky*.repo

        # epel
        sudo sed -e 's|^metalink=|#metalink=|' \
            -e "s|^#baseurl=https://download.example/pub|baseurl=${MIRROR_EPEL_RELEASE}|" \
        -i.bak \
        /etc/yum.repos.d/epel*.repo
    fi

    dnf makecache
}


# unset all mirrors
function unsetMirrorAll() {
    # docker
    unset MIRROR_DOCKER_REGISTRY
    # homebrew
    unset HOMEBREW_BREW_GIT_REMOTE
    unset HOMEBREW_CORE_GIT_REMOTE
    unset HOMEBREW_BOTTLE_DOMAIN
    unset HOMEBREW_API_DOMAIN
    # goup
    unset GOUP_GO_HOST
    # go
    unset MIRROR_GO_PROXY
    unset MIRROR_GO_SUMDB
    unset MIRROR_GO_NOSUMDB
    unset MIRROR_GO_PRIVATE
    if [[ -x "$(command -v go)" ]]; then
        go env -u GOPROXY
        go env -u GOSUMDB
        go env -u GONOSUMDB
        go env -u GOPRIVATE
    fi
    # flutter
    unset PUB_HOSTED_URL
    unset FLUTTER_STORAGE_BASE_URL
    # rustup & cargo
    unset RUSTUP_DIST_SERVER
    unset RUSTUP_UPDATE_ROOT
    unset MIRROR_RUST_CARGO
    [[ -s "$HOME/.cargo/config" ]] && rm -f "$HOME/.cargo/config"
    [[ -s "$HOME/.cargo/config.toml" ]] && rm -f "$HOME/.cargo/config.toml"
    # python
    unset PYTHON_PIP_CONFIG
    unset MIRROR_PYTHON_PIP_URL
    unset MIRROR_PYTHON_PIP_EXTRA
    unset MIRROR_PYTHON_PIP_HOST
    # conda
    unset MIRROR_PYTHON_CONDA
    [[ -s "$HOME/.condarc" ]] && rm -f "$HOME/.condarc"
    # rbenv
    [[ -x "$(command -v gem)" ]] && gem sources --add "https://rubygems.org/" --remove "${RUBY_GEM_SOURCE_MIRROR}"
    [[ -x "$(command -v bundle)" ]] && bundle config unset mirror.https://rubygems.org
    unset RUBY_BUILD_MIRROR_URL
    unset RUBY_GEM_SOURCE_MIRROR
    # nodejs
    unset MIRROR_NODEJS_REGISTRY
    unset NVM_NODEJS_ORG_MIRROR
    unset NVS_NODEJS_ORG_MIRROR
    # NPM Binary mirror
    unset CHROMEDRIVER_CDNURL
    unset COREPACK_NPM_REGISTRY
    unset CYPRESS_DOWNLOAD_PATH_TEMPLATE
    unset EDGEDRIVER_CDNURL
    unset ELECTRON_BUILDER_BINARIES_MIRROR
    unset ELECTRON_MIRROR
    unset NODEJS_ORG_MIRROR
    unset NVM_NODEJS_ORG_MIRROR
    unset NWJS_URLBASE
    unset OPERADRIVER_CDNURL
    unset PHANTOMJS_CDNURL
    unset PLAYWRIGHT_DOWNLOAD_HOST
    unset PRISMA_ENGINES_MIRROR
    unset PUPPETEER_CHROME_DOWNLOAD_BASE_URL
    unset PUPPETEER_CHROME_HEADLESS_SHELL_DOWNLOAD_BASE_URL
    unset PUPPETEER_DOWNLOAD_BASE_URL
    unset PUPPETEER_DOWNLOAD_HOST
    unset RE2_DOWNLOAD_MIRROR
    unset RE2_DOWNLOAD_SKIP_PATH
    unset SASS_BINARY_SITE
    unset SAUCECTL_INSTALL_BINARY_MIRROR
    unset SENTRYCLI_CDNURL
    unset SWC_BINARY_SITE
    # binary_host
    unset better_sqlite3_binary_host
    unset gl_binary_host
    unset keytar_binary_host
    unset robotjs_binary_host
    unset sharp_binary_host
    unset sharp_libvips_binary_host
    # npm config
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]]; then
        "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" RESET
    fi
    # Nix
    unset MIRROR_NIX_STORE
}
