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

# Conventional Commits
# https://www.conventionalcommits.org/en/about/
# Commitizen - The commitizen command line utility
# https://github.com/commitizen/cz-cli
# husky - Modern native Git hooks made easy
# https://github.com/typicode/husky
# commitlint - Lint commit messages
# https://github.com/conventional-changelog/commitlint
INSTALLER_APP_NAME="commitizen"
INSTALLER_GITHUB_REPO="commitizen/cz-cli"

INSTALLER_INSTALL_NAME="cz"

if [[ ! -d "${CURRENT_DIR}/.git" ]]; then
    INSTALLER_IS_INSTALL="no"
    colorEcho "${FUCHSIA}${CURRENT_DIR}${RED} not a valid git repository!"
else
    colorEchoN "${ORANGE}Install and run ${FUCHSIA}Commitizen ${ORANGE}in ${FUCHSIA}${CURRENT_DIR}${ORANGE}?[y/${CYAN}N${ORANGE}]: "
    read -r CHOICE
    [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]] && INSTALLER_IS_INSTALL="yes" || INSTALLER_IS_INSTALL="no"
fi

# Install nodejs
if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    install_Nodejs

    # jq
    [[ ! -x "$(command -v jq)" ]] && PackagesList=(jq) && InstallSystemPackages "" "${PackagesList[@]}"
fi

[[ -z "${NPM_INSTALL_CMD}" ]] && get_npm_package_install_command
[[ -z "${NPM_INSTALL_CMD}" ]] && colorEcho "${FUCHSIA}npm${RED} not found! Please install ${FUCHSIA}npm${RED} first." && exit 1

# Install packages If there is a package.json file in the directory
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && -s "${CURRENT_DIR}/package.json" ]]; then
    ${NPM_INSTALL_CMD}
    INSTALLER_IS_INSTALL="no"
fi

# Install and run Commitizen locally
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && -x "$(command -v npx)" ]]; then
    # commitizen
    ${NPM_INSTALL_CMD} commitizen conventional-changelog-cli conventional-changelog-cz-emoji-config --save-dev && \
        npx commitizen init cz-conventional-changelog --save-dev --save-exact

    # husky & commitlint
    ${NPM_INSTALL_CMD} husky @commitlint/config-conventional @commitlint/cli --save-dev

    # cz-emoji: Commitizen adapter formatting commit messages using emojis
    # https://github.com/ngryman/cz-emoji
    ${NPM_INSTALL_CMD} cz-emoji commitlint-config-gitmoji --save-dev

    # [cz-git | czg 🛠️ DX first and more engineered, lightweight, customizable, standard output format Commitizen adapter and CLI](https://github.com/Zhengqbbb/cz-git)
    ${NPM_INSTALL_CMD} cz-git czg --save-dev
fi

# husky hooks
if [[ -s "${CURRENT_DIR}/node_modules/.bin/husky" ]]; then
    npx husky install && \
        ${NPM_INSTALL_CMD} set-script prepare "husky && chmod ug+x .husky/*"
fi

if [[ ! -s "${CURRENT_DIR}/.husky/commit-msg" ]]; then
    echo 'npx --no -- commitlint --edit ""' > "${CURRENT_DIR}/.husky/commit-msg"
fi
chmod +x "${CURRENT_DIR}/.husky/commit-msg"

if [[ ! -s "${CURRENT_DIR}/.husky/prepare-commit-msg" ]]; then
    echo 'exec < /dev/tty && npx czg --hook || true' > "${CURRENT_DIR}/.husky/prepare-commit-msg"
fi
chmod +x "${CURRENT_DIR}/.husky/prepare-commit-msg"

# cz-emoji configuration
if [[ ! -s "${CURRENT_DIR}/package.json" ]]; then
    cat "${CURRENT_DIR}/package.json" \
        | jq -r '."config"."commitizen"."path"="cz-emoji"' \
        | jq -r '."config"."cz-emoji"."symbol"=true' \
        | jq -r '."config"."cz-emoji"."conventional"=true' \
        | tee "${CURRENT_DIR}/package.json" >/dev/null

    # commit types
    # cat "${CURRENT_DIR}/package.json" \
    #     | jq -r '."config"."cz-emoji"."types"=."config"."cz-emoji"."types" + [{"emoji": "✨","code": ":sparkles:","description": "Introducing new features.","name": "feat"}]' \
    #     | jq -r '."config"."cz-emoji"."types"=."config"."cz-emoji"."types" + [{"emoji": "🌀","code": ":cyclone:","description": "Refactoring code.","name": "refactor"}]' \
    #     | tee "${CURRENT_DIR}/package.json" >/dev/null
