$PS_CUSTOM_FUNCTION = "$env:USERPROFILE\Documents\PowerShell\Scripts\ps_custom_function.ps1"
if ((Test-Path "$PS_CUSTOM_FUNCTION") -and ((Get-Item "$PS_CUSTOM_FUNCTION").length -gt 0)) {
    . "$PS_CUSTOM_FUNCTION"
}

Import-Module Find-String
Import-Module Posh-git

# Import-Module PSColors
# Import-Module TabExpansionPlusPlus

# Import-Module PoshFunctions

Import-Module Terminal-Icons
Import-Module PSEverything

# Use github mirror to download oh-my-posh executable
$PoshExec = "oh-my-posh"
if ($PSVersionTable.PSEdition -ne "Core" -or $IsWindows) {
    $PoshExec = "oh-my-posh.exe"
}

if (Test-Path "$HOME\.oh-my-posh") {
    $InstalledPoshDir = "$HOME\.oh-my-posh"
} else {
    $InstalledPoshDir = "$env:USERPROFILE\Documents\PowerShell\Modules\oh-my-posh"
}

$InstalledPoshVersion = "0.0.0"
if (Test-Path "$InstalledPoshDir\$PoshExec") {
    $InstalledPoshVersion = & "$InstalledPoshDir\$PoshExec" --version
}

$ModulePoshPSM = (Get-ChildItem -Path "$InstalledPoshDir" `
    -Filter "oh-my-posh.psm1" -File -Recurse -ErrorAction SilentlyContinue -Force `
    | Sort-Object -Descending | Select-Object -First 1).FullName
#     | ForEach-Object {$_.FullName})

if (Test-Path "$ModulePoshPSM") {
    $ModulePoshVersion = Split-Path -Parent $ModulePoshPSM | Split-Path -Leaf
    if ([System.Version]"$ModulePoshVersion" -gt [System.Version]"$InstalledPoshVersion") {
        (Get-Content -path "$ModulePoshPSM" -Raw) `
            -Replace 'https://github.com/jandedobbeleer/oh-my-posh/','https://download.fastgit.org/jandedobbeleer/oh-my-posh/' `
            -Replace 'Invoke-WebRequest \$Url -Out \$Destination','curl -fSL -# -o $Destination $Url' `
            -Replace 'Invoke-WebRequest -OutFile \$tmp \$themesUrl','curl -fSL -# -o $tmp $themesUrl' `
            | Set-Content -Path "$ModulePoshPSM"
    }
}

## Skip oh-my-posh executable download if already installed by scoop
# $ScoopPoshExec = ""
# $ScoopPoshVersion = "0.0.0"
# if (Get-Command "scoop" -ErrorAction SilentlyContinue) {
#     $ScoopPoshExec = "$(scoop prefix oh-my-posh3 6>$null)\bin\$PoshExec"
#     if (Test-Path "$ScoopPoshExec") {
#         $ScoopPoshVersion = & "$ScoopPoshExec" --version
#     }
# }
# if ([System.Version]"$ScoopPoshVersion" -gt [System.Version]"$PoshVersion") {
#     if (Test-Path "$ScoopPoshExec") {
#         Copy-Item -Path "$ScoopPoshExec" -Destination "$InstalledPoshDir" -Force -Confirm:$false
#     }
# }

Import-Module oh-my-posh
$env:POSH_GIT_ENABLED = $true
# oh-my-posh --init --shell pwsh --config "$env:USERPROFILE\Documents\PowerShell\PoshThemes\powerlevel10k_my.omp.json" | Invoke-Expression
# Set-PoshPrompt -Theme powerlevel10k_rainbow
Set-PoshPrompt -Theme "$env:USERPROFILE\Documents\PowerShell\PoshThemes\powerlevel10k_my.omp.json"

