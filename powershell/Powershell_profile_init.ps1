#Requires -RunAsAdministrator

if (-Not (Get-Command -Name "check_webservice_up" 2>$null)) {
    $CUSTOM_FUNCTION="$PSScriptRoot\ps_custom_function.ps1"
    if ((Test-Path "$CUSTOM_FUNCTION") -and ((Get-Item "$CUSTOM_FUNCTION").length -gt 0)) {
        . "$CUSTOM_FUNCTION"
    }
}

# proxy
if (!$env:GLOBAL_PROXY_IP) {
    setGlobalProxies
}

$PROXY_ADDR = "${env:GLOBAL_PROXY_IP}:${env:GLOBAL_PROXY_MIXED_PORT}"
# if (-Not (check_http_proxy_up $PROXY_ADDR)) {
#     $PROXY_ADDR = ""
#     if($PROMPT_VALUE = Read-Host "Proxy address for Install-Module?") {
#         $PROXY_ADDR = $PROMPT_VALUE
#     }
# }

# Profile
if (Test-Path $PROFILE) {
    $CONTINUE_CONFIRM = "N"
    if($PROMPT_VALUE = Read-Host "${PROFILE} exists, continue will overwrite this profile, confirm?[y/N]") {
        $CONTINUE_CONFIRM = $PROMPT_VALUE
    }

    if (-Not (($CONTINUE_CONFIRM -eq "y") -or ($CONTINUE_CONFIRM -eq "Y"))) {
        exit 1
    }

    '' | Tee-Object $PROFILE | Out-Null
} else {
    New-Item $PROFILE -Type File -Force | Out-Null
}

@'
$PS_CUSTOM_FUNCTION = "$env:USERPROFILE\Documents\PowerShell\Scripts\ps_custom_function.ps1"
if ((Test-Path "$PS_CUSTOM_FUNCTION") -and ((Get-Item "$PS_CUSTOM_FUNCTION").length -gt 0)) {
    . "$PS_CUSTOM_FUNCTION"
}

$PS_CUSTOM_ENV = "$env:USERPROFILE\.powershell.env.ps1"
if (-Not (Test-Path "$PS_CUSTOM_ENV")) {
    $PS_CUSTOM_ENV = "$env:SystemDrive\Tools\.powershell.env.ps1"
}

if ((Test-Path "$PS_CUSTOM_ENV") -and ((Get-Item "$PS_CUSTOM_ENV").length -gt 0)) {
    . "$PS_CUSTOM_ENV"
}

if(!$env:SCOOP_HOME) {
    $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop)
}

'@ | Tee-Object $PROFILE -Append | Out-Null

# https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools
# Get-PackageSource
# Find-PackageProvider -Name "Nuget" -AllVersions
# Install-PackageProvider -Name "NuGet" -Force

# https://www.powershellgallery.com/
Write-Host "Setting powershell repository..." -ForegroundColor Blue
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

Write-Host "Installing powershell modules..." -ForegroundColor Blue
# Find-Module, Get-InstalledModule, Update-Module, Uninstall-Module
if (-Not (Get-Module -Name "PSReadLine")) {
    if (($null -eq $PROXY_ADDR) -or ($PROXY_ADDR -eq "")) {
        Install-Module -Name "PSReadLine" -AllowPrerelease -SkipPublisherCheck -Force
    } else {
        Install-Module -Name "PSReadLine" -AllowPrerelease -SkipPublisherCheck -Force -Proxy "http://$PROXY_ADDR"
    }
}

$InstallModules = @(
    "Find-String"
    "Posh-git"
    "oh-my-posh"
    "Terminal-Icons"
    "Get-ChildItemColor"
    "PoshFunctions"
    "PSEverything"
    "PSFzf"
    "PSWriteColor"
    "WozTools"
    "Az.Accounts"
    "Az.Tools.Predictor"
)

foreach ($TargetModule in $InstallModules) {
    if (-Not (Get-Module -Name $TargetModule)) {
        if (($null -eq $PROXY_ADDR) -or ($PROXY_ADDR -eq "")) {
            Install-Module -Name "$TargetModule" -AllowClobber -AllowPrerelease
        } else {
            Install-Module -Name "$TargetModule" -AllowClobber -AllowPrerelease -Proxy "http://$PROXY_ADDR"
        }
    }
}

# [Refresh-EnvironmentVariables](https://github.com/asheroto/Refresh-EnvironmentVariables)
Install-Script Refresh-EnvironmentVariables -Force

