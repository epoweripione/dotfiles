Param (
	[switch]$UseAria2,
	[string]$AppsInstallDir = ""
)

if (-Not (Get-Command -Name "check_webservice_up" 2>$null)) {
    $CUSTOM_FUNCTION="$PSScriptRoot\ps_custom_function.ps1"
    if ((Test-Path "$CUSTOM_FUNCTION") -and ((Get-Item "$CUSTOM_FUNCTION").length -gt 0)) {
        . "$CUSTOM_FUNCTION"
    }
}

# proxy
$SCOOP_PROXY_ADDR = "127.0.0.1:7890"
if (-Not (check_socks5_proxy_up $SCOOP_PROXY_ADDR)) {
    $SCOOP_PROXY_ADDR = ""
    if ($PROMPT_VALUE = Read-Host "Proxy address for scoop?") {
        $SCOOP_PROXY_ADDR = $PROMPT_VALUE
    }
}

# Scoop
# https://scoop.sh/
if (-Not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing scoop..." -ForegroundColor Blue

    # https://github.com/lukesampson/scoop/wiki/Quick-Start
    ## If you're behind a proxy you might need to run one or more of these commands first:
    ## If you want to use a proxy that isn't already configured in Internet Options
    # [net.webrequest]::defaultwebproxy = new-object net.webproxy "http://proxy.example.org:8080"
    ## If you want to use the Windows credentials of the logged-in user to authenticate with your proxy
    # [net.webrequest]::defaultwebproxy.credentials = [net.credentialcache]::defaultcredentials
    ## If you want to use other credentials (replace 'username' and 'password')
    # [net.webrequest]::defaultwebproxy.credentials = new-object net.networkcredential 'username', 'password'

    if (-Not (($null -eq $SCOOP_PROXY_ADDR) -or ($SCOOP_PROXY_ADDR -eq ""))) {
        [net.webrequest]::defaultwebproxy = new-object net.webproxy "http://$SCOOP_PROXY_ADDR"
    }

    Set-ExecutionPolicy RemoteSigned -scope CurrentUser

    if (-Not (($null -eq $AppsInstallDir) -or ($AppsInstallDir -eq ""))) {
        $AppsInstallDir = "$AppsInstallDir".trim("\")
        if (-Not (Test-Path "$AppsInstallDir")) {
            New-Item -path "$AppsInstallDir" -type Directory | Out-Null
        }

        $env:SCOOP = "$AppsInstallDir"
        $env:SCOOP_GLOBAL = "$AppsInstallDir\globalApps"
        [environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')
        [environment]::setEnvironmentVariable('SCOOP_GLOBAL',$env:SCOOP_GLOBAL,'Machine')
    }

    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    # Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression

    # scoop install -g <app>
}

if (Get-Command "scoop" -ErrorAction SilentlyContinue) {
    Write-Host "Installing apps using scoop..." -ForegroundColor Blue

    ## scoop config proxy [username:password@]host:port
    ## Use your Windows credentials with the default proxy configured in Internet Options
    # scoop config proxy currentuser@default
    ## Use hard-coded credentials with the default proxy configured in Internet Options
    # scoop config proxy user:password@default
    ## Use a proxy that isn't configured in Internet Options
    # scoop config proxy proxy.example.org:8080
    # scoop config proxy username:password@proxy.example.org:8080
    ## Bypassing the proxy configured in Internet Options
    # scoop config rm proxy

    if (-Not (($null -eq $SCOOP_PROXY_ADDR) -or ($SCOOP_PROXY_ADDR -eq ""))) {
        scoop config proxy $SCOOP_PROXY_ADDR
    }

    if (-Not (Get-Command "git" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing git..." -ForegroundColor Blue
        scoop install git
    }

    if (-Not (Get-Command "delta" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing delta..." -ForegroundColor Blue
        scoop install delta
    }

    # git global config
    if (Get-Command "git" -ErrorAction SilentlyContinue) {
        Write-Host "Setting git global config..." -ForegroundColor Blue
        & "$PSScriptRoot\git_global_config.ps1" -Proxy "$SCOOP_PROXY_ADDR"
    }

    if (-Not (Get-Command "aria2c" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing aria2..." -ForegroundColor Blue
        scoop install aria2
    }

    scoop config aria2-warning-enabled false
    if ($UseAria2) {
        scoop config aria2-enabled true
    } else {
        scoop config aria2-enabled false
    }

    if (-Not (Get-Command "sudo" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing sudo..." -ForegroundColor Blue
        scoop install sudo
    }

    Write-Host "Adding scoop buckets..." -ForegroundColor Blue
    # list all known buckets
    # scoop bucket known

    # Scoop buckets by Github score
    # https://rasa.github.io/scoop-directory/by-score
    $Buckets = @(
        "extras"
        "versions"
        "nerd-fonts"
        "java"
        "nirsoft"
        "dorado"
        # "dodorz"
        "epower"
        "nonportable"
        # "jetbrains"
        # "php"
        # "games"
    )

    $BucketsURL = @(
        ""
        ""
        ""
        ""
        ""
        "https://github.com/h404bi/dorado"
        # "https://github.com/dodorz/scoop-bucket"
        "https://github.com/epoweripione/scoop-bucket"
        ""
        ""
        # ""
        # ""
    )

    $AddedBuckets = scoop bucket list 6>&1 | Out-String
    for ($i = 0; $i -lt $Buckets.Count; $i++) {
        $TargetBucket = $Buckets[$i]
        $TargetBucketURL = $BucketsURL[$i]
        if (-Not ($AddedBuckets -match "$TargetBucket")) {
            Write-Host "Adding $TargetBucket..." -ForegroundColor Blue
            if (($null -eq $TargetBucketURL) -or ($TargetBucketURL -eq "")) {
                scoop bucket add $TargetBucket
            } else {
                scoop bucket add $TargetBucket $TargetBucketURL
            }
        }
    }

    Write-Host "Updating scoop..." -ForegroundColor Blue
    scoop update
    # scoop update *

    $Apps = @(
        "vcredist"
        "hub"
        "less"
        "oh-my-posh"
        "starship"
        # "googlechrome-dev"
        # "chromium"
        # "tor-browser-zh-cn"
        "firefox-zh-cn"
        "speedyfox"
        # "android-sdk"
        # "android-studio"
        # "flutter"
        "go"
        "rustup"
        "nodejs-lts"
        # "dotnet-sdk"
        "zulu17-jdk"
        # "zulu11-jdk"
        # "zulu11-jre"
        "python"
        "php"
        "composer"
        "cacert"
        "beekeeper-studio"
        "dbeaver"
        "dbgate"
        "krita"
        "obs-studio"
        # "geany"
        # "geany-plugins"
        # "notepad3"
        "notepadplusplus"
        # "vscode"
        # "wechatdevtools"
        "wireshark"
        # "babelmap"
        "nexusfont"
        "colortool"
        # "windowsterminal"
        "clash-for-windows"
        "clash-verge"
        # "trojan"
        "frp"
        # "v2rayn"
        # "lxrunoffline"
        "bulk-rename-utility"
        "fastcopy"
        "snipaste-beta"
        "ffmpeg"
        "listen1desktop"
        "mpc-be"
        "vlc"
        "potplayer"
        "captura"
        "quicklook"
        "screentogif"
        "aida64extreme"
        "cpu-z"
        "as-ssd"
        "crystaldiskinfo"
        "crystaldiskmark"
        # "crystaldiskinfo-shizuku-edition"
        # "crystaldiskmark-shizuku-edition"
        "onefetch"
        "winfetch"
        "diffinity"
        "winmerge"
        "everything"
        "filezilla"
        "freedownloadmanager"
        "hashcheck"
        "motrix"
        # "powertoys"
        "q-dir"
        "sumatrapdf"
        "syncback"
        "syncthing"
        "syncthingtray"
        # "sysinternals"
        # "utools"
        "ghostscript"
        "xnresize"
        "xnviewmp"
        # "telegram"
        # "cdburnerxp"
        # "wincdemu"
        "windowsupdateshistoryviewer"
        "ventoy"
        "cht"
        "fzf"
        "ag"
        "bat"
        "bottom"
        "broot"
        "cloc"
        "croc"
        "dasel"
        "duf"
        "dust"
        "fd"
        "file"
        "gping"
        "host-editor"
        "lsd"
        "mkcert"
        "nu"
        "openark"
        "procs"
        "smartmontools"
        "usql"
        "wget"
        "win32yank"
        "winmtr"
        "zoxide"
        "jq"
        "yq"
        # "trafficmonitor"
        "treesize-free"
        # "windterm"
        ## Diagram
        "graphviz"
        "plantuml"
        "draw.io"
        "yed"
        ## markdown editor
        "anki"
        "pandoc"
        "marktext"
        "notable"
        "typora"
        ## VNC/RDP
        "rustdesk"
        # "tightvnc"
        "vncviewer"
        ## k8s
        "openlens"
        ## images & videos
        "darktable"
        ## epower
        "chromium-justclueless-dev-avx2"
        # "chromium-robrich-dev-avx2"
        # "chromium-robrich-dev"
        # "ExplorerPlusPlus"
        # "TablacusExplorer"
        # "HBuilderXFull"
        "UniExtract2"
        "NewFileTime"
        # "notepad2-zufuliu"
        # "WiseCare365"
        "WiseDataRecovery"
        "WiseDiskCleaner"
        "WiseProgramUninstaller"
        "WiseRegistryCleaner"
        ## https://github.com/lukesampson/scoop/wiki/Theming-Powershell
        # "concfg"
    )

    $sudoApps = @(
        "dotnet-desktop-runtime"
        "file-converter-np"
        # "nmap"
    )

    $sudoFonts = @(
        "Cascadia-Code"
        ## epower
        "NotoSans-CJK"
        "NotoSerif-CJK"
        "FiraCode-Mono-NF"
        "Sarasa-Gothic-SC"
        ## nerd-fonts
        # "FiraCode-NF"
        # "FiraMono-NF"
        # "SarasaGothic-SC"
        "JetBrainsMono-NF"
        "CascadiaCode-NF"
        # "Noto-NF"
        "LXGWWenKai"
        "LXGWWenKaiMono"
    )

    # Use list file if exists
    if (Test-Path "$PSScriptRoot\scoop_install_apps.list") {
        # $Apps = [System.IO.File]::ReadAllLines("$PSScriptRoot\scoop_install_apps.list")
        $Apps = Get-Content -Path "$PSScriptRoot\scoop_install_apps.list"
    }

    if (Test-Path "$PSScriptRoot\scoop_install_apps_sudo.list") {
        # $sudoApps = [System.IO.File]::ReadAllLines("$PSScriptRoot\scoop_install_apps_sudo.list")
        $sudoApps = Get-Content -Path "$PSScriptRoot\scoop_install_apps_sudo.list"
    }

    # Remove failed installed apps
    $InstalledApps = scoop list 6>&1 | Out-String
    $InstalledApps = $InstalledApps -replace "`r`n"," " -replace "    "," " -replace "   "," " -replace "  "," "
    foreach ($TargetApp in $Apps) {
        if ($InstalledApps -match "$TargetApp \*failed\*") {
            Write-Host "Uninstalling $TargetApp..." -ForegroundColor Blue
            scoop uninstall $TargetApp
            scoop cache rm $TargetApp
        }
    }

    $InstalledApps = scoop list 6>&1 | Out-String
    $InstalledApps = $InstalledApps -replace "`r`n"," " -replace "    "," " -replace "   "," " -replace "  "," "

    foreach ($TargetApp in $Apps) {
        if (-Not ($InstalledApps -match "$TargetApp")) {
            Write-Host "Installing $TargetApp..." -ForegroundColor Blue
            scoop install $TargetApp
        }
    }

    foreach ($TargetApp in $sudoApps) {
        if (-Not ($InstalledApps -match "$TargetApp")) {
            Write-Host "Installing $TargetApp..." -ForegroundColor Blue
            sudo scoop install $TargetApp
        }
    }

    foreach ($TargetApp in $sudoFonts) {
        if (-Not ($InstalledApps -match "$TargetApp")) {
            Write-Host "Installing $TargetApp..." -ForegroundColor Blue
            sudo scoop install -g $TargetApp
        }
    }

    # scoop install zulu11
    # scoop install openedfilesview
    # scoop install python27
    # scoop install dorado/miniconda3

    # if (-Not (($null -eq $SCOOP_PROXY_ADDR) -or ($SCOOP_PROXY_ADDR -eq ""))) {
    #     scoop config rm proxy
    # }

    scoop config aria2-enabled true
} else {
    Write-Host "Install apps using scoop failed!"
}


## Bucket Operations
## Check update for all apps in bucket
# .\bin\checkver.ps1 -App * -Update
## Push updates directly to 'origin master'
# .\bin\auto-pr.ps1 -Push -SkipUpdated


# https://github.com/lukesampson/scoop/wiki/Custom-PHP-configuration
if (Get-Command "php" -ErrorAction SilentlyContinue) {

}

# flutter
if (Get-Command "flutter" -ErrorAction SilentlyContinue) {
    # fix: Cannot find Chrome executable at google-chrome
    if (Test-Path "$env:USERPROFILE\AppData\Local\Google\Chrome SxS\Application\chrome.exe") {
        [System.Environment]::SetEnvironmentVariable("CHROME_EXECUTABLE","$env:USERPROFILE\AppData\Local\Google\Chrome SxS\Application\chrome.exe",'User')
    } elseif (Test-Path "$env:USERPROFILE\AppData\Local\Google\Chrome Dev\Application\chrome.exe") {
        [System.Environment]::SetEnvironmentVariable("CHROME_EXECUTABLE","$env:USERPROFILE\AppData\Local\Google\Chrome Dev\Application\chrome.exe",'User')
    } elseif (Test-Path "$env:USERPROFILE\AppData\Local\Google\Chrome Beta\Application\chrome.exe") {
        [System.Environment]::SetEnvironmentVariable("CHROME_EXECUTABLE","$env:USERPROFILE\AppData\Local\Google\Chrome Beta\Application\chrome.exe",'User')
    } elseif (Test-Path "$env:USERPROFILE\AppData\Local\Google\Chrome\Application\chrome.exe") {
        [System.Environment]::SetEnvironmentVariable("CHROME_EXECUTABLE","$env:USERPROFILE\AppData\Local\Google\Chrome\Application\chrome.exe",'User')
    } elseif (Test-Path "$env:USERPROFILE\AppData\Local\Google\Chromium\Application\chrome.exe") {
        [System.Environment]::SetEnvironmentVariable("CHROME_EXECUTABLE","$env:USERPROFILE\AppData\Local\Google\Chromium\Application\chrome.exe",'User')
    }
    # mirror
    [System.Environment]::SetEnvironmentVariable("FLUTTER_STORAGE_BASE_URL","https://storage.flutter-io.cn",'User')
    [System.Environment]::SetEnvironmentVariable("PUB_HOSTED_URL","https://pub.flutter-io.cn",'User')
}

# go
if (Get-Command "go" -ErrorAction SilentlyContinue) {
    go env -w GO111MODULE=auto
}

# mirrors
if (-Not (check_webservice_up)) {
    if (Get-Command "go" -ErrorAction SilentlyContinue) {
        go env -w GOPROXY="https://goproxy.cn,direct"
        # go env -w GOPROXY="https://goproxy.io,direct"
        # go env -w GOPROXY="https://mirrors.aliyun.com/goproxy/,direct"
        # go env -w GOPROXY="https://proxy.golang.org,direct"

        go env -w GOSUMDB="sum.golang.google.cn"
        # go env -w GOSUMDB="gosum.io+ce6e7565+AY5qEHUk/qmHc5btzW45JVoENfazw8LielDsaI+lEbq6"

        ## https://goproxy.io/zh/docs/goproxyio-private.html
        # go env -w GOPRIVATE="*.corp.example.com"
    }

    if (Get-Command "npm" -ErrorAction SilentlyContinue) {
        & "$PSScriptRoot\npm_config.ps1"
    }
}


# Write-Host "Done." -ForegroundColor Blue