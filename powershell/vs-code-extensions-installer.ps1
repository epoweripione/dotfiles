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
    # Look & Feel
	"ms-ceintl.vscode-language-pack-zh-hans"
	"vscode-icons-team.vscode-icons"
	"miguelsolorio.fluent-icons"
	# "zhuangtongfa.material-theme"
	# "freecodecamp.freecodecamp-dark-vscode-theme"
	# "tds.taptap-vscode-theme"
	"daltonmenezes.aura-theme"
    # Editing
    "aaron-bond.better-comments"
	"esbenp.prettier-vscode"
	"oderwat.indent-rainbow"
	"tabnine.tabnine-vscode"
	"streetsidesoftware.code-spell-checker"
	"kamikillerto.vscode-colorize"
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
	"fr-str.vscode-postfix-go-fr"
	## HTML/CSS
	"ms-vscode.brackets-pack"
	"sidthesloth.html5-boilerplate"
    ## Javascript
	"dbaeumer.vscode-eslint"
    ## kubernete/docker
	"ms-kubernetes-tools.vscode-kubernetes-tools"
	"ms-azuretools.vscode-docker"
	"mindaro.mindaro"
	## Rest API Client
	"rangav.vscode-thunder-client"
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
	## caddy
	"matthewpi.caddyfile-support"
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
	## snippets
	"tahabasri.snippets"
	## cht.sh snippets
	"vscode-snippet.snippet"
	## linux/shell/vim
	"timonwong.shellcheck"
    ## XML/JSON/GraphQL/YAML
	"dotjoshjohnson.xml"
    "eriklynd.json-tools"
	"mohsen1.prettify-json"
    "kumar-harsh.graphql-for-vscode"
	"redhat.vscode-yaml"
    # Vesion Control
	"donjayamanne.githistory"
	"eamodio.gitlens"
	"mhutchie.git-graph"
	# Remote
	"ms-vscode-remote.vscode-remote-extensionpack"
	"ms-vscode-remote.remote-wsl"
	# Debug & Test
	"formulahendry.code-runner"
	"humao.rest-client"
	"hediet.debug-visualizer"
	# Extra tools
	"ms-toolsai.jupyter"
	# "shan.code-settings-sync"
	"anseki.vscode-color"
	"mkxml.vscode-filesize"
	"doggy8088.quicktype-refresh"
	"wayou.vscode-todo-highlight"
	"chouzz.vscode-better-align"
	"tyriar.sort-lines"
	"russell.any-rule"
	"hediet.vscode-drawio"
	"redhat.vscode-extension-bpmn-editor"
	"mqycn.huile8"
	"wscats.search"
	"chouzz.vscode-innosetup"
	"unbug.codelf"
	"jeff-hykin.polacode-2019"
	"mrmlnc.vscode-duplicate"
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