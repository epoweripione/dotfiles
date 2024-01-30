#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

App_Installer_Reset

# [Selenium_WebDriver](https://www.selenium.dev/documentation/webdriver/)
# [Run Selenium and Chrome on WSL2 using Python and Selenium webdriver](https://cloudbytes.dev/snippets/run-selenium-and-chrome-on-wsl2)
# [Setup Selenium and Chrome driver on ubuntu/debian](https://github.com/password123456/setup-selenium-with-chrome-driver-on-ubuntu_debian)
SELENIUM_INSTALL_DIR="$HOME/selenium"
mkdir -p "${SELENIUM_INSTALL_DIR}"

# ldd $HOME/selenium/chrome-linux64/chrome | grep not
if [[ -x "$(command -v pacman)" ]]; then
    # Pre-requisite packages
    PackagesList=(
        "ca-certificates"
        "fonts-liberation"
        "libappindicator3-1"
        "libasound2"
        "libatk-bridge2.0-0"
        "libatk1.0-0"
        "libc6"
        "libcairo2"
        "libcups2"
        "libdbus-1-3"
        "libexpat1"
        "libfontconfig1"
        "libgbm1"
        "libgcc1"
        "libglib2.0-0"
        "libgtk-3-0"
        "libnspr4"
        "libnss3"
        "libpango-1.0-0"
        "libpangocairo-1.0-0"
        "libstdc++6"
        "libx11-6"
        "libx11-xcb1"
        "libxcb1"
        "libxcomposite1"
        "libxcursor1"
        "libxdamage1"
        "libxext6"
        "libxfixes3"
        "libxi6"
        "libxrandr2"
        "libxrender1"
        "libxss1"
        "libxtst6"
        "lsb-release"
        "wget"
        "xdg-utils"
    )
    colorEcho "${FUCHSIA}  Android Studio${BLUE}: Checking Pre-requisite packages..."
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi

SELENIUM_DRIVER_URL="https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"

INSTALLER_APP_NAME="Chrome for Testing"
if App_Installer_Get_Remote_URL "${SELENIUM_DRIVER_URL}" "jq=.channels.Stable.downloads.chrome[].url" "jq=.channels.Stable.version"; then
    if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}" "${WORKDIR}/chrome-test.zip" "${SELENIUM_INSTALL_DIR}"; then
        SELENIUM_CHROME=$(find "${SELENIUM_INSTALL_DIR}" -type f -name "chrome" | head -n1)
        if [[ -n "${SELENIUM_CHROME}" ]]; then
            colorEcho "${GREEN}  Installed: ${YELLOW}${SELENIUM_CHROME}"
            "${SELENIUM_CHROME}" --version
        fi
    fi
fi

INSTALLER_APP_NAME="Chromedriver"
if App_Installer_Get_Remote_URL "${SELENIUM_DRIVER_URL}" "jq=.channels.Stable.downloads.chromedriver[].url" "jq=.channels.Stable.version"; then
    if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}" "${WORKDIR}/chrome-driver.zip" "${SELENIUM_INSTALL_DIR}"; then
        SELENIUM_CHROME_DRIVER=$(find "${SELENIUM_INSTALL_DIR}" -type f -name "chromedriver" | head -n1)
        if [[ -n "${SELENIUM_CHROME_DRIVER}" ]]; then
            colorEcho "${GREEN}  Installed: ${YELLOW}${SELENIUM_CHROME_DRIVER}"
            "${SELENIUM_CHROME_DRIVER}" --version
        fi
    fi
fi

if [[ -f "${SELENIUM_CHROME}" ]]; then
    ldd "${SELENIUM_CHROME}" | grep not
fi
