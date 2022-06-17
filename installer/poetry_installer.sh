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

# Poetry: Dependency Management for Python
# https://python-poetry.org/
APP_INSTALL_NAME="poetry"
GITHUB_REPO_NAME="python-poetry/poetry"

EXEC_INSTALL_NAME="poetry"

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

[[ ! -x "$(command -v cargo)" && ! -x "$(command -v brew)" ]] && IS_INSTALL="no"

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    if [[ -x "$(command -v poetry)" ]]; then
        poetry self update
    else
        if [[ -x "$(command -v python)" ]]; then
            curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
        elif [[ -x "$(command -v python3)" ]]; then
            curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -
        fi
    fi
fi

if [[ "${IS_INSTALL}" == "yes" && -x "$(command -v poetry)" ]]; then
    export PATH=$PATH:$HOME/.poetry/bin
    mkdir -p "$ZSH_CUSTOM/plugins/poetry" && \
        poetry completions zsh > "$ZSH_CUSTOM/plugins/poetry/_poetry"
fi

# poetry config --list

## pip mirror
# tee -a "$PWD/pyproject.toml" <<-'EOF'
# [[tool.poetry.source]]
# name = "aliyun"
# url = "https://mirrors.aliyun.com/pypi/simple/"
# default = true
# EOF

## windows powershell
# (Invoke-WebRequest -Uri https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py -UseBasicParsing).Content | python -
