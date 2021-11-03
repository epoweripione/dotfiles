#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

# https://github.com/chrislim2888/IP2Location-C-Library
install_ip2location_c() {
    Git_Clone_Update_Branch "chrislim2888/IP2Location-C-Library" "$HOME/IP2Location-C-Library"
    if [[ -d "$HOME/IP2Location-C-Library" ]]; then
        cd "$HOME/IP2Location-C-Library" && \
            sudo autoreconf -i -v --force && \
            sudo ./configure >/dev/null && sudo make >/dev/null && sudo make install >/dev/null && \
            cd data && perl ip-country.pl
    fi

    # Compile ip2locationLatLong
    if [[ -s "$HOME/ip2locationLatLong.c" ]]; then
        cd "$HOME" && \
            gcc ip2locationLatLong.c \
            -I /usr/local/include \
            -L /usr/local/lib -l IP2Location \
            -o ip2locationLatLong
    fi
}

# https://www.ip2location.com/development-libraries/ip2location/python
install_ip2location_python() {
    # https://github.com/chrislim2888/IP2Location-Python
    Git_Clone_Update_Branch "chrislim2888/IP2Location-Python" "$HOME/IP2Location-Python"
    if [[ -d "$HOME/IP2Location-C-Library" ]]; then
        cd "$HOME/IP2Location-C-Library" && \
            python setup.py build && \
            python setup.py install
    fi
}

# https://lite.ip2location.com/ip2location-lite
download_ip2location_db() {
    # Use your unique download token to download IP2Location databases
    local DOWNLOAD_TOKEN
    local DATABASE_CODE="DB5LITEBIN"

    echo "IP2Location IPv4 Database https://lite.ip2location.com/ip2location-lite"
    echo -n "Download Token? "
    read -r DOWNLOAD_TOKEN

    [[ -z "$BIN_FILE" ]] && BIN_FILE="IP2LOCATION-LITE-DB5.BIN"

    if [[ -n "$DOWNLOAD_TOKEN" ]]; then
        wget -c -O "${WORKDIR}/${BIN_FILE}.zip" \
            "https://www.ip2location.com/download/?token=${DOWNLOAD_TOKEN}&file=${DATABASE_CODE}" && \
            unzip -qo "${WORKDIR}/${BIN_FILE}.zip" "IP2LOCATION-LITE-DB5.BIN" -d "$HOME" && \
            rm -f "${WORKDIR}/${BIN_FILE}.zip"
    else
        wget -c -O "${WORKDIR}/${BIN_FILE}.zip" \
            "https://www.ip2location.com/downloads/sample.bin.db5.zip" && \
            unzip -qo "${WORKDIR}/${BIN_FILE}.zip" \
                "IP-COUNTRY-REGION-CITY-LATITUDE-LONGITUDE-SAMPLE.BIN" \
                -d "$CURRENT_DIR" && \
            mv "$HOME/IP-COUNTRY-REGION-CITY-LATITUDE-LONGITUDE-SAMPLE.BIN" \
                "$HOME/$BIN_FILE"
    fi
}

#This is the location of bin file
#You must modify for your system
BIN_FILE="IP2LOCATION-LITE-DB5.BIN"


#ip2locationLatLong
# C-Library
if [[ ! -s "$HOME/ip2locationLatLong" ]]; then
    if [[ ! -x "$(command -v make)" ]]; then
        colorEcho "${FUCHSIA}make${RED} is not installed!"
        exit 1
    fi

    if [[ ! -x "$(command -v gcc)" ]]; then
        colorEcho "${FUCHSIA}gcc${RED} is not installed!"
        exit 1
    fi

    install_ip2location_c
fi

# python
if [[ -x "$(command -v pip)" ]]; then
    if pip list 2>/dev/null | grep -q 'IP2Location'; then
        install_ip2location_python
    fi
fi

# db
[[ ! -s "$CURRENT_DIR/$BIN_FILE" ]] && download_ip2location_db


cd "${CURRENT_DIR}" || exit
colorEcho "${GREEN}ip2locationLatLong installed!"