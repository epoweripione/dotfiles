#Requires -RunAsAdministrator

if (-Not (Get-Command -Name "check_webservice_up" 2>$null)) {
    $CUSTOM_FUNCTION="$PSScriptRoot\ps_custom_function.ps1"
    if ((Test-Path "$CUSTOM_FUNCTION") -and ((Get-Item "$CUSTOM_FUNCTION").length -gt 0)) {
        . "$CUSTOM_FUNCTION"
    }
}

# socks proxy
if (-Not (check_webservice_up)) {
    $SOCKS_PROXY_ADDR = "127.0.0.1:7890"
    if($PROMPT_VALUE = Read-Host "Scoks proxy address for github download?[$($SOCKS_PROXY_ADDR)]") {
        $SOCKS_PROXY_ADDR = $PROMPT_VALUE
    }
    if (-Not (check_socks5_proxy_up $SOCKS_PROXY_ADDR)) {
        $SOCKS_PROXY_ADDR = ""
    }
}

# winget
# https://github.com/microsoft/winget-cli
if (-Not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing winget..." -ForegroundColor Blue
    $WINGET_PATH = "$TEMP\msixbundle.appxbundle"
    CHECK_URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $REMOTE_TAG = (Invoke-WebRequest -Uri $CHECK_URL | ConvertFrom-Json)[0].tag_name
    $DOWNLOAD_URL = "https://github.com/microsoft/winget-cli/releases/download/$REMOTE_TAG/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

    if (($null -eq $SOCKS_PROXY_ADDR) -or ($SOCKS_PROXY_ADDR -eq "")) {
        curl -fsL --connect-timeout 5 -o "$WINGET_PATH" "$DOWNLOAD_URL"
    } else {
        curl -fsL --connect-timeout 5 --socks5-hostname "$SOCKS_PROXY_ADDR" -o "$WINGET_PATH" "$DOWNLOAD_URL"
    }

    if ($?) {
        Add-AppxPackage -Path "$WINGET_PATH"
    }
}

if (Get-Command "winget" -ErrorAction SilentlyContinue) {
    Write-Host "Installing apps using winget..." -ForegroundColor Blue

    $Apps = @(
        # "Adobe.AdobeAcrobatReaderDC"
        # "AdrianAllard.FileConverter"
        # "AngusJohnson.ResourceHacker"
        # "Armin2208.WindowsAutoNightMode"
        # "Atlassian.Sourcetree"
        # "Balena.Etcher"
        # "Caphyon.AdvancedInstaller"
        "CopyTranslator.CopyTranslator"
        # "CrystalDewWorld.CrystalDiskInfo"
        # "CrystalDewWorld.CrystalDiskMark"
        # "Docker.DockerDesktop"
        # "ElectronCommunity.ElectronFiddle"
        # "Foxit.FoxitReader"
        # "Foxit.PhantomPDF"
        # "Git.Git"
        # "Git.GitLFS"
        # "GitExtensionsTeam.GitExtensions"
        # "GitHub.GitHubDesktop"
        # "Google.Chrome"
        # "Microsoft.Edge"
        # "Microsoft.PowerToys"
        # "Microsoft.PowerShell"
        # "Microsoft.Teams"
        "Microsoft.VisualStudioCode"
        # "Microsoft.WindowsAdminCenter"
        # "Microsoft.WindowsSDK"
        # "Microsoft.WindowsTerminal"
        # "Microsoft.dotNetFramework"
        # "Netease.CloudMusic"
        # "RealVNC.VNCViewer"
        # "Rufus.Rufus"
        "SVGExplorerExtension.SVGExplorerExtension"
        # "ShareX.ShareX"
        # "Signal.Signal"
        # "SimonTatham.Putty"
        # "Telerik.Fiddler"
        # "Tencent.WeChat"
        # "VMware.WorkstationPlayer"
        # "Videolan.Vlc"
        # "WinSCP.WinSCP"
        # "WiresharkFoundation.Wireshark"
        "Microsoft.VisualStudio.Enterprise"
    )

    foreach ($TargetApp in $Apps) {
        if (-Not ($InstalledApps -match "$TargetApp")) {
            Write-Host "Installing $TargetApp..." -ForegroundColor Blue
            winget install --id=$TargetApp --exact --rainbow
        }
    }
} else {
    Write-Host "Install apps using winget failed!"
}
