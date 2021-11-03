#!/usr/bin/env bash

# https://github.com/valtron/llvm-stuff/wiki/Set-up-Windows-dev-environment-with-MSYS2
# https://github.com/git-for-windows/git/wiki/Install-inside-MSYS2-proper

# Open an MSYS2 terminal.
# Edit /etc/pacman.conf and just before [mingw32], add the git-for-windows packages repository:
# and optionally also the MINGW-only repository for the opposite architecture (i.e. MINGW32 for 64-bit SDK):
sed -i "/^\[mingw32\]/i\[git-for-windows]\nServer = https://wingit.blob.core.windows.net/x86-64\n" /etc/pacman.conf
sed -i "/^\[mingw32\]/i\[git-for-windows-mingw32]\nServer = https://wingit.blob.core.windows.net/i686\n" /etc/pacman.conf

# Authorize signing key (this step may have to be repeated occasionally until https://github.com/msys2/msys2/issues/62 is fixed)
curl -fsSL https://raw.githubusercontent.com/git-for-windows/build-extra/master/git-for-windows-keyring/git-for-windows.gpg | \
    pacman-key --add - && \
    pacman-key --lsign-key 1A9F3986

# Then synchronize new repository
pacboy update
# This updates msys2-runtime and therefore will ask you to close the window (not just exit the pacman process). Don't panic, simply close all currently open MSYS2 shells and MSYS2 programs. Once all are closed, start a new terminal again.

# Then synchronize again (updating the non-core part of the packages):
pacboy update

# And finally install the Git/cURL packages:
pacboy sync git:x git-doc-html:x git-doc-man:x git-extra: curl:x
# Finally, check that everything went well by doing git --version in a MINGW64 shell and it should output something like git version 2.14.1.windows.1 (or newer).

# pacmann-Sy git-extra mingw-w64-x86_64-git mingw-w64-x86_64-git-doc-html mingw-w64-x86_64-git-doc-man
