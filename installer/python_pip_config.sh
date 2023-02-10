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

[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

mkdir -p "$HOME/.local/bin"

## python3
# sudo pacman -S python3

## pip
# sudo pacman -S build-essential pkg-config python3-dev python3-distutils
# sudo pacman -S libssl-dev libcurl4-openssl-dev libcairo2-dev libjpeg-dev libgif-dev libgirepository1.0-dev

## https://pip.pypa.io/en/stable/installing/
# curl "https://bootstrap.pypa.io/get-pip.py" -o get-pip.py && python3 get-pip.py && rm get-pip.py

## fix: ERROR: Could not install packages due to an OSError: Missing dependencies for SOCKS support.
# python3 -m pip install --user -U pysocks
# python3 -m pip install --user -U pip
# python3 -m pip install --user -U setuptools wheel

## update all outdated packages
# noproxy_cmd pip list -o | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 | xargs --no-run-if-empty -n1 pip install --user -U

## Install and use pip in a local directory without root/sudo access
## https://gist.github.com/saurabhshri/46e4069164b87a708b39d947e4527298
# .local/bin/pip install --user <package_name>

# Python3
if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        python3
        build-essential
        cairo-dev
        cairo-devel
        cairo-gobject-devel
        dbus-devel
        dbus-glib-devel
        gobject-introspection
        gobject-introspection-devel
        pkgconf
        pkg-config
        python3-dev
        python3-devel
        python3-distutils
        python3-venv
        swig
        libdbus-1-dev
        libglib2.0-dev
        libgpgme-dev
        libssl-dev
        libcurl4-openssl-dev
        libcairo2-dev
        libjpeg-dev
        libgif-dev
        libgirepository1.0-dev
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done

    # [[ -x "$(command -v dnf)" ]] && sudo dnf group install -y "Development Tools"
fi

PYTHON_CMD=""
if [[ -x "$(command -v python3)" ]]; then
    PYTHON_CMD="python3"
elif [[ -x "$(command -v python)" ]]; then
    PYTHON_CMD="python"
fi

# pip
INSTALL_PIP_LATEST="NO"
PYTHON_CURRENT_VERSION="0.0.0"
if [[ -n "${PYTHON_CMD}" ]]; then
    PYTHON_CURRENT_VERSION=$(sudo ${PYTHON_CMD} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
fi

PIP_CURRENT_VERSION="0.0.0"
if [[ -x "$(command -v pip)" ]]; then
    PIP_CURRENT_VERSION=$(sudo ${PYTHON_CMD} -m pip -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
fi

if version_lt "${PIP_CURRENT_VERSION}" "22.0.0"; then
    INSTALL_PIP_LATEST="YES"
fi

if [[ "${INSTALL_PIP_LATEST}" == "YES" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}pip${BLUE}..."
    if version_lt "${PYTHON_CURRENT_VERSION}" "3.7.0"; then
        PIP_DOWNLOAD_URL="https://bootstrap.pypa.io/pip/3.6/get-pip.py"
    else
        PIP_DOWNLOAD_URL="https://bootstrap.pypa.io/get-pip.py"
    fi

    curl "${PIP_DOWNLOAD_URL}" -o get-pip.py && \
        sudo ${PYTHON_CMD} get-pip.py --user && \
        ${PYTHON_CMD} get-pip.py --user && \
        rm -f get-pip.py
fi

if [[ ! -x "$(command -v pip)" || ! -x "$(command -v pip3)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}pip${BLUE}..."
    sudo ${PYTHON_CMD} -m ensurepip --upgrade
    # sudo ${PYTHON_CMD} -m pip install -U pip
fi

colorEcho "${BLUE}Setting ${FUCHSIA}pip${BLUE}..."
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH=$PATH:$HOME/.local/bin
fi

## WARNING: Discarding xxx has inconsistent version: filename has 'x.y.z', but metadata has 'x.y.z'
## https://forum.manjaro.org/t/cant-install-anything-with-pip3/92890/11
# if version_lt "${PIP_CURRENT_VERSION}" "22.0.0"; then
#     sudo sed -i 's/self._regex.search(version)/self._regex.search(str(version))/' "/usr/lib/python3.10/site-packages/packaging/version.py"
#     sudo ${PYTHON_CMD} -m pip install -U pip --use-deprecated=legacy-resolver
# fi

# pip.conf
mkdir -p "$HOME/.pip"
PIP_CONFIG="$HOME/.pip/pip.conf"

# fix `pip list` warning
if ! grep -q "format=columns" "${PIP_CONFIG}" 2>/dev/null; then
    if ! grep -q "^\[global\]" "${PIP_CONFIG}" 2>/dev/null; then
        echo "[global]" >> "${PIP_CONFIG}"
    fi
    sed -i "/^\[global\]/a\format=columns" "${PIP_CONFIG}"
fi

## pip mirror
# pip config list
# alias pip="pip --proxy 127.0.0.1:8080"
# alias pipinstall='pip install -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com'
PIP_MIRROR_URL=https://mirrors.aliyun.com/pypi/simple/
PIP_MIRROR_HOST=mirrors.aliyun.com
if [[ "${THE_WORLD_BLOCKED}" == "true" ]] && ! grep -q "${PIP_MIRROR_HOST}" "${PIP_CONFIG}" 2>/dev/null; then
    if grep -q "index-url" "${PIP_CONFIG}" 2>/dev/null; then
        sed -i "s|index-url.*|index-url=${PIP_MIRROR_URL}|" "${PIP_CONFIG}"
    else
        sed -i "/^\[global\]/a\index-url=${PIP_MIRROR_URL}" "${PIP_CONFIG}"
    fi

    if grep -q "trusted-host" "${PIP_CONFIG}" 2>/dev/null; then
        sed -i "s|trusted-host.*|trusted-host=${PIP_MIRROR_HOST}|" "${PIP_CONFIG}"
    else
        if ! grep -q "\[install\]" "${PIP_CONFIG}" 2>/dev/null; then
            echo -e "\n[install]" | tee -a "${PIP_CONFIG}" >/dev/null
        fi
        sed -i "/^\[install\]/a\trusted-host=${PIP_MIRROR_HOST}" "${PIP_CONFIG}"
    fi
fi

cat "${PIP_CONFIG}"

: '
[global]
index-url=https://mirrors.aliyun.com/pypi/simple/
format=columns

[install]
trusted-host=mirrors.aliyun.com
# '


if [[ -x "$(command -v pip)" || -x "$(command -v pip3)" ]]; then
    # fix: ERROR: Could not install packages due to an OSError: Missing dependencies for SOCKS support.
    colorEcho "${BLUE}Installing ${FUCHSIA}pip package ${ORANGE}pysocks${BLUE}..."
    # noproxy_cmd ${PYTHON_CMD} -m pip install --user -U pysocks
    sudo ${PYTHON_CMD} -m pip install -U pysocks

    colorEcho "${BLUE}Installing ${FUCHSIA}pip package ${ORANGE}virtualenv${BLUE}..."
    sudo ${PYTHON_CMD} -m pip install -U virtualenv

    ## pipq: Yet another pip search
    # pipq search numpy
    # pipq pkg numpy
    # pipq versions numpy
    ## pip_search: Warping the needs of a "pip search" command necessity through PyPi.org
    # pip_search numpy
    PipPackages=(
        setuptools
        wheel
        pipx
        # pipq
        pip_search
    )
    for TargetPackage in "${PipPackages[@]}"; do
        colorEcho "${BLUE}Installing ${FUCHSIA}pip package ${ORANGE}${TargetPackage}${BLUE}..."
        ${PYTHON_CMD} -m pip install --user -U "${TargetPackage}"
    done

    # pipx - Install and Run Python Applications in Isolated Environments
    # https://github.com/pypa/pipx
    [[ -x "$(command -v pipx)" ]] && ${PYTHON_CMD} -m pipx ensurepath

    # noproxy_cmd pipx install litecli
    # noproxy_cmd pipx install pgclt
fi


# pip configurations for root user
if [[ ! -s "/root/.pip/pip.conf" ]]; then
    sudo mkdir -p "/root/.pip" && sudo cp -f "${PIP_CONFIG}" "/root/.pip"
fi

## Upgrade installed system packages
# noproxy_cmd sudo pip list -o | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 | sudo xargs --no-run-if-empty -n1 pip install -U
