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
	"adpyke.js-unicode-preview"
	"ahmadalli.vscode-nginx-conf"
	"angular.ng-template"
	"apollographql.vscode-apollo"
	"aykutsarac.jsoncrack-vscode"
	"bierner.markdown-footnotes"
	"bierner.markdown-mermaid"
	"bradlc.vscode-tailwindcss"
	"burkeholland.simple-react-snippets"
	"chouzz.vscode-innosetup"
	"christian-kohler.path-intellisense"
	"circlecodesolution.ccs-flutter-color"
	"codezombiech.gitignore"
	"cweijan.dbclient-jdbc"
	"cweijan.vscode-database-client2"
	"daltonmenezes.aura-theme"
	"dart-code.dart-code"
	"dart-code.flutter"
	"davidanson.vscode-markdownlint"
	"dbaeumer.vscode-eslint"
	"docker.docker"
	"donjayamanne.githistory"
	"eamodio.gitlens"
	"ecmel.vscode-html-css"
	"editorconfig.editorconfig"
	"esbenp.prettier-vscode"
	"fill-labs.dependi"
	"formulahendry.code-runner"
	"gera2ld.markmap-vscode"
	"github.copilot"
	"github.copilot-chat"
	"github.github-vscode-theme"
	"golang.go"
	"gornivv.vscode-flutter-files"
	"gruntfuggly.todo-tree"
	"hangxingliu.vscode-systemd-support"
	"hediet.debug-visualizer"
	"hediet.vscode-drawio"
	"holmescn.vscode-wordcount-cjk"
	"ionide.ionide-fsharp"
	"isopodlabs.regedit-explorer"
	"james-yu.latex-workshop"
	"johnpapa.angular2"
	"k--kato.docomment"
	"kamikillerto.vscode-colorize"
	"lokalise.i18n-ally"
	"marp-team.marp-vscode"
	"marscode.marscode-extension"
	"marufhassan.flutter-snippets"
	"matthewpi.caddyfile-support"
	"mechatroner.rainbow-csv"
	"medo64.code-point"
	"mhutchie.git-graph"
	"miguelsolorio.fluent-icons"
	"mqycn.huile8"
	"ms-azuretools.vscode-containers"
	"ms-ceintl.vscode-language-pack-zh-hans"
	"ms-dotnettools.csdevkit"
	"ms-dotnettools.csharp"
	"ms-dotnettools.dotnet-interactive-vscode"
	"ms-dotnettools.dotnet-maui"
	"ms-dotnettools.vscode-dotnet-runtime"
	"ms-dotnettools.vscodeintellicode-csharp"
	"ms-kubernetes-tools.vscode-kubernetes-tools"
	"ms-python.debugpy"
	"ms-python.python"
	"ms-python.vscode-pylance"
	"ms-toolsai.jupyter"
	"ms-toolsai.jupyter-keymap"
	"ms-toolsai.jupyter-renderers"
	"ms-toolsai.vscode-jupyter-cell-tags"
	"ms-toolsai.vscode-jupyter-slideshow"
	"ms-vscode-remote.remote-containers"
	"ms-vscode-remote.remote-ssh"
	"ms-vscode-remote.remote-ssh-edit"
	"ms-vscode-remote.remote-wsl"
	"ms-vscode-remote.vscode-remote-extensionpack"
	"ms-vscode.js-debug-nightly"
	"ms-vscode.powershell"
	"ms-vscode.remote-explorer"
	"ms-vscode.remote-server"
	"ms-windows-ai-studio.windows-ai-studio"
	"nixon.env-cmd-file-syntax"
	"nromanov.dotnet-meteor"
	"oderwat.indent-rainbow"
	"patcx.vscode-nuget-gallery"
	"pbkit.vscode-pbkit"
	"pflannery.vscode-versionlens"
	"pomdtr.excalidraw-editor"
	"pranaygp.vscode-css-peek"
	"quicktype.quicktype"
	"rangav.vscode-thunder-client"
	"redhat.vscode-extension-bpmn-editor"
	"redhat.vscode-xml"
	"redhat.vscode-yaml"
	"ritwickdey.liveserver"
	"robert-brunhage.flutter-riverpod-snippets"
	"rodrigorahman.flutter-dart-utils"
	"russell.any-rule"
	"rust-lang.rust-analyzer"
	"shd101wyy.markdown-preview-enhanced"
	"sidthesloth.html5-boilerplate"
	"simonhe.common-intellisense"
	"streetsidesoftware.code-spell-checker"
	"svelte.svelte-vscode"
	"svenzhao.var-translation"
	"tabnine.tabnine-vscode"
	"tamasfe.even-better-toml"
	"telesoho.vscode-markdown-paste-image"
	"timonwong.shellcheck"
	"tintoy.msbuild-project-tools"
	"tldraw-org.tldraw-vscode"
	"unbug.codelf"
	"vscode-icons-team.vscode-icons"
	"vscode-snippet.snippet"
	"vue.volar"
	"wangguixuan.var-translate-en"
	"xyz.plsql-language"
	"yzhang.markdown-all-in-one"
	"zhuangtongfa.material-theme"
	"zhuyuanxiang.pangu-markdown-vscode"
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
