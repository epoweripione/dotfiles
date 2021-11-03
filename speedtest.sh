#!/usr/bin/env bash

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

# PageSpeed Insights
# https://developers.google.com/speed/pagespeed/insights/

# http://ping.chinaz.com/
# http://www.ipip.net/ping.php
# https://www.17ce.com/
# http://www.webkaka.com/
# http://ce.cloud.360.cn/
# 这几个在线测速工具各有各的优缺点，
# 推荐使用 ipip.net 测试服务器 IP 和路由追踪，
# 用 17ce.com 测试网页加载速度，
# 用 ping.chinaz.com 用国内不同地方的 Ping 值。

# bench.sh
# https://teddysun.com/444.html
function bench() {
    curl -Lso- bench.sh | bash
}

# Superbench.sh & SuperSpeed.sh
# https://www.oldking.net/305.html
function SuperBench() {
    curl -fsSL https://raw.githubusercontent.com/oooldking/script/master/superbench.sh | bash
}

function SuperSpeed() {
    curl -fsSL https://raw.githubusercontent.com/oooldking/script/master/superspeed.sh | bash
}

function Besttrack() {
    wget -qO- git.io/besttrace | bash
}

function ZBench() {
    wget -qO- https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh | bash
}

function LemonBenchFast() {
    curl -fsSL https://github.com/LemonBench/LemonBench/raw/master/LemonBench.sh | bash -s fast
}

function LemonBenchFull() {
    curl -fsSL https://github.com/LemonBench/LemonBench/raw/master/LemonBench.sh | bash -s full
}

function UnixBench() {
    curl -fsSL https://github.com/teddysun/across/raw/master/unixbench.sh | bash
}

echo -e ""
echo -e "1.bench.sh(teddysun)"
echo -e "2.SuperBench.sh(oldking)"
echo -e "3.SuperSpeed.sh(oldking)"
echo -e "4.Besttrack"
echo -e "5.ZBench-CN.sh"
echo -e "6.LemonBench.sh(Fast)"
echo -e "7.LemonBench.sh(Full)"
echo -e "8.UnixBench.sh"

while :; do echo
    colorEchoN "${ORANGE}Please choose test(enter to exit): "
	read -r -n1 CHOICE
	if [[ ! $CHOICE =~ ^[1-3]$ ]]; then
        if [[ -z ${CHOICE} ]]; then
            exit 0
        fi
		colorEcho "${RED}Input error, please choose test from above!"
	else
        echo -e "\n"
		break
	fi
done

case "$CHOICE" in
    1)
        bench
        ;;
    2)
        SuperBench
        ;;
    3)
        SuperSpeed
        ;;
    4)
        Besttrack
        ;;
    5)
        ZBench
        ;;
    6)
        LemonBenchFast
        ;;
    7)
        LemonBenchFull
        ;;
    8)
        UnixBench
        ;;
    *)
        colorEcho "${YELLOW}Wrong choice!"  # unknown option
        ;;
esac


cd "${CURRENT_DIR}" || exit