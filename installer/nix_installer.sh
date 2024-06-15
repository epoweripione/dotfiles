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

# [Nix, the purely functional package manager](https://nix.dev/)
INSTALLER_APP_NAME="nix"
INSTALLER_GITHUB_REPO="NixOS/nix"

INSTALLER_INSTALL_NAME="nix"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_UPDATE}" == "yes" ]]; then
    # nix-shell -p nix -I nixpkgs=channel:nixpkgs-unstable --run "nix --version"
    nix upgrade-nix
elif [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
fi

# [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]] && setMirrorNix

## Using Nix within Docker
# docker run -ti ghcr.io/nixos/nix

## [direnv – unclutter your .profile](https://direnv.net/)
# if [[ ! -x "$(command -v direnv)" ]]; then
#     [[ -x "$(command -v nix-env)" ]] && nix-env -iA nixpkgs.direnv
# fi

# [Search for packages](https://search.nixos.org/packages)

## nix-env
# nix-env --install nixpkgs.direnv
# nix-env --uninstall direnv
# nix-env --query --installed --json
# nix-env --upgrade '*'

## Create a shell environment
# nix-shell -p cowsay lolcat

## Running programs once
# nix-shell -p cowsay --run "cowsay Nix"

## Run any combination of programs
# nix-shell -p git neovim nodejs

## Nested shell sessions
# nix-shell -p python3

## Towards reproducibility
# nix-shell -p git --run "git --version" --pure -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/2a601aafdc5605a5133a2ca506a34a3a73377247.tar.gz

## Uninstall
# sudo rm -rf "/etc/nix" "/nix" "/root/.nix-profile" "/root/.nix-defexpr" "/root/.nix-channels" "/root/.local/state/nix" "/root/.cache/nix" \
#     "$HOME/.nix-profile" "$HOME/.nix-defexpr" "$HOME/.nix-channels" "$HOME/.local/state/nix" "$HOME/.cache/nix"

cd "${CURRENT_DIR}" || exit
