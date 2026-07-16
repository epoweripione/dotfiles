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

# [Nub - The fast all-in-one Node.js toolkit](https://github.com/nubjs/nub)
INSTALLER_APP_NAME="Nub"
INSTALLER_GITHUB_REPO="nubjs/nub"
INSTALLER_BINARY_NAME="nub"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    curl -fsSL https://nubjs.com/install.sh | bash
fi

## [Node manager](https://nubjs.com/docs/node)
# nub node -h
# nub node install 26          # newest 26.x
# nub node install lts         # newest LTS line
# nub node install 20.11.0     # an exact version
# nub node install 20 22       # several at once
## installs whatever .node-version / .nvmrc / engines.node names
# nub node install

## A Bun-like DX on top of stock node, written in Rust.
# nub index.ts             # TypeScript-first Node.js runtime
# nub run dev              # 24× faster pnpm run
# nubx prisma generate     # 19× faster npx
# nub install              # 18× faster pnpm install
# nub watch src/server.ts  # native watch mode
# nub pm shim              # built-in Corepack-style shims
# nub node install 26      # Node version manager
# nub upgrade              # self update

# | Nub | Instead of |
# |---|---|
# | `nub <file>` | `node`, `tsx`, `ts-node`, `dotenv-cli` |
# | `nub run <script>` | `npm run`, `pnpm run` |
# | `nubx` | `npx`, `pnpm dlx / exec` |
# | `nub install` | `npm`, `pnpm` |
# | `nub watch` | `nodemon`, `node --watch`, `tsx watch` |
# | `nub node` | `nvm`, `fnm`, `n`, `volta` |
# | `nub pm` | `corepack` |