## Fix error Authenticode issuer
# Install-Module -Name PSWriteColor -Force -AcceptLicense -SkipPublisherCheck

$EnableModules = @(
    "Find-String"
    "Posh-git"
    "Terminal-Icons"
    "PSEverything"
    "PSWriteColor"
    "WozTools"
)

foreach ($TargetModule in $EnableModules) {
    if (-Not (Get-Module -Name $TargetModule)) {
        Add-Content $PROFILE "Import-Module $TargetModule"
    }
}

# oh-my-posh theme
Write-Host "Setting powershell theme..." -ForegroundColor Blue
@'

# Oh My Posh
# # Use github mirror to download oh-my-posh executable
# $PoshExec = "oh-my-posh"
# if ($PSVersionTable.PSEdition -ne "Core" -or $IsWindows) {
#     $PoshExec = "oh-my-posh.exe"
# }

# $PoshModuleDir = "$env:USERPROFILE\Documents\PowerShell\Modules\oh-my-posh"
# if (Test-Path "$env:LOCALAPPDATA\oh-my-posh") {
#     $PoshExecDir = "$env:LOCALAPPDATA\oh-my-posh"
# } elseif (Test-Path "$env:XDG_CACHE_HOME\oh-my-posh") {
#     $PoshExecDir = "$env:XDG_CACHE_HOME\oh-my-posh"
# } elseif (Test-Path "$env:HOME\.cache\oh-my-posh") {
#     $PoshExecDir = "$env:HOME\.cache\oh-my-posh"
# } else {
#     $PoshExecDir = "$PoshModuleDir"
# }

# $InstalledPoshVersion = "0.0.0"
# if (Test-Path "$PoshExecDir\$PoshExec") {
#     $InstalledPoshVersion = & "$PoshExecDir\$PoshExec" --version
# }

# $PoshModulePSM = (Get-ChildItem -Path "$PoshModuleDir" `
#     -Filter "oh-my-posh.psm1" -File -Recurse -ErrorAction SilentlyContinue -Force `
#     | Sort-Object -Descending | Select-Object -First 1).FullName
# #     | ForEach-Object {$_.FullName})

# if (Test-Path "$PoshModulePSM") {
#     $ModulePoshVersion = Split-Path -Parent $PoshModulePSM | Split-Path -Leaf
#     if ([System.Version]"$ModulePoshVersion" -gt [System.Version]"$InstalledPoshVersion") {
#         (Get-Content -path "$PoshModulePSM" -Raw) `
#             -Replace 'https://github.com/jandedobbeleer/oh-my-posh/','https://download.fastgit.org/jandedobbeleer/oh-my-posh/' `
#             -Replace 'Invoke-WebRequest \$Url -Out \$Destination','curl -fSL -# -o $Destination $Url' `
#             -Replace 'Invoke-WebRequest -OutFile \$tmp \$themesUrl','curl -fSL -# -o $tmp $themesUrl' `
#             | Set-Content -Path "$PoshModulePSM"
#     }
# }

$env:POSH_GIT_ENABLED = $true
## https://ohmyposh.dev/docs/migrating
# Remove-Item $env:POSH_PATH -Force -Recurse
# Uninstall-Module oh-my-posh -AllVersions
# scoop install oh-my-posh
$env:POSH_THEMES_PATH = Resolve-Path "$(scoop prefix oh-my-posh)\themes\"
if (Test-Path "$env:USERPROFILE\Documents\PowerShell\PoshThemes\atomic_my.omp.json") {
    oh-my-posh init pwsh --config "$env:USERPROFILE\Documents\PowerShell\PoshThemes\atomic_my.omp.json" | Invoke-Expression
} else {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\powerlevel10k_rainbow.omp.json" | Invoke-Expression
}
'@ | Tee-Object $PROFILE -Append | Out-Null

# Add-Content $PROFILE '$env:POSH_GIT_ENABLED = $true'
$THEME_DIR = "$HOME\Documents\PowerShell\PoshThemes"
if (-Not (Test-Path $THEME_DIR)) {New-Item -path $THEME_DIR -type Directory | Out-Null}

$THEME_FILE = "$THEME_DIR\powerlevel10k_my.omp.json"
if (-Not (Test-Path $THEME_FILE)) {
    $DOWNLOAD_URL = "https://raw.githubusercontent.com/epoweripione/dotfiles/main/powershell/themes/powerlevel10k_my.omp.json"
    $p = New-Object System.Net.WebClient
    $p.DownloadFile($DOWNLOAD_URL, $THEME_FILE)
}

