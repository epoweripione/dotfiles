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

# oh-my-posh: A prompt theme engine for any shell
# https://github.com/JanDeDobbeleer/oh-my-posh
INSTALLER_APP_NAME="oh-my-posh"
INSTALLER_GITHUB_REPO="JanDeDobbeleer/oh-my-posh"

INSTALLER_INSTALL_PATH="/usr/local/bin"
INSTALLER_INSTALL_NAME="oh-my-posh"

INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_INSTALL_NAME}"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>/dev/null | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_ARCH}" in
                arm | arm64)
                    INSTALLER_FILE_NAME="posh-${OS_INFO_TYPE}-arm"
                    ;;
                *)
                    INSTALLER_FILE_NAME="posh-${OS_INFO_TYPE}-${OS_INFO_ARCH}"
                    ;;
            esac
            ;;
        darwin)
            INSTALLER_FILE_NAME="posh-${OS_INFO_TYPE}-${OS_INFO_ARCH}"
            ;;
        windows)
            INSTALLER_FILE_NAME="posh-${OS_INFO_TYPE}-${OS_INFO_ARCH}.exe"
            ;;
    esac

    [[ -z "${INSTALLER_FILE_NAME}" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        INSTALLER_DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo mv -f "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
            sudo chmod +x "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}"
    fi

    # themes
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}themes${BLUE}..."
    mkdir -p "$HOME/.poshthemes"

    [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/powershell/themes/powerlevel10k_my.omp.json" ]] && \
        cp -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/powershell/themes/powerlevel10k_my.omp.json" "$HOME/.poshthemes"

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/themes.zip"
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/themes.zip"
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        INSTALLER_DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        unzip -qo "${INSTALLER_DOWNLOAD_FILE}" -d "$HOME/.poshthemes" && \
            chmod u+rw "$HOME"/.poshthemes/*.json
    fi

    ## config
    # bash
    if ! grep -q "oh-my-posh --init" "$HOME/.bashrc" 2>/dev/null; then
        {
            echo ''
            echo '# eval "$(oh-my-posh --init --shell bash --config ~/.poshthemes/powerlevel10k_rainbow.omp.json)"'
            echo 'eval "$(oh-my-posh --init --shell bash --config ~/.poshthemes/powerlevel10k_my.omp.json)"'
        } >> "$HOME/.bashrc"
    fi

    # zsh
    if ! grep -q "oh-my-posh --init" "$HOME/.zshrc" 2>/dev/null; then
        {
            echo ''
            echo '# eval "$(oh-my-posh --init --shell zsh --config ~/.poshthemes/powerlevel10k_rainbow.omp.json)"'
            echo 'eval "$(oh-my-posh --init --shell zsh --config ~/.poshthemes/powerlevel10k_my.omp.json)"'
        } >> "$HOME/.zshrc"
    fi
fi

## Preview the themes
# for file in ~/.poshthemes/*.omp.json; do echo "$file\n"; oh-my-posh --config $file --shell universal; echo "\n"; done;

## nushell
# config set prompt "(oh-my-posh --config ~/.poshthemes/powerlevel10k_rainbow.omp.json | str collect)"

## powershell
# oh-my-posh --init --shell pwsh --config /.poshthemes/powerlevel10k_rainbow.omp.json | Invoke-Expression
