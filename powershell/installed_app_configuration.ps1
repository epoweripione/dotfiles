#Requires -RunAsAdministrator

if(!$env:SCOOP) {
    $env:SCOOP = "$env:USERPROFILE\scoop"
}

# Cherry Studio MCP depencency
if (Get-Command "$env:SCOOP\apps\cherry-studio\current\Cherry Studio.exe" -ErrorAction SilentlyContinue) {
    if (-Not (Test-Path "$env:USERPROFILE\.cherrystudio\bin\uv.exe")) {
        mkdir -p "$env:USERPROFILE\.cherrystudio\bin"
        sudo mklink "$env:USERPROFILE\.cherrystudio\bin\uv.exe" "$env:SCOOP\apps\uv\current\uv.exe"
        sudo mklink "$env:USERPROFILE\.cherrystudio\bin\uvx.exe" "$env:SCOOP\apps\uv\current\uvx.exe"
        sudo mklink "$env:USERPROFILE\.cherrystudio\bin\bun.exe" "$env:SCOOP\apps\bun\current\bun.exe"
    }
}

## Android Studio
# if (Get-Command "sdkmanager" -ErrorAction SilentlyContinue) {
#     # fix: java.lang.NoClassDefFoundError: javax/xml/bind/annotation/XmlSchema
#     # https://stackoverflow.com/questions/46402772/failed-to-install-android-sdk-java-lang-noclassdeffounderror-javax-xml-bind-a
#     $userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
#     $userenv = $userenv.TrimEnd(';')
#     [System.Environment]::SetEnvironmentVariable("PATH", "%ANDROID_HOME%\cmdline-tools\latest\bin;" + $userenv, 'User')
# }

if ( -Not (Get-Command "sdkmanager" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$HOME\AppData\Local\Android\Sdk\cmdline-tools\latest\bin") {
        $userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $userenv = $userenv.TrimEnd(';')
        [System.Environment]::SetEnvironmentVariable("PATH", "%USERPROFILE%\AppData\Local\Android\Sdk\cmdline-tools\latest\bin;" + $userenv, 'User')
    }
}

if ( -Not (Get-Command "adb" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$HOME\AppData\Local\Android\Sdk\platform-tools") {
        $userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $userenv = $userenv.TrimEnd(';')
        [System.Environment]::SetEnvironmentVariable("PATH", "%USERPROFILE%\AppData\Local\Android\Sdk\platform-tools;" + $userenv, 'User')
    } elseif (Test-Path "$env:SCOOP\apps\adb\current\platform-tools") {
        $userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $userenv = $userenv.TrimEnd(';')
        [System.Environment]::SetEnvironmentVariable("PATH", "%USERPROFILE%\scoop\apps\adb\current\platform-tools;" + $userenv, 'User')
    }
}

## [Unable to find bundled Java version on Flutter](https://stackoverflow.com/questions/51281702/unable-to-find-bundled-java-version-on-flutter)
# if (Test-Path "$env:SCOOP\apps\android-studio\current\jbr") {
#     if (-Not (Test-Path "$env:SCOOP\apps\android-studio\current\jre\java.exe")) {
#         Remove-Item -Path "$env:SCOOP\apps\android-studio\current\jre" -Recurse -Force -Confirm:$false
#         New-Item -ItemType SymbolicLink -Path "$env:SCOOP\apps\android-studio\current\jre" -Target "$env:SCOOP\apps\android-studio\current\jbr"
#     }
# }

## go
# if (Get-Command "go" -ErrorAction SilentlyContinue) {
#     go env -w GO111MODULE=auto
# }

# mirrors
if (-Not (check_webservice_up)) {
    if (Get-Command "go" -ErrorAction SilentlyContinue) {
        go env -w GOPROXY="https://goproxy.cn,direct"
        # go env -w GOPROXY="https://goproxy.io,direct"
        # go env -w GOPROXY="https://mirrors.aliyun.com/goproxy/,direct"
        # go env -w GOPROXY="https://proxy.golang.org,direct"

        # go env -w GOSUMDB="sum.golang.google.cn"
        # go env -w GOSUMDB="gosum.io+ce6e7565+AY5qEHUk/qmHc5btzW45JVoENfazw8LielDsaI+lEbq6"

        ## https://goproxy.io/zh/docs/goproxyio-private.html
        # go env -w GOPRIVATE="*.corp.example.com"
    }

    if (Get-Command "npm" -ErrorAction SilentlyContinue) {
        & "$PSScriptRoot\npm_config.ps1"
    }
}

# npm
if (Get-Command "npm" -ErrorAction SilentlyContinue) {
    if (-Not (Get-Command "pnpm" -ErrorAction SilentlyContinue)) {
        npm install -g npm-check pnpm pm2
    }
}

# pip
if (Get-Command "pip" -ErrorAction SilentlyContinue) {
    if (-Not (Get-Command "sqlfluff" -ErrorAction SilentlyContinue)) {
        pip install sqlfluff
    }

}

# cargo
if (Get-Command "cargo" -ErrorAction SilentlyContinue) {
    if (-Not (Get-Command "cargo-install-update" -ErrorAction SilentlyContinue)) {
        if (Get-Command -Name "cargo-binstall" -ErrorAction SilentlyContinue) {
            cargo binstall --no-confirm "cargo-update"
        } else {
            cargo install "cargo-update"
        }
    }
}
