#!/usr/bin/env bash

# Version Manager Functions

# [goup (pronounced Go Up) is an elegant Go version manager](https://github.com/owenthereal/goup)
# install latest go version
function goupInstallLatest() {
    local GO_VER_LATEST GO_VER_INSTALLED

    [[ ! -x "$(command -v goup)" ]] && colorEcho "${FUCHSIA}goup${RED} is not installed!" && return 1

    [[ "${THE_WORLD_BLOCKED}" == "true" && -z "${GOUP_GO_HOST}" ]] && export GOUP_GO_HOST="golang.google.cn"

    GO_VER_LATEST=$(curl "${CURL_CHECK_OPTS[@]}" "https://${GOUP_GO_HOST:-"go.dev"}/VERSION?m=text" | grep -Eo -m1 'go([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    GO_VER_INSTALLED=$(goup list 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}')

    if grep -q "${GO_VER_LATEST//go/}" <<<"${GO_VER_INSTALLED}"; then
        colorEcho "${FUCHSIA}${GO_VER_LATEST}${BLUE} already installed."
    else
        colorEcho "${BLUE}Installing ${FUCHSIA}${GO_VER_LATEST}${BLUE}..."
        # fix: proxyconnect tcp: dial tcp: lookup socks5h: no such host
        if echo "${all_proxy}" | grep -q 'socks5h'; then
            proxy_socks5h_to_socks5 goup install "${GO_VER_LATEST}"
        else
            goup install "${GO_VER_LATEST}"
        fi
    fi
}

# update goup & latest go version
function goupUpgrade() {
    local GO_VER_LATEST GO_VER_INSTALLED

    [[ ! -x "$(command -v goup)" ]] && colorEcho "${FUCHSIA}goup${RED} is not installed!" && return 1

    colorEcho "${BLUE}Updating ${FUCHSIA} Go toolchains and goup${BLUE}..."
    # fix: proxyconnect tcp: dial tcp: lookup socks5h: no such host
    if echo "${all_proxy}" | grep -q 'socks5h'; then
        proxy_socks5h_to_socks5 sudo "$(which goup)" upgrade
    else
        sudo "$(which goup)" upgrade
    fi

    [[ "${THE_WORLD_BLOCKED}" == "true" && -z "${GOUP_GO_HOST}" ]] && export GOUP_GO_HOST="golang.google.cn"

    GO_VER_LATEST=$(curl "${CURL_CHECK_OPTS[@]}" "https://${GOUP_GO_HOST:-"go.dev"}/VERSION?m=text" | grep -Eo -m1 'go([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    GO_VER_INSTALLED=$(goup list 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}')

    if ! grep -q "${GO_VER_LATEST//go/}" <<<"${GO_VER_INSTALLED}"; then
        colorEcho "${BLUE}Installing ${FUCHSIA}${GO_VER_LATEST}${BLUE}..."
        # fix: proxyconnect tcp: dial tcp: lookup socks5h: no such host
        if echo "${all_proxy}" | grep -q 'socks5h'; then
            proxy_socks5h_to_socks5 goup install "${GO_VER_LATEST}"
        else
            goup install "${GO_VER_LATEST}"
        fi
    fi
}

# remove unuse installed go version but keep the latest minor version
# e.g.: 1.19 1.20.5 1.20.6 1.20.7 1.21.0 will remove 1.20.5, 1.20.6
function goupRemoveUnuse() {
    local GO_VER_LATEST GO_VER_UNUSE GO_VER_MINOR TargetVer

    [[ ! -x "$(command -v goup)" ]] && colorEcho "${FUCHSIA}goup${RED} is not installed!" && return 1

    [[ "${THE_WORLD_BLOCKED}" == "true" && -z "${GOUP_GO_HOST}" ]] && export GOUP_GO_HOST="golang.google.cn"

    GO_VER_LATEST=$(curl "${CURL_CHECK_OPTS[@]}" "https://${GOUP_GO_HOST:-"go.dev"}/VERSION?m=text" | grep -Eo -m1 'go([0-9]{1,}\.)+[0-9]{1,}' | head -n1)

    GO_VER_UNUSE=$(goup list 2>&1 | grep -v '\*' | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | sort -rV)

    GO_VER_MINOR=$(awk -F'.' '{print $1"."$2}' <<<"${GO_VER_LATEST//go/}")
    while read -r TargetVer; do
        [[ -z "${TargetVer}" || -z "${GO_VER_MINOR}" ]] && continue
        [[ "${TargetVer}" == *"${GO_VER_MINOR}"* ]] && goup remove "go${TargetVer}"
        GO_VER_MINOR=$(awk -F'.' '{print $1"."$2}' <<<"${TargetVer}")
    done <<<"${GO_VER_UNUSE}"

    colorEcho "${BLUE}Installed go versions:"
    goup list
}