## PSFzf
## https://github.com/kelleyma49/PSFzf
## Usage:
## Select Current Provider Path (default chord: Ctrl+t)
## Reverse Search Through PSReadline History (default chord: Ctrl+r)
## Set-Location Based on Selected Directory (default chord: Alt+c)
## Search Through Command Line Arguments in PSReadline History (default chord: Alt+a)
## PSFzf supports specialized tab expansion with a small set of commands.
## After typing the default trigger command, which defaults to "**", and press Tab, 
## PsFzf tab expansion will provide selectable list of options.
# git, Get-Service, Start-Service, Stop-Service,Get-Process, Start-Process
## Helper Functions
# Invoke-FuzzyGitStatus
# Invoke-FuzzyHistory
# Invoke-FuzzyKillProcess
# Invoke-FuzzySetLocation
# Set-LocationFuzzyEverything
## To change to a user selected directory:
# Get-ChildItem . -Recurse -Attributes Directory | Invoke-Fzf | Set-Location
## To edit a file:
# Get-ChildItem . -Recurse -Attributes !Directory | Invoke-Fzf | % { notepad $_ }
Import-Module PSFzf

Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -TabExpansion

## $FZF_DEFAULT_COMMAND='powershell.exe -NoLogo -NoProfile -Noninteractive -Command "Get-ChildItem -File -Recurse -Name"'
## $FZF_DEFAULT_COMMAND='powershell.exe -NoLogo -NoProfile -Noninteractive -Command "Get-ChildItem -Depth 1 -Recurse -Name | Where-Object {$_ -notlike ".*"}"'
# $FZF_DEFAULT_COMMAND='powershell.exe -NoLogo -NoProfile -Noninteractive -Command "Get-ChildItem -Depth 1 -Recurse -Name"'
# [System.Environment]::SetEnvironmentVariable("FZF_DEFAULT_COMMAND", $FZF_DEFAULT_COMMAND, "User")

## Color coding Get-ChildItem
# Import-Module Get-ChildItemColor

Set-Alias l Get-ChildItemColor -option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -option AllScope

## PSReadLine
# With these settings, I can press up and down arrows for history substring search, and the tab completion shows me available candidates.
# You can also use CTRL + r for incremental history search.
# Import-Module PSReadLine

## Get all key mappings
# Get-PSReadLineKeyHandler -Bound -Unbound

Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
Set-PSReadLineOption -MaximumHistoryCount 4000

# history substring search
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# Tab completion
Set-PSReadlineKeyHandler -Chord 'Shift+Tab' -Function Complete
# Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# https://www.hanselman.com/blog/my-ultimate-powershell-prompt-with-oh-my-posh-and-the-windows-terminal
# https://gist.github.com/shanselman/25f5550ad186189e0e68916c6d7f44c3
# PowerShell parameter completion shim for the winget CLI
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# CaptureScreen is good for blog posts or email showing a transaction
# of what you did when asking for help or demonstrating a technique.
Set-PSReadLineKeyHandler -Chord 'Ctrl+d,Ctrl+c' -Function CaptureScreen

# The built-in word movement uses character delimiters, but token based word
# movement is also very useful - these are the bindings you'd use if you
# prefer the token based movements bound to the normal emacs word movement
# key bindings.
Set-PSReadLineKeyHandler -Key Alt+d -Function ShellKillWord
Set-PSReadLineKeyHandler -Key Alt+D -Function ShellKillWord
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function ShellBackwardKillWord

Set-PSReadLineKeyHandler -Key Alt+b -Function BackwardWord
Set-PSReadLineKeyHandler -Key Alt+B -Function BackwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ForwardWord
Set-PSReadLineKeyHandler -Key Alt+F -Function ForwardWord

Set-PSReadLineKeyHandler -Key Ctrl+b -Function BackwardChar
Set-PSReadLineKeyHandler -Key Ctrl+B -Function BackwardChar
Set-PSReadLineKeyHandler -Key Ctrl+f -Function ForwardChar
Set-PSReadLineKeyHandler -Key Ctrl+F -Function ForwardChar

Set-PSReadLineKeyHandler -Key Ctrl+a -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key Ctrl+A -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key Ctrl+e -Function EndOfLine
Set-PSReadLineKeyHandler -Key Ctrl+E -Function EndOfLine

Set-PSReadLineKeyHandler -Key Ctrl+u -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key Ctrl+U -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key Ctrl+k -Function ForwardDeleteLine
Set-PSReadLineKeyHandler -Key Ctrl+K -Function ForwardDeleteLine

## cddash
# You can use the following to have the "dash" functionality - namely, you can go back to the previous location by typing cd -. It is from http://goo.gl/xRbYbk.
function cddash {
    if ($args[0] -eq '-') {
        $CurrentPWD = $OLDPWD;
    } else {
        $CurrentPWD = $args[0];
    }
    $tmp = Get-Location;

    if ($CurrentPWD) {
        Set-Location $CurrentPWD;
    }
    Set-Variable -Name OLDPWD -Value $tmp -Scope global;
}

