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

# winget
# https://github.com/microsoft/winget-cli
if (-Not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing winget..." -ForegroundColor Blue
    $WINGET_PATH = "$TEMP\msixbundle.appxbundle"
    $CHECK_URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $REMOTE_TAG = (Invoke-WebRequest -Uri $CHECK_URL | ConvertFrom-Json)[0].tag_name
    $DOWNLOAD_URL = "https://github.com/microsoft/winget-cli/releases/download/$REMOTE_TAG/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

    curl -fsL --connect-timeout 5 -o "$WINGET_PATH" "$DOWNLOAD_URL"
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
        "Hiddify.Next"
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