$THEME_FILE = "$THEME_DIR\atomic_my.omp.json"
if (-Not (Test-Path $THEME_FILE)) {
    $DOWNLOAD_URL = "https://raw.githubusercontent.com/epoweripione/dotfiles/main/powershell/themes/atomic_my.omp.json"
    $p = New-Object System.Net.WebClient
    $p.DownloadFile($DOWNLOAD_URL, $THEME_FILE)
}

# Custom
Write-Host "Other powershell settings..." -ForegroundColor Blue
@'

## [PSFzf](https://github.com/kelleyma49/PSFzf)
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

##-------------------------------------------PSFzf: fix the shell prompt offset issue-------------------------------------------
##--------------------------------------------------------PSFzf.Base.ps1--------------------------------------------------------
## [Invoking command history leaves blank lines the size of displayed history](https://github.com/kelleyma49/PSFzf/issues/227)
# $PSFzfVersion = (Get-Module PSFzf).Version.ToString()
# $PSFzfBase = "$env:USERPROFILE\Documents\PowerShell\Modules\PSFzf\${PSFzfVersion}\PSFzf.Base.ps1"
$PSFzfDir = "$env:USERPROFILE\Documents\PowerShell\Modules\PSFzf"
$PSFzfBase = (Get-ChildItem -Path "$PSFzfDir" `
        -Filter "PSFzf.Base.ps1" -File -Recurse -ErrorAction SilentlyContinue -Force `
    | Sort-Object -Descending | Select-Object -First 1).FullName
