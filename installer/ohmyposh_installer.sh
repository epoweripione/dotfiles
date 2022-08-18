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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# oh-my-posh: A prompt theme engine for any shell
# https://github.com/JanDeDobbeleer/oh-my-posh
APP_INSTALL_NAME="oh-my-posh"
GITHUB_REPO_NAME="JanDeDobbeleer/oh-my-posh"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="oh-my-posh"

DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"

REMOTE_SUFFIX=""
REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} --version 2>/dev/null | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_ARCH}" in
                arm | arm64)
                    REMOTE_FILENAME="posh-${OS_INFO_TYPE}-arm"
                    ;;
                *)
                    REMOTE_FILENAME="posh-${OS_INFO_TYPE}-${OS_INFO_ARCH}"
                    ;;
            esac
            ;;
        darwin)
            REMOTE_FILENAME="posh-${OS_INFO_TYPE}-${OS_INFO_ARCH}"
            ;;
        windows)
            REMOTE_FILENAME="posh-${OS_INFO_TYPE}-${OS_INFO_ARCH}.exe"
            ;;
    esac

    [[ -z "${REMOTE_FILENAME}" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -N -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo mv -f "${DOWNLOAD_FILENAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
            sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}"
    fi

    # themes
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}themes${BLUE}..."
    mkdir -p "$HOME/.poshthemes"
    DOWNLOAD_FILENAME="${WORKDIR}/themes.zip"
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/v${REMOTE_VERSION}/themes.zip"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -N -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        unzip -qo "${DOWNLOAD_FILENAME}" -d "$HOME/.poshthemes" && \
            chmod u+rw "$HOME"/.poshthemes/*.json
    fi

    ## config
    # bash
    if ! grep -q "oh-my-posh --init" "$HOME/.bashrc" 2>/dev/null; then
        {
            echo ''
            echo 'eval "$(oh-my-posh --init --shell bash --config ~/.poshthemes/powerlevel10k_rainbow.omp.json)"'
        } >> "$HOME/.bashrc"
    fi

    # zsh
    if ! grep -q "oh-my-posh --init" "$HOME/.zshrc" 2>/dev/null; then
        {
            echo ''
            echo 'eval "$(oh-my-posh --init --shell zsh --config ~/.poshthemes/powerlevel10k_rainbow.omp.json)"'
        } >> "$HOME/.zshrc"
    fi
fi

## Preview the themes
# for file in ~/.poshthemes/*.omp.json; do echo "$file\n"; oh-my-posh --config $file --shell universal; echo "\n"; done;

## nushell
# config set prompt "(oh-my-posh --config ~/.poshthemes/powerlevel10k_rainbow.omp.json | str collect)"

## powershell
# oh-my-posh --init --shell pwsh --config /.poshthemes/powerlevel10k_rainbow.omp.json | Invoke-Expression
