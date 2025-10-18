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

# [Pixi: Package Management Made Easy](https://pixi.sh/)
curl -fsSL https://pixi.sh/install.sh | sh

if [[ "$(command -v pixi)" ]]; then
    # Autocompletion
    if ! grep -q 'pixi completion' "$HOME/.bashrc" >/dev/null 2>&1; then
        sed -i '/\/.pixi\/bin/d' "$HOME/.bashrc"
        (echo -e '\n# Pixi'; echo 'export PATH="$HOME/.pixi/bin:$PATH"'; echo 'eval "$(pixi completion --shell bash)"') >> "$HOME/.bashrc"
    fi

    if ! grep -q 'pixi completion' "$HOME/.zshrc" >/dev/null 2>&1; then
        sed -i '/\/.pixi\/bin/d' "$HOME/.zshrc"
        (echo -e '\n# Pixi'; echo 'export PATH="$HOME/.pixi/bin:$PATH"'; echo 'eval "$(pixi completion --shell zsh)"') >> "$HOME/.zshrc"
    fi

    ## [Configuration](https://pixi.sh/latest/reference/pixi_configuration/)
    ## $HOME/.pixi/config.toml
    # pixi info -vvv

    ## Configurations
    # pixi config list

    ## [Public Channels](https://prefix.dev/channels)
    # pixi config set default-channels '["conda-forge", "bioconda"]'
    # pixi config set --global mirrors '{"https://conda.anaconda.org/conda-forge": ["https://prefix.dev/conda-forge"]}'

    ## Other configurations
    # pixi config set repodata-config.disable-zstd true --system
    # pixi config set --global detached-environments "/opt/pixi/envs"
    # pixi config set detached-environments false
    # pixi config set s3-options.my-bucket '{"endpoint-url": "http://localhost:9000", "force-path-style": true, "region": "auto"}'
fi