fi

# commit types
# https://gitmoji.dev/api/gitmojis
if [[ ! -s "${CURRENT_DIR}/cz-emoji-types.json" ]]; then
    curl "${CURL_CHECK_OPTS[@]}" -o "${CURRENT_DIR}/cz-emoji-types.json" \
        "https://raw.githubusercontent.com/epoweripione/dotfiles/main/cz-emoji-types.json"

    ## How to merge every two lines into one from the command line?
    ## https://stackoverflow.com/questions/9605232/how-to-merge-every-two-lines-into-one-from-the-command-line
    # jq -r '."config"."cz-emoji"."types"[] | .name, .emoji' cz-emoji-types.json \
    #     | xargs -n2 -d'\n' \
    #     | sed -e "s/^/'/" -e "s/$/',/" -e "s/ /': '/"
fi

if [[ -s "${CURRENT_DIR}/cz-emoji-types.json" ]]; then
    CZ_EMOJI_TYPES=$(jq -r '."config"."cz-emoji"."types"' "${CURRENT_DIR}/cz-emoji-types.json")
    cat "${CURRENT_DIR}/package.json" \
        | jq -r ".\"config\".\"cz-emoji\".\"types\"=${CZ_EMOJI_TYPES}" \
        | tee "${CURRENT_DIR}/package.json" >/dev/null
fi

# commitlint configuration
# headerPattern: /^(:\w*:)(?:\s)(?:\((.*?)\))?\s((?:.*(?=\())|.*)(?:\(#(\d*)\))?/,
if [[ ! -s "${CURRENT_DIR}/commitlint.config.js" ]]; then
    curl "${CURL_CHECK_OPTS[@]}" -o "${CURRENT_DIR}/commitlint.config.js" \
        "https://raw.githubusercontent.com/epoweripione/dotfiles/main/commitlint.config.js"
fi

# git ignore
if ! grep -q "node_modules/" "${CURRENT_DIR}/.gitignore" 2>/dev/null; then
    echo "node_modules/" >> "${CURRENT_DIR}/.gitignore"
fi

# if ! grep -q "package-lock.json" "${CURRENT_DIR}/.gitignore" 2>/dev/null; then
#     echo "package-lock.json" >> "${CURRENT_DIR}/.gitignore"
# fi

# gitmoji-cli
# https://github.com/carloscuesta/gitmoji-cli
[[ ! -x "$(command -v gitmoji)" ]] && npm_Install_Global gitmoji-cli
[[ -x "$(command -v gitmoji)" ]] && gitmoji --list

## 🤖 🚀 ✨ Emojify your conventional commits with Devmoji
## https://github.com/folke/devmoji
# [[ ! -x "$(command -v devmoji)" ]] && npm install -g devmoji
# [[ -x "$(command -v devmoji)" ]] && devmoji --list
## echo "This is a :test: of the first :release: :boom: :sparkles:" | devmoji --format unicode
## echo "🚀 :boom: :sparkles:" | devmoji --format devmoji
## glol | devmoji --format unicode

## check the last commit
# npx commitlint --from HEAD~1 --to HEAD --verbose

## Generate a CHANGELOG from git metadata
## Based on commits since the last semver tag that matches the pattern of "Feature", "Fix", "Performance Improvement" or "Breaking Changes"
# ./node_modules/.bin/conventional-changelog -p angular -i CHANGELOG.md -s

## Generate all previous changelogs
# ./node_modules/.bin/conventional-changelog -p angular -i CHANGELOG.md -s -r 0

## Generate changelogs with gitmoji
# https://github.com/epoweripione/conventional-changelog-cz-emoji-config
# ./node_modules/.bin/conventional-changelog -p cz-emoji-config -i CHANGELOG.md -s
