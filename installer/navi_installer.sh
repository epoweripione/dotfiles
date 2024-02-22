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

# navi: An interactive cheatsheet tool for the command-line
# https://github.com/denisidoro/navi
INSTALLER_APP_NAME="navi"
INSTALLER_GITHUB_REPO="denisidoro/navi"

INSTALLER_ARCHIVE_EXT="tar.gz"

INSTALLER_INSTALL_NAME="navi"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

# new install
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && "${INSTALLER_IS_UPDATE}" == "no" && -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
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
    if [[ ! -x "$(command -v tldr)" ]]; then
        AppInstaller="${MY_SHELL_SCRIPTS}/installer/tealdeer_installer.sh"
        [[ -s "${AppInstaller}" ]] && source "${AppInstaller}"
    fi

    # use cheatsheets from cheat.sh: https://github.com/chubin/cheat.sh
    # navi --cheatsh <query>
    if [[ ! -x "$(command -v cht.sh)" ]]; then
        [[ ! -x "$(command -v rlwrap)" ]] && PackagesList=(rlwrap) && InstallSystemPackages "" "${PackagesList[@]}"

        colorEcho "${BLUE}  Installing ${FUCHSIA}cheat.sh${BLUE}..."
        curl "${CURL_DOWNLOAD_OPTS[@]}" "https://cht.sh/:cht.sh" | sudo tee "/usr/local/bin/cht.sh" >/dev/null && \
            sudo chmod +x "/usr/local/bin/cht.sh"

        curl "${CURL_DOWNLOAD_OPTS[@]}" "https://cheat.sh/:zsh" | sudo tee "/usr/local/share/zsh/site-functions/_cht" >/dev/null
    fi
fi


cd "${CURRENT_DIR}" || exit