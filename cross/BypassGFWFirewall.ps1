if (Get-Process -Name "naive" -ErrorAction SilentlyContinue) {
    Stop-Process -Name "naive" -Force
}

$NaiveCMD = "naive.exe"
if (-Not (Get-Command "${NaiveCMD}" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$env:SystemDrive\Tools\naiveproxy\naive.exe") {
        $NaiveCMD = "$env:SystemDrive\Tools\naiveproxy\naive.exe"
    }
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

foreach ($TargetUrl in ${NAIVEPROXY_URL}) {
    $NaiveArgs = "--listen=""socks://127.0.0.1:${NAIVEPROXY_PORT}"" --proxy=""${TargetUrl}"""

    Start-Process -FilePath "${NaiveCMD}" `
        -ArgumentList "${NaiveArgs}" `
        -WorkingDirectory "$env:USERPROFILE" `
        -WindowStyle "Hidden"

    ${NAIVEPROXY_PORT}++
}
