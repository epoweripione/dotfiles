
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

    [System.Environment]::SetEnvironmentVariable("CHROMEDRIVER_CDNURL", 'https://cdn.npmmirror.com/binaries/chromedriver', 'User')
    [System.Environment]::SetEnvironmentVariable("COREPACK_NPM_REGISTRY", 'https://registry.npmmirror.com', 'User')
    [System.Environment]::SetEnvironmentVariable("CYPRESS_DOWNLOAD_PATH_TEMPLATE", 'https://cdn.npmmirror.com/binaries/cypress/${version}/${platform}-${arch}/cypress.zip', 'User')
    [System.Environment]::SetEnvironmentVariable("EDGEDRIVER_CDNURL", 'https://npmmirror.com/mirrors/edgedriver', 'User')
    [System.Environment]::SetEnvironmentVariable("ELECTRON_BUILDER_BINARIES_MIRROR", 'https://cdn.npmmirror.com/binaries/electron-builder-binaries/', 'User')
    [System.Environment]::SetEnvironmentVariable("ELECTRON_MIRROR", 'https://cdn.npmmirror.com/binaries/electron/', 'User')
    [System.Environment]::SetEnvironmentVariable("NODEJS_ORG_MIRROR", 'https://cdn.npmmirror.com/binaries/node', 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_better_sqlite3_binary_host", 'https://cdn.npmmirror.com/binaries/better-sqlite3', 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_gl_binary_host", 'https://cdn.npmmirror.com/binaries/gl', 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_keytar_binary_host", 'https://cdn.npmmirror.com/binaries/keytar', 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_robotjs_binary_host", 'https://cdn.npmmirror.com/binaries/robotjs', 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_sharp_binary_host", 'https://cdn.npmmirror.com/binaries/sharp', 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_sharp_libvips_binary_host", 'https://cdn.npmmirror.com/binaries/sharp-libvips', 'User')
    [System.Environment]::SetEnvironmentVariable("NVM_NODEJS_ORG_MIRROR", 'https://cdn.npmmirror.com/binaries/node', 'User')
    [System.Environment]::SetEnvironmentVariable("NWJS_URLBASE", 'https://cdn.npmmirror.com/binaries/nwjs/v', 'User')
    [System.Environment]::SetEnvironmentVariable("OPERADRIVER_CDNURL", 'https://cdn.npmmirror.com/binaries/operadriver', 'User')
    [System.Environment]::SetEnvironmentVariable("PHANTOMJS_CDNURL", 'https://cdn.npmmirror.com/binaries/phantomjs', 'User')
    [System.Environment]::SetEnvironmentVariable("PLAYWRIGHT_DOWNLOAD_HOST", 'https://cdn.npmmirror.com/binaries/playwright', 'User')
    [System.Environment]::SetEnvironmentVariable("PRISMA_ENGINES_MIRROR", 'https://cdn.npmmirror.com/binaries/prisma', 'User')
    [System.Environment]::SetEnvironmentVariable("PUPPETEER_CHROME_DOWNLOAD_BASE_URL", 'https://cdn.npmmirror.com/binaries/chrome-for-testing', 'User')
    [System.Environment]::SetEnvironmentVariable("PUPPETEER_CHROME_HEADLESS_SHELL_DOWNLOAD_BASE_URL", 'https://cdn.npmmirror.com/binaries/chrome-for-testing', 'User')
    [System.Environment]::SetEnvironmentVariable("PUPPETEER_DOWNLOAD_BASE_URL", 'https://cdn.npmmirror.com/binaries/chrome-for-testing', 'User')
    [System.Environment]::SetEnvironmentVariable("PUPPETEER_DOWNLOAD_HOST", 'https://cdn.npmmirror.com/binaries/chrome-for-testing', 'User')
    [System.Environment]::SetEnvironmentVariable("RE2_DOWNLOAD_MIRROR", 'https://cdn.npmmirror.com/binaries/node-re2', 'User')
    [System.Environment]::SetEnvironmentVariable("RE2_DOWNLOAD_SKIP_PATH", 'true', 'User')
    [System.Environment]::SetEnvironmentVariable("SASS_BINARY_SITE", 'https://cdn.npmmirror.com/binaries/node-sass', 'User')
    [System.Environment]::SetEnvironmentVariable("SAUCECTL_INSTALL_BINARY_MIRROR", 'https://cdn.npmmirror.com/binaries/saucectl', 'User')
    [System.Environment]::SetEnvironmentVariable("SENTRYCLI_CDNURL", 'https://cdn.npmmirror.com/binaries/sentry-cli', 'User')
    [System.Environment]::SetEnvironmentVariable("SWC_BINARY_SITE", 'https://cdn.npmmirror.com/binaries/node-swc', 'User')
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

    [System.Environment]::SetEnvironmentVariable("CHROMEDRIVER_CDNURL", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("COREPACK_NPM_REGISTRY", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("CYPRESS_DOWNLOAD_PATH_TEMPLATE", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("EDGEDRIVER_CDNURL", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("ELECTRON_BUILDER_BINARIES_MIRROR", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("ELECTRON_MIRROR", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("NODEJS_ORG_MIRROR", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_better_sqlite3_binary_host", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_gl_binary_host", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_keytar_binary_host", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_robotjs_binary_host", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_sharp_binary_host", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("npm_config_sharp_libvips_binary_host", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("NVM_NODEJS_ORG_MIRROR", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("NWJS_URLBASE", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("OPERADRIVER_CDNURL", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("PHANTOMJS_CDNURL", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("PLAYWRIGHT_DOWNLOAD_HOST", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("PRISMA_ENGINES_MIRROR", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("PUPPETEER_CHROME_DOWNLOAD_BASE_URL", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("PUPPETEER_CHROME_HEADLESS_SHELL_DOWNLOAD_BASE_URL", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("PUPPETEER_DOWNLOAD_BASE_URL", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("PUPPETEER_DOWNLOAD_HOST", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("RE2_DOWNLOAD_MIRROR", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("RE2_DOWNLOAD_SKIP_PATH", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("SASS_BINARY_SITE", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("SAUCECTL_INSTALL_BINARY_MIRROR", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("SENTRYCLI_CDNURL", [NullString]::Value, 'User')
    [System.Environment]::SetEnvironmentVariable("SWC_BINARY_SITE", [NullString]::Value, 'User')
}

npm config list
