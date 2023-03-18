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

App_Installer_Reset

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
INSTALLER_APP_NAME="safe-rm"
INSTALLER_GITHUB_REPO="epoweripione/safe-rm"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_DIR="safe-rm-*"

INSTALLER_INSTALL_NAME="safe-rm"

INSTALLER_VER_FILE="${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}.version"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    [[ -s "${INSTALLER_VER_FILE}" ]] && INSTALLER_VER_CURRENT=$(head -n1 "${INSTALLER_VER_FILE}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if App_Installer_Install; then
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
else
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi


## srm: Safe Remove (rm) command with cache/undo
## This is a rm command imitation, but without actually removing anything, only moving it into cache (~/.cache/srm)
## https://github.com/WestleyR/srm


# install_shell-safe-rm


cd "${CURRENT_DIR}" || exit