#!/usr/bin/env bash

PARAMS_NUM=$#

if [[ $PARAMS_NUM == 1 ]]; then
    MIRROR_SERVER="$1"
else
    # MIRROR_SERVER="https://mirrors.ustc.edu.cn"
    MIRROR_SERVER="https://mirrors.tuna.tsinghua.edu.cn"
fi

if grep -q "^## Primary" /etc/pacman.d/mirrorlist.mingw32 2>/dev/null; then
    LineBegin=$(cat -n /etc/pacman.d/mirrorlist.mingw32 | grep '## Primary' | awk '{print $1}')
fi

[[ -z "$LineBegin" ]] && LineBegin=1

sed -i "${LineBegin}a Server = ${MIRROR_SERVER}/msys2/mingw/i686\n" /etc/pacman.d/mirrorlist.mingw32 && \
    sed -i "${LineBegin}a Server = ${MIRROR_SERVER}/msys2/mingw/x86_64\n" /etc/pacman.d/mirrorlist.mingw64 && \
    sed -i "${LineBegin}a Server = ${MIRROR_SERVER}/msys2/msys/\$arch\n" /etc/pacman.d/mirrorlist.msys
