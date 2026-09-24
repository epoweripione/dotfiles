if (Get-Process -Name "naive" -ErrorAction SilentlyContinue) {
    Stop-Process -Name "naive" -Force
}

$NaiveCMD = "naive.exe"
if (Get-Command "${NaiveCMD}" -ErrorAction SilentlyContinue) {
    $NaiveCMD = (Get-Command "${NaiveCMD}" -ErrorAction SilentlyContinue).Path
} else {
    if (Test-Path "$env:SystemDrive\Tools\naiveproxy\naive.exe") {
        $NaiveCMD = "$env:SystemDrive\Tools\naiveproxy\naive.exe"
    }
}

if (Get-Process -Name "mieru" -ErrorAction SilentlyContinue) {
    Stop-Process -Name "mieru" -Force
}

$MieruCMD = "mieru.exe"
if (Get-Command "${MieruCMD}" -ErrorAction SilentlyContinue) {
    $MieruCMD = (Get-Command "${MieruCMD}" -ErrorAction SilentlyContinue).Path
} else {
    if (Test-Path "$env:SystemDrive\Tools\mieru\mieru.exe") {
        $MieruCMD = "$env:SystemDrive\Tools\mieru\mieru.exe"
    }
}

if (Get-Process -Name "xray" -ErrorAction SilentlyContinue) {
    Stop-Process -Name "xray" -Force
}

$XRayCMD = "xray.exe"
$XRayVersion1 = "0.0.0"
if (Get-Command "${XRayCMD}" -ErrorAction SilentlyContinue) {
    $XRayCMD1 = (Get-Command "${XRayCMD}" -ErrorAction SilentlyContinue).Path
    $XRayVersion1 = (& "${XRayCMD1}" --version | Select-String '((?:\d{1,}\.)+\d{1,})' | ForEach-Object {$_.Matches[0].Groups[1].Value})
}

$XRayVersion2 = "0.0.0"
if (Test-Path "$env:SystemDrive\Tools\xray\xray.exe") {
    $XRayCMD2 = "$env:SystemDrive\Tools\xray\xray.exe"
    $XRayVersion2 = (& "${XRayCMD2}" --version | Select-String '((?:\d{1,}\.)+\d{1,})' | ForEach-Object {$_.Matches[0].Groups[1].Value})
}

if ([Version]$XRayVersion1 -lt [Version]$XRayVersion2){
    $XRayCMD = $XRayCMD2
} else {
    $XRayCMD = $XRayCMD1
}

## Load variables from local proxy env file
# NAIVEPROXY_PORT = 7895
# NAIVEPROXY_URL = @(
#     "https://user:password@test.com"
#     "https://user:password@example.com"
# )
if (Test-Path "$env:USERPROFILE\.proxy.env.ps1") {
    . "$env:USERPROFILE\.proxy.env.ps1"
} elseif (Test-Path "$env:SystemDrive\Tools\.proxy.env.ps1") {
    . "$env:SystemDrive\Tools\.proxy.env.ps1"
}

# naive
foreach ($TargetUrl in ${NAIVEPROXY_URL}) {
    # $NaiveArgs = "--listen=""socks://127.0.0.1:${NAIVEPROXY_PORT}"" --proxy=""${TargetUrl}"" --log=""$env:USERPROFILE\naive.${NAIVEPROXY_PORT}.log"""
    $NaiveArgs = "--listen=""socks://127.0.0.1:${NAIVEPROXY_PORT}"" --proxy=""${TargetUrl}"""

    Start-Process -FilePath "${NaiveCMD}" `
        -ArgumentList "${NaiveArgs}" `
        -WorkingDirectory "$env:USERPROFILE" `
        -WindowStyle "Hidden"

    ${NAIVEPROXY_PORT}++
}

# mieru
if ((Test-Path "${MieruCMD}") -and (Test-Path "$env:SystemDrive\Tools\mieru\mieru.json")) {
    # mieru.exe describe config

    # mieru.exe apply config "$env:SystemDrive\Tools\mieru\mieru.json"
    $MieruArgs = "apply config ""$env:SystemDrive\Tools\mieru\mieru.json"""
    Start-Process -FilePath "${MieruCMD}" `
        -ArgumentList "${MieruArgs}" `
        -WorkingDirectory "$env:USERPROFILE" `
        -WindowStyle "Hidden"

    # mieru stop; mieru start
    $MieruArgs = "start"
    Start-Process -FilePath "${MieruCMD}" `
        -ArgumentList "${MieruArgs}" `
        -WorkingDirectory "$env:USERPROFILE" `
        -WindowStyle "Hidden"
}

# xray
if ((Test-Path "${XRayCMD}") -and (Test-Path "$env:SystemDrive\Tools\xray\xray.json")) {
    # xray.exe run -c="$env:SystemDrive\Tools\xray\xray.json"
    $XRayArgs = "run -c=""$env:SystemDrive\Tools\xray\xray.json"""
    Start-Process -FilePath "${XRayCMD}" `
        -ArgumentList "${XRayArgs}" `
        -WorkingDirectory "$env:USERPROFILE" `
        -WindowStyle "Hidden"
}

<#
# Make WLAN Interface first
if (Get-NetIPInterface | Where-Object { $_.InterfaceAlias -eq 'WLAN' }) {
    Get-NetIPInterface | Where-Object { $_.InterfaceAlias -eq 'WLAN' } | `
        Select-Object 'ifIndex' -Unique | `
        ForEach-Object {
            Set-NetIPInterface -InterfaceIndex $_.ifIndex -InterfaceMetric 10
        }
}
#>
