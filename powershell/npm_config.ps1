
Param (
	[string]$ConfigAction = "AUTO"
)

if (-Not (Get-Command -Name "check_webservice_up" 2>$null)) {
    $CUSTOM_FUNCTION="$PSScriptRoot\ps_custom_function.ps1"
    if ((Test-Path "$CUSTOM_FUNCTION") -and ((Get-Item "$CUSTOM_FUNCTION").length -gt 0)) {
        . "$CUSTOM_FUNCTION"
    }
}

$UseMirror = $false
if (check_webservice_up) {
    $UseMirror = $true
}

if (($ConfigAction -eq "AUTO") -and $UseMirror) {
    Write-Host "Change npm registry to npmmirror.com..." -ForegroundColor Blue
    npm config set registry https://registry.npmmirror.com

    npm config set disturl https://npmmirror.com/dist # node-gyp
    npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass # node-sass
    npm config set electron_mirror https://npmmirror.com/mirrors/electron/ # electron
    npm config set puppeteer_download_host https://npmmirror.com/mirrors # puppeteer
    npm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver # chromedriver
    npm config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver # operadriver
    npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs # phantomjs
    npm config set selenium_cdnurl https://npmmirror.com/mirrors/selenium # selenium
    npm config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector # node-inspector
}

if ($ConfigAction -eq "RESET") {
    Write-Host "Reset npm registry (npmjs.org)..." -ForegroundColor Blue
    npm config set registry https://registry.npmjs.org/

    npm config delete disturl
    npm config delete sass_binary_site
    npm config delete electron_mirror
    npm config delete puppeteer_download_host
    npm config delete chromedriver_cdnurl
    npm config delete operadriver_cdnurl
    npm config delete phantomjs_cdnurl
    npm config delete selenium_cdnurl
    npm config delete node_inspector_cdnurl
}

npm config list
