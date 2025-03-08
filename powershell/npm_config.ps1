
Param (
	[string]$ConfigAction = "AUTO"
)

if (-Not (Get-Command -Name "check_webservice_up" 2>$null)) {
    $CUSTOM_FUNCTION="$PSScriptRoot\ps_custom_function.ps1"
    if ((Test-Path "$CUSTOM_FUNCTION") -and ((Get-Item "$CUSTOM_FUNCTION").length -gt 0)) {
        . "$CUSTOM_FUNCTION"
    }
}

$UseMirror = $true
if (check_webservice_up) {
    $UseMirror = $false
}

if (($ConfigAction -eq "AUTO") -and $UseMirror) {
    Write-Host "Change npm registry to npmmirror.com..." -ForegroundColor Blue
    npm config set registry https://registry.npmmirror.com

    # Add-Content "$env:USERPROFILE\.npmrc" "`ndisturl=https://npmmirror.com/dist" # node-gyp
    # Add-Content "$env:USERPROFILE\.npmrc" "`nsass_binary_site=https://npmmirror.com/mirrors/node-sass" # node-sass
    # Add-Content "$env:USERPROFILE\.npmrc" "`nelectron_mirror=https://npmmirror.com/mirrors/electron/" # electron
    # Add-Content "$env:USERPROFILE\.npmrc" "`npuppeteer_download_base_url=https://cdn.npmmirror.com/binaries/chrome-for-testing" # puppeteer
    # Add-Content "$env:USERPROFILE\.npmrc" "`nchromedriver_cdnurl=https://npmmirror.com/mirrors/chromedriver" # chromedriver
    # Add-Content "$env:USERPROFILE\.npmrc" "`noperadriver_cdnurl=https://npmmirror.com/mirrors/operadriver" # operadriver
    # Add-Content "$env:USERPROFILE\.npmrc" "`nphantomjs_cdnurl=https://npmmirror.com/mirrors/phantomjs" # phantomjs
    # Add-Content "$env:USERPROFILE\.npmrc" "`nselenium_cdnurl=https://npmmirror.com/mirrors/selenium" # selenium
    # Add-Content "$env:USERPROFILE\.npmrc" "`nnode_inspector_cdnurl=https://npmmirror.com/mirrors/node-inspector" # node-inspector
}

if ($ConfigAction -eq "RESET") {
    Write-Host "Reset npm registry (npmjs.org)..." -ForegroundColor Blue
    npm config set registry https://registry.npmjs.org/

    npm config delete disturl
    npm config delete sass_binary_site
    npm config delete electron_mirror
    npm config delete puppeteer_download_base_url
    npm config delete chromedriver_cdnurl
    npm config delete operadriver_cdnurl
    npm config delete phantomjs_cdnurl
    npm config delete selenium_cdnurl
    npm config delete node_inspector_cdnurl
}

npm config list
