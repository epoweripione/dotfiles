#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

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

colorEcho "${BLUE}Checking ${FUCHSIA}Lua & LuaRocks${BLUE}..."

if [[ -x "$(command -v apt)" ]]; then
    sudo apt -y install build-essential libreadline-dev
fi

if [[ -x "$(command -v dnf)" ]]; then
    sudo dnf -y groupinstall "Development Tools" readline
fi


# compile & install lua
# http://www.lua.org/
if [[ -x "$(command -v lua)" ]]; then
    INSTALLER_VER_CURRENT=$(lua -v | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    INSTALLER_VER_CURRENT=0.0
fi

INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" -N http://www.lua.org/download.html \
    | grep -Eo -m1 'lua-([0-9]{1,}\.)+[0-9]{1,}' | head -n1 | cut -d'-' -f2)

if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}lua ${YELLOW}${INSTALLER_VER_REMOTE} ${BLUE}from source..."
    INSTALLER_DOWNLOAD_URL="http://www.lua.org/ftp/lua-${INSTALLER_VER_REMOTE}.tar.gz"
    wget -O "${WORKDIR}/lua.tar.gz" "${INSTALLER_DOWNLOAD_URL}" && \
        tar -xzf "${WORKDIR}/lua.tar.gz" -C "${WORKDIR}" && \
        mv "${WORKDIR}"/lua-* "${WORKDIR}/lua" && \
        cd "${WORKDIR}/lua" && \
        make all test && \
        sudo make install
fi


# compile & install LuaRocks
# https://luarocks.org/
if [[ -x "$(command -v luarocks)" ]]; then
    INSTALLER_VER_CURRENT=$(luarocks --version | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    INSTALLER_VER_CURRENT=0.0
fi

INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" -N https://luarocks.org/ \
    | grep -Eo -m1 'luarocks-([0-9]{1,}\.)+[0-9]{1,}' | head -n1 | cut -d'-' -f2)

if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}luarocks ${YELLOW}${INSTALLER_VER_REMOTE} ${BLUE}from source..."
    INSTALLER_DOWNLOAD_URL="https://luarocks.org/releases/luarocks-${INSTALLER_VER_REMOTE}.tar.gz"
    wget -O "${WORKDIR}/luarocks.tar.gz" "${INSTALLER_DOWNLOAD_URL}" && \
        tar -xzf "${WORKDIR}/luarocks.tar.gz" -C "${WORKDIR}" && \
        mv "${WORKDIR}"/luarocks-* "${WORKDIR}/luarocks" && \
        cd "${WORKDIR}/luarocks" && \
        ./configure --with-lua-include=/usr/local/include >/dev/null && \
        make >/dev/null && \
        sudo make install >/dev/null
fi

cd "${CURRENT_DIR}" || exit