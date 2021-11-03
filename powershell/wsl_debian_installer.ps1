#Requires -RunAsAdministrator

# https://docs.microsoft.com/zh-cn/windows/wsl/wsl2-index
# https://docs.microsoft.com/zh-cn/windows/wsl/wsl2-install
# Please make sure that virtualization is enabled inside BIOS
# 1. run PowerShell as Admin
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
# Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
# 2. restart computer

# https://docs.microsoft.com/zh-cn/windows/wsl/install-manual
$WSL_NAME = "debian"
$WSL_URL = "https://aka.ms/wsl-debian-gnulinux"

$WSL_BASE_NAME = "$(Split-Path $WSL_URL -Leaf)"
$WSL_APPX_NAME = "$WSL_BASE_NAME.appx"
$WSL_ZIP_NAME = "$WSL_BASE_NAME.zip"

if (Get-Command "lxrunoffline" -ErrorAction SilentlyContinue) {
    # https://p3terx.com/archives/manage-wsl-with-lxrunoffline.html
    # https://www.jianshu.com/p/b68a28aa31a2
    Write-Host "Installing WSL by LxRunOffline..." -ForegroundColor Blue
    if (Test-Path "D:\") {
        $WSL_INSTALL_DIR = "D:\WSL\$WSL_NAME"
    } else {
        $WSL_INSTALL_DIR = "C:\WSL\$WSL_NAME"
    }
    if (-Not (Test-Path $WSL_INSTALL_DIR)) {
        New-Item -path $WSL_INSTALL_DIR -type Directory | Out-Null
    }

    curl -fsL -o "$WSL_APPX_NAME" "$WSL_URL"
    if ($?) {
        Rename-Item .\$WSL_APPX_NAME .\$WSL_ZIP_NAME
        Expand-Archive .\$WSL_ZIP_NAME .\$WSL_BASE_NAME

        lxrunoffline i -n "$WSL_NAME" -d "$WSL_INSTALL_DIR" -f ".\$WSL_BASE_NAME\install.tar.gz" -s

        Remove-Item .\$WSL_ZIP_NAME -Force -Confirm:$false
        Remove-Item .\$WSL_BASE_NAME -Recurse -Force -Confirm:$false
    }
} else {
    Write-Host "Installing WSL..." -ForegroundColor Blue
    # $ProgressPreference = 'SilentlyContinue'
    # Invoke-WebRequest -Uri $URL -OutFile $Filename -UseBasicParsing
    # Invoke-Item $FileName

    curl -fsL -o "$WSL_APPX_NAME" "$WSL_URL"
    if ($?) {
        Add-AppxPackage .\$WSL_APPX_NAME
        Remove-Item .\$WSL_APPX_NAME
    }
}