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

# navi: An interactive cheatsheet tool for the command-line
# https://github.com/denisidoro/navi
APP_INSTALL_NAME="navi"
GITHUB_REPO_NAME="denisidoro/navi"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_DIR=""
ARCHIVE_EXEC_NAME="navi"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="navi"

[[ -z "${ARCHIVE_EXEC_NAME}" ]] && ARCHIVE_EXEC_NAME="${EXEC_INSTALL_NAME}"

DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"
[[ -n "${ARCHIVE_EXT}" ]] && DOWNLOAD_FILENAME="${DOWNLOAD_FILENAME}.${ARCHIVE_EXT}"

REMOTE_SUFFIX=""
REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"
VERSION_FILENAME=""

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
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
    [[ -z "${OS_INFO_FLOAT}" ]] && get_arch_float

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_ARCH}" in
                arm64)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-v${REMOTE_VERSION}-aarch64-${OS_INFO_TYPE}-android.${ARCHIVE_EXT}
                    ;;
                arm)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-v${REMOTE_VERSION}-armv7-unknown-${OS_INFO_TYPE}-musleabihf.${ARCHIVE_EXT}
                    ;;
                *)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-v${REMOTE_VERSION}-x86_64-unknown-${OS_INFO_TYPE}-musl.${ARCHIVE_EXT}
                    ;;
            esac
            ;;
        darwin)
            case "${OS_INFO_ARCH}" in
                arm64)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-v${REMOTE_VERSION}-aarch64-apple-ios.${ARCHIVE_EXT}
                    ;;
                *)
                    REMOTE_FILENAME=${APP_INSTALL_NAME}-v${REMOTE_VERSION}-x86_64-apple-${OS_INFO_TYPE}.${ARCHIVE_EXT}
                    ;;
            esac
            ;;
        windows)
            ARCHIVE_EXT="zip"
            REMOTE_FILENAME=${APP_INSTALL_NAME}-v${REMOTE_VERSION}-x86_64-pc-${OS_INFO_TYPE}-gnu.${ARCHIVE_EXT}
            ;;
    esac

    [[ -z "${REMOTE_FILENAME}" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    # Git_Clone_Update_Branch "denisidoro/navi" "/opt/navi"
    # if [[ ! -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    #     cd /opt/navi && sudo make BIN_DIR=/usr/local/bin install
    # elif [[ -d "/opt/navi" ]]; then
    #     cd /opt/navi && sudo make update
    # fi

    # DOWNLOAD_FILENAME="${WORKDIR}/navi-install.sh"
    # DOWNLOAD_URL="https://raw.githubusercontent.com/${GITHUB_REPO_NAME}/master/scripts/install"
    # curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" && \
    #     sudo BIN_DIR=/usr/local/bin bash "${DOWNLOAD_FILENAME}"

    # Download file
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
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
                [[ -n "${VERSION_FILENAME}" ]] && echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true
        fi
    fi
fi

# new install
if [[ "${IS_INSTALL}" == "yes" && "${IS_UPDATE}" == "no" && -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    ## shell widget
    # bash
    if ! grep -q "navi widget bash" "$HOME/.bashrc" 2>/dev/null; then
        echo '' >> "$HOME/.bashrc"
        echo 'eval "$(navi widget bash)"' >> "$HOME/.bashrc"
    fi

    # zsh
    if ! grep -q "navi widget zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo '' >> "$HOME/.zshrc"
        echo 'eval "$(navi widget zsh)"' >> "$HOME/.zshrc"
    fi

    # Importing featured cheatsheets
    # https://github.com/denisidoro/cheats/blob/master/featured_repos.txt
    featured_repos=(
        "denisidoro/cheats"
        "denisidoro/navi-tldr-pages"
        "denisidoro/dotfiles"
        "mrVanDalo/navi-cheats"
        "chazeon/my-navi-cheats"
        "caojianhua/MyCheat"
        "Kidman1670/cheats"
        "isene/cheats"
        "m42martin/navi-cheats"
    )

    for Target in "${featured_repos[@]}"; do
        user=$(echo "${Target}" | cut -d'/' -f1)
        repo=$(echo "${Target}" | cut -d'/' -f2)
        Git_Clone_Update_Branch "${Target}" "$(navi info cheats-path)/${user}__${repo}"
        # navi repo add "${Target}"
    done

    # use cheatsheets from tldr: https://github.com/tldr-pages/tldr
    # navi --tldr <query>
    # tealdeer: A very fast implementation of tldr in Rust
    # https://github.com/dbrgn/tealdeer
    AppInstaller="${MY_SHELL_SCRIPTS}/installer/tealdeer_installer.sh"
    [[ -s "${AppInstaller}" ]] && source "${AppInstaller}"

    # use cheatsheets from cheat.sh: https://github.com/chubin/cheat.sh
    # navi --cheatsh <query>
    if [[ ! -x "$(command -v cht.sh)" ]]; then
        if checkPackageNeedInstall "rlwrap"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}rlwrap${BLUE}..."
            sudo pacman --noconfirm -S "rlwrap"
        fi

        colorEcho "${BLUE}  Installing ${FUCHSIA}cheat.sh${BLUE}..."
        curl "${CURL_DOWNLOAD_OPTS[@]}" "https://cht.sh/:cht.sh" | sudo tee "/usr/local/bin/cht.sh" >/dev/null && \
            sudo chmod +x "/usr/local/bin/cht.sh"

        curl "${CURL_DOWNLOAD_OPTS[@]}" "https://cheat.sh/:zsh" | sudo tee "/usr/local/share/zsh/site-functions/_cht" >/dev/null
    fi
fi


cd "${CURRENT_DIR}" || exit