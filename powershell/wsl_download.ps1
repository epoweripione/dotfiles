# https://docs.microsoft.com/zh-cn/windows/wsl/install-manual
# https://ridicurious.com/2019/07/08/download-install-all-wsl-distros-with-powershell/
$URLs = "https://aka.ms/wsl-ubuntu-1804", `
        "https://aka.ms/wsl-debian-gnulinux"

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
foreach ($URL in $URLs) {
    $Filename = "$(Split-Path $URL -Leaf).appx"
    Write-Host "Downloading: $Filename" -Foreground Yellow -NoNewline
    try {
        Invoke-WebRequest -Uri $URL -OutFile $Filename -UseBasicParsing
        Add-AppxPackage -Path $Filename
        if ($?) {
            Write-Host " Done" -Foreground Green
        }
    } catch {
        Write-Host " Failed" -Foreground Red
    }
}