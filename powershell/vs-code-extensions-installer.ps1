# https://gist.github.com/mdschweda/2311e3f2c7062bf7367e44f8a7aa8b55
# Script for batch installing Visual Studio Code extensions
# Specify extensions to be checked & installed by modifying $extensions

## How to export installed extensions list
# code --list-extensions > vscode_extensions.list

## How to install extensions from exprot list
# windows cmd:
# for /F "tokens=*" %%A in (vscode_extensions.list) do code --install-extension %%A
# bash:
# <vscode_extensions.list xargs -I % code --install-extension %

Param (
	[switch]$UseFile,
	[string]$FileName = "vscode_extensions.list"
)

$extensions = @(
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

$cmd = "code --list-extensions"
Invoke-Expression $cmd -OutVariable output | Out-Null
$installed = $output -split "\s"

$extTotal = 0
if ($UseFile) {
	## vscode_extensions.list
	# windows cmd:
	# for /F "tokens=*" %%A in ($FileName) do code --install-extension %%A
	
	## Get-Content has bad performance
	## it tries to read the file into memory all at once
	# foreach ($ext in Get-Content $PSScriptRoot\$FileName) {
	#     if ($ext -notmatch '\#') {
	# 		if ($installed -match "$ext") {
	# 			Write-Host "$ext already installed." -ForegroundColor Green
	# 		} else {
	# 			Write-Host "Installing $ext..." -ForegroundColor Blue
	# 			code --install-extension $ext
	# 		}
	#     }
	# }
	
	## (.NET) file reader reads each line one by one
	foreach ($ext in [System.IO.File]::ReadLines("$PSScriptRoot\$FileName")) {
		if ($ext -notmatch '\#') {
			$extTotal++
			# if ($installed.Contains($ext)) {
			if ($installed -match "$ext") {
				Write-Host "$ext already installed." -ForegroundColor Green
			} else {
				Write-Host "Installing $ext..." -ForegroundColor Blue
				code --install-extension $ext
			}
		}
	}
} else {
	foreach ($ext in $extensions) {
		$extTotal++
		if ($installed -match "$ext") {
			Write-Host "$ext already installed." -ForegroundColor Green
		} else {
			Write-Host "Installing $ext..." -ForegroundColor Blue
			code --install-extension $ext
		}
	}
}

Write-Host "Done, $extTotal extensions installed." -ForegroundColor Green