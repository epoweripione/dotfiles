#!/usr/bin/env bash

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


if [[ ! -x "$(command -v code)" ]]; then
    colorEcho "${RED}Please install ${FUCHSIA}visual studio code${RED} first!"
    exit 0
fi


# ExtFile="vscode_extensions.list"
[[ $PARAMS_NUM -gt 0 ]] && ExtFile=${1:-"vscode_extensions.list"}


extensions=(
    # Look & Feel
	"ms-ceintl.vscode-language-pack-zh-hans"
	"vscode-icons-team.vscode-icons"
	"miguelsolorio.fluent-icons"
	"zhuangtongfa.material-theme"
	"freecodecamp.freecodecamp-dark-vscode-theme"
	"tds.taptap-vscode-theme"
	"daltonmenezes.aura-theme"
    # Editing
    "aaron-bond.better-comments"
	"esbenp.prettier-vscode"
	"oderwat.indent-rainbow"
	"tabnine.tabnine-vscode"
    ## Core
	"doggy8088.netcore-extension-pack"
	"doggy8088.netcore-snippets"
	## Dart/Flutter
	"dart-code.dart-code"
	"dart-code.flutter"
	"nash.awesome-flutter-snippets"
	"gornivv.vscode-flutter-files"
	"alexisvt.flutter-snippets"
	## GO
	"golang.go"
	## HTML/CSS
	"ms-vscode.brackets-pack"
	"sidthesloth.html5-boilerplate"
    ## Javascript
	"dbaeumer.vscode-eslint"
    ## kubernete/docker
	"ms-kubernetes-tools.vscode-kubernetes-tools"
	"ms-azuretools.vscode-docker"
	"mindaro.mindaro"
	## Markdown
	"marp-team.marp-vscode"
	"evilz.vscode-reveal"
	"yzhang.markdown-all-in-one"
	"bierner.markdown-mermaid"
	"bierner.markdown-emoji"
	"bierner.markdown-footnotes"
	"devhawk.markdown-sup"
	"gera2ld.markmap-vscode"
	"mushan.vscode-paste-image"
	"shd101wyy.markdown-preview-enhanced"
	"orangex4.better-markdown-latex-shortcuts"
    ## nginx
	"shanoor.vscode-nginx"
    ## plsql
	"xyz.plsql-language"
	"ms-python.python"
    ## powershell
	"ms-vscode.powershell"
	## rust
	"rust-lang.rust-analyzer"
	"bungcip.better-toml"
	"serayuzgur.crates"
	## cht.sh snippets
	"vscode-snippet.snippet"
	## linux/shell/vim
	"timonwong.shellcheck"
    ## XML/JSON/GraphQL/YAML
    "eriklynd.json-tools"
	"mohsen1.prettify-json"
    "kumar-harsh.graphql-for-vscode"
	"redhat.vscode-yaml"
    # Vesion Control
	"eamodio.gitlens"
	# Remote
	"ms-vscode-remote.vscode-remote-extensionpack"
	"ms-vscode-remote.remote-wsl"
	# Debug & Test
	"formulahendry.code-runner"
	"humao.rest-client"
	"hediet.debug-visualizer"
    # Extra tools
	"ms-toolsai.jupyter"
	"shan.code-settings-sync"
	"anseki.vscode-color"
	"mkxml.vscode-filesize"
	"wayou.vscode-todo-highlight"
	"wwm.better-align"
	"tyriar.sort-lines"
	"russell.any-rule"
	"hediet.vscode-drawio"
	"mqycn.huile8"
	"wscats.search"
	"idleberg.innosetup"
	"unbug.codelf"
)

# How to export installed extensions list
# code --list-extensions > "${ExtFile}"

if [[ $PARAMS_NUM -gt 0 ]]; then
    if [[ ! -s "${ExtFile}" ]]; then
        colorEcho "${FUCHSIA}${ExtFile}${RED} does not exist or empty!"
        exit 0
    fi

    grep -v '^#' "${ExtFile}" | xargs -P "$(nproc --ignore=1)" -n1 code --install-extension
else
    # for Target in "${extensions[@]}"; do
    #     code --install-extension "${Target}"
    # done

	xargs -P "$(nproc --ignore=1)" -n1 code --install-extension <<<"${extensions[@]}"
fi

# How to install extensions from exprot list
# windows cmd:
# for /F "tokens=*" %%A in ("${ExtFile}") do code --install-extension %%A
# bash:
# <"${ExtFile}" xargs -I % code --install-extension %
# or
# grep -v '^#' "${ExtFile}" | xargs -L1 code --install-extension

## https://www.growingwiththeweb.com/2016/06/syncing-vscode-extensions.html
# EXTENSIONS=(
#     "cssho.vscode-svgviewer" \
#     "dbaeumer.vscode-eslint" \
#     "EditorConfig.EditorConfig" \
#     "ryzngard.vscode-header-source" \
#     "spywhere.guides" \
#     "Tyriar.sort-lines" \
#     "Tyriar.lorem-ipsum" \
#     "waderyan.gitblame"
# )

# for VARIANT in "code" "code-insiders"; do
#     if hash $VARIANT 2>/dev/null; then
#         echo "Installing extensions for $VARIANT"
#         for EXTENSION in ${EXTENSIONS[@]}; do
#             $VARIANT --install-extension $EXTENSION
#         done
#     fi
# done
