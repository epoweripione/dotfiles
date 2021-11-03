#!/usr/bin/env bash

OS_TYPE=$(uname)
DOWNLOAD_URL=https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/hosts

[ -e ~/hosts ] && rm -f ~/hosts

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

if [[ $OS_TYPE == "Darwin" ]]; then
	curl "${CURL_DOWNLOAD_OPTS[@]}" $DOWNLOAD_URL -o ~/hosts && \
		[ -e /private/etc/hosts.orig ] || cp /private/etc/hosts /private/etc/hosts.orig && \
		cp /private/etc/hosts /etc/hosts.bak && \
		cp hosts /private/etc/hosts && \
		echo "hosts is up to date!"
elif [[ $OS_TYPE =~ "MSYS_NT" || $OS_TYPE =~ "MINGW" || $OS_TYPE =~ "CYGWIN_NT" ]]; then
	curl "${CURL_DOWNLOAD_OPTS[@]}" $DOWNLOAD_URL -o ~/hosts && \
		cp /c/Windows/System32/drivers/etc/hosts /c/Windows/System32/drivers/etc/hosts.bak && \
		rm -f /c/Windows/System32/drivers/etc/hosts && \
		cp ~/hosts /c/Windows/System32/drivers/etc/hosts && \
		winpty ipconfig -flushdns && \
		echo "hosts is up to date!"
else
	curl "${CURL_DOWNLOAD_OPTS[@]}" $DOWNLOAD_URL -o ~/hosts && \
		[ -e /etc/hosts.orig ] || cp /etc/hosts /etc/hosts.orig && \
		cp /etc/hosts /etc/hosts.bak && \
		cp hosts /etc/hosts && \
		echo "hosts is up to date!"
fi