if (Test-Path "$PSFzfBase") {
    $FindString = Select-String -Path "$PSFzfBase" -Pattern '\[Microsoft\.PowerShell\.PSConsoleReadLine\]::InvokePrompt\(\)'
    if ($FindString.Count -gt 0) {
        (Get-Content -Path "$PSFzfBase" -Raw) `
            -Replace '\[Microsoft\.PowerShell\.PSConsoleReadLine\]::InvokePrompt\(\)', `
                '[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, [Console]::CursorTop)' `
        | Set-Content -Path "$PSFzfBase"
    }
}
Remove-Variable -Name PSFzfDir, PSFzfBase, FindString -ErrorAction SilentlyContinue
##--------------------------------------------------------PSFzf.Base.ps1--------------------------------------------------------

##----------------------------------------------------------PSFzf.psd1----------------------------------------------------------
## [The shell prompt get offsets every time an item was accepted](https://github.com/kelleyma49/PSFzf/issues/202)
# $PSFzfVersion = (Get-Module PSFzf).Version.ToString()
# $PSFzfPsd = "$env:USERPROFILE\Documents\PowerShell\Modules\PSFzf\${PSFzfVersion}\PSFzf.psd1"
$PSFzfDir = "$env:USERPROFILE\Documents\PowerShell\Modules\PSFzf"
$PSFzfPsd = (Get-ChildItem -Path "$PSFzfDir" `
        -Filter "PSFzf.psd1" -File -Recurse -ErrorAction SilentlyContinue -Force `
    | Sort-Object -Descending | Select-Object -First 1).FullName
if (Test-Path "$PSFzfPsd") {
    $FindString = Select-String -Path "$PSFzfPsd" -Pattern "'Invoke-FzfPsReadlineHandlerProvider'"
    $ReplaceString = "'Set-PsFzfOption', 'Invoke-FzfPsReadlineHandlerProvider'," + `
        "`r`n               'Invoke-FzfPsReadlineHandlerHistory', 'Invoke-FzfPsReadlineHandlerSetLocation'," + `
        "`r`n               'Invoke-FzfPsReadlineHandlerHistoryArgs', 'Invoke-TabCompletion'"
    if ($FindString.Count -eq 0) {
        (Get-Content -Path "$PSFzfPsd" -Raw) `
            -Replace "'Set-PsFzfOption'", "$ReplaceString" `
        | Set-Content -Path "$PSFzfPsd"
    }
}
Remove-Variable -Name PSFzfDir, PSFzfPsd, FindString, ReplaceString -ErrorAction SilentlyContinue
##----------------------------------------------------------PSFzf.psd1----------------------------------------------------------

# Import Module PSFzf
Import-Module PSFzf

##-------------------------------------------PSFzf: fix the shell prompt offset issue-------------------------------------------
# [The shell prompt get offsets every time an item was accepted](https://github.com/kelleyma49/PSFzf/issues/202)
$env:FZF_DEFAULT_OPTS = "--height=50% --min-height=8 --layout=reverse --info=right --scrollbar='▐'"
$env:FZF_CTRL_T_COMMAND = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git"
$env:FZF_ALT_C_COMMAND = "fd --type d --strip-cwd-prefix --hidden --follow --exclude .git"
# Refer to https://github.com/kelleyma49/PSFzf/issues/202#issuecomment-2495321758
function SetCursorPostion {
    param(
        [int]$MinHeight = 3
    )
    $rawUI = (Get-Host).UI.RawUI
    $matchs = [regex]::Matches($env:FZF_DEFAULT_OPTS, '--height=~?(\d+)(%?)').Groups
    if ($null -eq $matchs) {
        # if no --height option, set height to full screen
        $fzfHeight = $rawUI.BufferSize.Height
    } elseif ($matchs[2].Length -eq 0) {
        # if set --height without %, set as the fixed height but at least 3
        $fzfHeight = [Math]::Max([int]$matchs[1].Value, $MinHeight)
    } else {
        # if set --height with %, we need to considar --min-height
        $fzfMinHeight = [regex]::Matches($env:FZF_DEFAULT_OPTS, '--min-height=(\d+)').Groups
        if ($null -eq $fzfMinHeight) {
        $fzfMinHeight = 10
        } else {
        $fzfMinHeight = [Math]::Max([int]$fzfMinHeight[1].Value, $MinHeight)
        }
        $fzfHeight = [Math]::Max([Math]::Truncate(($rawUI.BufferSize.Height - 1) * [int]$matchs[1].Value / 100), $fzfMinHeight)
    }

    $Global:PositionBeforePsfzf = $rawUI.CursorPosition
    $Global:RepairedCursorPosition = $rawUI.CursorPosition
    if ($Global:RepairedCursorPosition.Y -ge ($rawUI.BufferSize.Height - $FzfHeight)) {
        # If the curosr position is too low to display Fzf UI, the prompt line will be shifted
        $Global:RepairedCursorPosition.Y = $rawUI.BufferSize.Height - $FzfHeight - 1
    }
}

Set-PSReadLineKeyHandler -Key Ctrl+t -ScriptBlock {
    SetCursorPostion
    Invoke-FzfPsReadlineHandlerProvider
    $Global:RepairedCursorPosition = $null
}

Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
    SetCursorPostion
    Invoke-FzfPsReadlineHandlerHistory
    $Global:RepairedCursorPosition = $null
}

Set-PSReadLineKeyHandler -Key Alt-c -ScriptBlock {
    SetCursorPostion
    Invoke-FzfPsReadlineHandlerSetLocation
    $Global:RepairedCursorPosition = $null
}

Set-PSReadLineKeyHandler -Key Alt-a -ScriptBlock {
    SetCursorPostion
    Invoke-FzfPsReadlineHandlerHistoryArgs
    $Global:RepairedCursorPosition = $null
}

Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
    SetCursorPostion
    Invoke-FzfTabCompletion
    $Global:RepairedCursorPosition = $null
}

$Global:__OriginalPrompt = $function:Prompt
function prompt {
    # Place at beginning of function to avoid oh-my-posh get the wrong last error code
    $out = $Global:__OriginalPrompt.Invoke()[0];

    # Transient prompt
    if ($out[-1] -eq "`b") {
        return $out
    }

    # Replace \n to \r\n to avoid some bug
    # $out = $out -replace "`n", "`r`n"
    $out = $out -replace "`n", "`r`n"

    # Reset the cursor to the correct shape
    if ($Global:PsReadLineViMode -eq "i") {
        $out += $PsReadLineViInsertModeCursor
    } else {
        $out += $PsReadLineViNormalModeCursor
    }

    # Repair the cursor position after PSReadline key handler
    if ($null -ne $Global:RepairedCursorPosition) {
        $rawUI = (Get-Host).UI.RawUI
        $promptAndCommandHeight = $Global:PositionBeforePsfzf.Y - $rawUI.CursorPosition.Y
        $Global:RepairedCursorPosition.X = 0
        $Global:RepairedCursorPosition.Y -= $promptAndCommandHeight
        $rawUI.CursorPosition = $Global:RepairedCursorPosition
    }

    return $out
}
##-------------------------------------------PSFzf: fix the shell prompt offset issue-------------------------------------------

# Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

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
Set-PSReadLineOption -MaximumHistoryCount 9999

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

# [Remove InsertPairedBraces by WozTools](https://github.com/Woznet/WozTools/blob/main/Lib/PSReadLine/PSReadLine-Config.ps1)
Remove-PSReadLineKeyHandler '(', '{', '[', '"', "'"

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

function UpdateInstalledApps {
    # Github mirror
    if (${GITHUB_HUB_URL}) {
        git config --global url."${GITHUB_HUB_URL}/".insteadOf "https://github.com/"
        # git config --global url."${GITHUB_HUB_URL}/".insteadOf "ssh://git@github.com/"
    }

    $CurrentDir = Get-Location

    # reset scoop repository
    if(!$env:SCOOP_HOME) {
        $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop)
    }
    $ScoopRoot = "$env:SCOOP_HOME"

    Set-Location -Path $ScoopRoot
    git reset --hard | Out-Null

    # reset scoop buckets repository
    $ScoopBucketPath = "$env:UserProfile\scoop\buckets"
    $ScoopBuckets = scoop bucket list 6>&1 | Select-Object -ExpandProperty Name
    foreach ($Bucket in $ScoopBuckets) {
        Set-Location -Path "${ScoopBucketPath}\${Bucket}"
        git reset --hard | Out-Null
    }

    Set-Location -Path $CurrentDir

    # update scoop
    scoop update

    # reset Github mirror
    if (${GITHUB_HUB_URL}) {
        git config --global --unset url."${GITHUB_HUB_URL}/".insteadOf
    }

    # modify `handle_special_urls()` to replace github download url
    $ScoopCore = "$ScoopRoot\lib\core.ps1"
    if ($GITHUB_DOWNLOAD_URL) {
        $GITHUB_MIRROR = Select-String -Path "$ScoopCore" -Pattern "# Github mirror"
        if (-not ($GITHUB_MIRROR)) {
            (Get-Content $ScoopCore) | Foreach-Object {
                if ($_ -match "return \`$url") {
                    #Add Lines before the selected pattern
                    "    # Github mirror"
                    "    if (`$url -match 'https://github.com/') {"
                    "        `$url = `$url -replace 'https://github.com/', '${GITHUB_DOWNLOAD_URL}/'"
                    "    }"
                    ""
                }
                $_ # send the current line to output
            } | Set-Content $ScoopCore
        }
    }

    # update installed scoop apps
    scoop config aria2-enabled true
    scoop update *
    scoop update * -g

    scoop config aria2-enabled false
    scoop update *
    scoop update * -g

    # cleanup
    scoop config aria2-enabled true
    scoop cleanup *
    scoop cleanup * -g

    # Module
    Update-Module -All

    # pip
    if (Get-Command -Name "cargo" -ErrorAction SilentlyContinue) {
        Write-Host
        Write-Color -Text "Updating pip packages..." -Color Cyan
        UpdateOutdatedPipPackages
    }

    ## micromamba
    # if (Get-Command -Name "micromamba" -ErrorAction SilentlyContinue) {
    #     Write-Host
    #     Write-Color -Text "Updating micromamba packages..." -Color Cyan
    #     $env:MAMBA_ROOT_PREFIX="$env:UserProfile\micromamba"
    #     # micromamba create -n default
    #     micromamba activate default
    #     micromamba self-update
    #     micromamba update -y --all
    #     micromamba deactivate
    # }

    # npm
    if (Get-Command -Name "npm" -ErrorAction SilentlyContinue) {
        Write-Host
        Write-Color -Text "Updating npm packages..." -Color Cyan
        npm install --location=global npm@latest
        npm update --location=global
    }

    # cargo
    if (Get-Command -Name "cargo-binstall" -ErrorAction SilentlyContinue) {
        Write-Host
        Write-Color -Text "Updating installed binary by ", "Rust Cargo", "..." -Color Cyan,Magenta,Cyan
        cargo install --list |
            Select-String -Pattern "^([a-z0-9_-]+) (v[0-9.]+).*:$" |
            ForEach-Object {
                cargo binstall --no-confirm $($_.Matches.Groups[1].Value)
            }
    } elseif (Get-Command -Name "cargo-install-update" -ErrorAction SilentlyContinue) {
        Write-Host
        Write-Color -Text "Updating installed binary by ", "Rust Cargo", "..." -Color Cyan,Magenta,Cyan
        cargo install-update --all
    }
}