Set-Alias -Name cd -value cddash -Option AllScope

## python encoding
$env:PYTHONIOENCODING="utf-8"

function GitLogPretty {
    git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all
}

function UpdateScoop {
    scoop update
    scoop config aria2-enabled false
    scoop update *
    scoop config aria2-enabled true
    scoop update *
    scoop config aria2-enabled false
    scoop cleanup *
}

function  SearchScoopBucket {
    param (
        [string]$SearchCond = ""
    )

    if ($SearchCond) {
        Get-ChildItem -Path "$env:UserProfile\scoop\buckets" `
            -Recurse -Include "*$SearchCond*.json" -Depth 2 -Name
    }
}

function UpdateMyScript {
    Set-Location ~
    if (check_socks5_proxy_up "127.0.0.1:7890") {
        curl -fsSL --socks5-hostname "127.0.0.1:7890" `
            -o ".\pwsh_script_download.ps1" "https://git.io/JPS2j" && `
        .\pwsh_script_download.ps1
    } else {
        curl -fsSL -o ".\pwsh_script_download.ps1" "https://git.io/JPS2j" && `
        .\pwsh_script_download.ps1
    }
}

function DockerPullAllImages {
    docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object {$_ -NotMatch "<none>"} | ForEach-Object {docker pull $_}
}

function DockerList {
    docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
}

function DockerListAll {
    docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}\t{{.Ports}}\t{{.Networks}}\t{{.Command}}\t{{.Size}}"
}

function GetTCPConnections {
    Get-NetTCPConnection -State Listen,Established |
        Select-Object -Property LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess,
            @{'Name' = 'ProcessName';'Expression'={(Get-Process -Id $_.OwningProcess).Name}},
            @{'Name' = 'Path';'Expression'={(Get-Process -Id $_.OwningProcess).Path}} |
        Sort-Object -Property ProcessName,LocalPort
}

function GetUDPConnections {
    Get-NetUDPEndpoint |
        Select-Object -Property LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess,
            @{'Name' = 'ProcessName';'Expression'={(Get-Process -Id $_.OwningProcess).Name}},
            @{'Name' = 'Path';'Expression'={(Get-Process -Id $_.OwningProcess).Path}} |
        Sort-Object -Property ProcessName,LocalPort
}

function GetTCPAll {GetTCPConnections | Format-Table}
function GetUDPAll {GetUDPConnections | Format-Table}

function PrettyLS {colorls --light -A}
function GitStat {git status}
function GoBack {Set-Location ..}
function GetMyIp {curl -fsSL -4 http://ip-api.com/json/ | ConvertFrom-Json}
function EditHosts {sudo notepad $env:windir\System32\drivers\etc\hosts}
function EditHistory {notepad (Get-PSReadlineOption).HistorySavePath}

## Other alias
Set-Alias open Invoke-Item -option AllScope
Set-Alias .. GoBack -option AllScope
Set-Alias glola GitLogPretty -option AllScope
Set-Alias gst GitStat -option AllScope
Set-Alias myip GetMyIp -option AllScope
Set-Alias pls PrettyLS -option AllScope
Set-Alias suu UpdateScoop -option AllScope
Set-Alias ssb SearchScoopBucket -option AllScope
Set-Alias ums UpdateMyScript -option AllScope
Set-Alias hosts EditHosts -option AllScope
Set-Alias history EditHistory -option AllScope

Set-Alias dockerpullall DockerPullAllImages -option AllScope
Set-Alias dockerps DockerList -option AllScope
Set-Alias dockerpsall DockerListAll -option AllScope

Set-Alias gettcp GetTCPAll -option AllScope
Set-Alias getudp GetUDPAll -option AllScope

# https://github.com/ajeetdsouza/zoxide
if (Get-Command "zoxide" -ErrorAction SilentlyContinue) {
    Invoke-Expression (& {
        $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
        (zoxide init --hook $hook powershell) -join "`n"
    })
}

## https://starship.rs/
# if (Get-Command "starship" -ErrorAction SilentlyContinue) {
#     Invoke-Expression (&starship init powershell)
# }
