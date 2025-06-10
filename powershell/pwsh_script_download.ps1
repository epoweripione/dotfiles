function check_webservice_up() {
    param($webservice_url)

    if (($null -eq $webservice_url) -or ($webservice_url -eq "")) {
        $webservice_url = "www.google.com"
    }

    curl -fsL --connect-timeout 3 --max-time 5 -I "$webservice_url"
    if ($?) {
        return $true
    } else {
        return $false
    }
}

function check_socks5_proxy_up() {
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $socks_proxy_url,
        [Parameter(Mandatory=$false, Position=1)]
        [string] $webservice_url
    )

    if (($webservice_url -eq $null) -or ($webservice_url -eq "")) {
        $webservice_url = "www.google.com"
    }

    curl -fsL --connect-timeout 3 --max-time 5 --socks5-hostname "$socks_proxy_url" -I "$webservice_url"
    if ($?) {
        return $true
    } else {
        return $false
    }
}


# socks proxy
$SOCKS_PROXY_ADDR = "127.0.0.1:7890"
if (-Not (check_webservice_up)) {
    if (-Not (check_socks5_proxy_up $SOCKS_PROXY_ADDR)) {
        if ($PROMPT_VALUE = Read-Host "Scoks proxy address for github download?[$($SOCKS_PROXY_ADDR)]") {
            $SOCKS_PROXY_ADDR = $PROMPT_VALUE
            if (-Not (check_socks5_proxy_up $SOCKS_PROXY_ADDR)) {
                $SOCKS_PROXY_ADDR = ""
            }
        } else {
            $SOCKS_PROXY_ADDR = ""
        }
    }
}


Set-Location ~

Write-Host "Downloading custom powershell scripts..." -ForegroundColor Blue
$DOWNLOAD_URL = "https://github.com/epoweripione/dotfiles/archive/refs/heads/main.zip"
if (($null -eq $SOCKS_PROXY_ADDR) -or ($SOCKS_PROXY_ADDR -eq "")) {
    curl -fsL -o ".\dotfiles.zip" "$DOWNLOAD_URL"
} else {
    curl -fsL --socks5-hostname "$SOCKS_PROXY_ADDR" -o ".\dotfiles.zip" "$DOWNLOAD_URL"
}

if ($?) {
    Write-Host "Extracting script files..." -ForegroundColor Blue
    Expand-Archive -Path ".\dotfiles.zip" -DestinationPath .
    Rename-Item -Path ".\dotfiles-main" -NewName ".\dotfiles"

    # Conda
    if (-Not (Test-Path "~\.condarc")) {
        Copy-Item -Path ".\dotfiles\conf\condarc" -Destination "~\.condarc"
    }

    # PIP
    if (-Not (Test-Path "~\.pip")) {
        Copy-Item -Path ".\dotfiles\conf\pip" -Destination "~\.pip"
    }

    # Rust Cargo
    if (-Not (Test-Path "~\.cargo")) {
        New-Item -path "~\.cargo" -type Directory | Out-Null
    }
    if (-Not (Test-Path "~\.cargo\config.toml")) {
        Copy-Item -Path ".\dotfiles\conf\cargo.toml" -Destination "~\.cargo\config.toml"

        (Get-Content "~\.cargo\config.toml").Replace("crates-io-sparse","rsproxy-sparse").Replace("# replace-with","replace-with") | Set-Content "~\.cargo\config.toml"
    }

    if (Test-Path "$env:CARGO_HOME") {
        if (-Not (Test-Path "$env:CARGO_HOME\config.toml")) {
            Copy-Item -Path ".\dotfiles\conf\cargo.toml" -Destination "$env:CARGO_HOME\config.toml"

            (Get-Content "$env:CARGO_HOME\config.toml").Replace("crates-io-sparse","rsproxy-sparse").Replace("# replace-with","replace-with") | Set-Content "$env:CARGO_HOME\config.toml"
        }
    }

    # Custom scripts
    $PWSH_DIR = "~\Documents\PowerShell\Scripts"
    if (-Not (Test-Path "$PWSH_DIR")) {New-Item -path "$PWSH_DIR" -type Directory | Out-Null}
    # Copy-Item -Path ".\dotfiles\powershell\*" -Destination "$PWSH_DIR" -Recurse -Force -Confirm:$false
    Copy-Item -Path ".\dotfiles\powershell\*.ps1" -Destination "$PWSH_DIR"
    Copy-Item -Path ".\dotfiles\wsl\*.ps1" -Destination "$PWSH_DIR"
    Copy-Item -Path ".\dotfiles\wsl\windows_terminal_profile.jsonc" -Destination "$PWSH_DIR"
    Copy-Item -Path ".\dotfiles\cross\hosts_accelerate_cn.list" -Destination "$PWSH_DIR"

    # PowerShell themes
    $CONFIG_DIR = "~\.config"
    if (-Not (Test-Path "$CONFIG_DIR")) {
        New-Item -path "$CONFIG_DIR" -type Directory | Out-Null
    }
    Copy-Item -Path ".\dotfiles\powershell\themes\starship.toml" -Destination "$CONFIG_DIR"

    $THEME_DIR = "~\Documents\PowerShell\PoshThemes"
    if (-Not (Test-Path "$THEME_DIR")) {New-Item -path "$THEME_DIR" -type Directory | Out-Null}
    Copy-Item -Path ".\dotfiles\powershell\themes\*.psm1" -Destination "$THEME_DIR"
    Copy-Item -Path ".\dotfiles\powershell\themes\*.json" -Destination "$THEME_DIR"

    # (Get-Content -path "~\Documents\PowerShell\PoshThemes\powerlevel10k_my.omp.json" -Raw) `
    #     -Replace '"type": "git",','"type": "poshgit",' `
    #     | Set-Content -Path "~\Documents\PowerShell\PoshThemes\powerlevel10k_my.omp.json"

    # WSL background images
    $IMAGE_DIR = "~\Pictures"
    Copy-Item -Path ".\dotfiles\wsl\*.jpg" -Destination "$IMAGE_DIR"

    # Clean up
    Write-Host "Cleaning up..." -ForegroundColor Blue
    Remove-Item -Path ".\dotfiles" -Recurse -Force -Confirm:$false
    Remove-Item -Path ".\dotfiles.zip" -Force -Confirm:$false
} else {
    Write-Host "Download custom powershell scripts failed!" -ForegroundColor Red
}