function SearchScoopBucket {
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
    curl -fsSL --connect-timeout 5 -o ".\pwsh_script_download.ps1" "https://git.io/JPS2j" && `
        .\pwsh_script_download.ps1
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

# eza
function ezan {
    param (
        [string]$ListPath = "."
    )

    eza -ghl --icons --git --time-style=long-iso $ListPath
}

function ezal {
    param (
        [string]$ListPath = "."
    )

    eza -aghl --icons --git --time-style=long-iso $ListPath
}

function ezaa {
    param (
        [string]$ListPath = "."
    )

    eza -abghHliS --icons --git --time-style=long-iso $ListPath
}

function ezat {
    param (
        [string]$ListPath = "."
    )

    eza --tree --icons $ListPath
}

function ezat1 {
    param (
        [string]$ListPath = "."
    )

    eza --tree --icons --level=1 $ListPath
}

function ezat2 {
    param (
        [string]$ListPath = "."
    )

    eza --tree --icons --level=2 $ListPath
}

function ezat3 {
    param (
        [string]$ListPath = "."
    )

    eza --tree --icons --level=3 $ListPath
}

function UpdateOutdatedPipPackages {
    # update `pip` first
    python -m pip install -U pip

    # conda
    if (Get-Command -Name "conda" -ErrorAction SilentlyContinue) {
        conda update -y --all
    }

    # update oudated packages
    pip list --outdated | ForEach-Object {$_.split(' ')[0]} | Where-Object {$_ -notmatch "^-|^package|^warning|^error"} | ForEach-Object {pip install -U $_}
}

## Other alias
Set-Alias open Invoke-Item -option AllScope
Set-Alias .. GoBack -option AllScope
Set-Alias glola GitLogPretty -option AllScope
Set-Alias gst GitStat -option AllScope
Set-Alias myip GetMyIp -option AllScope
Set-Alias pls PrettyLS -option AllScope
Set-Alias suu UpdateInstalledApps -option AllScope
Set-Alias ssb SearchScoopBucket -option AllScope
Set-Alias ums UpdateMyScript -option AllScope
Set-Alias hosts EditHosts -option AllScope
Set-Alias history EditHistory -option AllScope

Set-Alias dockerPullAll DockerPullAllImages -option AllScope
Set-Alias dockerPs DockerList -option AllScope
Set-Alias dockerPsAll DockerListAll -option AllScope

Set-Alias gettcp GetTCPAll -option AllScope
Set-Alias getudp GetUDPAll -option AllScope

Set-Alias pipUpdateAll UpdateOutdatedPipPackages -option AllScope

# https://github.com/ajeetdsouza/zoxide
if (Get-Command "zoxide" -ErrorAction SilentlyContinue) {
    Invoke-Expression (& {
        $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
        (zoxide init --hook $hook powershell) -join "`n"
    })
}

# https://github.com/version-fox/vfox
if (Get-Command "vfox" -ErrorAction SilentlyContinue) {
    Invoke-Expression "$(vfox activate pwsh)"
}

# micromamba
if($env:MAMBA_EXE) {
    (& $env:MAMBA_EXE 'shell' 'hook' -s 'powershell') | Out-String | Invoke-Expression
}

## https://starship.rs/
# if (Get-Command "starship" -ErrorAction SilentlyContinue) {
#     Invoke-Expression (&starship init powershell)
# }

# Global proxy settings
setGlobalProxies

## proxy for httpclient
# if ($env:HTTP_PROXY) {
#     if ([Net.WebRequest]::DefaultWebProxy | Select-Object -ExpandProperty Address -ErrorAction SilentlyContinue) {
#         [Net.WebRequest]::DefaultWebProxy = New-Object Net.WebProxy("$env:HTTP_PROXY")
#     }

#     if ([Net.Http.HttpClient]::DefaultProxy | Select-Object -ExpandProperty Address -ErrorAction SilentlyContinue) {
#         [Net.Http.HttpClient]::DefaultProxy = New-Object Net.WebProxy("$env:HTTP_PROXY")
#     }
# } else {
#     [Net.WebRequest]::DefaultWebProxy = $null
#     [Net.Http.HttpClient]::DefaultProxy = New-Object Net.WebProxy($null)
# }

'@ | Tee-Object $PROFILE -Append | Out-Null