# rbenv: install ruby version
function rbenvInstallRuby() {
    local RUBY_VERSION=$1
    local RUBY_MINOR_VERSION download_filename download_url

    [[ -z "${RUBY_VERSION}" ]] && colorEcho "${RED}Ruby version can't empty!" && return 1

    RUBY_MINOR_VERSION=$(cut -d'.' -f1-2 <<<"${RUBY_VERSION}")

    download_url="${RUBY_BUILD_MIRROR_URL:-"https://cache.ruby-lang.org"}/pub/ruby/${RUBY_MINOR_VERSION}/ruby-${RUBY_VERSION}.tar.gz"
    download_filename="$(rbenv root)/cache/ruby-${RUBY_VERSION}.tar.gz"

    colorEcho "${BLUE}Downloading ${FUCHSIA}ruby ${RUBY_VERSION}${BLUE} from ${ORANGE}${download_url}..."
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${download_filename}" "${download_url}"
    curl_rtn_code=$?

    if [[ ${curl_rtn_code} -eq 0 ]]; then
        colorEcho "${BLUE}Installing ${FUCHSIA}ruby ${YELLOW}${RUBY_VERSION}${BLUE}..."
        rbenv install "${RUBY_VERSION}" && rbenv rehash
    fi
}

# rbenv: fallback to system installed version
function rbenvFallbackSystemVersion() {
    rbenv global system
}

