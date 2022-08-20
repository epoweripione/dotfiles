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


## shell-safe-rm
## https://github.com/kaelzhang/shell-safe-rm
## rm_is_safe
## https://github.com/malongshuai/rm_is_safe
function install_shell-safe-rm() {
    SHELL_SAFE_RM="$HOME/.shell-safe-rm"
    [[ ! -s "${SHELL_SAFE_RM}/bin/rm.sh" ]] && Git_Clone_Update_Branch "kaelzhang/shell-safe-rm" "${SHELL_SAFE_RM}"

    if [[ -s "${SHELL_SAFE_RM}/bin/rm.sh" ]]; then
        sudo /bin/cp -f "${SHELL_SAFE_RM}/bin/rm.sh" "/bin/rm.sh" && sudo chmod +x "/bin/rm.sh"
        # alias rm='/bin/rm.sh'
    fi

    if [[ -s "/bin/rm.sh" ]]; then
        # bash
        # BASH_ENV
        # https://stackoverflow.com/a/20713296
        BASHENV_FILE="/etc/bashenv"
        if ! grep -q 'shopt -s expand_aliases extglob xpg_echo' "${BASHENV_FILE}" >/dev/null 2>&1; then
            echo -e '\n# == Setup for all shells ==' | sudo tee -a "${BASHENV_FILE}" >/dev/null
            echo '# This is executed for all interactive and for non-interactive shells (e.g. scripts)' | sudo tee -a "${BASHENV_FILE}" >/dev/null
            echo 'shopt -s expand_aliases extglob xpg_echo' | sudo tee -a "${BASHENV_FILE}" >/dev/null
            echo -e '\n# == General aliases ==' | sudo tee -a "${BASHENV_FILE}" >/dev/null
            echo "[[ -s \"/bin/rm.sh\" ]] && alias rm='/bin/rm.sh'" | sudo tee -a "${BASHENV_FILE}" >/dev/null
        fi

        BASHENV_SH_FILE="/etc/profile"
        if ! grep -q 'export BASH_ENV' "${BASHENV_SH_FILE}" >/dev/null 2>&1; then
            echo -e '\n# == Environment for all shells ==' | sudo tee -a "${BASHENV_SH_FILE}" >/dev/null
            echo "[[ -s \"${BASHENV_FILE}\" ]] && export BASH_ENV=${BASHENV_FILE} && . \$BASH_ENV" | sudo tee -a "${BASHENV_SH_FILE}" >/dev/null
        fi

        # zsh
        [[ -d "/etc/zsh" ]] && ZSHENV_FILE="/etc/zsh/zshenv" || ZSHENV_FILE="/etc/zshenv"
        if [[ -s "${ZSHENV_FILE}" ]]; then
            if ! grep -q '/bin/rm.sh' "${ZSHENV_FILE}" >/dev/null 2>&1; then
                echo -e '\n# shell-safe-rm' | sudo tee -a "${ZSHENV_FILE}" >/dev/null
                echo "[[ -s \"/bin/rm.sh\" ]] && alias rm='/bin/rm.sh'" | sudo tee -a "${ZSHENV_FILE}" >/dev/null

                echo -e '\n# BASH_ENV' | sudo tee -a "${ZSHENV_FILE}" >/dev/null
                echo "[[ -s \"${BASHENV_FILE}\" ]] && export BASH_ENV=${BASHENV_FILE}" | sudo tee -a "${ZSHENV_FILE}" >/dev/null
            fi
        fi
    fi
}

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

## Safe-rm
## https://launchpad.net/safe-rm
## /etc/safe-rm.conf
## /usr/local/etc/safe-rm.conf
## ~/.config/safe-rm
# Git_Clone_Update_Branch "safe-rm" "$HOME/safe-rm" "git://git.launchpad.net/safe-rm"

## fork: https://github.com/epoweripione/safe-rm
## config & enviroment variable support for real `rm` binary
## /etc/safe-rm.toml
## SAFE_RM_REAL_RM_BINARY
APP_INSTALL_NAME="safe-rm"
GITHUB_REPO_NAME="epoweripione/safe-rm"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_DIR="safe-rm-*"
ARCHIVE_EXEC_NAME="safe-rm"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="safe-rm"

[[ -z "${ARCHIVE_EXEC_NAME}" ]] && ARCHIVE_EXEC_NAME="${EXEC_INSTALL_NAME}"

DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"
[[ -n "${ARCHIVE_EXT}" ]] && DOWNLOAD_FILENAME="${DOWNLOAD_FILENAME}.${ARCHIVE_EXT}"

REMOTE_SUFFIX=""
REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"
VERSION_FILENAME="${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}.version"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    [[ -s "${VERSION_FILENAME}" ]] && CURRENT_VERSION=$(head -n1 "${VERSION_FILENAME}")
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
            REMOTE_FILENAME="${EXEC_INSTALL_NAME}-${REMOTE_VERSION}.${ARCHIVE_EXT}"
            ;;
    esac

    [[ -z "${REMOTE_FILENAME}" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    # Download file
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        # Extract file
        case "${ARCHIVE_EXT}" in
            "zip")
                unzip -qo "${DOWNLOAD_FILENAME}" -d "${WORKDIR}"
                ;;
            "tar.bz2")
                tar -xjf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
                ;;
            "tar.gz")
                tar -xzf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
                ;;
            "tar.xz")
                tar -xJf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
                ;;
            "gz")
                cd "${WORKDIR}" && gzip -df "${DOWNLOAD_FILENAME}"
                ;;
            "bz")
                cd "${WORKDIR}" && bzip2 -df "${DOWNLOAD_FILENAME}"
                ;;
            "7z")
                7z e "${DOWNLOAD_FILENAME}" -o"${WORKDIR}"
                ;;
        esac

        # Install
        [[ -n "${ARCHIVE_EXEC_DIR}" ]] && ARCHIVE_EXEC_DIR=$(find "${WORKDIR}" -type d -name "${ARCHIVE_EXEC_DIR}")
        [[ -z "${ARCHIVE_EXEC_DIR}" || ! -d "${ARCHIVE_EXEC_DIR}" ]] && ARCHIVE_EXEC_DIR=${WORKDIR}

        if [[ -s "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" ]]; then
            sudo cp -f "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                sudo cp -f "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}.1" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}.1"
                [[ -n "${VERSION_FILENAME}" ]] && echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true
        fi
    fi

    # Move the native `rm` command to `/bin/rm.real` then replace the native `rm` with `safe-rm`
    if [[ -x "$(command -v safe-rm)" ]]; then
        if [[ ! -f "/bin/rm.real" ]]; then
            file "/bin/rm" | grep -q ELF && sudo /bin/mv -f "/bin/rm" "/bin/rm.real"
        fi

        if [[ -f "/bin/rm.real" ]]; then
            if ! grep -q 'rm_binary = ' "/etc/safe-rm.toml" >/dev/null 2>&1; then
                echo 'rm_binary = "/bin/rm.real"' | sudo tee -a "/etc/safe-rm.toml" >/dev/null
            fi
        fi

        sudo /bin/cp -f "/usr/local/bin/safe-rm" "/bin/rm"
    fi
fi


## srm: Safe Remove (rm) command with cache/undo
## This is a rm command imitation, but without actually removing anything, only moving it into cache (~/.cache/srm)
## https://github.com/WestleyR/srm


# install_shell-safe-rm


cd "${CURRENT_DIR}" || exit