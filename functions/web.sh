#!/usr/bin/env bash

# Run Chrome Headless docker images built upon alpine official image
# https://github.com/Zenika/alpine-chrome
function run_chrome_headless() {
    local seccomp_file="$HOME/chrome_headless_seccomp.json"
    local download_url="https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json"

    [[ ! -s "${seccomp_file}" ]] && curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${seccomp_file}" "${download_url}"

    if [[ -s "$HOME/chrome_headless_seccomp.json" ]]; then
        docker run -d --name alpine-chrome --security-opt seccomp="${seccomp_file}" zenika/alpine-chrome
    else
        docker run -d --name alpine-chrome --cap-add=SYS_ADMIN zenika/alpine-chrome
    fi
}

function run_chrome_headless_with_puppeteer() {
    local js_path=$1
    local seccomp_file="$HOME/chrome_headless_seccomp.json"
    local download_url="https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json"

    [[ ! -s "${seccomp_file}" ]] && curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${seccomp_file}" "${download_url}"

    [[ -z "${js_path}" ]] && js_path="$HOME/.dotfiles/nodejs"
    if [[ -s "$HOME/chrome_headless_seccomp.json" ]]; then
        docker run -d --name alpine-chrome -v "${js_path}":/usr/src/app/ --security-opt seccomp="${seccomp_file}" zenika/alpine-chrome:with-puppeteer
    else
        docker run -d --name alpine-chrome -v "${js_path}":/usr/src/app/ --cap-add=SYS_ADMIN zenika/alpine-chrome:with-puppeteer
    fi
}
