#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

# Conventional Commits
# https://www.conventionalcommits.org/en/about/
# Commitizen - The commitizen command line utility
# https://github.com/commitizen/cz-cli
# husky - Modern native Git hooks made easy
# https://github.com/typicode/husky
# commitlint - Lint commit messages
# https://github.com/conventional-changelog/commitlint
APP_INSTALL_NAME="commitizen"
GITHUB_REPO_NAME="commitizen/cz-cli"

EXEC_INSTALL_NAME="cz"

IS_INSTALL="yes"
IS_UPDATE="no"

if [[ ! -d "${CURRENT_DIR}/.git" ]]; then
    IS_INSTALL="no"
    colorEcho "${FUCHSIA}${CURRENT_DIR}${RED} not a valid git repository!"
else
    colorEchoN "${ORANGE}Install and run ${FUCHSIA}Commitizen ${ORANGE}in ${FUCHSIA}${CURRENT_DIR}${ORANGE}?[y/${CYAN}N${ORANGE}]: "
    read -r CHOICE
    [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]] && IS_INSTALL="yes" || IS_INSTALL="no"
fi

# Install nodejs
if [[ "${IS_INSTALL}" == "yes" ]]; then
    if [[ ! -x "$(command -v node)" && "$(command -v asdf)" ]]; then
        asdf_App_Install nodejs lts
    fi

    if [[ -x "$(command -v node)" && -x "$(command -v npm)" && ! -d "$HOME/.npm-global" ]]; then
        [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh" ]] && \
            source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nodejs/npm_config.sh"
    fi

    # jq
    if [[ ! -x "$(command -v jq)" ]]; then
        if checkPackageNeedInstall "jq"; then
            colorEcho "${BLUE}Installing ${FUCHSIA}jq${BLUE}..."
            sudo pacman --noconfirm -S jq
        fi
    fi
fi

# Install packages If there is a package.json file in the directory
if [[ "${IS_INSTALL}" == "yes" && -x "$(command -v npm)" && -s "${CURRENT_DIR}/package.json" ]]; then
    npm install
    IS_INSTALL="no"
fi

# Install and run Commitizen locally
if [[ "${IS_INSTALL}" == "yes" && -x "$(command -v npx)" ]]; then
    # commitizen
    npx commitizen init cz-conventional-changelog --save-dev --save-exact && \
        ./node_modules/.bin/commitizen init cz-conventional-changelog --save-dev --save-exact

    ## husky commitlint
    # npm install husky @commitlint/config-conventional @commitlint/cli --save-dev && \
    #     npx husky install && \
    #     npm set-script prepare "husky install" && \
    #     npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"' && \
    #     npm set-script prepare-commit-msg "exec < /dev/tty && git cz --hook || true"

    # cz-emoji: Commitizen adapter formatting commit messages using emojis
    # https://github.com/ngryman/cz-emoji
    npm install conventional-changelog-cli cz-emoji commitlint commitlint-config-gitmoji --save-dev

    cat "${CURRENT_DIR}/package.json" \
        | jq -r '."config"."commitizen"."path"="cz-emoji"' \
        | jq -r '."config"."cz-emoji"."symbol"=true' \
        | jq -r '."config"."cz-emoji"."conventional"=true' \
        | tee "${CURRENT_DIR}/package.json" >/dev/null

    tee "${CURRENT_DIR}/commitlint.config.js" >/dev/null <<-'EOF'
module.exports = {
  extends: ['gitmoji'],
  parserPreset: {
    parserOpts: {
      headerPattern: /^(:\w*:)(?:\s)(?:\((.*?)\))?\s((?:.*(?=\())|.*)(?:\(#(\d*)\))?/,
      headerCorrespondence: ['type', 'scope', 'subject', 'ticket']
    }
  }
}
EOF

    if ! grep -q "node_modules/" "${CURRENT_DIR}/.gitignore" 2>/dev/null; then
        echo "node_modules/" >> "${CURRENT_DIR}/.gitignore"
    fi

    # if ! grep -q "package-lock.json" "${CURRENT_DIR}/.gitignore" 2>/dev/null; then
    #     echo "package-lock.json" >> "${CURRENT_DIR}/.gitignore"
    # fi

    if [[ ! -s "${CURRENT_DIR}/.git/hooks/prepare-commit-msg" ]]; then
        echo '#!/bin/bash' >> "${CURRENT_DIR}/.git/hooks/prepare-commit-msg"
        echo 'exec < /dev/tty && node_modules/.bin/cz --hook || true' >> "${CURRENT_DIR}/.git/hooks/prepare-commit-msg"
        chmod +x "${CURRENT_DIR}/.git/hooks/prepare-commit-msg"
    fi

    # gitmoji-cli
    # https://github.com/carloscuesta/gitmoji-cli
    [[ ! -x "$(command -v gitmoji)" ]] && npm install -g gitmoji-cli
    [[ -x "$(command -v gitmoji)" ]] && noproxy_cmd gitmoji --list

    # 🤖 🚀 ✨ Emojify your conventional commits with Devmoji
    # https://github.com/folke/devmoji
    [[ ! -x "$(command -v devmoji)" ]] && npm install -g devmoji
    [[ -x "$(command -v devmoji)" ]] && devmoji --list
    # echo "This is a :test: of the first :release: :boom: :sparkles:" | devmoji --format unicode
    # echo "🚀 :boom: :sparkles:" | devmoji --format devmoji
    # glol | devmoji --format unicode
fi

## Generate a CHANGELOG from git metadata
# ./node_modules/.bin/conventional-changelog -p angular -i CHANGELOG.md -s