# [Runtime Executor (asdf rust clone)](https://github.com/jdxcode/rtx)
function rtx_App_Update() {
    # Usage:
    # rtx_App_Update all
    # rtx_App_Update neovim
    # rtx_App_Update nodejs lts
    local appName=${1:-"all"}
    local appVersion=$2
    local InstalledPlugins InstalledApp allVersion currentVersion currentVerNum majorVersion matchVersion latestVersion
    local appInstallStatus=0

    [[ ! "$(command -v rtx)" ]] && colorEcho "${FUCHSIA}rtx${RED} is not installed!" && return 1

    if [[ "${appName}" == "all" ]]; then
        colorEcho "${BLUE}Checking update for all installed ${FUCHSIA}rtx plugins${BLUE}..."
        rtx plugins update --all
        InstalledPlugins=$(rtx plugins ls 2>/dev/null)
    else
        colorEcho "${BLUE}Checking update for ${FUCHSIA}rtx plugin ${ORANGE}${appName}${BLUE}..."
        rtx plugins update "${appName}"
        InstalledPlugins="${appName}"
    fi

    while read -r InstalledApp; do
        [[ -z "${InstalledApp}" ]] && continue
        colorEcho "${BLUE}  Checking latest version for ${FUCHSIA}${InstalledApp}${BLUE}..."

        appInstallStatus=0
        allVersion=""
        latestVersion=""
        currentVersion=$(rtx current "${InstalledApp}" 2>/dev/null)
        [[ -z "${currentVersion}" ]] && continue # no installed version

        if [[ -n "${appVersion}" ]]; then
            matchVersion="${appVersion}"
        else
            currentVerNum=$(grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' <<<"${currentVersion}")
            if [[ -z "${currentVerNum}" ]]; then
                matchVersion="${currentVersion}"
            elif [[ "${currentVerNum}" == "${currentVersion}" ]]; then
                matchVersion=""
            else
                # fetch major version from current version string: {major}.{minor}.{revision}
                # zulu-17.40.19 → zulu-17
                majorVersion=$(cut -d'.' -f1 <<<"${currentVerNum}")
                matchVersion="${currentVersion/${currentVerNum}/}${majorVersion}"
            fi
        fi

        if [[ -n "${matchVersion}" ]]; then
            allVersion=$(rtx ls-remote "${InstalledApp}" 2>/dev/null | grep "${matchVersion}" 2>/dev/null | grep -Ev 'alpha|beta|rc|_[0-9]+$')
        else
            allVersion=$(rtx ls-remote "${InstalledApp}" 2>/dev/null | grep -E '([0-9]{1,}\.)+[0-9]{1,}' 2>/dev/null | grep -Ev 'alpha|beta|rc|_[0-9]+$')
        fi

        [[ -z "${allVersion}" ]] && allVersion=$(rtx ls-remote "${InstalledApp}" 2>/dev/null | grep -Ev 'alpha|beta|rc|_[0-9]+$')
        [[ -n "${allVersion}" ]] && latestVersion=$(sort -rV <<<"${allVersion}" | head -n1)

        [[ -z "${latestVersion}" ]] && continue

        # Alwarys reinstall if specify appVersion (stable, lts...)
        [[ -z "${appVersion}" && "${latestVersion}" == "${currentVersion}" ]] && continue

        # Uninstall first if specify appVersion (stable, lts...)
        [[ -n "${appVersion}" && "${latestVersion}" == "${currentVersion}" ]] && rtx uninstall "${InstalledApp}@${currentVersion}"

        rtx install "${InstalledApp}@${latestVersion}"
        appInstallStatus=$?

        if [[ ${appInstallStatus} -eq 0 ]]; then
            # Set the global runtime version to latest installed version
            rtx global "${InstalledApp}@${latestVersion}"

            # Uninstall old version
            [[ -z "${appVersion}" ]] && rtx uninstall "${InstalledApp}@${currentVersion}"
        fi
    done <<<"${InstalledPlugins}"
}

# asdf: Extendable version manager with support for Ruby, Node.js, Elixir, Erlang & more
# https://asdf-vm.com/
# https://github.com/asdf-vm/asdf
function asdf_App_Install() {
    # Usage:
    # asdf_App_Install neovim stable
    # asdf_App_Install java openjdk-11
    # asdf_App_Install nodejs lts
    local appName=$1
    local appVersion=${2:-"latest"}
    local allPlugin allVersion currentVersion latestVersion
    local appInstallStatus=0

    [[ ! "$(command -v asdf)" ]] && colorEcho "${FUCHSIA}asdf${RED} is not installed!" && return 1

    [[ -z "${appName}" ]] && \
        colorEcho "${FUCHSIA}asdf plugin${RED} name can't empty!" && \
        return 1

    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}asdf plugin ${ORANGE}${appName}${BLUE}..."
    # List All in Short-name Repository
    allPlugin=$(asdf plugin list all 2>/dev/null | awk '{print $1}')
    if [[ -z "${allPlugin}" ]]; then
        colorEcho "${RED}Get all ${FUCHSIA}asdf plugins${RED} list failed!"
        return 1
    fi

    if ! echo "${allPlugin}" | grep -q "^${appName}$"; then
        colorEchoN "${ORANGE}${appName}${RED} is not a valid ${FUCHSIA}asdf plugin${RED}!"
        colorEcho " More: ${FUCHSIA}https://asdf-vm.com/#/plugins-all"
        return 1
    fi

    # List Installed
    if ! asdf plugin list 2>/dev/null | grep -q "^${appName}$"; then
        asdf plugin add "${appName}"
    fi

    if ! asdf plugin list 2>/dev/null | grep -q "^${appName}$"; then
        colorEcho "${RED}Install ${FUCHSIA}asdf plugin ${ORANGE}${appName}${RED} failed!"
        return 1
    fi

    ## List All Available Versions
    # asdf list all "${appName}"
    # asdf list all "${appName}" "${appVersion}"
    # asdf list all java | cut -d'-' -f1 | sort -V | uniq

    # If `appVersion` is not a valid version, get latest version from all versions
    allVersion=$(asdf list all "${appName}" "${appVersion}" 2>/dev/null | grep -Ev 'alpha|beta|rc|_[0-9]+$')
    [[ -z "${allVersion}" ]] && allVersion=$(asdf list all "${appName}" 2>/dev/null | grep -Ev 'alpha|beta|rc|_[0-9]+$')
    # https://stackoverflow.com/questions/4493205/unix-sort-of-version-numbers
    # sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n
    # To reverse the order: sort -t. -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr
    [[ -n "${allVersion}" ]] && latestVersion=$(echo "${allVersion}" | sort -rV | head -n1)
    [[ -z "${latestVersion}" ]] && latestVersion="latest"

    # Current Version
    # currentVersion=$(asdf current "${appName}" 2>/dev/null | sed 's/  */ /g' | cut -d' ' -f2)
    # currentVersion=$(asdf current "${appName}" 2>/dev/null | tr -s ' ' | cut -d' ' -f2)
    currentVersion=$(asdf current "${appName}" 2>/dev/null | awk '{print $2}')

    if [[ "${latestVersion}" == "${currentVersion}" ]]; then
        colorEcho "${FUCHSIA}${appName} ${latestVersion}${GREEN} is already installed!"
        return 0
    fi

    colorEcho "${BLUE}  Installing ${FUCHSIA}${appName} ${YELLOW}${latestVersion}${BLUE}..."
    # Install Version
    if [[ "${appName}" == "nodejs" ]]; then
        [[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env
        if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
            NODEJS_CHECK_SIGNATURES="no" NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node/" \
                asdf install "${appName}" "${latestVersion}"
            appInstallStatus=$?
        else
            NODEJS_CHECK_SIGNATURES="no" asdf install "${appName}" "${latestVersion}"
            appInstallStatus=$?
        fi
    else
        asdf install "${appName}" "${latestVersion}"
        appInstallStatus=$?
    fi

    # Set Current Version
    if [[ ${appInstallStatus} -eq 0 ]]; then
        asdf global "${appName}" "${latestVersion}"
        # asdf shell "${appName}" "${latestVersion}"
        # asdf local "${appName}" "${latestVersion}"

        # [[ -n "${currentVersion}" ]] && asdf uninstall "${appName}" "${currentVersion}"
    fi

    ## Fallback to System Version
    # asdf local ${appName} system

    # View Current Version
    asdf current "${appName}"

    ## Show Latest Stable Version
    # asdf latest "${appName}"
    # asdf latest "${appName}" "${latestVersion}"

    ## List Installed Versions
    # asdf list "${appName}"

    ## Uninstall Installed Version
    # asdf uninstall "${appName}" "${latestVersion}"

    ## Update all
    # asdf plugin update --all
}

function asdf_App_Update() {
    # Usage:
    # asdf_App_Update all
    # asdf_App_Update neovim
    # asdf_App_Update nodejs lts
    local appName=${1:-"all"}
    local appVersion=$2
    local InstalledPlugins InstalledApp allVersion currentVersion currentVerNum majorVersion matchVersion latestVersion
    local appInstallStatus=0

    [[ ! "$(command -v asdf)" ]] && colorEcho "${FUCHSIA}asdf${RED} is not installed!" && return 1

    if [[ "${appName}" == "all" ]]; then
        colorEcho "${BLUE}Checking update for all installed ${FUCHSIA}asdf plugins${BLUE}..."
        InstalledPlugins=$(asdf plugin list 2>/dev/null)
    else
        colorEcho "${BLUE}Checking update for ${FUCHSIA}asdf plugin ${ORANGE}${appName}${BLUE}..."
        InstalledPlugins="${appName}"
    fi

    while read -r InstalledApp; do
        [[ -z "${InstalledApp}" ]] && continue
        colorEcho "${BLUE}  Checking latest version for ${FUCHSIA}${InstalledApp}${BLUE}..."

        appInstallStatus=0
        allVersion=""
        latestVersion=""
        currentVersion=$(asdf current "${InstalledApp}" 2>/dev/null | awk '{print $2}')
        [[ -z "${currentVersion}" ]] && continue # no installed version

        if [[ -n "${appVersion}" ]]; then
            matchVersion="${appVersion}"
        else
            currentVerNum=$(echo "${currentVersion}" | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}')
            if [[ -z "${currentVerNum}" ]]; then
                matchVersion="${currentVersion}"
            elif [[ "${currentVerNum}" == "${currentVersion}" ]]; then
                matchVersion=""
            else
                # fetch major version from current version string: {major}.{minor}.{revision}
                # zulu-17.40.19 → zulu-17
                majorVersion=$(echo "${currentVerNum}" | cut -d'.' -f1)
                matchVersion="${currentVersion/${currentVerNum}/}${majorVersion}"
            fi
        fi

        [[ -n "${matchVersion}" ]] && allVersion=$(asdf list all "${InstalledApp}" "${matchVersion}" 2>/dev/null | grep -Ev 'alpha|beta|rc|_[0-9]+$')
        [[ -z "${allVersion}" ]] && allVersion=$(asdf list all "${InstalledApp}" 2>/dev/null | grep -Ev 'alpha|beta|rc|_[0-9]+$')
        [[ -n "${allVersion}" ]] && latestVersion=$(echo "${allVersion}" | sort -rV | head -n1)

        # [[ -z "${latestVersion}" ]] && latestVersion="latest"
        [[ -z "${latestVersion}" ]] && continue

        # Alwarys reinstall if specify appVersion (stable, lts...)
        [[ -z "${appVersion}" && "${latestVersion}" == "${currentVersion}" ]] && continue

        colorEcho "${BLUE}  Updating ${FUCHSIA}${InstalledApp}${BLUE} to ${YELLOW}${latestVersion}${BLUE}..."
        asdf plugin update "${InstalledApp}"

        # Uninstall first if specify appVersion (stable, lts...)
        [[ -n "${appVersion}" && "${latestVersion}" == "${currentVersion}" ]] && asdf uninstall "${InstalledApp}" "${currentVersion}"

        if [[ "${appName}" == "nodejs" ]]; then
            [[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env
            if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
                NODEJS_CHECK_SIGNATURES="no" NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node/" \
                    asdf install "${InstalledApp}" "${latestVersion}"
                appInstallStatus=$?
            else
                NODEJS_CHECK_SIGNATURES="no" asdf install "${InstalledApp}" "${latestVersion}"
                appInstallStatus=$?
            fi
        else
            asdf install "${InstalledApp}" "${latestVersion}"
            appInstallStatus=$?
        fi

        if [[ ${appInstallStatus} -eq 0 ]]; then
            # Set the global runtime version to latest installed version
            asdf global "${InstalledApp}" "${latestVersion}"

            # Uninstall old version
            [[ -z "${appVersion}" ]] || asdf uninstall "${InstalledApp}" "${currentVersion}"
        fi
    done <<<"${InstalledPlugins}"
}
